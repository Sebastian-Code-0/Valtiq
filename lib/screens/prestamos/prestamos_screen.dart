import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/interes_calculator.dart';
import '../../theme/theme.dart';
import '../../utils/date_format.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../../utils/notificaciones.dart';
import 'prestamo_detalle.dart';
import 'prestamo_form.dart';

class PrestamosScreen extends StatefulWidget {
  const PrestamosScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<PrestamosScreen> createState() => _PrestamosScreenState();
}

class _PrestamoConAbonos {
  _PrestamoConAbonos(this.prestamo, this.abonado);
  final Prestamo prestamo;
  final double abonado;
}

class _PrestamosScreenState extends State<PrestamosScreen> {
  bool _mostrarPagados = false;

  Stream<List<_PrestamoConAbonos>> _stream() {
    final estado = _mostrarPagados ? 'pagado' : 'activo';
    final p = widget.db.prestamos;
    final pr = widget.db.pagosRecibidos;
    final sumExpr = pr.montoAbonado.sum();

    final query =
        widget.db.select(p).join([
            leftOuterJoin(pr, pr.prestamoId.equalsExp(p.id)),
          ])
          ..where(p.estado.equals(estado))
          ..groupBy([p.id])
          ..orderBy([OrderingTerm.desc(p.fechaPrestamo)])
          ..addColumns([sumExpr]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) =>
                _PrestamoConAbonos(row.readTable(p), row.read(sumExpr) ?? 0.0),
          )
          .toList(),
    );
  }

  Future<void> _abrirForm({Prestamo? prestamo}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrestamoForm(db: widget.db, prestamo: prestamo),
      ),
    );
  }

  Future<void> _abrirDetalle(int prestamoId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrestamoDetalle(db: widget.db, prestamoId: prestamoId),
      ),
    );
  }

  Future<void> _confirmarMarcarPagado(Prestamo prestamo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como pagado'),
        content: Text(
          '¿Confirmas que el préstamo a ${prestamo.deudorNombre} ya fue pagado por completo?',
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
      await widget.db.prestamosDao.marcarComoPagado(prestamo.id);
    }
  }

  Future<void> _confirmarReactivar(Prestamo prestamo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reactivar préstamo'),
        content: Text(
          '¿Volver a marcar como activo el préstamo a ${prestamo.deudorNombre}?',
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
      await widget.db.prestamosDao.reactivarPrestamo(prestamo.id);
    }
  }

  Future<void> _confirmarEliminar(Prestamo prestamo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar préstamo'),
        content: Text(
          '¿Eliminar el préstamo a ${prestamo.deudorNombre}? '
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
        await widget.db.prestamosDao.deletePrestamoConPagos(prestamo.id);
      } catch (_) {
        if (mounted) {
          mostrarAlerta(context, 'No se pudo eliminar el préstamo.');
        }
      }
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
                    'Préstamos',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (!_mostrarPagados)
                    FloatingActionButton.small(
                      heroTag: 'fab_prestamos',
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
                      setState(() => _mostrarPagados = !_mostrarPagados),
                  icon: Icon(
                    _mostrarPagados ? Icons.visibility : Icons.history,
                  ),
                  label: Text(_mostrarPagados ? 'Ver activos' : 'Ver pagados'),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<_PrestamoConAbonos>>(
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
                    final mensaje = _mostrarPagados
                        ? 'No tienes préstamos pagados'
                        : 'No tienes préstamos registrados';
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
                      return _PrestamoCard(
                        key: ValueKey(item.prestamo.id),
                        prestamo: item.prestamo,
                        abonado: item.abonado,
                        atenuada: _mostrarPagados,
                        colorSec: colorSec,
                        onTap: () => _abrirDetalle(item.prestamo.id),
                        onLongPress: () => _confirmarEliminar(item.prestamo),
                        onMarcarPagado: _mostrarPagados
                            ? null
                            : () => _confirmarMarcarPagado(item.prestamo),
                        onReactivar: _mostrarPagados
                            ? () => _confirmarReactivar(item.prestamo)
                            : null,
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

class _PrestamoCard extends StatelessWidget {
  const _PrestamoCard({
    super.key,
    required this.prestamo,
    required this.abonado,
    required this.atenuada,
    required this.colorSec,
    required this.onTap,
    required this.onLongPress,
    this.onMarcarPagado,
    this.onReactivar,
  });

  final Prestamo prestamo;
  final double abonado;
  final bool atenuada;
  final Color colorSec;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onMarcarPagado;
  final VoidCallback? onReactivar;

  String _fmtTasa(double t) {
    if (t == t.truncateToDouble()) return t.toStringAsFixed(0);
    return t.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saldo = InteresCalculator.calcularDeudaTotal(
      montoPrestado: prestamo.montoPrestado,
      tasaInteres: prestamo.tasaInteres,
      tipoInteres: prestamo.tipoInteres,
      modalidadCalculo: prestamo.modalidadCalculo,
      fechaPrestamo: prestamo.fechaPrestamo,
      totalAbonado: abonado,
    );
    final totalConInteres = abonado + saldo;
    final fraccionCobrada = totalConInteres > 0
        ? abonado / totalConInteres
        : 0.0;
    final vencido =
        prestamo.fechaPactadaPago != null &&
        prestamo.fechaPactadaPago!.isBefore(DateTime.now()) &&
        prestamo.estado == 'activo';

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
                      prestamo.deudorNombre,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formatCOP(prestamo.montoPrestado),
                      style: monoStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
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
                        case 'pagado':
                          onMarcarPagado?.call();
                        case 'reactivar':
                          onReactivar?.call();
                        case 'eliminar':
                          onLongPress();
                      }
                    },
                    itemBuilder: (_) => [
                      if (onMarcarPagado != null)
                        const PopupMenuItem(
                          value: 'pagado',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 18,
                                color: AppColors.positivo,
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Text('Marcar como pagado'),
                            ],
                          ),
                        ),
                      if (onReactivar != null)
                        PopupMenuItem(
                          value: 'reactivar',
                          child: Row(
                            children: [
                              Icon(
                                Icons.undo,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Text('Reactivar préstamo'),
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
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: colorSec),
                      const SizedBox(width: 4),
                      Text(
                        formatFecha(prestamo.fechaPrestamo),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorSec,
                        ),
                      ),
                    ],
                  ),
                  if (prestamo.tasaInteres > 0)
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
                        '${_fmtTasa(prestamo.tasaInteres)}% '
                        '${prestamo.tipoInteres} ${prestamo.modalidadCalculo}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (vencido)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.alerta.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Text(
                        'Vencido',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.alerta,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
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
                      fraccion: fraccionCobrada,
                      color: AppColors.positivo,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${(fraccionCobrada * 100).round()}% cobrado',
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
