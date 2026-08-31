import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/interes_calculator.dart';
import '../../theme/theme.dart';
import '../../utils/form_widgets.dart';
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

  late final StreamController<
    ({double ingresos, double gastos, double variables})
  >
  _balanceCtrl;
  late final Stream<({double ingresos, double gastos, double variables})>
  _streamBalance;
  StreamSubscription<double>? _subIng, _subGas, _subVar;
  double _bIng = 0, _bGas = 0, _bVar = 0;

  @override
  void initState() {
    super.initState();
    final db = widget.db;

    // Join sin agregar (en vez de groupBy + sum): el modo de amortización
    // 'saldo_insoluto' necesita la fecha de cada abono, no solo la suma —
    // ver InteresCalculator._resumenSaldoInsoluto. Se agrupa en Dart.
    final d = db.deudas;
    final pd = db.pagosDeuda;
    final queryDeudas = db.select(d).join([
      leftOuterJoin(pd, pd.deudaId.equalsExp(d.id)),
    ])..where(d.estado.equals('activa'));

    _streamDeudas = queryDeudas.watch().map((rows) {
      final deudas = <int, Deuda>{};
      final abonosPorDeuda = <int, List<AbonoInteres>>{};
      for (final row in rows) {
        final deuda = row.readTable(d);
        deudas[deuda.id] = deuda;
        final pago = row.readTableOrNull(pd);
        if (pago != null) {
          (abonosPorDeuda[deuda.id] ??= []).add(
            AbonoInteres(fecha: pago.fechaPago, monto: pago.montoAbonado),
          );
        }
      }
      double total = 0;
      for (final deuda in deudas.values) {
        final abonos = abonosPorDeuda[deuda.id] ?? const [];
        total += InteresCalculator.calcularDeudaTotal(
          montoPrestado: deuda.montoOriginal,
          tasaInteres: deuda.tasaInteres,
          tipoInteres: deuda.tipoInteres,
          modalidadCalculo: deuda.modalidadCalculo,
          fechaPrestamo: deuda.fechaPrestamo,
          totalAbonado: abonos.fold<int>(0, (s, a) => s + a.monto),
          tipoAmortizacion: deuda.tipoAmortizacion,
          abonos: abonos,
        );
      }
      return total;
    });

    final p = db.prestamos;
    final pr = db.pagosRecibidos;
    final queryPrestamos = db.select(p).join([
      leftOuterJoin(pr, pr.prestamoId.equalsExp(p.id)),
    ])..where(p.estado.equals('activo'));

    _streamPrestamos = queryPrestamos.watch().map((rows) {
      final prestamos = <int, Prestamo>{};
      final abonosPorPrestamo = <int, List<AbonoInteres>>{};
      for (final row in rows) {
        final prestamo = row.readTable(p);
        prestamos[prestamo.id] = prestamo;
        final pago = row.readTableOrNull(pr);
        if (pago != null) {
          (abonosPorPrestamo[prestamo.id] ??= []).add(
            AbonoInteres(fecha: pago.fechaPago, monto: pago.montoAbonado),
          );
        }
      }
      double total = 0;
      for (final prestamo in prestamos.values) {
        final abonos = abonosPorPrestamo[prestamo.id] ?? const [];
        total += InteresCalculator.calcularDeudaTotal(
          montoPrestado: prestamo.montoPrestado,
          tasaInteres: prestamo.tasaInteres,
          tipoInteres: prestamo.tipoInteres,
          modalidadCalculo: prestamo.modalidadCalculo,
          fechaPrestamo: prestamo.fechaPrestamo,
          totalAbonado: abonos.fold<int>(0, (s, a) => s + a.monto),
          tipoAmortizacion: prestamo.tipoAmortizacion,
          abonos: abonos,
        );
      }
      return total;
    });

    final sumIngresos = db.ingresos.monto.sum();
    _streamIngresos =
        (db.selectOnly(db.ingresos)
              ..addColumns([sumIngresos])
              ..where(db.ingresos.activo.equals(true)))
            .watchSingle()
            .map((row) => (row.read(sumIngresos) ?? 0).toDouble());

    final sumGastos = db.gastosFijos.monto.sum();
    _streamGastos =
        (db.selectOnly(db.gastosFijos)
              ..addColumns([sumGastos])
              ..where(db.gastosFijos.activo.equals(true)))
            .watchSingle()
            .map((row) => (row.read(sumGastos) ?? 0).toDouble());

    final now = DateTime.now();
    _streamGastosVariables = widget.db.gastosVariablesDao
        .watchTotalMes(now.year, now.month)
        .map((v) => v.toDouble());

    _balanceCtrl = StreamController.broadcast();
    _streamBalance = _balanceCtrl.stream;
    _subIng = _streamIngresos.listen((v) {
      _bIng = v;
      _emitBalance();
    }, onError: (_) {});
    _subGas = _streamGastos.listen((v) {
      _bGas = v;
      _emitBalance();
    }, onError: (_) {});
    _subVar = _streamGastosVariables.listen((v) {
      _bVar = v;
      _emitBalance();
    }, onError: (_) {});
  }

  void _emitBalance() {
    if (!_balanceCtrl.isClosed) {
      _balanceCtrl.add((ingresos: _bIng, gastos: _bGas, variables: _bVar));
    }
  }

  @override
  void dispose() {
    _subIng?.cancel();
    _subGas?.cancel();
    _subVar?.cancel();
    _balanceCtrl.close();
    super.dispose();
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
              _ComparativoCategorias(db: widget.db),
              const SizedBox(height: AppSpacing.md),
              _PresupuestosCard(db: widget.db),
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
                final valor = snapshot.data ?? 0.0;
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
                        final donut = _BalanceDonut(
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

class _ComparativoCategorias extends StatefulWidget {
  const _ComparativoCategorias({required this.db});

  final AppDatabase db;

  @override
  State<_ComparativoCategorias> createState() => _ComparativoCategoriasState();
}

class _ComparativoCategoriasState extends State<_ComparativoCategorias> {
  late DateTime _mesA;
  late DateTime _mesB;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final mesAnterior = now.month == 1 ? 12 : now.month - 1;
    final anioAnterior = now.month == 1 ? now.year - 1 : now.year;
    _mesA = DateTime(anioAnterior, mesAnterior, 1);
    _mesB = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StreamBuilder<Map<String, double>>(
          stream: widget.db.gastosVariablesDao
              .watchTotalPorCategoria(_mesB.year, _mesB.month)
              .map((m) => m.map((k, v) => MapEntry(k, v.toDouble()))),
          builder: (context, snapB) {
            if (snapB.hasError) {
              return Center(
                child: Text(
                  'Error al cargar los datos.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }
            return StreamBuilder<Map<String, double>>(
              stream: widget.db.gastosVariablesDao
                  .watchTotalPorCategoria(_mesA.year, _mesA.month)
                  .map((m) => m.map((k, v) => MapEntry(k, v.toDouble()))),
              builder: (context, snapA) {
                if (snapA.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar los datos.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                final montosB = snapB.data ?? {};
                final montosA = snapA.data ?? {};

                final totalB = montosB.values.fold<double>(0, (s, v) => s + v);
                final totalA = montosA.values.fold<double>(0, (s, v) => s + v);

                final hayMesB = montosB.isNotEmpty;
                final hayMesA = montosA.isNotEmpty;

                final nombreMesA = SelectorMes.nombreMes(_mesA.month);
                final nombreMesB = SelectorMes.nombreMes(_mesB.month);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comparación entre meses',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SelectorMes(
                          compacto: true,
                          anio: _mesA.year,
                          mes: _mesA.month,
                          onCambiar: (d) => setState(() => _mesA = d),
                          mesExcluido: _mesB,
                        ),
                        Text(
                          'vs',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorSecundario,
                          ),
                        ),
                        SelectorMes(
                          compacto: true,
                          anio: _mesB.year,
                          mes: _mesB.month,
                          onCambiar: (d) => setState(() => _mesB = d),
                          mesExcluido: _mesA,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Column(
                        key: ValueKey('$_mesA-$_mesB'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!hayMesB)
                            _estadoVacio(nombreMesB)
                          else if (!hayMesA)
                            _estadoVacio(nombreMesA)
                          else ...[
                            _FraseResumen(
                              totalMesA: totalA,
                              totalMesB: totalB,
                              nombreMesA: nombreMesA,
                              nombreMesB: nombreMesB,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Divider(),
                            const SizedBox(height: AppSpacing.sm),
                            ..._barrasPorCategoria(montosA, montosB),
                          ],
                        ],
                      ),
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

  Widget _estadoVacio(String nombreMes) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 32,
              color: theme.colorSecundario,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sin gastos en $nombreMes',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No hay nada registrado ese mes para comparar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _barrasPorCategoria(
    Map<String, double> montosA,
    Map<String, double> montosB,
  ) {
    final categorias = {...montosA.keys, ...montosB.keys};
    final entradas =
        categorias
            .map(
              (c) => (
                categoria: c,
                montoA: montosA[c] ?? 0.0,
                montoB: montosB[c] ?? 0.0,
              ),
            )
            .where((e) => e.montoA > 0 || e.montoB > 0)
            .toList()
          ..sort((a, b) {
            final maxA = a.montoA > a.montoB ? a.montoA : a.montoB;
            final maxB = b.montoA > b.montoB ? b.montoA : b.montoB;
            return maxB.compareTo(maxA);
          });

    final montoMaximo = entradas.fold<double>(
      0,
      (m, e) => [m, e.montoA, e.montoB].reduce((x, y) => x > y ? x : y),
    );
    final mesACorto = SelectorMes.nombreMesCorto(_mesA.month);
    final mesBCorto = SelectorMes.nombreMesCorto(_mesB.month);

    return [
      for (final e in entradas)
        BarraCategoriaComparada(
          categoria: e.categoria,
          mesACorto: mesACorto,
          montoA: e.montoA,
          mesBCorto: mesBCorto,
          montoB: e.montoB,
          montoMaximo: montoMaximo,
        ),
    ];
  }
}

class _FraseResumen extends StatelessWidget {
  const _FraseResumen({
    required this.totalMesA,
    required this.totalMesB,
    required this.nombreMesA,
    required this.nombreMesB,
  });

  final double totalMesA;
  final double totalMesB;
  final String nombreMesA;
  final String nombreMesB;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diferencia = totalMesB - totalMesA;
    final esMas = diferencia > 0;
    final color = esMas ? AppColors.alerta : AppColors.positivo;
    final verbo = esMas ? 'más' : 'menos';

    if (diferencia.abs() < 1) {
      return Text(
        'Gastaste prácticamente lo mismo en $nombreMesB que en $nombreMesA.',
        style: theme.textTheme.bodyMedium,
      );
    }

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: [
          const TextSpan(text: 'Gastaste '),
          TextSpan(
            text: formatCOP(diferencia.abs()),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          TextSpan(text: ' $verbo en $nombreMesB que en $nombreMesA.'),
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

/// Donut de composición del balance mensual: gastos fijos, gastos variables
/// y disponible como fracciones de ingresos. Si gastos + variables superan
/// los ingresos, se reescalan entre sí para llenar el anillo completo (sin
/// porción de "disponible"), evitando arcos que se solapen más allá de 360°.
class _BalanceDonut extends StatelessWidget {
  const _BalanceDonut({
    required this.ingresos,
    required this.gastos,
    required this.gastosVariables,
    required this.disponible,
    required this.disponibleColor,
    this.diametro = 100.0,
  });

  final double ingresos;
  final double gastos;
  final double gastosVariables;
  final double disponible;
  final Color disponibleColor;
  final double diametro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (ingresos <= 0) {
      return SizedBox(
        width: diametro,
        height: diametro,
        child: Center(
          child: Icon(
            Icons.donut_large_outlined,
            size: 32,
            color: theme.colorSecundario,
          ),
        ),
      );
    }

    final gastosTotal = gastos + gastosVariables;
    double fraccionGastos;
    double fraccionVariables;
    double fraccionDisponible;
    if (gastosTotal >= ingresos) {
      fraccionGastos = gastosTotal <= 0 ? 0.0 : gastos / gastosTotal;
      fraccionVariables = gastosTotal <= 0
          ? 0.0
          : gastosVariables / gastosTotal;
      fraccionDisponible = 0.0;
    } else {
      fraccionGastos = gastos / ingresos;
      fraccionVariables = gastosVariables / ingresos;
      fraccionDisponible = disponible / ingresos;
    }

    final texto = formatCOP(disponible);
    final painter = TextPainter(
      text: TextSpan(
        text: texto,
        style: monoStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final diametroInterior = diametro - 24 - AppSpacing.sm;
    final cabeAdentro = painter.width <= diametroInterior * 0.78;

    final anillo = SizedBox(
      width: diametro,
      height: diametro,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, progreso, child) => CustomPaint(
              size: Size(diametro, diametro),
              painter: _BalanceDonutPainter(
                fraccionGastos: fraccionGastos,
                fraccionVariables: fraccionVariables,
                fraccionDisponible: fraccionDisponible,
                colorGastos: AppColors.alerta,
                colorVariables: AppColors.alerta.withValues(alpha: 0.35),
                colorDisponible: disponibleColor,
                colorPista: theme.dividerColor,
                progreso: progreso,
                relleno: !cabeAdentro,
              ),
            ),
          ),
          if (cabeAdentro)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  texto,
                  style: monoStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: disponibleColor,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
        ],
      ),
    );

    if (cabeAdentro) return anillo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        anillo,
        const SizedBox(height: AppSpacing.xs),
        Text(
          texto,
          style: monoStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: disponibleColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BalanceDonutPainter extends CustomPainter {
  _BalanceDonutPainter({
    required this.fraccionGastos,
    required this.fraccionVariables,
    required this.fraccionDisponible,
    required this.colorGastos,
    required this.colorVariables,
    required this.colorDisponible,
    required this.colorPista,
    required this.progreso,
    required this.relleno,
  });

  final double fraccionGastos;
  final double fraccionVariables;
  final double fraccionDisponible;
  final Color colorGastos;
  final Color colorVariables;
  final Color colorDisponible;
  final Color colorPista;
  final double progreso;
  final bool relleno;

  static const _grosor = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = relleno
        ? size.shortestSide / 2
        : (size.shortestSide - _grosor) / 2;
    final arcoRect = Rect.fromCircle(center: centro, radius: radio);
    final estilo = relleno ? PaintingStyle.fill : PaintingStyle.stroke;

    final pistaPaint = Paint()
      ..color = colorPista
      ..style = estilo
      ..strokeWidth = _grosor
      ..isAntiAlias = true;
    canvas.drawCircle(centro, radio, pistaPaint);

    var anguloActual = -math.pi / 2;

    void dibujarArco(double fraccion, Color color) {
      final barrido = 2 * math.pi * fraccion * progreso;
      if (barrido > 0) {
        final paint = Paint()
          ..color = color
          ..style = estilo
          ..strokeWidth = _grosor
          ..isAntiAlias = true;
        // Solape leve para que segmentos consecutivos se toquen de más en
        // vez de dejar una línea/gap visible entre colores.
        const solape = 0.025;
        canvas.drawArc(
          arcoRect,
          anguloActual,
          barrido + solape,
          relleno,
          paint,
        );
      }
      anguloActual += 2 * math.pi * fraccion;
    }

    dibujarArco(fraccionGastos, colorGastos);
    dibujarArco(fraccionVariables, colorVariables);
    dibujarArco(fraccionDisponible, colorDisponible);
  }

  @override
  bool shouldRepaint(covariant _BalanceDonutPainter oldDelegate) {
    return oldDelegate.fraccionGastos != fraccionGastos ||
        oldDelegate.fraccionVariables != fraccionVariables ||
        oldDelegate.fraccionDisponible != fraccionDisponible ||
        oldDelegate.colorDisponible != colorDisponible ||
        oldDelegate.progreso != progreso ||
        oldDelegate.relleno != relleno;
  }
}

class _PresupuestosCard extends StatelessWidget {
  const _PresupuestosCard({required this.db});
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
