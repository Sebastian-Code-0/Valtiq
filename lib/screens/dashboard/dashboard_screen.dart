import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/format.dart';
import '../config/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Stream<double> _streamDeudas;
  late final Stream<double> _streamPrestamos;
  late final Stream<double> _streamIngresos;
  late final Stream<double> _streamGastos;

  @override
  void initState() {
    super.initState();
    final db = widget.db;

    final sumDeudas = db.deudas.montoOriginal.sum();
    _streamDeudas = (db.selectOnly(db.deudas)
          ..addColumns([sumDeudas])
          ..where(db.deudas.estado.equals('activa')))
        .watchSingle()
        .map((row) => row.read(sumDeudas) ?? 0.0);

    final sumPrestamos = db.prestamos.montoPrestado.sum();
    _streamPrestamos = (db.selectOnly(db.prestamos)
          ..addColumns([sumPrestamos])
          ..where(db.prestamos.estado.equals('activo')))
        .watchSingle()
        .map((row) => row.read(sumPrestamos) ?? 0.0);

    final sumIngresos = db.ingresos.monto.sum();
    _streamIngresos = (db.selectOnly(db.ingresos)
          ..addColumns([sumIngresos])
          ..where(db.ingresos.activo.equals(true)))
        .watchSingle()
        .map((row) => row.read(sumIngresos) ?? 0.0);

    final sumGastos = db.gastosFijos.monto.sum();
    _streamGastos = (db.selectOnly(db.gastosFijos)
          ..addColumns([sumGastos])
          ..where(db.gastosFijos.activo.equals(true)))
        .watchSingle()
        .map((row) => row.read(sumGastos) ?? 0.0);
  }

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
              Row(
                children: [
                  Text(
                    'Dashboard',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Configuración',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(db: widget.db),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.8,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _ResumenCard(
                    titulo: 'Deudas activas',
                    icono: Icons.credit_card,
                    colorIcono: AppColors.alerta,
                    stream: _streamDeudas,
                  ),
                  _ResumenCard(
                    titulo: 'Prestado activo',
                    icono: Icons.handshake_outlined,
                    colorIcono: AppColors.acento,
                    stream: _streamPrestamos,
                  ),
                  _ResumenCard(
                    titulo: 'Ingresos mensuales',
                    icono: Icons.trending_up,
                    colorIcono: AppColors.positivo,
                    stream: _streamIngresos,
                  ),
                  _ResumenCard(
                    titulo: 'Gastos fijos mensuales',
                    icono: Icons.trending_down,
                    colorIcono: AppColors.alerta,
                    stream: _streamGastos,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _BalanceMensualCard(
                streamIngresos: _streamIngresos,
                streamGastos: _streamGastos,
              ),
              const SizedBox(height: AppSpacing.md),
              _PosicionPrestamosCard(
                streamPrestamos: _streamPrestamos,
                streamDeudas: _streamDeudas,
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
    required this.stream,
  });

  final String titulo;
  final IconData icono;
  final Color colorIcono;
  final Stream<double> stream;

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
            StreamBuilder<double>(
              stream: stream,
              builder: (context, snapshot) {
                final valor = snapshot.data ?? 0.0;
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatCOP(valor),
                    style: monoStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceMensualCard extends StatelessWidget {
  const _BalanceMensualCard({
    required this.streamIngresos,
    required this.streamGastos,
  });

  final Stream<double> streamIngresos;
  final Stream<double> streamGastos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StreamBuilder<double>(
          stream: streamIngresos,
          builder: (context, snapIng) {
            return StreamBuilder<double>(
              stream: streamGastos,
              builder: (context, snapGas) {
                final ingresos = snapIng.data ?? 0.0;
                final gastos = snapGas.data ?? 0.0;
                final disponible = ingresos - gastos;
                final disponibleColor =
                    disponible >= 0 ? AppColors.positivo : AppColors.alerta;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance mensual',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FilaMonto(
                      label: 'Ingresos',
                      valor: formatCOP(ingresos),
                      color: AppColors.positivo,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _FilaMonto(
                      label: 'Gastos fijos',
                      valor: '-${formatCOP(gastos)}',
                      color: AppColors.alerta,
                    ),
                    const Divider(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Disponible',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatCOP(disponible),
                              style: monoStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: disponibleColor,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PosicionPrestamosCard extends StatelessWidget {
  const _PosicionPrestamosCard({
    required this.streamPrestamos,
    required this.streamDeudas,
  });

  final Stream<double> streamPrestamos;
  final Stream<double> streamDeudas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StreamBuilder<double>(
          stream: streamPrestamos,
          builder: (context, snapPres) {
            return StreamBuilder<double>(
              stream: streamDeudas,
              builder: (context, snapDeu) {
                final prestado = snapPres.data ?? 0.0;
                final deudas = snapDeu.data ?? 0.0;
                final neto = prestado - deudas;
                final netoColor =
                    neto >= 0 ? AppColors.positivo : AppColors.alerta;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Posición de préstamos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FilaMonto(
                      label: 'Total prestado',
                      valor: formatCOP(prestado),
                      color: AppColors.positivo,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _FilaMonto(
                      label: 'Total deudas',
                      valor: formatCOP(deudas),
                      color: AppColors.alerta,
                    ),
                    const Divider(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Neto',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatCOP(neto),
                              style: monoStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: netoColor,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FilaMonto extends StatelessWidget {
  const _FilaMonto({
    required this.label,
    required this.valor,
    required this.color,
  });

  final String label;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyLarge),
        Text(
          valor,
          style: monoStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
