import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../db/database.dart';
import '../main.dart';
import '../services/crypto_service.dart';
import '../services/notification_service.dart';
import '../services/widgets_service.dart';
import '../utils/notificaciones.dart';
import '../utils/fecha_civil.dart';
import '../utils/preferencia_menu.dart';
import 'barra_inferior.dart';
import 'barra_lateral.dart';
import 'config/config_smtp_screen.dart';
import 'config/settings_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'deudas/deudas_screen.dart';
import 'finanzas/finanzas_screen.dart';
import 'prestamos/prestamos_screen.dart';
import 'recordatorios/recordatorios_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, required this.db, this.ahora = DateTime.now});

  final AppDatabase db;

  /// Reloj de la pantalla. Solo se reemplaza en tests, para simular que la
  /// app quedó abierta de un mes a otro.
  final DateTime Function() ahora;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> with WidgetsBindingObserver {
  int _index = 0;
  final List<bool> _visitada = [true, false, false, false, false, false];

  /// Posición de Ajustes en la lista de pantallas (después de las 5 pestañas).
  static const _indiceAjustes = 5;
  int _vecesPerfil = 0;

  late final Stream<List<Recordatorio>> _streamRecordatoriosActivos =
      (widget.db.select(
        widget.db.recordatorios,
      )..where((r) => r.activo.equals(true))).watch();

  /// Mes (año*12+mes) con el que se montaron las pestañas. Los totales "de
  /// este mes" fijan el mes al crearse; si la app sigue abierta cuando
  /// cambia el mes, hay que volver a montarlas (ver [_alVolver]).
  late int _mesMontado = _claveMes(widget.ahora());

  static int _claveMes(DateTime d) => d.year * 12 + d.month;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ShellScreen monta igual aunque el bloqueo PIN/biometría esté activo
    // (SplashScreen navega acá con su propio timer, sin esperar a que se
    // desbloquee — el bloqueo es solo un overlay visual encima). Mostrar
    // estos avisos sin importar eso sería un hueco de seguridad real:
    // información sobre el estado de la cuenta quedaría lista/mostrándose
    // antes de que alguien probara el PIN. `appDesbloqueadaNotifier` (ver
    // main.dart) es falso mientras la app arranca bloqueada.
    _escucharWidgets();
    if (appDesbloqueadaNotifier.value) {
      _revisarAvisosPendientes();
    } else {
      appDesbloqueadaNotifier.addListener(_onAppDesbloqueada);
    }
  }

  StreamSubscription<Uri?>? _widgetTocado;

  /// Al tocar el widget de deudas o de préstamos se abre Valtiq en esa
  /// sección (con el bloqueo con PIN de siempre, si está activo).
  void _escucharWidgets() {
    if (!WidgetsService.soportado) return;
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_abrirDesdeWidget);
    _widgetTocado = HomeWidget.widgetClicked.listen(_abrirDesdeWidget);
  }

  void _abrirDesdeWidget(Uri? uri) {
    final seccion = WidgetsService.seccionDeUri(uri);
    if (seccion == null || !mounted) return;
    _cambiarIndice(seccion == 'deudas' ? 1 : 2);
  }

  void _onAppDesbloqueada() {
    if (!appDesbloqueadaNotifier.value) return;
    appDesbloqueadaNotifier.removeListener(_onAppDesbloqueada);
    _revisarAvisosPendientes();
  }

  void _revisarAvisosPendientes() {
    // CryptoService.claveFueRegenerada queda fijo desde CryptoService.init()
    // en main(), antes de runApp() — es seguro leerlo una sola vez aquí. Si
    // la clave se regeneró (corrupta o migración fallida desde el archivo
    // viejo), cualquier config SMTP cifrada con la clave anterior quedó
    // ilegible: ConfigSmtpDao.getPassword() ya la limpia sola al detectarlo,
    // pero eso solo pasa cuando se intenta usar — sin este aviso, el usuario
    // no se entera hasta que un correo falla en silencio.
    if (CryptoService.claveFueRegenerada) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _avisarClavePerdida(),
      );
    }
    if (NotificationService.ingresosUnicosDesactivados.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _avisarIngresosDesactivados(),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_alVolver());
  }

  /// Al volver a primer plano. Antes los recordatorios solo se revisaban al
  /// ARRANCAR: en Android la app puede quedar viva en segundo plano varios
  /// días, y en ese tiempo no salía ningún aviso aunque se abriera a diario.
  Future<void> _alVolver() async {
    // Lo anotado desde el widget de "Anotar gasto" entra por otra conexión
    // a la base: se avisa a las pantallas para que lo muestren.
    widget.db.markTablesUpdated([widget.db.gastosVariables]);

    unawaited(
      NotificationService.sincronizar(widget.db).catchError((Object e) {
        debugPrint('ShellScreen: fallo al revisar recordatorios al volver: $e');
      }),
    );

    final mesActual = _claveMes(widget.ahora());
    if (mesActual == _mesMontado) return;
    // Cambió el mes con la app abierta: mismo trabajo que hace main() al
    // arrancar en un mes nuevo, y se remontan las pestañas para que sus
    // totales apunten al mes correcto.
    final desactivados =
        await NotificationService.revisarIngresosUnicosVencidos(widget.db);
    if (!mounted) return;
    setState(() => _mesMontado = mesActual);
    if (desactivados > 0 && appDesbloqueadaNotifier.value) {
      _avisarIngresosDesactivados();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appDesbloqueadaNotifier.removeListener(_onAppDesbloqueada);
    _widgetTocado?.cancel();
    super.dispose();
  }

  void _avisarIngresosDesactivados() {
    if (!mounted) return;
    final nombres = NotificationService.ingresosUnicosDesactivados;
    final texto = nombres.length == 1
        ? '"${nombres.first}" se movió a Desactivados: ya pasó su mes.'
        : '${nombres.length} ingresos únicos se movieron a Desactivados: '
              'ya pasó su mes.';
    mostrarInfo(context, texto);
  }

  Future<void> _avisarClavePerdida() async {
    if (!mounted) return;
    final abrirConfig = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configuración de correo perdida'),
        content: const Text(
          'No se pudo recuperar la clave de cifrado guardada, así que la '
          'contraseña de tu configuración de correo (SMTP) ya no es '
          'legible y tendrás que ingresarla de nuevo. El resto de tus '
          'datos no se vio afectado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Más tarde'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ir a Configuración'),
          ),
        ],
      ),
    );
    if (abrirConfig == true && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ConfigSmtpScreen(db: widget.db)),
      );
    }
  }

  void _cambiarIndice(int i) {
    setState(() {
      _index = i;
      _visitada[i] = true;
    });
  }

  /// Desde el perfil del menú lateral: abre Ajustes directo en "Perfil".
  void _abrirPerfil() {
    setState(() {
      _index = _indiceAjustes;
      _visitada[_indiceAjustes] = true;
      // Clave nueva = Ajustes se vuelve a montar ya parado en Perfil,
      // aunque estuviera abierto en otra sección.
      _vecesPerfil++;
    });
  }

  /// Cuántos recordatorios activos ya están en su ventana de aviso o
  /// vencidos: el número de la insignia junto a "Recordatorios".
  int _recordatoriosPendientes(List<Recordatorio> lista) {
    final hoy = normalizarFechaCivil(widget.ahora());
    return lista.where((r) {
      final dias = fechaCivilGuardada(r.fechaAlerta).difference(hoy).inDays;
      return dias <= r.diasAnticipacion;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final pantallas = [
      DashboardScreen(db: widget.db),
      DeudasScreen(db: widget.db),
      PrestamosScreen(db: widget.db),
      FinanzasScreen(db: widget.db),
      RecordatoriosScreen(db: widget.db),
      // Solo se llega aquí desde el menú lateral (PC). En celular, Ajustes
      // se abre como página aparte desde el ícono de Inicio.
      SettingsScreen(
        key: ValueKey('ajustes-$_vecesPerfil'),
        db: widget.db,
        embebido: true,
      ),
    ];

    final escritorio =
        MediaQuery.sizeOf(context).width >= anchoMinimoBarraLateral;
    // Si la ventana se achica estando en Ajustes, en la barra inferior no
    // existe esa pestaña: se muestra Inicio.
    final indice = !escritorio && _index == _indiceAjustes ? 0 : _index;

    final contenido = IndexedStack(
      index: indice,
      children: [
        for (var i = 0; i < pantallas.length; i++)
          _visitada[i]
              ? KeyedSubtree(
                  key: ValueKey('pestana-$i-$_mesMontado'),
                  child: pantallas[i],
                )
              : const SizedBox.shrink(),
      ],
    );

    return ValueListenableBuilder<bool>(
      valueListenable: menuSuperiorNotifier,
      // Un solo StreamBuilder para la insignia de Recordatorios, la muestre
      // el menú de PC o la barra del celular.
      builder: (context, menuArriba, _) => StreamBuilder<List<Recordatorio>>(
        stream: _streamRecordatoriosActivos,
        builder: (context, snap) {
          final pendientes = _recordatoriosPendientes(snap.data ?? const []);
          return Scaffold(
            // Siempre un Flex, con o sin menú y esté el menú al lado o
            // arriba: el contenido lleva clave para que las pestañas
            // conserven su estado si la ventana cruza el ancho que separa el
            // diseño de PC del de celular o si se cambia la posición del
            // menú.
            body: Flex(
              direction: escritorio && menuArriba
                  ? Axis.vertical
                  : Axis.horizontal,
              children: [
                if (escritorio)
                  KeyedSubtree(
                    key: ValueKey(
                      menuArriba ? 'barra-superior' : 'barra-lateral',
                    ),
                    child: _menuEscritorio(menuArriba, indice, pendientes),
                  ),
                Expanded(key: const ValueKey('contenido'), child: contenido),
              ],
            ),
            bottomNavigationBar: escritorio
                ? null
                : BarraInferior(
                    indice: indice,
                    onElegir: _cambiarIndice,
                    items: [
                      const ItemBarraInferior(
                        'Inicio',
                        Icons.home_outlined,
                        Icons.home_rounded,
                      ),
                      const ItemBarraInferior(
                        'Deudas',
                        Icons.credit_card_outlined,
                        Icons.credit_card,
                      ),
                      const ItemBarraInferior(
                        'Préstamos',
                        Icons.handshake_outlined,
                        Icons.handshake,
                      ),
                      const ItemBarraInferior(
                        'Finanzas',
                        Icons.insights_outlined,
                        Icons.insights,
                      ),
                      ItemBarraInferior(
                        'Avisos',
                        Icons.notifications_outlined,
                        Icons.notifications,
                        nombreCompleto: 'Recordatorios',
                        contador: pendientes,
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _menuEscritorio(bool menuArriba, int indice, int pendientes) {
    final items = [
      const ItemBarraLateral('Inicio'),
      const ItemBarraLateral('Deudas'),
      const ItemBarraLateral('Préstamos'),
      const ItemBarraLateral('Finanzas'),
      ItemBarraLateral('Recordatorios', contador: pendientes),
    ];
    return menuArriba
        ? BarraSuperior(
            items: items,
            indice: indice,
            indiceAjustes: _indiceAjustes,
            onElegir: _cambiarIndice,
            onPerfil: _abrirPerfil,
          )
        : BarraLateral(
            items: items,
            indice: indice,
            indiceAjustes: _indiceAjustes,
            onElegir: _cambiarIndice,
            onPerfil: _abrirPerfil,
          );
  }
}
