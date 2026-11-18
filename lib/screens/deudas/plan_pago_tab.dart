import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../db/database.dart';
import '../../services/deudas_calculos.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/date_format.dart';
import '../../utils/encabezado_pantalla.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/format.dart';
import '../../utils/selector_pildoras.dart';
import 'deuda_widgets.dart';

/// Pestaña "Plan de pago": el usuario elige una estrategia (avalancha o
/// bola de nieve) y cuánto extra puede pagar al mes; la pestaña le dice
/// cuándo queda libre de deudas, cuánto pagarle a cada una este mes, en qué
/// orden, cómo baja lo que debe y cuánto pagará de intereses. Las cuentas
/// las hace [PlanPago.simular].
class PlanPagoTab extends StatefulWidget {
  const PlanPagoTab({
    super.key,
    required this.activas,
    required this.margen,
    this.onEditar,
  });

  final List<ResumenDeuda> activas;
  final double margen;

  /// Abre el formulario de una deuda (para ponerle el pago mínimo que le
  /// falta). Sin esto, el aviso se muestra con los botones apagados.
  final ValueChanged<Deuda>? onEditar;

  /// Preferencias donde se recuerda lo elegido (solo en este dispositivo).
  static const claveEstrategia = 'valtiq_plan_estrategia';
  static const claveExtra = 'valtiq_plan_extra';

  /// Botones rápidos para sumar al extra del mes.
  static const extrasRapidos = [50000, 100000, 200000];

  @override
  State<PlanPagoTab> createState() => _PlanPagoTabState();
}

