import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/daos/categorias_dao.dart';
import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/encabezado_pantalla.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../../utils/iconos_categoria.dart';
import '../../utils/notificaciones.dart';
import 'ajustes_widgets.dart';

/// Ajustes → Presupuestos: las categorías de los gastos del día a día (crear,
/// cambiar nombre/ícono/color, borrar) y el tope mensual de cada una.
class PresupuestosScreen extends StatefulWidget {
  const PresupuestosScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends State<PresupuestosScreen> {
  bool _errorAvisado = false;

  late final _streamCategorias = widget.db.categoriasDao.watchCategorias();
  late final _streamPresupuestos = widget.db.presupuestosCategoriasDao
      .watchPresupuestos();
  late final _streamGastado = () {
    final hoy = DateTime.now();
    return widget.db.gastosVariablesDao.watchTotalPorCategoria(
      hoy.year,
      hoy.month,
    );
  }();

  PresupuestosCategoria? _presupuestoPara(
    List<PresupuestosCategoria> lista,
    String nombre,
  ) {
    for (final p in lista) {
      if (p.categoria == nombre) return p;
    }
    return null;
  }

  void _avisarError() {
    if (_errorAvisado) return;
    _errorAvisado = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        mostrarAlerta(context, 'No se pudieron cargar las categorías.');
      }
    });
  }

  Future<void> _abrirEditor(
    Categoria? categoria,
    PresupuestosCategoria? presupuesto,
  ) async {
    final borrar = await showDialog<bool>(
      context: context,
      builder: (_) => _EditorCategoriaDialog(
        db: widget.db,
        categoria: categoria,
        presupuesto: presupuesto,
      ),
    );
    if (borrar == true && categoria != null && mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            BorrarCategoriaDialog(db: widget.db, categoria: categoria),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Categoria>>(
      stream: _streamCategorias,
      builder: (context, cats) {
        if (cats.hasError) _avisarError();
        return StreamBuilder<List<PresupuestosCategoria>>(
          stream: _streamPresupuestos,
          builder: (context, pres) {
            if (pres.hasError) _avisarError();
            // Lo gastado este mes en "Día a día", por categoría.
            return StreamBuilder<Map<String, int>>(
              stream: _streamGastado,
              builder: (context, gastos) => _contenido(
                context,
                cats.data ?? const [],
                pres.data ?? const [],
                gastos.data ?? const {},
              ),
            );
          },
        );
      },
    );
  }

  Widget _contenido(
    BuildContext context,
    List<Categoria> categorias,
    List<PresupuestosCategoria> presupuestos,
    Map<String, int> gastado,
  ) {
    final theme = Theme.of(context);
    final c = context.colores;
    final n = categorias.length;
    final conLimite = presupuestos.length;
    return PaginaAjustes(
      titulo: 'Categorías y presupuestos',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextoKicker(
                '${n == 1 ? '1 categoría' : '$n categorías'} · '
                '$conLimite con límite',
              ),
              const SizedBox(height: 6),
              Text(
                'Las categorías de tus gastos del día a día. Toca una para '
                'cambiarle el nombre, el ícono o el color, o para ponerle un '
                'tope al mes.',
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
            for (final categoria in categorias)
              _fila(
                context,
                categoria,
                _presupuestoPara(presupuestos, categoria.nombre),
                gastado[categoria.nombre] ?? 0,
              ),
            FilaAjuste(
              key: const ValueKey('nueva-categoria'),
              icono: Icons.add,
              colorIcono: c.acento,
              titulo: 'Nueva categoría',
              onTap: () => _abrirEditor(null, null),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fila(
    BuildContext context,
    Categoria categoria,
    PresupuestosCategoria? presupuesto,
    int gastado,
  ) {
    final theme = Theme.of(context);
    final c = context.colores;
    final icono = iconoDeClave(categoria.icono);
    final color = Color(categoria.color);
    final flecha = Icon(Icons.chevron_right, color: c.textoSecundario);
    if (presupuesto == null) {
      return FilaAjuste(
        icono: icono,
        colorIcono: color,
        titulo: categoria.nombre,
        subtitulo: 'Sin límite',
        trailing: flecha,
        onTap: () => _abrirEditor(categoria, null),
      );
    }
    final limite = presupuesto.limiteMensual;
    final superado = gastado > limite;
    return FilaAjuste(
      icono: icono,
      colorIcono: color,
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
      onTap: () => _abrirEditor(categoria, presupuesto),
    );
  }
}

/// Ventana base de esta pantalla: esquinas de la app, ancho cómodo y
/// desplazable si el teclado la tapa.
class _Ventana extends StatelessWidget {
  const _Ventana({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

Widget _tituloVentana(BuildContext context, String texto) => Text(
  texto,
  style: Theme.of(context).textTheme.titleLarge?.copyWith(
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  ),
);

/// Crear o editar una categoría (nombre, ícono, color y tope mensual).
/// Guarda ella misma; devuelve `true` si el usuario pidió borrarla.
class _EditorCategoriaDialog extends StatefulWidget {
  const _EditorCategoriaDialog({
    required this.db,
    this.categoria,
    this.presupuesto,
  });

  final AppDatabase db;
  final Categoria? categoria;
  final PresupuestosCategoria? presupuesto;

  @override
  State<_EditorCategoriaDialog> createState() => _EditorCategoriaDialogState();
}

class _EditorCategoriaDialogState extends State<_EditorCategoriaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreCtrl = TextEditingController(
    text: widget.categoria?.nombre ?? '',
  );
  late final _limiteCtrl = TextEditingController(
    text: widget.presupuesto == null
        ? ''
        : formatCOPInput(widget.presupuesto!.limiteMensual),
  );
  late String _icono = widget.categoria?.icono ?? 'otros';
  late int _color =
      widget.categoria?.color ?? coloresCategoria.first.toARGB32();
  String? _errorNombre;
  bool _guardando = false;

  bool get _esOtros => widget.categoria?.nombre == CategoriasDao.nombreOtros;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _limiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _errorNombre = null);
    if (!_formKey.currentState!.validate()) return;
    final dao = widget.db.categoriasDao;
    final nombre = _nombreCtrl.text.trim();
    if (await dao.existeNombre(nombre, salvoId: widget.categoria?.id)) {
      setState(() => _errorNombre = 'Ya tienes una categoría con ese nombre');
      return;
    }
    setState(() => _guardando = true);
    try {
      final actual = widget.categoria;
      if (actual == null) {
        await dao.crear(nombre: nombre, icono: _icono, color: _color);
      } else {
        await dao.actualizar(
          actual,
          nombre: nombre,
          icono: _icono,
          color: _color,
        );
      }
      final nombreFinal = _esOtros ? CategoriasDao.nombreOtros : nombre;
      final limite = parseCOP(_limiteCtrl.text);
      final presupuestos = widget.db.presupuestosCategoriasDao;
      if (limite == null || limite <= 0) {
        final p = await presupuestos.getPresupuestoPorCategoria(nombreFinal);
        if (p != null) await presupuestos.eliminarPresupuesto(p.id);
      } else {
        await presupuestos.upsertPresupuesto(
          PresupuestosCategoriasCompanion(
            categoria: Value(nombreFinal),
            limiteMensual: Value(limite),
          ),
        );
      }
      if (mounted) Navigator.pop(context, false);
    } catch (e) {
      debugPrint('Categorías: no se pudo guardar: $e');
      if (mounted) {
        setState(() => _guardando = false);
        mostrarAlerta(context, 'No se pudo guardar la categoría.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final nueva = widget.categoria == null;
    return Form(
      key: _formKey,
      child: _Ventana(
        children: [
          _tituloVentana(
            context,
            nueva ? 'Nueva categoría' : 'Editar categoría',
          ),
          const SizedBox(height: AppSpacing.lg),
          CampoEtiquetado(
            etiqueta: 'Nombre',
            ayuda: _esOtros
                ? '"Otros" no se puede renombrar ni borrar: es a donde van '
                      'los gastos de una categoría borrada.'
                : null,
            error: _errorNombre,
            child: TextFormField(
              key: const ValueKey('categoria-nombre'),
              controller: _nombreCtrl,
              enabled: !_esOtros,
              autofocus: nueva,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 30,
              decoration: const InputDecoration(
                hintText: 'Ej. Gimnasio',
                counterText: '',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ponle un nombre' : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          CampoEtiquetado(
            etiqueta: 'Ícono',
            ayuda: 'Desliza para ver más.',
            // Tres filas que se deslizan de lado: con todos los íconos en
            // columna la ventana quedaba larguísima en celular.
            child: SizedBox(
              height: 42 * 3 + 6 * 2,
              child: GridView.count(
                crossAxisCount: 3,
                scrollDirection: Axis.horizontal,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (final e in iconosCategoria.entries)
                    _Opcion(
                      key: ValueKey('icono-${e.key}'),
                      elegida: e.key == _icono,
                      color: Color(_color),
                      onTap: () => setState(() => _icono = e.key),
                      child: Icon(
                        e.value,
                        size: 20,
                        color: e.key == _icono
                            ? Color(_color)
                            : c.textoSecundario,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          CampoEtiquetado(
            etiqueta: 'Color',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in coloresCategoria)
                  _PuntoColor(
                    color: color,
                    elegido: color.toARGB32() == _color,
                    onTap: () => setState(() => _color = color.toARGB32()),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          CampoEtiquetado(
            etiqueta: 'Límite mensual (opcional)',
            ayuda: 'Déjalo vacío si no quieres tope.',
            child: TextFormField(
              key: const ValueKey('categoria-limite'),
              controller: _limiteCtrl,
              style: monoStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'Sin límite',
                prefixText: r'$ ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CopInputFormatter(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Si no caben en una línea (letra grande), se apilan.
          OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: AppSpacing.xs,
            overflowSpacing: AppSpacing.xs,
            overflowAlignment: OverflowBarAlignment.end,
            children: [
              TextButton(
                onPressed: _guardando ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: const Text('Guardar'),
              ),
            ],
          ),
          if (!nueva && !_esOtros) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(color: c.divisor, height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _guardando
                    ? null
                    : () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: c.alerta),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Eliminar categoría'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    super.key,
    required this.elegida,
    required this.color,
    required this.onTap,
    required this.child,
  });

  final bool elegida;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: elegida ? color.withValues(alpha: 0.16) : c.relieve,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: elegida ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _PuntoColor extends StatelessWidget {
  const _PuntoColor({
    required this.color,
    required this.elegido,
    required this.onTap,
  });

  final Color color;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: elegido ? context.colores.texto : Colors.transparent,
            width: 2,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Borrar una categoría. Primero explica TODO lo que se va a borrar (sus
/// gastos del día a día de todos los meses y su límite: no hay papelera) y
/// ofrece pasar los gastos a "Otros" en vez de borrarlos. Después, en la
/// misma ventana, dice lo que se borró.
class BorrarCategoriaDialog extends StatefulWidget {
  const BorrarCategoriaDialog({
    super.key,
    required this.db,
    required this.categoria,
  });

  final AppDatabase db;
  final Categoria categoria;

  @override
  State<BorrarCategoriaDialog> createState() => _BorrarCategoriaDialogState();
}

class _BorrarCategoriaDialogState extends State<BorrarCategoriaDialog> {
  UsoCategoria? _uso;
  CategoriaBorrada? _hecho;
  bool _borrando = false;

  @override
  void initState() {
    super.initState();
    widget.db.categoriasDao.usoDe(widget.categoria.nombre).then((u) {
      if (mounted) setState(() => _uso = u);
    });
  }

  Future<void> _borrar({required bool moverAOtros}) async {
    setState(() => _borrando = true);
    try {
      final r = await widget.db.categoriasDao.borrar(
        widget.categoria,
        moverAOtros: moverAOtros,
      );
      if (mounted) setState(() => _hecho = r);
    } catch (e) {
      debugPrint('Categorías: no se pudo borrar: $e');
      if (mounted) {
        Navigator.pop(context);
        mostrarAlerta(context, 'No se pudo borrar la categoría.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uso = _uso;
    if (uso == null) {
      return const _Ventana(
        children: [Center(child: CircularProgressIndicator())],
      );
    }
    return _hecho == null ? _confirmar(context, uso) : _resumen(context);
  }

  Widget _confirmar(BuildContext context, UsoCategoria uso) {
    final theme = Theme.of(context);
    final c = context.colores;
    final nombre = widget.categoria.nombre;
    final texto = theme.textTheme.bodyMedium?.copyWith(height: 1.45);
    final g = uso.gastos;
    final puntos = <String>[
      if (g > 0)
        'Se ${g == 1 ? 'borrará 1 gasto' : 'borrarán $g gastos'} del día a '
            'día que ${g == 1 ? 'tiene' : 'tienen'} esta categoría '
            '(${formatCOP(uso.totalGastos)} en total, de todos los meses).',
      if (uso.limiteMensual != null)
        'Se borrará su límite mensual de ${formatCOP(uso.limiteMensual!)}.',
      if (uso.vacia) 'No tiene gastos ni límite: solo se borra la categoría.',
    ];
    return _Ventana(
      children: [
        _tituloVentana(context, '¿Borrar la categoría "$nombre"?'),
        const SizedBox(height: AppSpacing.md),
        for (final p in puntos) _Punto(texto: p, estilo: texto),
        if (g > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Esos gastos desaparecen de tus números en Valtiq (Inicio, '
            'Finanzas y presupuestos). No hay papelera: no se pueden '
            'recuperar.',
            style: texto?.copyWith(
              color: c.alerta,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Si quieres conservarlos, pásalos a "${CategoriasDao.nombreOtros}": '
            'se borra la categoría pero los gastos se quedan.',
            style: texto?.copyWith(color: c.textoSecundario),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (g > 0) ...[
          OutlinedButton.icon(
            key: const ValueKey('borrar-categoria-mover'),
            onPressed: _borrando ? null : () => _borrar(moverAOtros: true),
            icon: const Icon(Icons.drive_file_move_outline, size: 18),
            label: Text('Pasar gastos a "${CategoriasDao.nombreOtros}"'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        FilledButton.icon(
          key: const ValueKey('borrar-categoria-confirmar'),
          onPressed: _borrando ? null : () => _borrar(moverAOtros: false),
          style: FilledButton.styleFrom(
            backgroundColor: c.alerta,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: Text(g > 0 ? 'Borrar categoría y gastos' : 'Borrar'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _borrando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _resumen(BuildContext context) {
    final theme = Theme.of(context);
    final h = _hecho!;
    final uso = h.uso;
    final texto = theme.textTheme.bodyMedium?.copyWith(height: 1.45);
    final g = uso.gastos;
    final puntos = <String>[
      'Se borró la categoría "${h.nombre}".',
      if (g > 0 && h.gastosMovidos)
        '${g == 1 ? '1 gasto pasó' : '$g gastos pasaron'} a '
            '"${CategoriasDao.nombreOtros}" (${formatCOP(uso.totalGastos)}).',
      if (g > 0 && !h.gastosMovidos)
        '${g == 1 ? 'Se borró 1 gasto' : 'Se borraron $g gastos'} del día a '
            'día (${formatCOP(uso.totalGastos)}).',
      if (uso.limiteMensual != null)
        'Se borró su límite mensual de ${formatCOP(uso.limiteMensual!)}.',
    ];
    return _Ventana(
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_outline, color: context.colores.positivo),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _tituloVentana(context, 'Listo')),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final p in puntos) _Punto(texto: p, estilo: texto),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          key: const ValueKey('borrar-categoria-listo'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({required this.texto, this.estilo});

  final String texto;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: estilo),
          Expanded(child: Text(texto, style: estilo)),
        ],
      ),
    );
  }
}
