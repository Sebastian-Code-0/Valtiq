import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../services/categorias_service.dart';
import '../../theme/theme.dart';
import '../../utils/encabezado_pantalla.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/format.dart';
import '../../utils/gasto_rapido.dart';
import '../../utils/nombres_conocidos.dart';

/// La categoría que Valtiq propone para un gasto escrito a la carrera:
/// 1. la que se usó antes para ese mismo nombre (aprende del historial),
/// 2. si nunca se anotó, la que sugiere la lista de nombres conocidos
///    ("uber" → Transporte, "café" → Restaurantes),
/// 3. si no, "Otros".
/// Siempre devuelve una de [existentes] (las categorías que hay ahora).
String categoriaPropuesta(
  String descripcion,
  Iterable<(String, String)> historial,
  List<String> existentes,
) {
  const otros = 'Otros';
  for (final c in [
    categoriaAprendida(descripcion, historial),
    categoriaPorNombre(descripcion),
  ]) {
    if (c != null && existentes.contains(c)) return c;
  }
  return existentes.contains(otros) || existentes.isEmpty
      ? otros
      : existentes.last;
}

/// Ventana de "Anotar gasto" que abre el widget de Android: un renglón
/// ("café 5mil"), la categoría ya elegida y Guardar. Va sola, encima de la
/// pantalla de inicio del celular (ver `anotarMain` en main.dart): no pasa
/// por el bloqueo con PIN, a propósito, porque solo agrega un gasto y no
/// muestra nada de lo que ya hay guardado.
class AnotarRapidoScreen extends StatefulWidget {
  const AnotarRapidoScreen({
    super.key,
    required this.db,
    required this.alCerrar,
    this.ahora = DateTime.now,
    this.cierreAutomatico = const Duration(seconds: 4),
  });

  final AppDatabase db;

  /// Cierra la ventana (en Android, vuelve a la pantalla de inicio).
  final VoidCallback alCerrar;
  final DateTime Function() ahora;

  /// Cuánto se queda abierto el "Guardado" si no se toca nada.
  final Duration cierreAutomatico;

  @override
  State<AnotarRapidoScreen> createState() => _AnotarRapidoScreenState();
}

class _AnotarRapidoScreenState extends State<AnotarRapidoScreen> {
  final _texto = TextEditingController();
  final _foco = FocusNode();

  /// Gastos anteriores, del más nuevo al más viejo: (nombre, categoría).
  List<(String, String)> _historial = const [];
  GastoLeido? _leido;
  String _categoria = 'Otros';

  /// El usuario tocó una categoría a mano: ya no se cambia sola.
  bool _categoriaElegida = false;
  bool _guardando = false;
  bool _intentoSinMonto = false;

  /// Lo último guardado (para "Deshacer").
  ({int id, GastoLeido gasto, String categoria, String? aviso})? _guardado;
  Timer? _cierre;

  @override
  void initState() {
    super.initState();
    _texto.addListener(_alEscribir);
    _cargarHistorial();
  }

  @override
  void dispose() {
    _cierre?.cancel();
    _texto.dispose();
    _foco.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    final gastos = await widget.db.gastosVariablesDao.getAllGastosVariables();
    gastos.sort((a, b) {
      final f = b.fecha.compareTo(a.fecha);
      return f != 0 ? f : b.id.compareTo(a.id);
    });
    if (!mounted) return;
    setState(() {
      _historial = [for (final g in gastos) (g.descripcion, g.categoria)];
    });
    _alEscribir();
  }

  void _alEscribir() {
    final leido = leerGastoRapido(_texto.text);
    setState(() {
      _leido = leido;
      if (leido != null) _intentoSinMonto = false;
      if (!_categoriaElegida) {
        _categoria = categoriaPropuesta(
          leido?.descripcion ?? _texto.text,
          _historial,
          CategoriasService.nombres,
        );
      }
    });
  }

