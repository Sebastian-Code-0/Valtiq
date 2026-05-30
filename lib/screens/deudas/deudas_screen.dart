import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/date_format.dart';
import '../../utils/format.dart';
import 'deuda_detalle.dart';
import 'deuda_form.dart';

class DeudasScreen extends StatefulWidget {
  const DeudasScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<DeudasScreen> createState() => _DeudasScreenState();
}

class _DeudasScreenState extends State<DeudasScreen> {
  bool _mostrarPagadas = false;

  Stream<List<Deuda>> _stream() {
    final estado = _mostrarPagadas ? 'pagada' : 'activa';
    return (widget.db.select(widget.db.deudas)
          ..where((d) => d.estado.equals(estado))
          ..orderBy([(d) => OrderingTerm.desc(d.fechaPrestamo)]))
        .watch();
  }

  Future<void> _abrirForm({Deuda? deuda}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeudaForm(db: widget.db, deuda: deuda),
      ),
    );
  }

  Future<void> _confirmarEliminar(Deuda deuda) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar deuda'),
        content: Text('¿Eliminar la deuda con ${deuda.acreedorNombre}?'),
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
      await widget.db.deudasDao.deleteDeuda(deuda.id);
    }
  }

  Future<void> _confirmarMarcarPagada(Deuda deuda) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como pagada'),
        content: Text(
          '¿Confirmas que ya pagaste la deuda con ${deuda.acreedorNombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.db.deudasDao.marcarComoPagada(deuda.id, DateTime.now());
    }
  }

  Future<void> _confirmarMarcarActiva(Deuda deuda) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reactivar deuda'),
        content: Text(
          '¿Volver a marcar como activa la deuda con ${deuda.acreedorNombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.db.deudasDao.marcarComoActiva(deuda.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorSec = isDark
        ? AppColors.textoSecundarioOscuro
        : AppColors.textoSecundarioClaro;

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
                    'Deudas',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (!_mostrarPagadas)
                    FloatingActionButton.small(
                      heroTag: 'fab_deudas',
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
                  onPressed: () => setState(
                    () => _mostrarPagadas = !_mostrarPagadas,
                  ),
                  icon: Icon(
                    _mostrarPagadas ? Icons.visibility : Icons.history,
                  ),
                  label: Text(
                    _mostrarPagadas ? 'Ver activas' : 'Ver pagadas',
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Deuda>>(
                stream: _stream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final deudas = snapshot.data!;
                  if (deudas.isEmpty) {
                    final mensaje = _mostrarPagadas
                        ? 'No tienes deudas pagadas'
                        : 'No tienes deudas registradas';
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
                    itemCount: deudas.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final d = deudas[i];
                      return _DeudaCard(
                        deuda: d,
                        atenuada: _mostrarPagadas,
                        colorSec: colorSec,
                        onTap: _mostrarPagadas
                            ? () => _abrirForm(deuda: d)
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DeudaDetalle(
                                    db: widget.db,
                                    deudaId: d.id,
                                  ),
                                ),
                              ),
                        onLongPress: () => _confirmarEliminar(d),
                        onMarcarPagada: _mostrarPagadas
                            ? null
                            : () => _confirmarMarcarPagada(d),
                        onMarcarActiva: _mostrarPagadas
                            ? () => _confirmarMarcarActiva(d)
                            : null,
                        onEliminar: () => _confirmarEliminar(d),
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

class _DeudaCard extends StatelessWidget {
  const _DeudaCard({
    required this.deuda,
    required this.atenuada,
    required this.colorSec,
    required this.onTap,
    required this.onLongPress,
    required this.onEliminar,
    this.onMarcarPagada,
    this.onMarcarActiva,
  });

  final Deuda deuda;
  final bool atenuada;
  final Color colorSec;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEliminar;
  final VoidCallback? onMarcarPagada;
  final VoidCallback? onMarcarActiva;

  String _formatTasa(double t) {
    if (t == t.truncateToDouble()) return t.toStringAsFixed(0);
    return t.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vencida =
        deuda.fechaLimite != null &&
        deuda.fechaLimite!.isBefore(DateTime.now());

    final card = Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
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
                      deuda.acreedorNombre,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      formatCOP(deuda.montoOriginal),
                      style: monoStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.alerta,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: colorSec, size: 20),
                    tooltip: 'Acciones',
                    onSelected: (v) {
                      switch (v) {
                        case 'pagada':
                          onMarcarPagada?.call();
                          break;
                        case 'activa':
                          onMarcarActiva?.call();
                          break;
                        case 'eliminar':
                          onEliminar();
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      if (onMarcarPagada != null)
                        const PopupMenuItem(
                          value: 'pagada',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 18,
                                color: AppColors.positivo,
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Text('Marcar como pagada'),
                            ],
                          ),
                        ),
                      if (onMarcarActiva != null)
                        const PopupMenuItem(
                          value: 'activa',
                          child: Row(
                            children: [
                              Icon(
                                Icons.undo,
                                size: 18,
                                color: AppColors.acento,
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Text('Reactivar deuda'),
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
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: colorSec),
                    const SizedBox(width: 4),
                    Text(
                      formatFecha(deuda.fechaPrestamo),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorSec,
                      ),
                    ),
                    if (deuda.tasaInteres > 0) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.acento.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: Text(
                          '${_formatTasa(deuda.tasaInteres)}% ${deuda.tipoInteres}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.acento,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (deuda.fechaLimite != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Text(
                    'Vence: ${formatFecha(deuda.fechaLimite!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: vencida ? AppColors.alerta : colorSec,
                      fontWeight: vencida ? FontWeight.bold : null,
                    ),
                  ),
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
