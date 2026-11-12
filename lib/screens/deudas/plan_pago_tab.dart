import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../db/database.dart';
import '../../services/deudas_calculos.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/date_format.dart';
import '../../utils/encabezado_pantalla.dart';
import '../../utils/format.dart';
import '../../utils/selector_pildoras.dart';
import 'deuda_widgets.dart';

/// Pestaña "Plan de pago": el usuario elige una estrategia (avalancha o
/// bola de nieve) y cuánto extra puede pagar al mes; la pestaña le dice en
/// qué orden pagar, cuándo queda libre de deudas y cuánto pagará de
/// intereses. Las cuentas las hace [PlanPago.simular].
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

  Future<void> _cambiarExtra(String texto) async {
    final extra = parseCOP(texto) ?? 0;
    setState(() => _extra = extra < 0 ? 0 : extra);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PlanPagoTab.claveExtra, _extra);
  }

  PlanPago _simular(EstrategiaPago e, DateTime hoy) => PlanPago.simular(
    deudas: widget.activas,
    estrategia: e,
    extraMensual: _extra,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth - 2 * widget.margen;
        final controles = _tarjetaControles(context, plan, hoy);
        final resultado = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _tarjetaLibre(context, plan),
            const SizedBox(height: 12),
            _tarjetaIntereses(context, plan, planOtra),
          ],
        );
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            widget.margen,
            AppSpacing.sm,
            widget.margen,
            widget.margen,
          ),
          // En PC: a la izquierda lo que se elige (estrategia, extra y el
          // orden que resulta) y a la derecha la respuesta (cuándo se queda
          // libre y cuánto cuesta). En celular, uno debajo del otro.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (plan.orden.any((p) => p.resumen.pagoMinimo == null)) ...[
                _avisoSinMinimo(context, plan),
                const SizedBox(height: 12),
              ],
              if (ancho >= 720)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: controles),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 2, child: resultado),
                  ],
                )
              else ...[
                controles,
                const SizedBox(height: 12),
                resultado,
              ],
            ],
          ),
        );
      },
    );
  }

  /// Aviso de las deudas que no tienen pago mínimo. Sin ese dato el plan no
  /// sabe cuánto se les paga cada mes: solo reciben "lo que sobra", y si
  /// ninguna lo tiene, el plan no puede dar fecha.
  Widget _avisoSinMinimo(BuildContext context, PlanPago plan) {
    final theme = Theme.of(context);
    final c = context.colores;
    final faltan = [
      for (final p in plan.orden)
        if (p.resumen.pagoMinimo == null) p.resumen.deuda,
    ];
    final una = faltan.length == 1;
    return Container(
      key: const ValueKey('plan-sin-minimo'),
      padding: EdgeInsets.all(_relleno(context) - 6),
      decoration: BoxDecoration(
        color: c.alerta.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusTarjeta),
        border: Border.all(color: c.alerta.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: c.alerta),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  una
                      ? 'A 1 deuda le falta el pago mínimo'
                      : 'A ${faltan.length} deudas les falta el pago mínimo',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'El pago mínimo es lo que pagas cada mes por esa deuda. Sin ese '
            'dato el plan no puede calcular bien cuándo terminas: '
            '${una ? 'esa deuda' : 'esas deudas'} solo '
            '${una ? 'recibe' : 'reciben'} lo que sobra de las demás.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              height: 1.45,
              color: c.textoSecundario,
            ),
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

  /// Tarjeta grande: estrategia, extra al mes y el orden de pago.
  Widget _tarjetaControles(BuildContext context, PlanPago plan, DateTime hoy) {
    final theme = Theme.of(context);
    final c = context.colores;
    final sinMinimo = plan.orden
        .where((p) => p.resumen.pagoMinimo == null)
        .length;
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
            for (final (i, paso) in plan.orden.indexed)
              _filaOrden(context, i, paso),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Cada mes pagas el mínimo de todas y lo que sobra va completo a '
              'la primera de la lista. Cuando terminas una, lo que le pagabas '
              'pasa a la siguiente. Las fechas son un estimado con las tasas '
              'de hoy.'
              '${sinMinimo > 0 ? ' $sinMinimo ${sinMinimo == 1 ? 'deuda no tiene' : 'deudas no tienen'} pago mínimo: solo ${sinMinimo == 1 ? 'recibe' : 'reciben'} lo que sobra.' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: c.textoSecundario,
              ),
            ),
          ],
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
                  paso.resumen.deuda.acreedorNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${formatCOP(paso.resumen.saldo)} · '
                  '${etiquetaTasa(paso.resumen.deuda)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: pequeno,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                paso.fecha == null ? '—' : formatMesAnioCorto(paso.fecha!),
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
              if (paso.fecha != null)
                Text('liquidada', style: pequeno?.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  /// Tarjeta destacada: cuándo se queda libre de deudas.
  Widget _tarjetaLibre(BuildContext context, PlanPago plan) {
    final theme = Theme.of(context);
    final c = context.colores;
    final String grande;
    final String detalle;
    if (plan.alcanza) {
      final meses = plan.meses!;
      grande = formatMesAnio(plan.fechaLibre!);
      detalle =
          'En $meses ${meses == 1 ? 'mes' : 'meses'}, pagando '
          '${formatCOP(plan.presupuestoMensual)} al mes entre todas.';
    } else if (plan.presupuestoMensual == 0) {
      grande = 'Sin fecha';
      detalle =
          'Ninguna deuda tiene pago mínimo. Edítalas para ponérselo, o '
          'escribe cuánto extra puedes pagar al mes.';
    } else {
      grande = 'Sin fecha';
      detalle =
          'Pagando ${formatCOP(plan.presupuestoMensual)} al mes los '
          'intereses crecen más rápido que los pagos. Prueba con un extra '
          'al mes.';
    }
    final radio = BorderRadius.circular(AppSpacing.radiusTarjeta);
    return Container(
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
                Text(
                  detalle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    height: 1.45,
                    color: c.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
