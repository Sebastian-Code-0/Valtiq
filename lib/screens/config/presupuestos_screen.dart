import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/categoria_gasto.dart';
import '../../utils/currency_input.dart';
import '../../utils/encabezado_pantalla.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../../utils/notificaciones.dart';
import 'ajustes_widgets.dart';

class PresupuestosScreen extends StatefulWidget {
  const PresupuestosScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends State<PresupuestosScreen> {
  bool _errorAvisado = false;

  PresupuestosCategoria? _presupuestoPara(
    List<PresupuestosCategoria> lista,
    CategoriaGasto categoria,
  ) {
    for (final p in lista) {
      if (p.categoria == categoria.nombre) return p;
    }
    return null;
  }

  Future<void> _editarPresupuesto(
    CategoriaGasto categoria,
    PresupuestosCategoria? actual,
  ) async {
    final resultado = await showDialog<Object?>(
      context: context,
      builder: (ctx) =>
          _EditarPresupuestoDialog(categoria: categoria, actual: actual),
    );

    if (resultado == 'quitar' && actual != null) {
      await widget.db.presupuestosCategoriasDao.eliminarPresupuesto(actual.id);
    } else if (resultado is int) {
      await widget.db.presupuestosCategoriasDao.upsertPresupuesto(
        PresupuestosCategoriasCompanion(
          categoria: Value(categoria.nombre),
          limiteMensual: Value(resultado),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    return StreamBuilder<List<PresupuestosCategoria>>(
      stream: widget.db.presupuestosCategoriasDao.watchPresupuestos(),
      builder: (context, snapshot) {
        if (snapshot.hasError && !_errorAvisado) {
          _errorAvisado = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              mostrarAlerta(context, 'No se pudieron cargar los presupuestos.');
            }
          });
        }
        final lista = snapshot.data ?? const <PresupuestosCategoria>[];
        // Lo gastado este mes en "Día a día", por categoría.
        return StreamBuilder<Map<String, int>>(
          stream: widget.db.gastosVariablesDao.watchTotalPorCategoria(
            hoy.year,
            hoy.month,
          ),
          builder: (context, gastos) =>
              _contenido(context, lista, gastos.data ?? const {}),
        );
      },
    );
  }

  Widget _contenido(
    BuildContext context,
    List<PresupuestosCategoria> lista,
    Map<String, int> gastado,
  ) {
    final theme = Theme.of(context);
    final c = context.colores;
    final conLimite = lista.length;
    return PaginaAjustes(
      titulo: 'Presupuestos por categoría',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextoKicker(
                conLimite == 1
                    ? '1 categoría con límite'
                    : '$conLimite categorías con límite',
              ),
              const SizedBox(height: 6),
              Text(
                'Pon un tope mensual a tus gastos del día a día. Toca una '
                'categoría para ponerlo o cambiarlo.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: c.textoSecundario,
                ),
              ),
            ],
          ),
        ),
        TarjetaFilas(
          children: [
            for (final categoria in CategoriaGasto.values)
              _fila(
                context,
                categoria,
                _presupuestoPara(lista, categoria),
                gastado[categoria.nombre] ?? 0,
              ),
          ],
        ),
      ],
    );
  }

  Widget _fila(
    BuildContext context,
    CategoriaGasto categoria,
    PresupuestosCategoria? presupuesto,
    int gastado,
  ) {
    final theme = Theme.of(context);
    final c = context.colores;
    final flecha = Icon(Icons.chevron_right, color: c.textoSecundario);
    if (presupuesto == null) {
      return FilaAjuste(
        icono: categoria.icono,
        colorIcono: categoria.color,
        titulo: categoria.nombre,
        subtitulo: 'Sin límite',
        trailing: flecha,
        onTap: () => _editarPresupuesto(categoria, null),
      );
    }
    final limite = presupuesto.limiteMensual;
    final superado = gastado > limite;
    return FilaAjuste(
      icono: categoria.icono,
      colorIcono: categoria.color,
      titulo: categoria.nombre,
      abajo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BarraProgreso(
            fraccion: limite > 0 ? gastado / limite : 0,
            color: superado ? c.alerta : c.acento,
          ),
          const SizedBox(height: 6),
          Text(
            superado
                ? 'Superado por ${formatCOP(gastado - limite)} este mes'
                : 'Llevas ${formatCOP(gastado)} este mes',
            style: theme.textTheme.bodySmall?.copyWith(
              color: superado ? c.alerta : c.textoSecundario,
              fontWeight: superado ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatCOP(limite),
            style: monoStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          flecha,
        ],
      ),
      onTap: () => _editarPresupuesto(categoria, presupuesto),
    );
  }
}

class _EditarPresupuestoDialog extends StatefulWidget {
  const _EditarPresupuestoDialog({required this.categoria, this.actual});

  final CategoriaGasto categoria;
  final PresupuestosCategoria? actual;

  @override
  State<_EditarPresupuestoDialog> createState() =>
      _EditarPresupuestoDialogState();
}

class _EditarPresupuestoDialogState extends State<_EditarPresupuestoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.actual != null
          ? formatCOPInput(widget.actual!.limiteMensual)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Límite para ${widget.categoria.nombre}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          style: monoStyle(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            hintText: '0',
            prefixText: r'$ ',
            helperText: 'Tope para un mes',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CopInputFormatter(),
          ],
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Requerido';
            final n = parseCOP(v);
            if (n == null || n <= 0) return 'Debe ser mayor a 0';
            return null;
          },
        ),
      ),
      actions: [
        if (widget.actual != null)
          TextButton(
            onPressed: () => Navigator.pop(context, 'quitar'),
            child: Text(
              'Quitar límite',
              style: TextStyle(color: context.colores.alerta),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, parseCOP(_controller.text));
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
