import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/categorias_service.dart';
import '../../theme/theme.dart';
import '../../utils/confirmar.dart';
import '../../utils/date_format.dart';
import '../../utils/encabezado_pantalla.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../../utils/frecuencia.dart';
import '../../utils/notificaciones.dart';
import '../../utils/selector_pildoras.dart';
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

  static const _categoriasVisibles = 3;
  bool _todasLasCategorias = false;
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
    final ok = await confirmar(
      context,
      titulo: 'Eliminar gasto',
      mensaje: '¿Eliminar "${gasto.descripcion}"?',
      accion: 'Eliminar',
      peligro: true,
    );
    if (ok) await widget.db.gastosVariablesDao.deleteGastoVariable(gasto.id);
  }

  Future<void> _confirmarEliminarIngreso(Ingreso ingreso) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar ingreso',
      mensaje: '¿Eliminar el ingreso "${ingreso.concepto}"?',
      accion: 'Eliminar',
      peligro: true,
    );
    if (ok) await widget.db.ingresosDao.deleteIngreso(ingreso.id);
  }

  Future<void> _confirmarEliminarGasto(GastosFijo gasto) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar gasto fijo',
      mensaje: '¿Eliminar el gasto "${gasto.concepto}"?',
      accion: 'Eliminar',
      peligro: true,
    );
    if (!ok) return;
    try {
      await widget.db.gastosFijosDao.deleteGastoFijoConRecordatorios(gasto.id);
    } catch (_) {
      if (mounted) mostrarAlerta(context, 'No se pudo eliminar el gasto.');
    }
  }

  Future<void> _toggleIngreso(Ingreso ingreso) async {
    await widget.db.ingresosDao.setActivo(ingreso.id, activo: !ingreso.activo);
  }

  Future<void> _toggleGasto(GastosFijo gasto) async {
    await widget.db.gastosFijosDao.setActivo(gasto.id, activo: !gasto.activo);
  }

  static const _pestanas = [
    OpcionPildora('Ingresos'),
    OpcionPildora('Gastos fijos'),
    OpcionPildora('Día a día'),
  ];
  static const _modos = ['ingresos', 'gastos', 'variables'];

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final ancho = constraints.maxWidth >= 800;
            final margen = ancho ? AppSpacing.xl : AppSpacing.md;
            return Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppSpacing.anchoContenido + 2 * margen,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        margen,
                        margen,
                        margen,
                        AppSpacing.lg,
                      ),
                      child: EncabezadoPantalla(
                        kicker: formatMesAnio(hoy),
                        titulo: 'Finanzas',
                        // El botón de crear cambia con la pestaña.
                        accion: switch (_modo) {
                          'ingresos' => BotonCrear(
                            texto: 'Nuevo ingreso',
                            heroTag: 'fab_ingresos',
                            onPressed: () => _abrirIngresoForm(),
                          ),
                          'variables' => BotonCrear(
                            texto: 'Nuevo gasto',
                            heroTag: 'fab_variables',
                            onPressed: () => _abrirGastoVariableForm(),
                          ),
                          _ => BotonCrear(
                            texto: 'Nuevo gasto fijo',
                            heroTag: 'fab_gastos',
                            onPressed: () => _abrirGastoForm(),
                          ),
                        },
                      ),
                    ),
                    SelectorPildoras(
                      opciones: _pestanas,
                      seleccionada: _modos.indexOf(_modo),
                      margen: margen,
                      repartirEnCelular: true,
                      onElegir: (i) => setState(() => _modo = _modos[i]),
                    ),
                    SizedBox(height: ancho ? AppSpacing.md : AppSpacing.sm),
                    Expanded(
                      child: switch (_modo) {
                        'variables' => _listaGastosVariables(margen),
                        'ingresos' => _listaIngresos(margen),
                        _ => _listaGastos(margen),
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _cargando(AsyncSnapshot<Object?> snapshot) => snapshot.hasError
      ? const Center(child: Text('Error al cargar los datos.'))
      : const Center(child: CircularProgressIndicator());

  /// Mensaje para una lista sin nada.
  Widget _vacio(String mensaje, {IconData? icono}) {
    final c = context.colores;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          if (icono != null) ...[
            Icon(icono, size: 32, color: c.textoSecundario),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: c.textoSecundario),
          ),
        ],
      ),
    );
  }

  /// Una sola tarjeta con las filas separadas por líneas finas.
  Widget _tarjetaFilas(List<Widget> filas) {
    final c = context.colores;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, f) in filas.indexed) ...[
            if (i > 0)
              Divider(height: 1, indent: 22, endIndent: 22, color: c.divisor),
            f,
          ],
        ],
      ),
    );
  }

  Widget _listaGastosVariables(double margen) {
    return StreamBuilder<List<GastosVariable>>(
      stream: _streamGastosVariables,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _cargando(snapshot);
        final c = context.colores;
        final gastos = snapshot.data!;
        final total = gastos.fold<int>(0, (s, g) => s + g.monto);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          // Todo en UNA sola lista que se desplaza junta: mes, total, barras
          // por categoría y el detalle de cada gasto. (Con las barras fijas
          // arriba, varias categorías se comían la pantalla y no se podía
          // bajar a ver los gastos.)
          child: ListView(
            key: ValueKey(_mesVariables),
            padding: EdgeInsets.fromLTRB(margen, AppSpacing.sm, margen, margen),
            children: [
              Wrap(
                spacing: 40,
                runSpacing: AppSpacing.md,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  _Total(titulo: 'Gastado en el mes', valor: formatCOP(total)),
                  _Total(titulo: 'Gastos', valor: '${gastos.length}'),
                  // Selector de mes, en su propia píldora.
                  Container(
                    decoration: ShapeDecoration(
                      color: c.superficie,
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: c.divisor,
                          width: AppSpacing.borde,
                        ),
                      ),
                    ),
                    // Del ancho de su contenido (si no, se estira a toda la
                    // fila).
                    child: IntrinsicWidth(
                      child: SelectorMes(
                        anio: _mesVariables.year,
                        mes: _mesVariables.month,
                        onCambiar: _cambiarMesVariables,
                        compacto: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _resumenPorCategoria(),
              if (gastos.isEmpty)
                _vacio(
                  'No hay gastos del día a día este mes',
                  icono: Icons.calendar_month_outlined,
                )
              else
                _tarjetaFilas([
                  for (final g in gastos)
                    _Fila(
                      key: ValueKey(g.id),
                      icono: CategoriasService.iconoPara(g.categoria),
                      titulo: g.descripcion,
                      detalle:
                          '${g.categoria} · '
                          '${formatFecha(fechaCivilGuardada(g.fecha))}',
                      monto: formatCOP(g.monto),
                      onTap: () => _abrirGastoVariableForm(gasto: g),
                      onEliminar: () => _confirmarEliminarGastoVariable(g),
                    ),
                ]),
            ],
          ),
        );
      },
    );
  }

  /// Barras de gasto por categoría, de mayor a menor. Solo se muestran las
  /// [_categoriasVisibles] más grandes; el resto se despliega con un botón,
  /// para que el resumen no empuje el detalle fuera de la pantalla.
  Widget _resumenPorCategoria() {
    final theme = Theme.of(context);
    return StreamBuilder<Map<String, double>>(
      stream: _streamTotalPorCategoria,
      builder: (context, snapCategorias) {
        final porCategoria = snapCategorias.data ?? {};
        if (porCategoria.isEmpty) return const SizedBox.shrink();

        final entradas = porCategoria.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final montoMaximo = entradas.first.value;
        final ocultas = entradas.length - _categoriasVisibles;
        final visibles = _todasLasCategorias || ocultas <= 0
            ? entradas
            : entradas.take(_categoriasVisibles);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Por categoría',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final e in visibles)
                    BarraCategoria(
                      categoria: e.key,
                      monto: e.value,
                      montoMaximo: montoMaximo,
                    ),
                  if (ocultas > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(
                          () => _todasLasCategorias = !_todasLasCategorias,
                        ),
                        icon: Icon(
                          _todasLasCategorias
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                        label: Text(
                          _todasLasCategorias
                              ? 'Ver menos'
                              : 'Ver $ocultas ${ocultas == 1 ? 'categoría' : 'categorías'} más',
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _listaIngresos(double margen) {
    return StreamBuilder<List<Ingreso>>(
      stream: _streamIngresos,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _cargando(snapshot);
        final c = context.colores;
        final ingresos = snapshot.data!;
        final activos = ingresos.where((i) => i.activo).length;

        return ListView(
          padding: EdgeInsets.fromLTRB(margen, AppSpacing.sm, margen, margen),
          children: [
            Wrap(
              spacing: 40,
              runSpacing: AppSpacing.md,
              children: [
                StreamBuilder<int>(
                  stream: _streamTotalIngresosMes,
                  builder: (context, totalSnap) => _Total(
                    titulo: 'Ingresos de este mes',
                    valor: formatCOP(totalSnap.data ?? 0),
                    color: c.positivo,
                  ),
                ),
                _Total(titulo: 'Activos', valor: '$activos'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (ingresos.isEmpty)
              _vacio('No tienes ingresos registrados')
            else
              _tarjetaFilas([
                for (final ing in ingresos)
                  _Fila(
                    key: ValueKey(ing.id),
                    icono: Icons.trending_up,
                    colorIcono: c.positivo,
                    titulo: ing.concepto,
                    detalle:
                        '${_capitalizar(ing.frecuencia)} · '
                        '${formatFecha(fechaCivilGuardada(ing.fecha))}'
                        '${ing.frecuencia == 'quincenal' || ing.frecuencia == 'semanal' ? ' · ≈ ${formatCOP(ing.monto * factorMensual(ing.frecuencia))} / mes' : ''}',
                    aviso: ing.activo && !_cuentaEsteMes(ing)
                        ? 'No cuenta en el total de este mes'
                        : null,
                    monto: formatCOP(ing.monto),
                    colorMonto: c.positivo,
                    atenuada: !ing.activo,
                    activo: ing.activo,
                    onTap: () => _abrirIngresoForm(ingreso: ing),
                    onToggleActivo: () => _toggleIngreso(ing),
                    onEliminar: () => _confirmarEliminarIngreso(ing),
                  ),
              ]),
          ],
        );
      },
    );
  }

  Widget _listaGastos(double margen) {
    return StreamBuilder<List<GastosFijo>>(
      stream: _streamGastos,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _cargando(snapshot);
        final gastos = snapshot.data!;
        final activos = gastos.where((g) => g.activo).toList();
        final total = activos.fold<int>(
          0,
          (sum, g) => sum + (g.monto * factorMensual(g.frecuencia)).round(),
        );

        return ListView(
          padding: EdgeInsets.fromLTRB(margen, AppSpacing.sm, margen, margen),
          children: [
            Wrap(
              spacing: 40,
              runSpacing: AppSpacing.md,
              children: [
                _Total(titulo: 'Gastos fijos al mes', valor: formatCOP(total)),
                _Total(titulo: 'Activos', valor: '${activos.length}'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (gastos.isEmpty)
              _vacio('No tienes gastos fijos registrados')
            else
              _tarjetaFilas([
                for (final g in gastos)
                  _Fila(
                    key: ValueKey(g.id),
                    icono: Icons.event_repeat,
                    titulo: g.concepto,
                    detalle:
                        '${_capitalizar(g.frecuencia)}'
                        '${g.diaCobro != null ? ' · Se cobra el día ${g.diaCobro}' : ''}'
                        '${g.frecuencia == 'quincenal' || g.frecuencia == 'semanal' ? ' · ≈ ${formatCOP(g.monto * factorMensual(g.frecuencia))} / mes' : ''}',
                    monto: formatCOP(g.monto),
                    atenuada: !g.activo,
                    activo: g.activo,
                    onTap: () => _abrirGastoForm(gasto: g),
                    onToggleActivo: () => _toggleGasto(g),
                    onEliminar: () => _confirmarEliminarGasto(g),
                  ),
              ]),
          ],
        );
      },
    );
  }
}

/// Un total de arriba, suelto (sin tarjeta): rótulo pequeño y cifra grande.
class _Total extends StatelessWidget {
  const _Total({required this.titulo, required this.valor, this.color});

  final String titulo;
  final String valor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width >= 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titulo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.colores.textoSecundario,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: monoStyle(
            fontSize: ancho ? 28 : 22,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Fila de un ingreso o un gasto: cuadro con ícono, nombre y detalle, el
/// monto a la derecha y el menú de acciones. Tocarla abre el formulario para
/// editar; mantenerla presionada pide eliminar.
class _Fila extends StatelessWidget {
  const _Fila({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.monto,
    required this.onTap,
    required this.onEliminar,
    this.colorIcono,
    this.colorMonto,
    this.aviso,
    this.atenuada = false,
    this.activo,
    this.onToggleActivo,
  });

  final IconData icono;
  final Color? colorIcono;
  final String titulo;
  final String detalle;

  /// Línea extra en rojo (p. ej. "No cuenta en el total de este mes").
  final String? aviso;
  final String monto;
  final Color? colorMonto;

  /// Desactivado: se ve apagado.
  final bool atenuada;

  /// Si no es `null`, el menú ofrece Activar/Desactivar.
  final bool? activo;
  final VoidCallback? onToggleActivo;
  final VoidCallback onTap;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    final pequeno = theme.textTheme.bodySmall?.copyWith(
      color: c.textoSecundario,
    );
    final fila = InkWell(
      onTap: onTap,
      onLongPress: onEliminar,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 10, 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorIcono?.withValues(alpha: 0.14) ?? c.relieve,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icono,
                size: 18,
                color: colorIcono ?? c.textoSecundario,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    detalle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: pequeno,
                  ),
                  if (aviso != null)
                    Text(
                      aviso!,
                      style: pequeno?.copyWith(
                        color: c.alerta,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              monto,
              style: monoStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorMonto,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 32,
              height: 32,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: c.textoSecundario, size: 20),
                padding: EdgeInsets.zero,
                tooltip: 'Acciones',
                // Con textos tan cortos el menú salía muy angosto.
                constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
                onSelected: (v) => switch (v) {
                  'editar' => onTap(),
                  'toggle' => onToggleActivo?.call(),
                  _ => onEliminar(),
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'editar', child: Text('Editar')),
                  if (activo != null)
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(activo! ? 'Desactivar' : 'Activar'),
                    ),
                  PopupMenuItem(
                    value: 'eliminar',
                    child: Text('Eliminar', style: TextStyle(color: c.alerta)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return atenuada ? Opacity(opacity: 0.55, child: fila) : fila;
  }
}
