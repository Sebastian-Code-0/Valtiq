import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/dashboard_service.dart';
import '../../theme/theme.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../config/settings_screen.dart';
import 'widgets/balance_donut.dart';
import 'widgets/comparativo_categorias.dart';
import 'widgets/presupuestos_card.dart';

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
  late final Stream<double> _streamGastosVariables;
  late final Stream<({double ingresos, double gastos, double variables})>
  _streamBalance;

  @override
  void initState() {
    super.initState();
    final db = widget.db;

    _streamDeudas = DashboardService.watchTotalDeudasActivas(db);
    _streamPrestamos = DashboardService.watchTotalPrestamosActivos(db);
    _streamIngresos = DashboardService.watchIngresosMensuales(db);
    _streamGastos = DashboardService.watchGastosFijosMensuales(db);
    _streamGastosVariables = DashboardService.watchGastosVariablesMes(db);
    _streamBalance = DashboardService.watchBalanceMensual(db);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/logo_icono.png',
                    height: 32,
                    color: Theme.of(context).colorScheme.primary,
                    colorBlendMode: BlendMode.srcIn,
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
                childAspectRatio: 1.25,
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
                    colorIcono: Theme.of(context).colorScheme.primary,
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
              const SizedBox(height: AppSpacing.md),
              Builder(
                builder: (context) {
                  final anchoDisponible =
                      MediaQuery.sizeOf(context).width - AppSpacing.md * 2;
                  final anchoCelda = (anchoDisponible - AppSpacing.md) / 2;
                  final altoFila = anchoCelda / 1.25;
                  return SizedBox(
                    width: double.infinity,
                    height: altoFila,
                    child: _ResumenCard(
                      titulo: 'Gastos variables (mes)',
                      icono: Icons.shopping_bag_outlined,
                      colorIcono: AppColors.alerta,
                      stream: _streamGastosVariables,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _PosicionPrestamosCard(
                streamPrestamos: _streamPrestamos,
                streamDeudas: _streamDeudas,
              ),
              const SizedBox(height: AppSpacing.md),
              _BalanceMensualCard(streamBalance: _streamBalance),
              const SizedBox(height: AppSpacing.md),
              ComparativoCategorias(db: widget.db),
              const SizedBox(height: AppSpacing.md),
              PresupuestosCard(db: widget.db),
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
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar los datos.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  // Sin esto, el primer valor real (que puede tardar un rato
                  // en llegar por el join con InteresCalculator) se ve como
                  // "$0" antes de saltar al monto correcto — un estado
                  // engañoso, no solo lento.
                  return const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final valor = snapshot.data!;
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatCOP(valor),
                    style: monoStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
  const _BalanceMensualCard({required this.streamBalance});

  final Stream<({double ingresos, double gastos, double variables})>
  streamBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child:
            StreamBuilder<({double ingresos, double gastos, double variables})>(
              stream: streamBalance,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar los datos.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const SizedBox(
                    height: 130,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final ingresos = snap.data?.ingresos ?? 0.0;
                final gastos = snap.data?.gastos ?? 0.0;
                final gastosVariables = snap.data?.variables ?? 0.0;
                final disponible = ingresos - gastos - gastosVariables;
                final disponibleColor = disponible >= 0
                    ? AppColors.positivo
                    : AppColors.alerta;
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Pantallas angostas no tienen espacio para el
                        // anillo y las tres filas de montos lado a lado
                        // sin desbordar; ahí se apilan verticalmente.
                        final angosto = constraints.maxWidth < 360;
                        final donut = BalanceDonut(
                          ingresos: ingresos,
                          gastos: gastos,
                          gastosVariables: gastosVariables,
                          disponible: disponible,
                          disponibleColor: disponibleColor,
                          diametro: angosto ? 160 : 130,
                        );
                        final filas = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            const SizedBox(height: AppSpacing.sm),
                            _FilaMonto(
                              label: 'Gastos variables',
                              valor: '-${formatCOP(gastosVariables)}',
                              color: AppColors.alerta,
                            ),
                          ],
                        );

                        if (angosto) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(child: donut),
                              const SizedBox(height: AppSpacing.md),
                              filas,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            donut,
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: filas),
                          ],
                        );
                      },
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
            if (snapPres.hasError) {
              return Center(
                child: Text(
                  'Error al cargar los datos.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }
            return StreamBuilder<double>(
              stream: streamDeudas,
              builder: (context, snapDeu) {
                if (snapDeu.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar los datos.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                if (!snapPres.hasData || !snapDeu.hasData) {
                  return const SizedBox(
                    height: 130,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final prestado = snapPres.data ?? 0.0;
                final deudas = snapDeu.data ?? 0.0;
                final totalPosicion = prestado + deudas;
                final fraccionPrestado = totalPosicion == 0
                    ? 0.0
                    : prestado / totalPosicion;
                final fraccionDeudas = totalPosicion == 0
                    ? 0.0
                    : deudas / totalPosicion;
                final neto = prestado - deudas;
                final netoColor = neto >= 0
                    ? AppColors.positivo
                    : AppColors.alerta;
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
                    const SizedBox(height: AppSpacing.xs),
                    BarraProgreso(
                      fraccion: fraccionPrestado,
                      color: AppColors.positivo,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _FilaMonto(
                      label: 'Total deudas',
                      valor: formatCOP(deudas),
                      color: AppColors.alerta,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    BarraProgreso(
                      fraccion: fraccionDeudas,
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
        Flexible(
          child: Text(
            valor,
            style: monoStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
