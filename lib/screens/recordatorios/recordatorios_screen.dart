import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/notification_service.dart';
import '../../theme/theme.dart';
import '../../utils/confirmar.dart';
import '../../utils/date_format.dart';
import '../../utils/encabezado_pantalla.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/form_widgets.dart';
import '../../utils/notificaciones.dart';
import '../../utils/selector_hora.dart';
import '../../utils/selector_pildoras.dart';
import 'recordatorio_form.dart';

class RecordatoriosScreen extends StatefulWidget {
  const RecordatoriosScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen> {
  static const _pestanas = [
    OpcionPildora('Activos'),
    OpcionPildora('Inactivos'),
  ];

  // Un solo stream para las dos pestañas; se separan en Dart.
  late final Stream<List<Recordatorio>> _stream = (widget.db.select(
    widget.db.recordatorios,
  )..orderBy([(r) => OrderingTerm.asc(r.fechaAlerta)])).watch();

  int _pestana = 0;

  bool get _mostrarInactivos => _pestana == 1;

  Future<void> _abrirForm({Recordatorio? recordatorio}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RecordatorioForm(db: widget.db, recordatorio: recordatorio),
      ),
    );
  }

  Future<void> _confirmarEliminar(Recordatorio r) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar recordatorio',
      mensaje: '¿Eliminar el recordatorio "${r.titulo}"?',
      accion: 'Eliminar',
      peligro: true,
    );
    if (ok) await widget.db.recordatoriosDao.deleteRecordatorio(r.id);
  }

  Future<void> _inactivar(Recordatorio r) async {
    await widget.db.recordatoriosDao.desactivarRecordatorio(r.id);
    if (mounted) {
      mostrarInfo(context, 'Recordatorio "${r.titulo}" desactivado');
    }
  }

  Future<void> _activar(Recordatorio r) async {
    await widget.db.recordatoriosDao.activarRecordatorio(r.id);
    await widget.db.recordatoriosDao.resetearDeduplicacion(r.id);
    if (mounted) {
      mostrarInfo(context, 'Recordatorio "${r.titulo}" activado');
    }
  }

  Future<void> _vaciarInactivos() async {
    final ok = await confirmar(
      context,
      titulo: 'Vaciar recordatorios inactivos',
      mensaje:
          '¿Eliminar permanentemente todos los recordatorios inactivos? '
          'Esta acción no se puede deshacer.',
      accion: 'Eliminar todos',
      peligro: true,
    );
    if (!ok) return;
    final eliminados = await widget.db.recordatoriosDao
        .eliminarRecordatoriosInactivos();
    if (mounted) {
      if (eliminados > 0) {
        mostrarExito(
          context,
          'Se eliminaron $eliminados recordatorios inactivos',
        );
      } else {
        mostrarInfo(context, 'No hay recordatorios inactivos para eliminar');
      }
    }
  }

  Future<void> _probarNotificacion(Recordatorio r) async {
    await NotificationService.showNotification(
      id: r.id,
      title: r.titulo,
      body:
          'Así se verá este aviso. Fecha: '
          '${fechaRelativa(fechaCivilGuardada(r.fechaAlerta))}',
    );
    if (mounted) {
      mostrarInfo(context, 'Notificación enviada');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Recordatorio>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error al cargar los datos.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final todos = snapshot.data!;
            final activos = [
              for (final r in todos)
                if (r.activo) r,
            ];
            final inactivos = [
              for (final r in todos)
                if (!r.activo) r,
            ];
            // Los que ya están en su ventana de aviso o vencidos: el mismo
            // número de la insignia del menú.
            final pendientes = activos
                .where((r) => _Tiempo(r).pendiente)
                .length;
            final lista = _mostrarInactivos ? inactivos : activos;

            return LayoutBuilder(
              builder: (context, constraints) {
                final ancho = constraints.maxWidth >= 800;
                final margen = ancho ? AppSpacing.xl : AppSpacing.md;
                return Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppSpacing.anchoContenido + 2 * margen,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            margen,
                            margen,
                            margen,
                            AppSpacing.lg,
                          ),
                          child: EncabezadoPantalla(
                            kicker: switch (pendientes) {
                              0 => 'Nada pendiente',
                              1 => '1 pendiente',
                              _ => '$pendientes pendientes',
                            },
                            titulo: 'Recordatorios',
                            accion: BotonCrear(
                              texto: 'Nuevo recordatorio',
                              heroTag: 'fab_recordatorios',
                              onPressed: () => _abrirForm(),
                            ),
                          ),
                        ),
                        // Pestañas a la izquierda y, en "Inactivos", el botón
                        // de vaciar a la derecha, en la misma fila.
                        Row(
                          children: [
                            Expanded(
                              child: SelectorPildoras(
                                opciones: _pestanas,
                                seleccionada: _pestana,
                                margen: margen,
                                repartirEnCelular: true,
                                onElegir: (i) => setState(() => _pestana = i),
                              ),
                            ),
                            if (_mostrarInactivos && inactivos.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(right: margen),
                                child: BotonLimpiarHistorial(
                                  texto: 'Vaciar inactivos',
                                  onPressed: _vaciarInactivos,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: ancho ? AppSpacing.md : AppSpacing.sm),
                        Expanded(
                          child: lista.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.lg,
                                    ),
                                    child: Text(
                                      _mostrarInactivos
                                          ? 'No tienes recordatorios inactivos'
                                          : 'No tienes recordatorios.\n'
                                                'Toca + para crear uno.',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(color: c.textoSecundario),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.fromLTRB(
                                    margen,
                                    AppSpacing.sm,
                                    margen,
                                    margen,
                                  ),
                                  itemCount: lista.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    final r = lista[i];
                                    return _RecordatorioCard(
                                      key: ValueKey(r.id),
                                      recordatorio: r,
                                      atenuada: _mostrarInactivos,
                                      onTap: () => _abrirForm(recordatorio: r),
                                      onProbarNotificacion: () =>
                                          _probarNotificacion(r),
                                      onInactivar: _mostrarInactivos
                                          ? null
                                          : () => _inactivar(r),
                                      onActivar: _mostrarInactivos
                                          ? () => _activar(r)
                                          : null,
                                      onEliminar: () => _confirmarEliminar(r),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Cuánto falta para un recordatorio, contado en días de calendario.
class _Tiempo {
  _Tiempo(Recordatorio r) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    // fechaAlerta se guarda como medianoche UTC (fecha civil); se extrae con
    // .toUtc() y se reconstruye en convención local para comparar contra
    // "hoy" (también local) con diferencias exactas de 24h.
    fecha = fechaCivilGuardada(r.fechaAlerta);
    dias = DateTime(fecha.year, fecha.month, fecha.day).difference(hoy).inDays;
    vencido = dias < 0;
    proximo = !vencido && dias <= r.diasAnticipacion;
  }

  late final DateTime fecha;
  late final int dias;
  late final bool vencido;

  /// Ya entró en sus días de anticipación.
  late final bool proximo;

  bool get pendiente => vencido || proximo;
}

String _labelReferencia(String tabla) => switch (tabla) {
  'deuda' => 'Deuda',
  'prestamo' => 'Préstamo',
  'gasto' => 'Gasto fijo',
  _ => tabla,
};

/// Tarjeta de un recordatorio: recuadro con el día y el mes (con aro rojo
/// si está vencido, vino si ya está cerca), título, de qué es y cuánto
/// falta, la hora del aviso y el menú de acciones.
class _RecordatorioCard extends StatelessWidget {
  const _RecordatorioCard({
    super.key,
    required this.recordatorio,
    required this.atenuada,
    required this.onTap,
    required this.onProbarNotificacion,
    required this.onEliminar,
    this.onInactivar,
    this.onActivar,
  });

  final Recordatorio recordatorio;
  final bool atenuada;
  final VoidCallback onTap;
  final VoidCallback onProbarNotificacion;
  final VoidCallback onEliminar;
  final VoidCallback? onInactivar;
  final VoidCallback? onActivar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    final r = recordatorio;
    final t = _Tiempo(r);
    final vencido = t.vencido && !atenuada;
    final proximo = t.proximo && !atenuada;
    final colorEstado = vencido
        ? c.alerta
        : proximo
        ? c.acento
        : c.textoSecundario;
    final pequeno = theme.textTheme.bodySmall?.copyWith(
      color: c.textoSecundario,
    );
    final detalles = [
      if (r.referenciaTabla != null) _labelReferencia(r.referenciaTabla!),
      if (r.repetir) 'Cada mes',
      formatHora12(r.horaAviso, r.minutoAviso),
    ].join(' · ');

    final card = Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.divisor, width: AppSpacing.borde),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onEliminar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
          child: Row(
            children: [
              // Día y mes.
              Container(
                width: 46,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: vencido || proximo ? colorEstado : c.divisor,
                    width: vencido || proximo ? 1.5 : AppSpacing.borde,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${t.fecha.day}',
                      style: TextStyle(
                        fontFamily: fuenteTexto,
                        fontSize: 18,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: c.texto,
                      ),
                    ),
                    Text(
                      SelectorMes.nombreMesCorto(t.fecha.month).toUpperCase(),
                      style: TextStyle(
                        fontFamily: fuenteTexto,
                        fontSize: 10.5,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                        color: c.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Cuánto falta, en una etiqueta del color del estado.
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 2,
                          ),
                          decoration: ShapeDecoration(
                            color: vencido || proximo
                                ? colorEstado.withValues(alpha: 0.14)
                                : c.relieve,
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            vencido
                                ? 'Vencido · ${fechaRelativa(t.fecha).toLowerCase()}'
                                : fechaRelativa(t.fecha),
                            style: pequeno?.copyWith(
                              color: colorEstado,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(detalles, style: pequeno),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 32,
                height: 32,
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: c.textoSecundario,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: 'Acciones',
                  onSelected: (v) => switch (v) {
                    'editar' => onTap(),
                    'probar' => onProbarNotificacion(),
                    'inactivar' => onInactivar?.call(),
                    'activar' => onActivar?.call(),
                    _ => onEliminar(),
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'editar', child: Text('Editar')),
                    const PopupMenuItem(
                      value: 'probar',
                      child: Text('Probar notificación'),
                    ),
                    if (onInactivar != null)
                      const PopupMenuItem(
                        value: 'inactivar',
                        child: Text('Inactivar'),
                      ),
                    if (onActivar != null)
                      const PopupMenuItem(
                        value: 'activar',
                        child: Text('Activar'),
                      ),
                    PopupMenuItem(
                      value: 'eliminar',
                      child: Text(
                        'Eliminar',
                        style: TextStyle(color: c.alerta),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return atenuada ? Opacity(opacity: 0.6, child: card) : card;
  }
}