  Future<void> _guardar() async {
    final leido = _leido;
    if (leido == null) {
      setState(() => _intentoSinMonto = true);
      _foco.requestFocus();
      return;
    }
    setState(() => _guardando = true);
    final hoy = normalizarFechaCivil(widget.ahora());
    final nombre = leido.descripcion.isEmpty ? 'Sin nombre' : leido.descripcion;
    final id = await widget.db.gastosVariablesDao.insertGastoVariable(
      GastosVariablesCompanion.insert(
        descripcion: nombre,
        monto: leido.monto,
        categoria: _categoria,
        fecha: hoy,
      ),
    );
    final aviso = await _avisoPresupuesto(hoy);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _guardando = false;
      _guardado = (
        id: id,
        gasto: GastoLeido(descripcion: nombre, monto: leido.monto),
        categoria: _categoria,
        aviso: aviso,
      );
      _historial = [(nombre, _categoria), ..._historial];
    });
    _foco.unfocus();
    _programarCierre();
  }

  /// "Superaste tu presupuesto de Restaurantes este mes", si pasó.
  Future<String?> _avisoPresupuesto(DateTime hoy) async {
    final p = await widget.db.presupuestosCategoriasDao
        .getPresupuestoPorCategoria(_categoria);
    if (p == null) return null;
    final llevas = await widget.db.gastosVariablesDao.totalCategoriaMes(
      _categoria,
      hoy.year,
      hoy.month,
    );
    if (llevas <= p.limiteMensual) return null;
    return 'Superaste tu presupuesto de $_categoria este mes '
        '(${formatCOP(llevas)} de ${formatCOP(p.limiteMensual)}).';
  }

  void _programarCierre() {
    _cierre?.cancel();
    _cierre = Timer(widget.cierreAutomatico, widget.alCerrar);
  }

  Future<void> _deshacer() async {
    _cierre?.cancel();
    final g = _guardado;
    if (g == null) return;
    await widget.db.gastosVariablesDao.deleteGastoVariable(g.id);
    if (!mounted) return;
    setState(() {
      _guardado = null;
      _historial = _historial.skip(1).toList();
    });
    _foco.requestFocus();
  }

  void _anotarOtro() {
    _cierre?.cancel();
    _texto.clear();
    setState(() {
      _guardado = null;
      _categoriaElegida = false;
    });
    _foco.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      // Fondo oscurecido: tocar fuera de la tarjeta cierra.
      backgroundColor: Colors.black.withValues(alpha: 0.55),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.alCerrar,
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              // Los toques dentro de la tarjeta no la cierran.
              onTap: () {},
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  key: const ValueKey('anotar-tarjeta'),
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration: BoxDecoration(
                    color: c.superficie,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusTarjeta,
                    ),
                    border: Border.all(
                      color: c.divisor,
                      width: AppSpacing.borde,
                    ),
                  ),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    alignment: Alignment.bottomCenter,
                    child: _guardado == null
                        ? _escribir(context)
                        : _listo(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _escribir(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    final leido = _leido;
    return Column(
      key: const ValueKey('anotar-escribir'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: TextoKicker('Anotar gasto')),
            IconButton(
              tooltip: 'Cerrar',
              onPressed: widget.alCerrar,
              icon: Icon(Icons.close, color: c.textoSecundario),
            ),
          ],
        ),
        TextField(
          key: const ValueKey('anotar-texto'),
          controller: _texto,
          focusNode: _foco,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _guardar(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          decoration: const InputDecoration(hintText: 'Ej. café 5000'),
        ),
        const SizedBox(height: 10),
        // Lo que Valtiq entendió, o cómo escribirlo.
        if (leido != null)
          Row(
            key: const ValueKey('anotar-vista-previa'),
            children: [
              Expanded(
                child: Text(
                  leido.descripcion.isEmpty ? 'Sin nombre' : leido.descripcion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: c.textoSecundario,
                  ),
                ),
              ),
              Text(
                formatCOP(leido.monto),
                style: monoStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          )
        else
          Text(
            _intentoSinMonto
                ? 'Falta el monto. Escribe qué fue y cuánto: café 5000.'
                : 'Escribe qué fue y cuánto: café 5000, almuerzo 15mil, '
                      'bus 2.500…',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _intentoSinMonto ? c.alerta : c.textoSecundario,
              fontWeight: _intentoSinMonto ? FontWeight.w600 : null,
            ),
          ),
        const SizedBox(height: 14),
        _selectorCategoria(context),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const ValueKey('anotar-guardar'),
          onPressed: _guardando ? null : _guardar,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _selectorCategoria(BuildContext context) {
    final c = context.colores;
    final nombres = CategoriasService.nombres;
    // La elegida primero, para que siempre se vea sin deslizar.
    final orden = [_categoria, ...nombres.where((n) => n != _categoria)];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: orden.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final nombre = orden[i];
          final elegida = nombre == _categoria;
          final color = CategoriasService.colorPara(nombre);
          return InkWell(
            key: ValueKey('anotar-categoria-$nombre'),
            onTap: () => setState(() {
              _categoria = nombre;
              _categoriaElegida = true;
            }),
            customBorder: const StadiumBorder(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: ShapeDecoration(
                color: elegida ? color.withValues(alpha: 0.18) : c.relieve,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: elegida ? color : Colors.transparent,
                    width: 1.2,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CategoriasService.iconoPara(nombre),
                    size: 16,
                    color: elegida ? color : c.textoSecundario,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    nombre,
                    style: TextStyle(
                      fontFamily: fuenteTexto,
                      fontSize: 13,
                      fontWeight: elegida ? FontWeight.w700 : FontWeight.w500,
                      color: elegida ? c.texto : c.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _listo(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    final g = _guardado!;
    return Column(
      key: const ValueKey('anotar-listo'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.check_circle, color: c.positivo),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Guardado',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${g.gasto.descripcion} · ${formatCOP(g.gasto.monto)} · '
          '${g.categoria}',
          style: theme.textTheme.bodyMedium?.copyWith(color: c.textoSecundario),
        ),
        if (g.aviso != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            g.aviso!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: c.alerta,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('anotar-deshacer'),
                onPressed: _deshacer,
                child: const Text('Deshacer'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                key: const ValueKey('anotar-otro'),
                onPressed: _anotarOtro,
                child: const Text('Anotar otro'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