class _PlanPagoTabState extends State<PlanPagoTab> {
  final _extraCtrl = TextEditingController();
  EstrategiaPago _estrategia = EstrategiaPago.avalancha;
  int _extra = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _extraCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final extra = prefs.getInt(PlanPagoTab.claveExtra) ?? 0;
    setState(() {
      _estrategia = EstrategiaPago.desdeClave(
        prefs.getString(PlanPagoTab.claveEstrategia),
      );
      _extra = extra;
      _extraCtrl.text = extra > 0 ? formatCOPInput(extra) : '';
    });
  }

  Future<void> _elegirEstrategia(EstrategiaPago e) async {
    setState(() => _estrategia = e);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PlanPagoTab.claveEstrategia, e.clave);
  }

  Future<void> _guardarExtra() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PlanPagoTab.claveExtra, _extra);
  }

  Future<void> _cambiarExtra(String texto) async {
    final extra = parseCOP(texto) ?? 0;
    setState(() => _extra = extra < 0 ? 0 : extra);
    await _guardarExtra();
  }

  /// Pone el extra desde un botón (rápido o "Usar este extra").
  Future<void> _ponerExtra(int extra) async {
    setState(() {
      _extra = extra;
      _extraCtrl.text = extra > 0 ? formatCOPInput(extra) : '';
    });
    await _guardarExtra();
  }

  PlanPago _simular(EstrategiaPago e, DateTime hoy, {int? extra}) =>
      PlanPago.simular(
        deudas: widget.activas,
        estrategia: e,
        extraMensual: extra ?? _extra,
        hoy: hoy,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    if (widget.activas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'No tienes deudas activas: no hay nada que planear.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: c.textoSecundario,
            ),
          ),
        ),
      );
    }

    final hoy = DateTime.now();
    final plan = _simular(_estrategia, hoy);
    final otra = _estrategia == EstrategiaPago.avalancha
        ? EstrategiaPago.bolaDeNieve
        : EstrategiaPago.avalancha;
    final planOtra = _simular(otra, hoy);
    final avisos = _avisos(context, plan);
    final esteMes = _tarjetaEsteMes(context, plan, hoy);
    final grafica = _tarjetaGrafica(context, plan);

    Widget columna(List<Widget?> hijos) {
      final visibles = hijos.whereType<Widget>().toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, w) in visibles.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            w,
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth - 2 * widget.margen;
        final controles = _tarjetaControles(context, plan, planOtra, hoy);
        final libre = _tarjetaLibre(context, plan);
        final intereses = _tarjetaIntereses(context, plan, planOtra);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            widget.margen,
            AppSpacing.sm,
            widget.margen,
            widget.margen,
          ),
          // En PC: a la izquierda lo que se elige (estrategia, extra, el
          // orden que resulta) y la gráfica; a la derecha la respuesta. En
          // celular, primero la respuesta (cuándo quedas libre, avisos y lo
          // de este mes) y después los controles.
          child: ancho >= 720
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: columna([controles, grafica])),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: columna([libre, ...avisos, esteMes, intereses]),
                    ),
                  ],
                )
              : columna([
                  libre,
                  ...avisos,
                  esteMes,
                  controles,
                  grafica,
                  intereses,
                ]),
        );
      },
    );
  }

  double _relleno(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 ? 26 : 20;

  Widget _rotulo(BuildContext context, String texto) => Text(
    texto,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: context.colores.textoSecundario,
    ),
  );

  TextStyle? _gris(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 13,
        height: 1.45,
        color: context.colores.textoSecundario,
      );

  // ───────────────────────── Avisos ─────────────────────────

  /// Avisos discretos (se ven como una tarjeta más, solo el ícono lleva el
  /// color de marca): deudas sin pago mínimo, deudas que no bajan, deudas
  /// que terminarían después de su fecha límite.
  List<Widget> _avisos(BuildContext context, PlanPago plan) {
    final avisos = <Widget>[];
    final sinMinimo = [
      for (final p in plan.orden)
        if (p.resumen.pagoMinimo == null) p.resumen.deuda,
    ];
    if (sinMinimo.isNotEmpty) avisos.add(_avisoSinMinimo(context, sinMinimo));

    // Si ninguna tiene pago ni hay extra, la tarjeta grande ya lo explica.
    final noBajan = plan.presupuestoMensual == 0
        ? <PasoPlan>[]
        : plan.sinTerminar;
    if (noBajan.isNotEmpty) {
      final nombres = _lista(
        noBajan.map((p) => p.resumen.deuda.acreedorNombre),
      );
      final una = noBajan.length == 1;
      final s = plan.paraTerminar;
      avisos.add(
        _aviso(
          context,
          llave: 'plan-no-baja',
          icono: Icons.trending_up,
          titulo: una ? '$nombres no baja' : '$nombres no bajan',
          texto:
              'Con lo que se paga al mes, el interés crece más rápido que '
              'los pagos. '
              '${s == null ? 'Sube el pago mínimo o el extra al mes.' : 'Con ${formatCOP(s.extra)} de extra al mes sí terminas todo, en ${formatMesAnio(s.fechaLibre)}.'}',
          extra: s?.extra,
        ),
      );
    }

    final tarde = plan.tarde;
    if (tarde.isNotEmpty) {
      final s = plan.paraLimites;
      final detalle = [
        for (final p in tarde)
          '${p.resumen.deuda.acreedorNombre}: '
              '${p.fecha == null ? 'no termina' : 'termina en ${formatMesAnioCorto(p.fecha!)}'}'
              ', límite ${formatMesAnioCorto(fechaCivilGuardada(p.resumen.deuda.fechaLimite!))}.',
      ].join('\n');
      avisos.add(
        _aviso(
          context,
          llave: 'plan-tarde',
          icono: Icons.event_busy_outlined,
          titulo: tarde.length == 1
              ? '1 deuda termina después de su fecha límite'
              : '${tarde.length} deudas terminan después de su fecha límite',
          texto:
              '$detalle\n'
              '${s == null ? 'Ni con mucho extra se alcanza: habla con quien te prestó para mover la fecha.' : 'Con ${formatCOP(s.extra)} de extra al mes llegas a tiempo.'}',
          extra: s?.extra,
        ),
      );
    }

    final vencidas = [
      for (final p in plan.orden)
        if (p.limiteVencido) p,
    ];
    if (vencidas.isNotEmpty) {
      final nombres = _lista(
        vencidas.map((p) => p.resumen.deuda.acreedorNombre),
      );
      avisos.add(
        _aviso(
          context,
          llave: 'plan-vencida',
          icono: Icons.history_toggle_off,
          titulo: vencidas.length == 1
              ? 'La fecha límite de $nombres ya pasó'
              : 'La fecha límite de $nombres ya pasó',
          texto:
              'El plan la sigue pagando como las demás. Si acordaste una '
              'fecha nueva, edita la deuda para cambiarla.',
        ),
      );
    }
    return avisos;
  }

  /// "Banco", "Banco y Nu", "Banco, Nu y Juan".
  String _lista(Iterable<String> nombres) {
    final l = nombres.toList();
    if (l.length <= 1) return l.join();
    return '${l.sublist(0, l.length - 1).join(', ')} y ${l.last}';
  }

  Widget _cajaAviso(
    BuildContext context, {
    required Key key,
    required Widget child,
  }) {
    final c = context.colores;
    return Container(
      key: key,
      padding: EdgeInsets.all(_relleno(context) - 6),
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.radiusTarjeta),
        border: Border.all(color: c.divisor, width: AppSpacing.borde),
      ),
      child: child,
    );
  }

  Widget _tituloAviso(BuildContext context, IconData icono, String titulo) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icono, size: 18, color: context.colores.acento),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            titulo,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// Aviso con, opcionalmente, un botón que pone el extra sugerido.
  Widget _aviso(
    BuildContext context, {
    required String llave,
    required IconData icono,
    required String titulo,
    required String texto,
    int? extra,
  }) {
    return _cajaAviso(
      context,
      key: ValueKey(llave),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloAviso(context, icono, titulo),
          const SizedBox(height: 6),
          Text(texto, style: _gris(context)),
          if (extra != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              key: ValueKey('$llave-usar'),
              onPressed: () => _ponerExtra(extra),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: Text('Usar ${formatCOP(extra)} de extra'),
            ),
          ],
        ],
      ),
    );
  }

  /// Aviso de las deudas que no tienen pago mínimo. Sin ese dato el plan no
  /// sabe cuánto se les paga cada mes: solo reciben "lo que sobra", y si
  /// ninguna lo tiene, el plan no puede dar fecha.
  Widget _avisoSinMinimo(BuildContext context, List<Deuda> faltan) {
    final una = faltan.length == 1;
    return _cajaAviso(
      context,
      key: const ValueKey('plan-sin-minimo'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloAviso(
            context,
            Icons.info_outline,
            una
                ? 'A 1 deuda le falta el pago mínimo'
                : 'A ${faltan.length} deudas les falta el pago mínimo',
          ),
          const SizedBox(height: 6),
          Text(
            'El pago mínimo es lo que pagas cada mes por esa deuda. Sin ese '
            'dato el plan no puede calcular bien cuándo terminas: '
            '${una ? 'esa deuda' : 'esas deudas'} solo '
            '${una ? 'recibe' : 'reciben'} lo que sobra de las demás.',
            style: _gris(context),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final d in faltan)
                OutlinedButton.icon(
                  onPressed: widget.onEditar == null
                      ? null
                      : () => widget.onEditar!(d),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(
                    'Poner pago mínimo a ${d.acreedorNombre}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Libre de deudas ─────────────────────────

  /// Tarjeta destacada: cuándo se queda libre de deudas y cuánto se gana
  /// frente a pagar solo los mínimos.
  Widget _tarjetaLibre(BuildContext context, PlanPago plan) {
    final c = context.colores;
    final String grande;
    final String detalle;
    if (plan.alcanza) {
      final meses = plan.meses!;
      grande = formatMesAnio(plan.fechaLibre!);
      detalle =
          '${meses == 0 ? 'Este mismo mes' : 'En $meses ${meses == 1 ? 'mes' : 'meses'}'}, '
          'pagando ${formatCOP(plan.presupuestoMensual)} al mes entre todas.';
    } else if (plan.presupuestoMensual == 0) {
      grande = 'Sin fecha';
      detalle =
          'Ninguna deuda tiene pago mínimo. Edítalas para ponérselo, o '
          'escribe cuánto extra puedes pagar al mes.';
    } else {
      grande = 'Sin fecha';
      detalle =
          'Pagando ${formatCOP(plan.presupuestoMensual)} al mes no terminas: '
          'mira el aviso de abajo.';
    }

    // Frente a pagar solo los mínimos (solo si todas tienen mínimo; si no,
    // "solo mínimos" no termina por falta de datos, no por los intereses).
    String? ganancia;
    final todasConMinimo = plan.orden.every(
      (p) => p.resumen.pagoMinimo != null,
    );
    final solo = plan.soloMinimos;
    if (plan.alcanza && todasConMinimo) {
      if (!solo.termina) {
        ganancia = 'Pagando solo los mínimos no terminarías nunca.';
      } else {
        final antes = solo.meses! - plan.meses!;
        final ahorro = solo.interesesTotales - plan.interesesTotales;
        final partes = [
          if (antes > 0) '$antes ${antes == 1 ? 'mes' : 'meses'} antes',
          if (ahorro > 0) '${formatCOP(ahorro)} menos en intereses',
        ];
        if (partes.isNotEmpty) {
          ganancia = '${partes.join(' y ')} que pagando solo los mínimos.';
          ganancia = ganancia[0].toUpperCase() + ganancia.substring(1);
        }
      }
    }

    final radio = BorderRadius.circular(AppSpacing.radiusTarjeta);
    return Container(
      key: const ValueKey('plan-libre'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: radio,
        border: Border.all(color: c.divisor, width: AppSpacing.borde),
      ),
      // Dos brillos tenues con los colores de la marca: vino arriba a la
      // derecha y morado abajo a la izquierda.
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.3,
            colors: [
              c.acento.withValues(alpha: 0.22),
              c.acento.withValues(alpha: 0),
            ],
            stops: const [0, 0.6],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.bottomLeft,
              radius: 1.3,
              colors: [
                c.secundario.withValues(alpha: 0.16),
                c.secundario.withValues(alpha: 0),
              ],
              stops: const [0, 0.6],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(_relleno(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextoKicker('Libre de deudas en', color: c.acento),
                const SizedBox(height: AppSpacing.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    // "abril de 2028" → "Abril de 2028"
                    grande[0].toUpperCase() + grande.substring(1),
                    style: TextStyle(
                      fontFamily: fuenteTexto,
                      fontSize: 32,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      color: plan.alcanza ? c.texto : c.alerta,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(detalle, style: _gris(context)),
                if (ganancia != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          solo.termina
                              ? Icons.trending_down
                              : Icons.info_outline,
                          size: 17,
                          color: solo.termina ? c.positivo : c.acento,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          ganancia,
                          key: const ValueKey('plan-vs-minimos'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 13,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Este mes ─────────────────────────

  /// Cuánto pagarle a cada deuda este mes (o el siguiente, si lo de este
  /// mes ya está pago). `null` si no hay nada que pagar.
  Widget? _tarjetaEsteMes(BuildContext context, PlanPago plan, DateTime hoy) {
    final theme = Theme.of(context);
    final c = context.colores;
    final proximos = plan.proximosPagos;
    if (proximos.pagos.isEmpty) return null;
    final mes = proximos.esteMes
        ? 'Este mes'
        : 'En ${formatMesAnio(DateTime(hoy.year, hoy.month + 1)).split(' de ').first}';
    final total = proximos.pagos.fold<int>(0, (s, p) => s + p.$2);

    String etiqueta(ResumenDeuda r, int pago) {
      final minimo = proximos.esteMes
          ? r.pendienteEsteMes(hoy, r.pagoMinimo)
          : (r.pagoMinimo ?? 0);
      if (minimo <= 0) return 'extra';
      return pago > minimo ? 'mínimo + extra' : 'mínimo';
    }

    return Card(
      key: const ValueKey('plan-este-mes'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(_relleno(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextoKicker('$mes paga', color: c.acento),
            if (!proximos.esteMes) ...[
              const SizedBox(height: 6),
              Text('Lo de este mes ya está pago.', style: _gris(context)),
            ],
            const SizedBox(height: AppSpacing.xs),
            for (final (r, pago) in proximos.pagos)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: c.divisor, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.deuda.acreedorNombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            etiqueta(r, pago),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11.5,
                              color: c.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      formatCOP(pago),
                      style: monoStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (proximos.pagos.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    formatCOP(total),
                    style: monoStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Controles ─────────────────────────

  /// Tarjeta grande: estrategia, extra al mes y el orden de pago.
  Widget _tarjetaControles(
    BuildContext context,
    PlanPago plan,
    PlanPago planOtra,
    DateTime hoy,
  ) {
    final theme = Theme.of(context);
    final c = context.colores;
    final cualAhorra = _cualAhorra(context, plan, planOtra);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(_relleno(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _rotulo(context, 'Estrategia'),
            const SizedBox(height: 10),
            GrupoPildoras<EstrategiaPago>(
              opciones: {for (final e in EstrategiaPago.values) e: e.nombre},
              valor: _estrategia,
              onElegir: _elegirEstrategia,
            ),
            const SizedBox(height: 10),
            Text(
              _estrategia.resumen,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                height: 1.5,
                color: c.textoSecundario,
              ),
            ),
            ?cualAhorra,
            const SizedBox(height: 26),
            _rotulo(context, 'Extra al mes'),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: TextField(
                  key: const ValueKey('plan-extra'),
                  controller: _extraCtrl,
                  style: monoStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixText: r'$ ',
                    prefixStyle: monoStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: c.textoSecundario,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CopInputFormatter(),
                  ],
                  onChanged: _cambiarExtra,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final monto in PlanPagoTab.extrasRapidos)
                  _botonExtra(context, plan, hoy, monto),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Lo que puedes pagar además de los pagos mínimos. Entre más '
              'pongas, antes terminas y menos intereses pagas.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: c.textoSecundario,
              ),
            ),
            const SizedBox(height: 26),
            _rotulo(context, 'Orden de pago'),
            const SizedBox(height: AppSpacing.xs),
            Column(
              key: const ValueKey('plan-orden'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, paso) in plan.orden.indexed)
                  _filaOrden(context, i, paso),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Cada mes pagas el mínimo de todas y lo que sobra va completo a '
              'la primera de la lista. Cuando terminas una, lo que le pagabas '
              'pasa a la siguiente. Las fechas son un estimado con las tasas '
              'de hoy.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: c.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Debajo de las píldoras: cuál de las dos estrategias cobra menos
  /// intereses y cuánto. `null` si no se pueden comparar o cuestan igual.
  Widget? _cualAhorra(BuildContext context, PlanPago plan, PlanPago otra) {
    if (!plan.alcanza || !otra.alcanza) return null;
    final diferencia = otra.interesesTotales - plan.interesesTotales;
    if (diferencia == 0) return null;
    final c = context.colores;
    final esta = diferencia > 0;
    final texto = esta
        ? 'Es la que menos intereses te cobra: ${formatCOP(diferencia)} '
              'menos que ${otra.estrategia.nombre.toLowerCase()}.'
        : '${otra.estrategia.nombre} te ahorraría ${formatCOP(-diferencia)} '
              'en intereses.';
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        key: const ValueKey('plan-cual-ahorra'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: esta ? c.positivo.withValues(alpha: 0.12) : c.relieve,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              esta ? Icons.check_circle_outline : Icons.savings_outlined,
              size: 17,
              color: esta ? c.positivo : c.acento,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                texto,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!esta)
              TextButton(
                onPressed: () => _elegirEstrategia(otra.estrategia),
                child: const Text('Cambiar'),
              ),
          ],
        ),
      ),
    );
  }

  /// Botón rápido "+$100.000" con lo que se ganaría al sumarlo al extra.
  Widget _botonExtra(
    BuildContext context,
    PlanPago plan,
    DateTime hoy,
    int monto,
  ) {
    final c = context.colores;
    final con = _simular(_estrategia, hoy, extra: _extra + monto);
    final String efecto;
    if (!con.alcanza) {
      efecto = 'aún sin fecha';
    } else if (!plan.alcanza) {
      efecto = 'terminas ${formatMesAnioCorto(con.fechaLibre!)}';
    } else {
      final antes = plan.meses! - con.meses!;
      efecto = antes <= 0
          ? 'misma fecha'
          : '$antes ${antes == 1 ? 'mes' : 'meses'} antes';
    }
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.divisor, width: AppSpacing.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('plan-extra-mas-$monto'),
        onTap: () => _ponerExtra(_extra + monto),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+${formatCOP(monto)}',
                style: monoStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              Text(
                efecto,
                style: TextStyle(
                  fontFamily: fuenteTexto,
                  fontSize: 11.5,
                  color: efecto.endsWith('antes')
                      ? c.positivo
                      : c.textoSecundario,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filaOrden(BuildContext context, int i, PasoPlan paso) {
    final theme = Theme.of(context);
    final c = context.colores;
    final pequeno = theme.textTheme.bodySmall?.copyWith(
      color: c.textoSecundario,
    );
    final r = paso.resumen;
    // En avalancha se explica por qué una deuda va antes que otra con más
    // tasa: lo que cuesta de verdad cada peso que se debe.
    final costoDistinto =
        _estrategia == EstrategiaPago.avalancha &&
        (r.costoMensualPct - r.tasaMensualPct).abs() >= 0.05;
    final String fecha;
    final String? nota;
    if (!paso.termina) {
      fecha = 'No baja';
      nota = null;
    } else {
      fecha = formatMesAnioCorto(paso.fecha!);
      nota = paso.tarde
          ? 'después del límite'
          : paso.meses == 0
          ? 'este mes'
          : 'liquidada';
    }
    final alerta = !paso.termina || paso.tarde;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.divisor, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.acentoSuave,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${i + 1}',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: fuenteTexto,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: c.acento,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.deuda.acreedorNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${formatCOP(r.saldo)} · ${etiquetaTasa(r.deuda)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: pequeno,
                ),
                if (costoDistinto)
                  Text(
                    'Te cuesta ${_porcentaje(r.costoMensualPct)} al mes de '
                    'lo que debes',
                    maxLines: 2,
                    style: pequeno?.copyWith(fontSize: 11.5, color: c.acento),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fecha,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: alerta ? c.alerta : null,
                  fontWeight: alerta ? FontWeight.w600 : null,
                ),
              ),
              if (nota != null)
                Text(
                  nota,
                  style: pequeno?.copyWith(
                    fontSize: 11,
                    color: paso.tarde ? c.alerta : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// "4,5 %", "25 %".
  String _porcentaje(double pct) {
    final redondo = (pct * 10).round() / 10;
    final texto = redondo == redondo.truncateToDouble()
        ? redondo.toStringAsFixed(0)
        : redondo.toStringAsFixed(1).replaceAll('.', ',');
    return '$texto %';
  }

  // ───────────────────────── Gráfica ─────────────────────────

  /// Cómo baja lo que se debe mes a mes, con un punto numerado donde se
  /// termina cada deuda. `null` si no hay curva que mostrar (el plan no
  /// alcanza o se termina todo en uno o dos meses).
  Widget? _tarjetaGrafica(BuildContext context, PlanPago plan) {
    if (!plan.alcanza || plan.saldoPorMes.length < 4) return null;
    final c = context.colores;
    final theme = Theme.of(context);
    final marcas = [
      for (final (i, p) in plan.orden.indexed)
        if (p.meses != null) (mes: p.meses!, numero: i + 1),
    ];
    final pequeno = theme.textTheme.bodySmall?.copyWith(
      fontSize: 11.5,
      color: c.textoSecundario,
    );
    return Card(
      key: const ValueKey('plan-grafica'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(_relleno(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextoKicker('Cómo baja tu deuda', color: c.acento),
            const SizedBox(height: 6),
            Text(
              'Lo que debes entre todas, mes a mes. Cada número es el mes '
              'en que terminas esa deuda del orden de pago.',
              style: _gris(context),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(formatCOP(plan.saldoPorMes.reduce(math.max)), style: pequeno),
            const SizedBox(height: 4),
            Semantics(
              label:
                  'Gráfica: lo que debes baja de '
                  '${formatCOP(plan.saldoPorMes.first)} hoy a cero en '
                  '${formatMesAnio(plan.fechaLibre!)}.',
              child: SizedBox(
                height: 150,
                child: CustomPaint(
                  painter: _PintorSaldo(
                    saldos: plan.saldoPorMes,
                    marcas: marcas,
                    linea: c.acento,
                    guia: c.divisor,
                    textoMarca: c.fondo,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Hoy', style: pequeno),
                const Spacer(),
                Text(formatMesAnioCorto(plan.fechaLibre!), style: pequeno),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Intereses ─────────────────────────

  /// Tarjeta de intereses: lo que cuesta este plan, lo que costaría con la
  /// otra estrategia y la diferencia.
  Widget _tarjetaIntereses(BuildContext context, PlanPago plan, PlanPago otra) {
    final theme = Theme.of(context);
    final c = context.colores;
    final comparable = plan.alcanza && otra.alcanza;
    final diferencia = comparable
        ? otra.interesesTotales - plan.interesesTotales
        : 0;
    final nombreOtra = otra.estrategia.nombre.toLowerCase();

    Widget fila(
      String nombre,
      String valor, {
      bool fuerte = false,
      Color? color,
    }) => Row(
      children: [
        Expanded(
          child: Text(
            nombre,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: fuerte ? 14.5 : 13.5,
              fontWeight: fuerte ? FontWeight.w700 : null,
              color: fuerte ? null : c.textoSecundario,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          valor,
          style: monoStyle(
            fontSize: fuerte ? 14.5 : 13.5,
            fontWeight: fuerte ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(_relleno(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fila(
              'Intereses totales',
              plan.alcanza ? formatCOP(plan.interesesTotales) : '—',
            ),
            if (comparable) ...[
              const SizedBox(height: 12),
              fila('Con $nombreOtra', formatCOP(otra.interesesTotales)),
              const SizedBox(height: 12),
              Divider(height: 1, color: c.divisor),
              const SizedBox(height: 12),
              if (diferencia > 0)
                fila(
                  'Ahorro en intereses',
                  formatCOP(diferencia),
                  fuerte: true,
                  color: c.positivo,
                )
              else if (diferencia < 0)
                fila(
                  'Pagas de más',
                  formatCOP(-diferencia),
                  fuerte: true,
                  color: c.alerta,
                )
              else
                fila('Diferencia', 'Ninguna', fuerte: true),
            ],
            const SizedBox(height: 12),
            Text(
              plan.alcanza
                  ? 'Intereses de hoy hasta terminar de pagar todo.'
                  : 'Se calcula cuando el plan alcanza para pagar todo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: c.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Curva de lo que se debe (área suave debajo) con un círculo numerado en
/// el mes en que se termina cada deuda. `saldos[0]` es hoy y `saldos[k+1]`
/// el cierre del mes k (el mes 0 es el actual).
class _PintorSaldo extends CustomPainter {
  _PintorSaldo({
    required this.saldos,
    required this.marcas,
    required this.linea,
    required this.guia,
    required this.textoMarca,
  });

  final List<int> saldos;
  final List<({int mes, int numero})> marcas;
  final Color linea;
  final Color guia;
  final Color textoMarca;

  static const _radio = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final maximo = saldos.reduce(math.max).toDouble();
    if (maximo <= 0 || saldos.length < 2) return;
    // Aire arriba para los círculos y a los lados para que no se corten.
    const arriba = _radio * 2 + 4;
    const lado = _radio + 1;
    final ancho = size.width - 2 * lado;
    final alto = size.height - arriba;
    final ultimo = saldos.length - 1;
    Offset punto(int i) => Offset(
      lado + ancho * i / ultimo,
      arriba + alto * (1 - saldos[i] / maximo),
    );

    // Línea de base.
    canvas.drawLine(
      Offset(lado, size.height),
      Offset(size.width - lado, size.height),
      Paint()
        ..color = guia
        ..strokeWidth = 1,
    );

    final curva = Path()..moveTo(punto(0).dx, punto(0).dy);
    for (var i = 1; i <= ultimo; i++) {
      curva.lineTo(punto(i).dx, punto(i).dy);
    }
    final area = Path.from(curva)
      ..lineTo(punto(ultimo).dx, size.height)
      ..lineTo(punto(0).dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [linea.withValues(alpha: 0.28), linea.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, arriba, size.width, alto)),
    );
    canvas.drawPath(
      curva,
      Paint()
        ..color = linea
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Varias deudas pueden terminar el mismo mes: sus círculos se apilan.
    final apilados = <int, int>{};
    for (final m in marcas) {
      final i = (m.mes + 1).clamp(0, ultimo);
      final base = punto(i);
      final nivel = apilados.update(i, (n) => n + 1, ifAbsent: () => 0);
      final centro = Offset(
        base.dx,
        math.max(_radio, base.dy - _radio - 4 - nivel * (_radio * 2 + 2)),
      );
      // Guía punteada del círculo a la base.
      final pincel = Paint()
        ..color = guia
        ..strokeWidth = 1;
      for (var y = centro.dy + _radio; y < size.height; y += 6) {
        canvas.drawLine(
          Offset(centro.dx, y),
          Offset(centro.dx, math.min(y + 3, size.height)),
          pincel,
        );
      }
      canvas.drawCircle(centro, _radio, Paint()..color = linea);
      final texto = TextPainter(
        text: TextSpan(
          text: '${m.numero}',
          style: TextStyle(
            fontFamily: fuenteTexto,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textoMarca,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      texto.paint(canvas, centro - Offset(texto.width / 2, texto.height / 2));
      texto.dispose();
    }
  }

  @override
  bool shouldRepaint(_PintorSaldo old) =>
      old.saldos != saldos ||
      old.marcas != marcas ||
      old.linea != linea ||
      old.guia != guia ||
      old.textoMarca != textoMarca;
}
