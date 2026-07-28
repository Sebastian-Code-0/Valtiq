import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/notification_service.dart';
import '../../theme/theme.dart';
import '../../utils/date_format.dart';
import 'recordatorio_form.dart';

class RecordatoriosScreen extends StatefulWidget {
  const RecordatoriosScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen> {
  bool _mostrarInactivos = false;

  Stream<List<Recordatorio>> _stream() {
    return (widget.db.select(widget.db.recordatorios)
          ..where((r) => r.activo.equals(!_mostrarInactivos))
          ..orderBy([(r) => OrderingTerm.asc(r.fechaAlerta)]))
        .watch();
  }

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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar recordatorio'),
        content: Text('¿Eliminar el recordatorio "${r.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.alerta),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.db.recordatoriosDao.deleteRecordatorio(r.id);
    }
  }

  Future<void> _inactivar(Recordatorio r) async {
    await widget.db.recordatoriosDao.desactivarRecordatorio(r.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recordatorio "${r.titulo}" desactivado')),
      );
    }
  }

  Future<void> _activar(Recordatorio r) async {
    await widget.db.recordatoriosDao.activarRecordatorio(r.id);
    await widget.db.recordatoriosDao.resetearDeduplicacion(r.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recordatorio "${r.titulo}" activado')),
      );
    }
  }

  Future<void> _vaciarInactivos() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vaciar recordatorios inactivos'),
        content: const Text(
          '¿Eliminar permanentemente todos los recordatorios inactivos? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar todos',
              style: TextStyle(color: AppColors.alerta),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final eliminados = await widget.db.recordatoriosDao
        .eliminarRecordatoriosInactivos();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            eliminados > 0
                ? 'Se eliminaron $eliminados recordatorios inactivos'
                : 'No hay recordatorios inactivos para eliminar',
          ),
        ),
      );
    }
  }

  Future<void> _probarNotificacion(Recordatorio r) async {
    await NotificationService.showNotification(
      id: r.id,
      title: r.titulo,
      body: '🔔 Prueba — ${fechaRelativa(r.fechaAlerta)}',
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notificación enviada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorSec = theme.colorSecundario;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    'Recordatorios',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_mostrarInactivos)
                    IconButton(
                      onPressed: _vaciarInactivos,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      tooltip: 'Vaciar recordatorios inactivos',
                      color: AppColors.alerta,
                    )
                  else
                    FloatingActionButton.small(
                      heroTag: 'fab_recordatorios',
                      onPressed: () => _abrirForm(),
                      child: const Icon(Icons.add),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _mostrarInactivos = !_mostrarInactivos),
                  icon: Icon(
                    _mostrarInactivos ? Icons.visibility : Icons.history,
                  ),
                  label: Text(
                    _mostrarInactivos ? 'Ver activos' : 'Ver inactivos',
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Recordatorio>>(
                stream: _stream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar los datos.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final lista = snapshot.data!;
                  if (lista.isEmpty) {
                    final mensaje = _mostrarInactivos
                        ? 'No tienes recordatorios inactivos'
                        : 'No tienes recordatorios';
                    return Center(
                      child: Text(
                        mensaje,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorSec,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: lista.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final r = lista[i];
                      return _RecordatorioCard(
                        recordatorio: r,
                        atenuada: _mostrarInactivos,
                        colorSec: colorSec,
                        onTap: () => _abrirForm(recordatorio: r),
                        onLongPress: () => _confirmarEliminar(r),
                        onProbarNotificacion: () => _probarNotificacion(r),
                        onInactivar: _mostrarInactivos
                            ? null
                            : () => _inactivar(r),
                        onActivar: _mostrarInactivos ? () => _activar(r) : null,
                        onEliminar: () => _confirmarEliminar(r),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordatorioCard extends StatelessWidget {
  const _RecordatorioCard({
    required this.recordatorio,
    required this.atenuada,
    required this.colorSec,
    required this.onTap,
    required this.onLongPress,
    required this.onProbarNotificacion,
    required this.onEliminar,
    this.onInactivar,
    this.onActivar,
  });

  final Recordatorio recordatorio;
  final bool atenuada;
  final Color colorSec;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onProbarNotificacion;
  final VoidCallback onEliminar;
  final VoidCallback? onInactivar;
  final VoidCallback? onActivar;

  String _labelReferencia(String tabla) {
    switch (tabla) {
      case 'deuda':
        return 'Deuda';
      case 'prestamo':
        return 'Préstamo';
      case 'gasto':
        return 'Gasto fijo';
      default:
        return tabla;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final diaAlerta = DateTime(
      recordatorio.fechaAlerta.year,
      recordatorio.fechaAlerta.month,
      recordatorio.fechaAlerta.day,
    );
    final diasFaltantes = diaAlerta.difference(hoy).inDays;
    final vencido = diasFaltantes < 0;
    final proximo = !vencido && diasFaltantes <= recordatorio.diasAnticipacion;

    final card = Card(
      color: proximo ? theme.colorScheme.primary.withValues(alpha: 0.12) : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          decoration: vencido
              ? const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.alerta, width: 3),
                  ),
                )
              : null,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recordatorio.titulo,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: colorSec, size: 20),
                    tooltip: 'Acciones',
                    onSelected: (v) {
                      switch (v) {
                        case 'probar':
                          onProbarNotificacion();
                          break;
                        case 'inactivar':
                          onInactivar?.call();
                          break;
                        case 'activar':
                          onActivar?.call();
                          break;
                        case 'eliminar':
                          onEliminar();
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'probar',
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_outlined,
                              size: 18,
                              color: AppColors.acento,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text('Probar notificación'),
                          ],
                        ),
                      ),
                      if (onInactivar != null)
                        const PopupMenuItem(
                          value: 'inactivar',
                          child: Row(
                            children: [
                              Icon(Icons.pause_circle_outline, size: 18),
                              SizedBox(width: AppSpacing.sm),
                              Text('Inactivar'),
                            ],
                          ),
                        ),
                      if (onActivar != null)
                        const PopupMenuItem(
                          value: 'activar',
                          child: Row(
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                size: 18,
                                color: AppColors.positivo,
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Text('Activar'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.alerta,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Eliminar',
                              style: TextStyle(color: AppColors.alerta),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: colorSec),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${formatFecha(recordatorio.fechaAlerta)} — ${fechaRelativa(recordatorio.fechaAlerta)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: vencido ? AppColors.alerta : colorSec,
                        fontWeight: vencido ? FontWeight.bold : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (vencido) ...[
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Vencido',
                  style: TextStyle(
                    color: AppColors.alerta,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (recordatorio.referenciaTabla != null ||
                  recordatorio.repetir) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (recordatorio.referenciaTabla != null)
                      _Chip(
                        label: _labelReferencia(recordatorio.referenciaTabla!),
                      ),
                    if (recordatorio.repetir) const _Chip(label: 'Mensual'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return atenuada ? Opacity(opacity: 0.6, child: card) : card;
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
