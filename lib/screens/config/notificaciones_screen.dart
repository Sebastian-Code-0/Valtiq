import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/notification_service.dart';
import '../../theme/theme.dart';
import '../../utils/form_widgets.dart';
import '../../utils/notificaciones.dart';
import '../../utils/selector_hora.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: NotificationService.programacionSoportada
                  ? _ajustesCelular(context)
                  : [_soloComputador(context)],
            ),
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
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
              ),
              leading: Icon(Icons.schedule, color: c.textoSecundario),
              title: const Text('Hora del aviso'),
              trailing: Text(
                _horaDiario,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: c.acento,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: _elegirHoraDiario,
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      FormSection(
        title: 'Si no te llegan los avisos',
        icon: Icons.help_outline,
        children: [
          Text(
            '• Revisa que Valtiq no tenga restringida la batería: Ajustes '
            'del celular → Aplicaciones → Valtiq → Batería → "Sin '
            'restricciones".\n'
            '• En Xiaomi, Huawei, Oppo y similares, activa también "Inicio '
            'automático" para Valtiq.\n'
            '• Si usas "Forzar detención", Android cancela todos los avisos '
            'hasta que vuelvas a abrir Valtiq.\n'
            '• Los recordatorios por correo se envían cuando abres la '
            'aplicación.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: c.textoSecundario,
            ),
          ),
        ],
      ),
    ];
  }
}
