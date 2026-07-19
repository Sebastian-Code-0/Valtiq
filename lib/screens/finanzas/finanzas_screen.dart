import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/date_format.dart';
import '../../utils/format.dart';
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
  late final Stream<List<GastosVariable>> _streamGastosVariables;
  late final Stream<List<GastosFijo>> _streamGastos;

  String _capitalizar(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  void initState() {
    super.initState();
    _streamIngresos = (widget.db.select(widget.db.ingresos)
          ..orderBy([(i) => OrderingTerm.desc(i.fecha)]))
        .watch();
    final now = DateTime.now();
    _streamGastosVariables =
        widget.db.gastosVariablesDao.watchGastosPorMes(now.year, now.month);
    _streamGastos = (widget.db.select(widget.db.gastosFijos)
          ..orderBy([(g) => OrderingTerm.asc(g.concepto)]))
        .watch();
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GastoVariableForm(db: widget.db, gasto: gasto),
      ),
    );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo eliminar el gasto.')),
          );
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
    final isDark = theme.brightness == Brightness.dark;
    final colorSec = isDark
        ? AppColors.textoSecundarioOscuro
        : AppColors.textoSecundarioClaro;

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
                    ButtonSegment(
                      value: 'gastos',
                      label: Text('Gastos Fijos'),
                    ),
                    ButtonSegment(
                      value: 'variables',
                      label: Text('Variables'),
                    ),
                  ],
                  selected: {_modo},
                  onSelectionChanged: (s) => setState(() => _modo = s.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                    selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
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
        final total = gastos.fold<double>(0, (s, g) => s + g.monto);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _totalRow(theme: theme, total: total, color: AppColors.alerta),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: gastos.isEmpty
                  ? Center(
                      child: Text(
                        'No hay gastos variables este mes',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorSec,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: gastos.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final g = gastos[i];
                        return _GastoVariableCard(
                          gasto: g,
                          colorSec: colorSec,
                          onTap: () => _abrirGastoVariableForm(gasto: g),
                          onLongPress: () =>
                              _confirmarEliminarGastoVariable(g),
                          onEditar: () => _abrirGastoVariableForm(gasto: g),
                          onEliminar: () =>
                              _confirmarEliminarGastoVariable(g),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _totalRow({
    required ThemeData theme,
    required double total,
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
        final total = ingresos
            .where((i) => i.activo)
            .fold<double>(0, (sum, i) => sum + i.monto);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _totalRow(theme: theme, total: total, color: AppColors.positivo),
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
            .fold<double>(0, (sum, g) => sum + g.monto);

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

  static IconData _iconoCategoria(String cat) {
    switch (cat) {
      case 'Alimentación':
        return Icons.restaurant_outlined;
      case 'Ropa':
        return Icons.checkroom_outlined;
      case 'Transporte':
        return Icons.directions_bus_outlined;
      case 'Entretenimiento':
        return Icons.movie_outlined;
      case 'Salud':
        return Icons.health_and_safety_outlined;
      case 'Educación':
        return Icons.school_outlined;
      case 'Hogar':
        return Icons.home_outlined;
      default:
        return Icons.category_outlined;
    }
  }

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
                    _iconoCategoria(gasto.categoria),
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
                  _FrecuenciaChip(label: gasto.categoria),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.calendar_today, size: 14, color: colorSec),
                  const SizedBox(width: 4),
                  Text(
                    formatFecha(gasto.fecha),
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

class _FrecuenciaChip extends StatelessWidget {
  const _FrecuenciaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
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
    required this.onTap,
    required this.onLongPress,
    required this.onEditar,
    required this.onToggleActivo,
    required this.onEliminar,
  });

  final Ingreso ingreso;
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
                  _FrecuenciaChip(label: frecuenciaLabel),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.calendar_today, size: 14, color: colorSec),
                  const SizedBox(width: 4),
                  Text(
                    formatFecha(ingreso.fecha),
                    style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return ingreso.activo ? card : Opacity(opacity: 0.6, child: card);
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
                  _FrecuenciaChip(label: frecuenciaLabel),
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
            ],
          ),
        ),
      ),
    );
    return gasto.activo ? card : Opacity(opacity: 0.6, child: card);
  }
}
