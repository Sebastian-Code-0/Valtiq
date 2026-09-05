import 'package:flutter/material.dart';

import '../../../db/database.dart';
import '../../../theme/theme.dart';
import '../../../utils/form_widgets.dart';
import '../../../utils/format.dart';

class ComparativoCategorias extends StatefulWidget {
  const ComparativoCategorias({super.key, required this.db});

  final AppDatabase db;

  @override
  State<ComparativoCategorias> createState() => _ComparativoCategoriasState();
}

class _ComparativoCategoriasState extends State<ComparativoCategorias> {
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
