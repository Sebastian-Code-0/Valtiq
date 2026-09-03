import 'package:flutter/material.dart';

import '../db/database.dart';
import '../main.dart';
import '../services/crypto_service.dart';
import '../services/notification_service.dart';
import '../utils/notificaciones.dart';
import 'config/config_smtp_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'deudas/deudas_screen.dart';
import 'finanzas/finanzas_screen.dart';
import 'prestamos/prestamos_screen.dart';
import 'recordatorios/recordatorios_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;
  final List<bool> _visitada = [true, false, false, false, false];

  @override
  void initState() {
    super.initState();
    // ShellScreen monta igual aunque el bloqueo PIN/biometría esté activo
    // (SplashScreen navega acá con su propio timer, sin esperar a que se
    // desbloquee — el bloqueo es solo un overlay visual encima). Mostrar
    // estos avisos sin importar eso sería un hueco de seguridad real:
    // información sobre el estado de la cuenta quedaría lista/mostrándose
    // antes de que alguien probara el PIN. `appDesbloqueadaNotifier` (ver
    // main.dart) es falso mientras la app arranca bloqueada.
    if (appDesbloqueadaNotifier.value) {
      _revisarAvisosPendientes();
    } else {
      appDesbloqueadaNotifier.addListener(_onAppDesbloqueada);
    }
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _avisarClavePerdida());
    }
    if (NotificationService.ingresosUnicosDesactivados.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _avisarIngresosDesactivados(),
      );
    }
  }

  @override
  void dispose() {
    appDesbloqueadaNotifier.removeListener(_onAppDesbloqueada);
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
        MaterialPageRoute(
          builder: (_) => ConfigSmtpScreen(db: widget.db),
        ),
      );
    }
  }

  void _cambiarIndice(int i) {
    setState(() {
      _index = i;
      _visitada[i] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pantallas = [
      DashboardScreen(db: widget.db),
      DeudasScreen(db: widget.db),
      PrestamosScreen(db: widget.db),
      FinanzasScreen(db: widget.db),
      RecordatoriosScreen(db: widget.db),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < pantallas.length; i++)
            _visitada[i] ? pantallas[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _cambiarIndice,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Deudas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake_outlined),
            label: 'Préstamos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Finanzas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Recordatorios',
          ),
        ],
      ),
    );
  }
}
