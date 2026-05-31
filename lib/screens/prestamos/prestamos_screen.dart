import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/interes_calculator.dart';
import '../../theme/theme.dart';
import '../../utils/date_format.dart';
import '../../utils/format.dart';
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
            (row) => _PrestamoConAbonos(
              row.readTable(p),
              row.read(sumExpr) ?? 0.0,
            ),
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
        builder: (_) => PrestamoDetalle(
          db: widget.db,
          prestamoId: prestamoId,
        ),
      ),
    );
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
      await (widget.db.delete(widget.db.pagosRecibidos)
            ..where((t) => t.prestamoId.equals(prestamo.id)))
          .go();
      await widget.db.prestamosDao.deletePrestamo(prestamo.id);
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
                  onPressed: () => setState(
                    () => _mostrarPagados = !_mostrarPagados,
                  ),
                  icon: Icon(
                    _mostrarPagados ? Icons.visibility : Icons.history,
                  ),
                  label: Text(
                    _mostrarPagados ? 'Ver activos' : 'Ver pagados',
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<_PrestamoConAbonos>>(
                stream: _stream(),
                builder: (context, snapshot) {
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
  });

  final Prestamo prestamo;
  final double abonado;
  final bool atenuada;
  final Color colorSec;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

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
    final vencido = prestamo.fechaPactadaPago != null &&
        prestamo.fechaPactadaPago!.isBefore(DateTime.now()) &&
        prestamo.estado == 'activo';

    final card = Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
                  Text(
                    formatCOP(prestamo.montoPrestado),
                    style: monoStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.acento,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: colorSec),
                  const SizedBox(width: 4),
                  Text(
                    formatFecha(prestamo.fechaPrestamo),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorSec,
                    ),
                  ),
                  if (prestamo.tasaInteres > 0) ...[
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
                        '${_fmtTasa(prestamo.tasaInteres)}% '
                        '${prestamo.tipoInteres} ${prestamo.modalidadCalculo}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.acento,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (vencido) ...[
                    const SizedBox(width: AppSpacing.sm),
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
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saldo pendiente',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorSec,
                    ),
                  ),
                  Text(
                    formatCOP(saldo),
                    style: monoStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: saldo > 0
                          ? AppColors.alerta
                          : AppColors.positivo,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return atenuada ? Opacity(opacity: 0.6, child: card) : card;
  }
}
