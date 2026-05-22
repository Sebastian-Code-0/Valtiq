import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/format.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _ResumenCard(
                    titulo: 'Deudas activas',
                    icono: Icons.credit_card,
                    colorIcono: AppColors.alerta,
                    valor: 0,
                  ),
                  _ResumenCard(
                    titulo: 'Prestado activo',
                    icono: Icons.handshake_outlined,
                    colorIcono: AppColors.acento,
                    valor: 0,
                  ),
                  _ResumenCard(
                    titulo: 'Ingresos mensuales',
                    icono: Icons.trending_up,
                    colorIcono: AppColors.positivo,
                    valor: 0,
                  ),
                  _ResumenCard(
                    titulo: 'Gastos fijos mensuales',
                    icono: Icons.trending_down,
                    colorIcono: AppColors.alerta,
                    valor: 0,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  const _ResumenCard({
    required this.titulo,
    required this.icono,
    required this.colorIcono,
    required this.valor,
  });

  final String titulo;
  final IconData icono;
  final Color colorIcono;
  final double valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icono, color: colorIcono, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    titulo,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              formatCOP(valor),
              style: monoStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
