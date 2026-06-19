import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/interes_calculator.dart';
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
  late final Stream<double> _streamGastosVariables;

  @override
  void initState() {
    super.initState();
    final db = widget.db;

    final d = db.deudas;
    final pd = db.pagosDeuda;
    final sumPagosDeuda = pd.montoAbonado.sum();
    final queryDeudas = db.select(d).join([
      leftOuterJoin(pd, pd.deudaId.equalsExp(d.id)),
    ])
      ..where(d.estado.equals('activa'))
      ..groupBy([d.id])
      ..addColumns([sumPagosDeuda]);

    _streamDeudas = queryDeudas.watch().map((rows) {
      double total = 0;
      for (final row in rows) {
        final deuda = row.readTable(d);
        final abonado = row.read(sumPagosDeuda) ?? 0.0;
        final interes = InteresCalculator.calcularInteresSimple(
          monto: deuda.montoOriginal,
          tasaInteres: deuda.tasaInteres,
          tipoInteres: deuda.tipoInteres,
          fechaInicio: deuda.fechaPrestamo,
        );
        final saldo = deuda.montoOriginal + interes - abonado;
        total += saldo < 0 ? 0 : saldo;
      }
      return total;
    });

    final p = db.prestamos;
    final pr = db.pagosRecibidos;
    final sumAbonosPrestamos = pr.montoAbonado.sum();
    final queryPrestamos = db.select(p).join([
      leftOuterJoin(pr, pr.prestamoId.equalsExp(p.id)),
    ])
      ..where(p.estado.equals('activo'))
      ..groupBy([p.id])
      ..addColumns([sumAbonosPrestamos]);

    _streamPrestamos = queryPrestamos.watch().map((rows) {
      double total = 0;
      for (final row in rows) {
        final prestamo = row.readTable(p);
        final abonado = row.read(sumAbonosPrestamos) ?? 0.0;
        final saldo = InteresCalculator.calcularDeudaTotal(
          montoPrestado: prestamo.montoPrestado,
          tasaInteres: prestamo.tasaInteres,
          tipoInteres: prestamo.tipoInteres,
          modalidadCalculo: prestamo.modalidadCalculo,
          fechaPrestamo: prestamo.fechaPrestamo,
          totalAbonado: abonado,
        );
        total += saldo;
      }
      return total;
    });

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

    final now = DateTime.now();
    _streamGastosVariables =
        widget.db.gastosVariablesDao.watchTotalMes(now.year, now.month);
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
                    color: AppColors.acento,
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
                childAspectRatio: 1.6,
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
                  _ResumenCard(
                    titulo: 'Gastos variables (mes)',
                    icono: Icons.shopping_bag_outlined,
                    colorIcono: AppColors.alerta,
                    stream: _streamGastosVariables,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _BalanceMensualCard(
                streamIngresos: _streamIngresos,
                streamGastos: _streamGastos,
                streamGastosVariables: _streamGastosVariables,
              ),
              const SizedBox(height: AppSpacing.md),
              _ComparativoCategorias(db: widget.db),
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
    required this.streamGastosVariables,
  });

  final Stream<double> streamIngresos;
  final Stream<double> streamGastos;
  final Stream<double> streamGastosVariables;

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
                return StreamBuilder<double>(
                  stream: streamGastosVariables,
                  builder: (context, snapVar) {
                    final ingresos = snapIng.data ?? 0.0;
                    final gastos = snapGas.data ?? 0.0;
                    final gastosVariables = snapVar.data ?? 0.0;
                    final disponible = ingresos - gastos - gastosVariables;
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
                        const SizedBox(height: AppSpacing.sm),
                        _FilaMonto(
                          label: 'Gastos variables',
                          valor: '-${formatCOP(gastosVariables)}',
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

class _ComparativoCategorias extends StatelessWidget {
  const _ComparativoCategorias({required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final mesAnterior = now.month == 1 ? 12 : now.month - 1;
    final anioAnterior = now.month == 1 ? now.year - 1 : now.year;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StreamBuilder<Map<String, double>>(
          stream: db.gastosVariablesDao.watchTotalPorCategoria(
            now.year,
            now.month,
          ),
          builder: (context, snapActual) {
            return StreamBuilder<Map<String, double>>(
              stream: db.gastosVariablesDao.watchTotalPorCategoria(
                anioAnterior,
                mesAnterior,
              ),
              builder: (context, snapAnterior) {
                final actual = snapActual.data ?? {};
                final anterior = snapAnterior.data ?? {};

                final totalActual =
                    actual.values.fold<double>(0, (s, v) => s + v);
                final totalAnterior =
                    anterior.values.fold<double>(0, (s, v) => s + v);

                final hayMesAnterior = anterior.isNotEmpty;
                final hayMesActual = actual.isNotEmpty;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comparación con el mes pasado',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (!hayMesActual)
                      Text(
                        'Aún no has registrado gastos este mes.',
                        style: theme.textTheme.bodyMedium,
                      )
                    else if (!hayMesAnterior)
                      Text(
                        'Todavía no hay datos del mes pasado para comparar. '
                        'Vuelve en unos días para ver cómo va tu mes.',
                        style: theme.textTheme.bodyMedium,
                      )
                    else ...[
                      _FraseResumen(
                        totalActual: totalActual,
                        totalAnterior: totalAnterior,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      ..._frasesPorCategoria(actual, anterior, theme),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<Widget> _frasesPorCategoria(
    Map<String, double> actual,
    Map<String, double> anterior,
    ThemeData theme,
  ) {
    final categorias = actual.keys.toList()..sort();
    final frases = <Widget>[];

    for (final cat in categorias) {
      final montoActual = actual[cat] ?? 0.0;
      final montoAnterior = anterior[cat] ?? 0.0;
      final diferencia = montoActual - montoAnterior;

      if (diferencia == 0) continue;

      final esMas = diferencia > 0;
      final colorTexto = esMas ? AppColors.alerta : AppColors.positivo;
      final verbo = esMas ? 'más' : 'menos';

      frases.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(text: 'En $cat gastaste '),
                TextSpan(
                  text: formatCOP(diferencia.abs()),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorTexto,
                  ),
                ),
                TextSpan(text: ' $verbo que el mes pasado.'),
              ],
            ),
          ),
        ),
      );
    }

    if (frases.isEmpty) {
      frases.add(
        Text(
          'Gastaste prácticamente igual que el mes pasado en todas '
          'las categorías.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return frases;
  }
}

class _FraseResumen extends StatelessWidget {
  const _FraseResumen({
    required this.totalActual,
    required this.totalAnterior,
  });

  final double totalActual;
  final double totalAnterior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diferencia = totalActual - totalAnterior;
    final esMas = diferencia > 0;
    final color = esMas ? AppColors.alerta : AppColors.positivo;
    final verbo = esMas ? 'más' : 'menos';

    if (diferencia.abs() < 1) {
      return Text(
        'Este mes has gastado prácticamente lo mismo que el mes pasado.',
        style: theme.textTheme.bodyMedium,
      );
    }

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: [
          const TextSpan(text: 'Este mes has gastado '),
          TextSpan(
            text: formatCOP(diferencia.abs()),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          TextSpan(text: ' $verbo que el mes pasado.'),
        ],
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
