import 'package:flutter/material.dart';

import '../../../db/database.dart';
import '../../../theme/theme.dart';
import '../../../utils/form_widgets.dart';
import '../../../utils/format.dart';

class PresupuestosCard extends StatelessWidget {
  const PresupuestosCard({super.key, required this.db});
  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return StreamBuilder<List<PresupuestosCategoria>>(
      stream: db.presupuestosCategoriasDao.watchPresupuestos(),
      builder: (context, presupuestosSnap) {
        final presupuestos = presupuestosSnap.data ?? const [];
        if (presupuestos.isEmpty) return const SizedBox.shrink();

        return StreamBuilder<Map<String, double>>(
          stream: db.gastosVariablesDao
              .watchTotalPorCategoria(now.year, now.month)
              .map((m) => m.map((k, v) => MapEntry(k, v.toDouble()))),
          builder: (context, gastosSnap) {
            final gastos = gastosSnap.data ?? const {};
            final filas = [...presupuestos]
              ..sort((a, b) {
                final pa = (gastos[a.categoria] ?? 0) / a.limiteMensual;
                final pb = (gastos[b.categoria] ?? 0) / b.limiteMensual;
                return pb.compareTo(pa);
              });

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Presupuestos del mes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final p in filas)
                      _FilaPresupuesto(
                        categoria: p.categoria,
                        gastado: gastos[p.categoria] ?? 0.0,
                        limite: p.limiteMensual.toDouble(),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilaPresupuesto extends StatelessWidget {
  const _FilaPresupuesto({
    required this.categoria,
    required this.gastado,
    required this.limite,
  });

  final String categoria;
  final double gastado;
  final double limite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sobrepasado = gastado > limite;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BarraCategoria(
            categoria: categoria,
            monto: gastado,
            montoMaximo: limite,
            colorOverride: sobrepasado ? AppColors.alerta : null,
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'de ${formatCOP(limite)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorSecundario,
                  ),
                ),
                if (sobrepasado) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 12,
                    color: AppColors.alerta,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Superado',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.alerta,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
