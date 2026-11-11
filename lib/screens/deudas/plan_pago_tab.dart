import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/deudas_calculos.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/date_format.dart';
import '../../utils/format.dart';
import 'deuda_widgets.dart';

/// Pestaña "Plan de pago": el usuario elige una estrategia (avalancha o
/// bola de nieve) y cuánto extra puede pagar al mes; la pestaña le dice en
/// qué orden pagar, cuándo queda libre de deudas y cuánto pagará de
/// intereses. Las cuentas las hace [PlanPago.simular].
class PlanPagoTab extends StatefulWidget {
  const PlanPagoTab({super.key, required this.activas, required this.margen});

  final List<ResumenDeuda> activas;
  final double margen;

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
        Widget par(Widget a, Widget b) => ancho >= 640
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: a),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: b),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  a,
                  const SizedBox(height: AppSpacing.md),
                  b,
                ],
              );

        return ListView(
          padding: EdgeInsets.fromLTRB(
            widget.margen,
            AppSpacing.sm,
            widget.margen,
            widget.margen,
          ),
          children: [
            par(_tarjetaEstrategia(context), _tarjetaLibre(context, plan)),
            const SizedBox(height: AppSpacing.md),
            par(
              _tarjetaIntereses(context, plan, planOtra),
              _tarjetaExtra(context, plan),
            ),
            const SizedBox(height: AppSpacing.md),
            _tarjetaOrden(context, plan, hoy),
          ],
        );
      },
    );
  }

  Widget _tarjeta(BuildContext context, String titulo, List<Widget> hijos) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...hijos,
          ],
        ),
      ),
    );
  }

  Widget _tarjetaEstrategia(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    return _tarjeta(context, 'Estrategia', [
      SegmentedButton<EstrategiaPago>(
        showSelectedIcon: false,
        segments: [
          for (final e in EstrategiaPago.values)
            ButtonSegment(value: e, label: Text(e.nombre)),
        ],
        selected: {_estrategia},
        onSelectionChanged: (s) => _elegirEstrategia(s.first),
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: c.acentoRelleno,
          selectedForegroundColor: c.sobreAcento,
          foregroundColor: c.texto,
          side: BorderSide(color: c.divisor, width: 1.5),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        _estrategia.resumen,
        style: theme.textTheme.bodyMedium?.copyWith(color: c.textoSecundario),
      ),
    ]);
  }

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
    return _tarjeta(context, 'Libre de deudas en', [
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          // "abril de 2028" → "Abril de 2028"
          grande[0].toUpperCase() + grande.substring(1),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: plan.alcanza ? c.positivo : c.alerta,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        detalle,
        style: theme.textTheme.bodyMedium?.copyWith(color: c.textoSecundario),
      ),
    ]);
  }

  Widget _tarjetaIntereses(BuildContext context, PlanPago plan, PlanPago otra) {
    final theme = Theme.of(context);
    final c = context.colores;
    final String comparacion;
    if (!plan.alcanza || !otra.alcanza) {
      comparacion = 'Se calcula cuando el plan alcanza para pagar todo.';
    } else {
      final diferencia = otra.interesesTotales - plan.interesesTotales;
      final nombreOtra = otra.estrategia.nombre.toLowerCase();
      if (diferencia > 0) {
        comparacion = 'Ahorras ${formatCOP(diferencia)} frente a $nombreOtra.';
      } else if (diferencia < 0) {
        comparacion =
            'Pagas ${formatCOP(-diferencia)} más que con $nombreOtra.';
      } else {
        comparacion =
            'Con tus deudas de hoy, $nombreOtra cuesta lo mismo en '
            'intereses.';
      }
    }
    return _tarjeta(context, 'Intereses totales', [
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          plan.alcanza ? formatCOP(plan.interesesTotales) : '—',
          style: monoStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        plan.alcanza
            ? 'Lo que pagarás de intereses de hoy hasta terminar. '
                  '$comparacion'
            : comparacion,
        style: theme.textTheme.bodyMedium?.copyWith(color: c.textoSecundario),
      ),
    ]);
  }

  Widget _tarjetaExtra(BuildContext context, PlanPago plan) {
    final theme = Theme.of(context);
    final c = context.colores;
    return _tarjeta(context, 'Extra al mes', [
      TextField(
        key: const ValueKey('plan-extra'),
        controller: _extraCtrl,
        decoration: const InputDecoration(
          hintText: '0',
          prefixText: r'$ ',
          isDense: true,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          CopInputFormatter(),
        ],
        onChanged: _cambiarExtra,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Lo que puedes pagar además de los pagos mínimos. Entre más pongas, '
        'antes terminas y menos intereses pagas.',
        style: theme.textTheme.bodyMedium?.copyWith(color: c.textoSecundario),
      ),
    ]);
  }

  Widget _tarjetaOrden(BuildContext context, PlanPago plan, DateTime hoy) {
    final theme = Theme.of(context);
    final c = context.colores;
    final sinMinimo = plan.orden
        .where((p) => p.resumen.pagoMinimo == null)
        .length;
    return _tarjeta(context, 'Orden de pago', [
      for (final (i, paso) in plan.orden.indexed) ...[
        if (i > 0) const Divider(height: AppSpacing.md),
        Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${i + 1}.',
                maxLines: 1,
                softWrap: false,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: c.acento,
                ),
              ),
            ),
            ImagenDeuda(tipo: paso.resumen.deuda.tipo, lado: 36),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paso.resumen.deuda.acreedorNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${etiquetaTasa(paso.resumen.deuda)} · '
                    '${formatCOP(paso.resumen.saldo)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: c.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              paso.fecha == null ? '—' : formatMesAnioCorto(paso.fecha!),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      Text(
        'Cada mes pagas el mínimo de todas y lo que sobra va completo a la '
        'primera de la lista. Cuando terminas una, lo que le pagabas pasa a '
        'la siguiente. Las fechas son un estimado con las tasas de hoy.'
        '${sinMinimo > 0 ? ' $sinMinimo ${sinMinimo == 1 ? 'deuda no tiene' : 'deudas no tienen'} pago mínimo: solo ${sinMinimo == 1 ? 'recibe' : 'reciben'} lo que sobra.' : ''}',
        style: theme.textTheme.bodySmall?.copyWith(color: c.textoSecundario),
      ),
    ]);
  }
}
