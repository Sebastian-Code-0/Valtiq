import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/interes_calculator.dart';
import '../../theme/theme.dart';
import '../../utils/date_format.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../../utils/notificaciones.dart';
import 'deuda_detalle.dart';
import 'deuda_form.dart';

class _DeudaConAbonos {
  _DeudaConAbonos(this.deuda, this.abonado);
  final Deuda deuda;
  final double abonado;
}

class DeudasScreen extends StatefulWidget {
  const DeudasScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<DeudasScreen> createState() => _DeudasScreenState();
}

class _DeudasScreenState extends State<DeudasScreen> {
  bool _mostrarPagadas = false;

  Stream<List<_DeudaConAbonos>> _stream() {
    final estado = _mostrarPagadas ? 'pagada' : 'activa';
    final d = widget.db.deudas;
    final pd = widget.db.pagosDeuda;
    final sumExpr = pd.montoAbonado.sum();

    final query =
        widget.db.select(d).join([
            leftOuterJoin(pd, pd.deudaId.equalsExp(d.id)),
          ])
          ..where(d.estado.equals(estado))
          ..groupBy([d.id])
          ..orderBy([OrderingTerm.desc(d.fechaPrestamo)])
          ..addColumns([sumExpr]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) =>
                _DeudaConAbonos(row.readTable(d), row.read(sumExpr) ?? 0.0),
          )
          .toList(),
    );
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
        content: Text(
          '¿Eliminar la deuda con ${deuda.acreedorNombre}? '
          'También se eliminarán sus pagos registrados.',
        ),
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
      try {
        await widget.db.deudasDao.deleteDeudaConPagos(deuda.id);
      } catch (_) {
        if (mounted) {
          mostrarAlerta(context, 'No se pudo eliminar la deuda.');
        }
      }
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
                  onPressed: () =>
                      setState(() => _mostrarPagadas = !_mostrarPagadas),
                  icon: Icon(
                    _mostrarPagadas ? Icons.visibility : Icons.history,
                  ),
                  label: Text(_mostrarPagadas ? 'Ver activas' : 'Ver pagadas'),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<_DeudaConAbonos>>(
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
                  final items = snapshot.data!;
                  if (items.isEmpty) {
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
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return _DeudaCard(
                        key: ValueKey(item.deuda.id),
                        deuda: item.deuda,
                        abonado: item.abonado,
                        atenuada: _mostrarPagadas,
                        colorSec: colorSec,
                        onTap: _mostrarPagadas
                            ? () => _abrirForm(deuda: item.deuda)
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DeudaDetalle(
                                    db: widget.db,
                                    deudaId: item.deuda.id,
                                  ),
                                ),
                              ),
                        onLongPress: () => _confirmarEliminar(item.deuda),
                        onMarcarPagada: _mostrarPagadas
                            ? null
                            : () => _confirmarMarcarPagada(item.deuda),
                        onMarcarActiva: _mostrarPagadas
                            ? () => _confirmarMarcarActiva(item.deuda)
                            : null,
                        onEliminar: () => _confirmarEliminar(item.deuda),
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
    super.key,
    required this.deuda,
    required this.abonado,
    required this.atenuada,
    required this.colorSec,
    required this.onTap,
    required this.onLongPress,
    required this.onEliminar,
    this.onMarcarPagada,
    this.onMarcarActiva,
  });

  final Deuda deuda;
  final double abonado;
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
    final saldo = InteresCalculator.calcularDeudaTotal(
      montoPrestado: deuda.montoOriginal,
      tasaInteres: deuda.tasaInteres,
      tipoInteres: deuda.tipoInteres,
      modalidadCalculo: deuda.modalidadCalculo,
      fechaPrestamo: deuda.fechaPrestamo,
      totalAbonado: abonado,
    );
    final totalConInteres = abonado + saldo;
    final fraccionPagada = totalConInteres > 0
        ? abonado / totalConInteres
        : 0.0;
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
                  Expanded(
                    child: Text(
                      formatCOP(deuda.montoOriginal),
                      style: monoStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.alerta,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: colorSec, size: 20),
                    padding: EdgeInsets.zero,
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
                        PopupMenuItem(
                          value: 'activa',
                          child: Row(
                            children: [
                              Icon(
                                Icons.undo,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Text('Reactivar deuda'),
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
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: Text(
                          '${_formatTasa(deuda.tasaInteres)}% ${deuda.tipoInteres}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
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
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saldo pendiente',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
                  ),
                  Flexible(
                    child: Text(
                      formatCOP(saldo),
                      style: monoStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: saldo > 0
                            ? AppColors.alerta
                            : AppColors.positivo,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: BarraProgreso(
                      fraccion: fraccionPagada,
                      color: AppColors.positivo,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${(fraccionPagada * 100).round()}% pagado',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return AtenuableCard(atenuada: atenuada, child: card);
  }
}
