import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/notification_service.dart';
import '../../theme/theme.dart';
import '../../utils/form_widgets.dart';
import '../../utils/notificaciones.dart';
import '../../utils/selector_hora.dart';
import 'ajustes_widgets.dart';
import 'settings_screen.dart';

/// Configuración → Notificaciones: permiso, avisos a la hora exacta y
/// recordatorio diario. En PC solo explica cómo funcionan los avisos ahí
/// (no se pueden programar con la app cerrada).
class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen>
    with WidgetsBindingObserver {
  bool _cargando = true;
  bool? _permitidas;
  bool _exactos = false;
  bool _diario = false;
  int _diarioMinutos = NotificationService.recordatorioDiarioPorDefecto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // El usuario puede cambiar permisos en los Ajustes de Android y volver:
  // se relee el estado real en vez de confiar en lo último que se mostró.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cargar();
  }

  Future<void> _cargar() async {
    final permitidas = await NotificationService.notificacionesPermitidas();
    final exactos = await NotificationService.avisosExactosActivados();
    final diario = await NotificationService.recordatorioDiario();
    if (!mounted) return;
    setState(() {
      _permitidas = permitidas;
      _exactos = exactos;
      _diario = diario.activo;
      _diarioMinutos = diario.minutos;
      _cargando = false;
    });
  }

  Future<void> _pedirPermiso() async {
    await NotificationService.solicitarPermisoNotificaciones();
    await _cargar();
    if (mounted && _permitidas == false) {
      mostrarAlerta(
        context,
        'Android no mostró la pregunta. Actívalas en Ajustes del celular → '
        'Aplicaciones → Valtiq → Notificaciones.',
        duracion: const Duration(seconds: 7),
      );
    }
  }

  Future<void> _cambiarExactos(bool activar) async {
    final quedo = await NotificationService.setAvisosExactos(
      widget.db,
      activar,
    );
    if (!mounted) return;
    setState(() => _exactos = quedo);
    if (activar && !quedo) {
      mostrarInfo(
        context,
        'Falta el permiso "Alarmas y recordatorios". Sin él, tus avisos '
        'llegan igual, con unos minutos de margen.',
        duracion: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _cambiarDiario(bool activo) async {
    setState(() => _diario = activo);
    await NotificationService.setRecordatorioDiario(
      widget.db,
      activo: activo,
      minutos: _diarioMinutos,
    );
  }

  Future<void> _elegirHoraDiario() async {
    final elegida = await mostrarSelectorHora(
      context,
      hora: _diarioMinutos ~/ 60,
      minuto: _diarioMinutos % 60,
      titulo: 'Hora del aviso',
    );
    if (elegida == null) return;
    final minutos = elegida.hora * 60 + elegida.minuto;
    setState(() => _diarioMinutos = minutos);
    await NotificationService.setRecordatorioDiario(
      widget.db,
      activo: _diario,
      minutos: minutos,
    );
  }

  String get _horaDiario =>
      formatHora12(_diarioMinutos ~/ 60, _diarioMinutos % 60);

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: barraAjustes(context, 'Notificaciones'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return PaginaAjustes(
      titulo: 'Notificaciones',
      children: NotificationService.programacionSoportada
          ? _ajustesCelular(context)
          : [_soloComputador(context)],
    );
  }

  Widget _soloComputador(BuildContext context) {
    return FormSection(
      title: 'Avisos en el computador',
      icon: Icons.computer_outlined,
      children: [
        Text(
          'En el computador, Valtiq te avisa de tus recordatorios cuando '
          'abres la aplicación o vuelves a ella. Con la aplicación cerrada '
          'no puede avisarte.\n\n'
          'En el celular (Android) los avisos sí llegan a su hora aunque '
          'Valtiq esté cerrado.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  List<Widget> _ajustesCelular(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    final permitidas = _permitidas ?? true;
    return [
      FormSection(
        title: 'Permiso',
        icon: Icons.notifications_active_outlined,
        children: [
          Row(
            children: [
              Icon(
                permitidas ? Icons.check_circle : Icons.error_outline,
                color: permitidas ? c.positivo : c.alerta,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  permitidas
                      ? 'Las notificaciones están activadas.'
                      : 'Las notificaciones están desactivadas: no te va a '
                            'llegar ningún aviso.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (!permitidas) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _pedirPermiso,
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('Permitir notificaciones'),
            ),
          ],
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      FormSection(
        title: 'Tus recordatorios',
        icon: Icons.alarm_outlined,
        children: [
          Text(
            'Tus recordatorios llegan a la hora que elegiste aunque Valtiq '
            'esté cerrado, y se vuelven a programar solos si reinicias o '
            'apagas el celular.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: c.textoSecundario,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchTile(
            icon: Icons.timer_outlined,
            title: 'Avisar a la hora exacta',
            subtitle:
                'Sin esto, Android puede retrasar el aviso unos minutos '
                'para ahorrar batería. Te pedirá el permiso "Alarmas y '
                'recordatorios".',
            value: _exactos,
            onChanged: _cambiarExactos,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      FormSection(
        title: 'Recordatorio diario',
        icon: Icons.edit_calendar_outlined,
        children: [
          SwitchTile(
            icon: Icons.receipt_long_outlined,
            title: 'Recordarme anotar mis gastos',
            subtitle: 'Un aviso cada día para que no se te pase ninguno.',
            value: _diario,
            onChanged: _cambiarDiario,
          ),
          if (_diario)
            InkWell(
              onTap: _elegirHoraDiario,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 20, color: c.textoSecundario),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Hora del aviso',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // La hora en una píldora, como en el formulario de
                    // recordatorio.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: ShapeDecoration(
                        color: c.relieve,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: c.divisor,
                            width: AppSpacing.borde,
                          ),
                        ),
                      ),
                      child: Text(
                        _horaDiario,
                        style: monoStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      const ConsejosNotificaciones(),
    ];
  }
}

/// "Si no te llegan los avisos". Siempre a la vista (no plegable): es lo
/// que hay que leer cuando un aviso no llega.
class ConsejosNotificaciones extends StatelessWidget {
  const ConsejosNotificaciones({super.key});

  @override
  Widget build(BuildContext context) {
    return const FormSection(
      title: 'Si no te llegan los avisos',
      icon: Icons.help_outline,
      children: [
        _Consejo(
          icono: Icons.battery_saver_outlined,
          titulo: 'Quítale la restricción de batería',
          texto:
              'Ajustes del celular → Aplicaciones → Valtiq → Batería → '
              '"Sin restricciones".',
        ),
        _Consejo(
          icono: Icons.rocket_launch_outlined,
          titulo: 'Activa el "Inicio automático"',
          texto:
              'En Xiaomi, Huawei, Oppo y similares hace falta para que '
              'los avisos vuelvan después de reiniciar.',
        ),
        _Consejo(
          icono: Icons.block_outlined,
          titulo: 'No uses "Forzar detención"',
          texto:
              'Android cancela todos los avisos hasta que vuelvas a abrir '
              'Valtiq.',
        ),
        _Consejo(
          icono: Icons.email_outlined,
          titulo: 'Los correos salen al abrir Valtiq',
          texto:
              'Los recordatorios por correo se envían cuando abres la '
              'aplicación.',
          ultimo: true,
        ),
      ],
    );
  }
}

/// Un consejo de "Si no te llegan los avisos": ícono en recuadro, qué
/// hacer en negrita y el detalle debajo.
class _Consejo extends StatelessWidget {
  const _Consejo({
    required this.icono,
    required this.titulo,
    required this.texto,
    this.ultimo = false,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.relieve,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, size: 18, color: c.textoSecundario),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  texto,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    height: 1.4,
                    color: c.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
