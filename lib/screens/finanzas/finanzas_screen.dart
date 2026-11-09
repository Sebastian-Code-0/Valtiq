import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/categoria_gasto.dart';
import '../../utils/date_format.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../../utils/frecuencia.dart';
import '../../utils/notificaciones.dart';
import 'gasto_fijo_form.dart';
import 'gasto_variable_form.dart';
import 'ingreso_form.dart';

class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  String _modo = 'ingresos';

  late final Stream<List<Ingreso>> _streamIngresos;
  late final Stream<int> _streamTotalIngresosMes;
  late Stream<List<GastosVariable>> _streamGastosVariables;
  late final Stream<List<GastosFijo>> _streamGastos;

  late DateTime _mesVariables;
  late Stream<Map<String, double>> _streamTotalPorCategoria;

  String _capitalizar(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  // Un ingreso 'unico' (pago puntual, ej. un trabajo secundario) solo cuenta
  // en el mes de su propia fecha — misma convención que
  // IngresosDao.watchTotalIngresosMes, replicada acá para poder marcar en la
  // card las fuentes que NO están sumando en el total mostrado arriba.
  bool _cuentaEsteMes(Ingreso ingreso) {
    if (ingreso.frecuencia != 'unico') return true;
    final now = DateTime.now();
    final fecha = fechaCivilGuardada(ingreso.fecha);
    return fecha.year == now.year && fecha.month == now.month;
  }

  @override
  void initState() {
    super.initState();
    _streamIngresos = (widget.db.select(
      widget.db.ingresos,
    )..orderBy([(i) => OrderingTerm.desc(i.fecha)])).watch();
    final now = DateTime.now();
    _streamTotalIngresosMes = widget.db.ingresosDao.watchTotalIngresosMes(
      now.year,
      now.month,
    );
    _mesVariables = DateTime(now.year, now.month, 1);
    _cargarStreamsVariables();
    _streamGastos = (widget.db.select(
      widget.db.gastosFijos,
    )..orderBy([(g) => OrderingTerm.asc(g.concepto)])).watch();
  }

  void _cargarStreamsVariables() {
    _streamGastosVariables = widget.db.gastosVariablesDao.watchGastosPorMes(
      _mesVariables.year,
      _mesVariables.month,
    );
    _streamTotalPorCategoria = widget.db.gastosVariablesDao
        .watchTotalPorCategoria(_mesVariables.year, _mesVariables.month)
        .map((m) => m.map((k, v) => MapEntry(k, v.toDouble())));
  }

  void _cambiarMesVariables(DateTime nuevoMes) {
    setState(() {
      _mesVariables = nuevoMes;
      _cargarStreamsVariables();
    });
  }

  Future<void> _abrirIngresoForm({Ingreso? ingreso}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IngresoForm(db: widget.db, ingreso: ingreso),
      ),
    );
  }

  Future<void> _abrirGastoVariableForm({GastosVariable? gasto}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GastoVariableForm(db: widget.db, gasto: gasto),
      ),
    );
    if (resultado is ({String categoria, DateTime mes}) && mounted) {
      final ahora = DateTime.now();
      final esMesActual =
          resultado.mes.year == ahora.year &&
          resultado.mes.month == ahora.month;
      final cuando = esMesActual
          ? 'este mes'
          : 'en ${formatMesAnio(resultado.mes)}';
      mostrarAlerta(
        context,
        'Superaste tu presupuesto de ${resultado.categoria} $cuando.',
      );
    }
  }

  Future<void> _abrirGastoForm({GastosFijo? gasto}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GastoFijoForm(db: widget.db, gasto: gasto),
      ),
    );
  }

  Future<void> _confirmarEliminarGastoVariable(GastosVariable gasto) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Eliminar "${gasto.descripcion}"?'),
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
      await widget.db.gastosVariablesDao.deleteGastoVariable(gasto.id);
    }
  }

  Future<void> _confirmarEliminarIngreso(Ingreso ingreso) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar ingreso'),
        content: Text('¿Eliminar el ingreso "${ingreso.concepto}"?'),
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
      await widget.db.ingresosDao.deleteIngreso(ingreso.id);
    }
  }

  Future<void> _confirmarEliminarGasto(GastosFijo gasto) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar gasto fijo'),
        content: Text('¿Eliminar el gasto "${gasto.concepto}"?'),
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
        await widget.db.gastosFijosDao.deleteGastoFijoConRecordatorios(
          gasto.id,
        );
      } catch (_) {
        if (mounted) {
          mostrarAlerta(context, 'No se pudo eliminar el gasto.');
        }
      }
    }
  }

  Future<void> _toggleIngreso(Ingreso ingreso) async {
    await widget.db.ingresosDao.setActivo(ingreso.id, activo: !ingreso.activo);
  }

  Future<void> _toggleGasto(GastosFijo gasto) async {
    await widget.db.gastosFijosDao.setActivo(gasto.id, activo: !gasto.activo);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorSec = theme.colorSecundario;

    return Scaffold(
      floatingActionButton: switch (_modo) {
        'ingresos' => FloatingActionButton(
          heroTag: 'fab_ingresos',
          onPressed: () => _abrirIngresoForm(),
          child: const Icon(Icons.add),
        ),
        'variables' => FloatingActionButton(
          heroTag: 'fab_variables',
          onPressed: () => _abrirGastoVariableForm(),
          child: const Icon(Icons.add),
        ),
        _ => FloatingActionButton(
          heroTag: 'fab_gastos',
          onPressed: () => _abrirGastoForm(),
          child: const Icon(Icons.add),
        ),
      },
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Finanzas',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ingresos', label: Text('Ingresos')),
                    ButtonSegment(value: 'gastos', label: Text('Gastos Fijos')),
                    ButtonSegment(value: 'variables', label: Text('Variables')),
                  ],
                  selected: {_modo},
                  onSelectionChanged: (s) => setState(() => _modo = s.first),
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary,
                    selectedForegroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _modo == 'variables'
                    ? _listaGastosVariables(theme, colorSec)
                    : (_modo == 'ingresos'
                          ? _listaIngresos(theme, colorSec)
                          : _listaGastos(theme, colorSec)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listaGastosVariables(ThemeData theme, Color colorSec) {
    return StreamBuilder<List<GastosVariable>>(
      stream: _streamGastosVariables,
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
        final gastos = snapshot.data!;
        final total = gastos.fold<int>(0, (s, g) => s + g.monto);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectorMes(
              anio: _mesVariables.year,
              mes: _mesVariables.month,
              onCambiar: _cambiarMesVariables,
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Column(
                  key: ValueKey(_mesVariables),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _totalRow(
                      theme: theme,
                      total: total,
                      color: AppColors.alerta,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StreamBuilder<Map<String, double>>(
                      stream: _streamTotalPorCategoria,
                      builder: (context, snapCategorias) {
                        final porCategoria = snapCategorias.data ?? {};
                        if (porCategoria.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final entradas = porCategoria.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));
                        final montoMaximo = entradas.first.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final e in entradas)
                                BarraCategoria(
                                  categoria: e.key,
                                  monto: e.value,
                                  montoMaximo: montoMaximo,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: gastos.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_month_outlined,
                                    size: 32,
                                    color: colorSec,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'No hay gastos variables este mes',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: colorSec,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: gastos.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (_, i) {
                                final g = gastos[i];
                                return _GastoVariableCard(
                                  gasto: g,
                                  colorSec: colorSec,
                                  onTap: () =>
                                      _abrirGastoVariableForm(gasto: g),
                                  onLongPress: () =>
                                      _confirmarEliminarGastoVariable(g),
                                  onEditar: () =>
                                      _abrirGastoVariableForm(gasto: g),
                                  onEliminar: () =>
                                      _confirmarEliminarGastoVariable(g),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _totalRow({
    required ThemeData theme,
    required num total,
    required Color color,
  }) {
    return Row(
      children: [
        Text(
          'Total:',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            formatCOP(total),
            style: monoStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _listaIngresos(ThemeData theme, Color colorSec) {
    return StreamBuilder<List<Ingreso>>(
      stream: _streamIngresos,
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
        final ingresos = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder<int>(
              stream: _streamTotalIngresosMes,
              builder: (context, totalSnap) {
                return _totalRow(
                  theme: theme,
                  total: totalSnap.data ?? 0,
                  color: AppColors.positivo,
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ingresos.isEmpty
                  ? Center(
                      child: Text(
                        'No tienes ingresos registrados',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorSec,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: ingresos.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final ing = ingresos[i];
                        return _IngresoCard(
                          ingreso: ing,
                          colorSec: colorSec,
                          frecuenciaLabel: _capitalizar(ing.frecuencia),
                          cuentaEsteMes: _cuentaEsteMes(ing),
                          onTap: () => _abrirIngresoForm(ingreso: ing),
                          onLongPress: () => _confirmarEliminarIngreso(ing),
                          onEditar: () => _abrirIngresoForm(ingreso: ing),
                          onToggleActivo: () => _toggleIngreso(ing),
                          onEliminar: () => _confirmarEliminarIngreso(ing),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _listaGastos(ThemeData theme, Color colorSec) {
    return StreamBuilder<List<GastosFijo>>(
      stream: _streamGastos,
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
        final gastos = snapshot.data!;
        final total = gastos
            .where((g) => g.activo)
            .fold<int>(
              0,
              (sum, g) => sum + (g.monto * factorMensual(g.frecuencia)).round(),
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _totalRow(theme: theme, total: total, color: AppColors.alerta),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: gastos.isEmpty
                  ? Center(
                      child: Text(
                        'No tienes gastos fijos registrados',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorSec,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: gastos.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final g = gastos[i];
                        return _GastoFijoCard(
                          gasto: g,
                          colorSec: colorSec,
                          frecuenciaLabel: _capitalizar(g.frecuencia),
                          onTap: () => _abrirGastoForm(gasto: g),
                          onLongPress: () => _confirmarEliminarGasto(g),
                          onEditar: () => _abrirGastoForm(gasto: g),
                          onToggleActivo: () => _toggleGasto(g),
                          onEliminar: () => _confirmarEliminarGasto(g),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _GastoVariableCard extends StatelessWidget {
  const _GastoVariableCard({
    required this.gasto,
    required this.colorSec,
    required this.onTap,
    required this.onLongPress,
    required this.onEditar,
    required this.onEliminar,
  });

  final GastosVariable gasto;
  final Color colorSec;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
                  Icon(
                    CategoriaGasto.iconoPara(gasto.categoria),
                    size: 18,
                    color: colorSec,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      gasto.descripcion,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formatCOP(gasto.monto),
                      style: monoStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.alerta,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: colorSec, size: 20),
                    padding: EdgeInsets.zero,
                    tooltip: 'Acciones',
                    onSelected: (v) {
                      if (v == 'editar') onEditar();
                      if (v == 'eliminar') onEliminar();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: AppSpacing.sm),
                            Text('Editar'),
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
              Row(
                children: [
                  AppChip(label: gasto.categoria),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.calendar_today, size: 14, color: colorSec),
                  const SizedBox(width: 4),
                  Text(
                    formatFecha(fechaCivilGuardada(gasto.fecha)),
                    style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
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

class _IngresoCard extends StatelessWidget {
  const _IngresoCard({
    required this.ingreso,
    required this.colorSec,
    required this.frecuenciaLabel,
    required this.cuentaEsteMes,
    required this.onTap,
    required this.onLongPress,
    required this.onEditar,
    required this.onToggleActivo,
    required this.onEliminar,
  });

  final Ingreso ingreso;
  final Color colorSec;
  final String frecuenciaLabel;
  final bool cuentaEsteMes;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEditar;
  final VoidCallback onToggleActivo;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      ingreso.concepto,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formatCOP(ingreso.monto),
                      style: monoStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.positivo,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: colorSec, size: 20),
                    padding: EdgeInsets.zero,
                    tooltip: 'Acciones',
                    onSelected: (v) {
                      switch (v) {
                        case 'editar':
                          onEditar();
                          break;
                        case 'toggle':
                          onToggleActivo();
                          break;
                        case 'eliminar':
                          onEliminar();
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: AppSpacing.sm),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              ingreso.activo
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                              size: 18,
                              color: ingreso.activo ? null : AppColors.positivo,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(ingreso.activo ? 'Desactivar' : 'Activar'),
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
              Row(
                children: [
                  AppChip(label: frecuenciaLabel),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.calendar_today, size: 14, color: colorSec),
                  const SizedBox(width: 4),
                  Text(
                    formatFecha(fechaCivilGuardada(ingreso.fecha)),
                    style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
                  ),
                ],
              ),
              if (ingreso.frecuencia == 'quincenal' ||
                  ingreso.frecuencia == 'semanal') ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '≈ ${formatCOP(ingreso.monto * factorMensual(ingreso.frecuencia))} / mes',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
                ),
              ],
              if (ingreso.activo && !cuentaEsteMes) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'No cuenta en el total de este mes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.alerta,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return AtenuableCard(atenuada: !ingreso.activo, child: card);
  }
}

class _GastoFijoCard extends StatelessWidget {
  const _GastoFijoCard({
    required this.gasto,
    required this.colorSec,
    required this.frecuenciaLabel,
    required this.onTap,
    required this.onLongPress,
    required this.onEditar,
    required this.onToggleActivo,
    required this.onEliminar,
  });

  final GastosFijo gasto;
  final Color colorSec;
  final String frecuenciaLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEditar;
  final VoidCallback onToggleActivo;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      gasto.concepto,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formatCOP(gasto.monto),
                      style: monoStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.alerta,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: colorSec, size: 20),
                    padding: EdgeInsets.zero,
                    tooltip: 'Acciones',
                    onSelected: (v) {
                      switch (v) {
                        case 'editar':
                          onEditar();
                          break;
                        case 'toggle':
                          onToggleActivo();
                          break;
                        case 'eliminar':
                          onEliminar();
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: AppSpacing.sm),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              gasto.activo
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                              size: 18,
                              color: gasto.activo ? null : AppColors.positivo,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(gasto.activo ? 'Desactivar' : 'Activar'),
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
              Row(
                children: [
                  AppChip(label: frecuenciaLabel),
                  if (gasto.diaCobro != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.event_repeat, size: 14, color: colorSec),
                    const SizedBox(width: 4),
                    Text(
                      'Se cobra el día ${gasto.diaCobro}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorSec,
                      ),
                    ),
                  ],
                ],
              ),
              if (gasto.frecuencia == 'quincenal' ||
                  gasto.frecuencia == 'semanal') ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '≈ ${formatCOP(gasto.monto * factorMensual(gasto.frecuencia))} / mes',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return AtenuableCard(atenuada: !gasto.activo, child: card);
  }
}
