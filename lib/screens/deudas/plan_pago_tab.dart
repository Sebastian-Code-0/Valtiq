import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/deudas_calculos.dart';
import '../../services/plan_pago_preferencias.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/date_format.dart';
import '../../utils/encabezado_pantalla.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/format.dart';
import '../../utils/notificaciones.dart';
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
    this.terminadas = const [],
    this.onMarcarPagada,
    this.onEditar,
    this.onPonerCuota,
    this.onAbrirDeuda,
  });

  final List<ResumenDeuda> activas;
  final double margen;

  /// Deudas ya pagadas: de aquí sale el aviso "Terminaste X: te quedan
  /// $Y libres al mes".
  final List<ResumenDeuda> terminadas;

  /// Pasa a "Pagadas" una deuda activa que ya no debe nada.
  final ValueChanged<Deuda>? onMarcarPagada;

  /// Abre el formulario de una deuda (para ponerle el pago mínimo que le
  /// falta). Sin esto, el aviso se muestra con los botones apagados.
  final ValueChanged<Deuda>? onEditar;

  /// Guarda [cuota] como pago mínimo de la deuda (botones de cuota
  /// sugerida de los avisos). Sin esto, esos botones no se muestran.
  final Future<void> Function(Deuda deuda, int cuota)? onPonerCuota;

  /// Abre el detalle de una deuda al tocarla en el orden de pago.
  final ValueChanged<int>? onAbrirDeuda;

  /// Preferencias donde se recuerda lo elegido (solo en este dispositivo).
  static const claveEstrategia = PreferenciasPlan.claveEstrategia;
  static const claveExtra = PreferenciasPlan.claveExtra;

  /// Botones rápidos para sumar al extra del mes.
  static const extrasRapidos = [50000, 100000, 200000];

  @override
  State<PlanPagoTab> createState() => _PlanPagoTabState();
}

class _PlanPagoTabState extends State<PlanPagoTab> {
  final _extraCtrl = TextEditingController();

  /// Lo que eligió el usuario; `null` = "Automática" (Valtiq usa la
  /// recomendada).
  EstrategiaPago? _elegida;
  int _extra = 0;
  PreferenciasPlan _prefs = const PreferenciasPlan(estrategia: null, extra: 0);
  bool _verComoFunciona = false;

  @override
  void initState() {
    super.initState();
    PreferenciasPlan.restauraciones.addListener(_recargar);
    _cargar();
  }

  @override
  void didUpdateWidget(PlanPagoTab old) {
    super.didUpdateWidget(old);
    // Una deuda que se reabre vuelve a cobrar su cuota.
    final antes = {for (final r in old.activas) r.deuda.id};
    if (widget.activas.any((r) => !antes.contains(r.deuda.id))) _cargar();
  }

  @override
  void dispose() {
    PreferenciasPlan.restauraciones.removeListener(_recargar);
    _extraCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final prefs = await PreferenciasPlan.reconciliar({
      for (final r in widget.activas) r.deuda.id,
    });
    if (!mounted) return;
    setState(() => _aplicar(prefs));
  }

  /// Tras restaurar un respaldo: solo lee. Las deudas de este widget todavía
  /// pueden ser las de antes, así que aquí no se ajusta nada.
  Future<void> _recargar() async {
    final prefs = await PreferenciasPlan.leer();
    if (!mounted) return;
    setState(() => _aplicar(prefs));
  }

  void _aplicar(PreferenciasPlan prefs) {
    _prefs = prefs;
    _elegida = prefs.estrategia;
    if (prefs.extra != _extra || _extraCtrl.text.isEmpty) {
      _extra = prefs.extra;
      _extraCtrl.text = prefs.extra > 0 ? formatCOPInput(prefs.extra) : '';
    }
  }

  Future<void> _usarLiberada(CuotaLiberada c) async {
    final prefs = await PreferenciasPlan.usarLiberada(c);
    if (!mounted) return;
    setState(() => _aplicar(prefs));
    mostrarExito(context, 'Sumamos ${formatCOP(c.monto)} a tu extra al mes.');
  }

  Future<void> _descartarLiberada(CuotaLiberada c) async {
    final prefs = await PreferenciasPlan.descartarLiberada(c);
    if (!mounted) return;
    setState(() => _aplicar(prefs));
  }

  Future<void> _elegirEstrategia(EstrategiaPago? e) async {
    setState(() => _elegida = e);
    await PreferenciasPlan.guardarEstrategia(e);
  }

  Future<void> _cambiarExtra(String texto) async {
    // A medio escribir (`1,500,0`) no se lee aún: se deja el extra anterior.
    final extra = texto.trim().isEmpty ? 0 : parseCOP(texto);
    if (extra == null) return;
    setState(() => _extra = extra < 0 ? 0 : extra);
    await PreferenciasPlan.guardarExtra(_extra);
  }

  /// Pone el extra desde un botón (rápido o "Usar este extra").
  Future<void> _ponerExtra(int extra) async {
    setState(() {
      _extra = extra;
      _extraCtrl.text = extra > 0 ? formatCOPInput(extra) : '';
    });
    await PreferenciasPlan.guardarExtra(_extra, escritoPorUsuario: false);
  }

  /// Último plan calculado: buscar el extra para las fechas límite puede
  /// tardar, y la pantalla se redibuja sin que cambie nada de esto.
  PlanElegido? _planGuardado;
  List<Object?> _llavePlan = const [];

  /// Lo que daría cada botón de extra rápido con el plan guardado.
  final _vistasPrevias = <int, PlanPago>{};

  /// Lo que daría seguir pagando cada cuota liberada, con el plan guardado.
  final _previasLiberadas =
      <
        ({int deuda, int monto, int diferido, EstrategiaPago estrategia}),
        PlanPago
      >{};

  PlanElegido _elegir(DateTime hoy) {
    final llave = <Object?>[
      widget.activas,
      widget.terminadas,
      _elegida,
      _extra,
      _prefs.extraDiferido(hoy),
      hoy.year,
      hoy.month,
      hoy.day,
    ];
    final guardado = _planGuardado;
    if (guardado != null &&
        llave.length == _llavePlan.length &&
        Iterable<int>.generate(llave.length).every(
          (i) =>
              identical(llave[i], _llavePlan[i]) || llave[i] == _llavePlan[i],
        )) {
      return guardado;
    }
    _llavePlan = llave;
    _vistasPrevias.clear();
    _previasLiberadas.clear();
    return _planGuardado = PlanPago.elegir(
      deudas: widget.activas,
      elegida: _elegida,
      extraMensual: _extra,
      extraDiferido: _prefs.extraDiferido(hoy),
      terminadas: widget.terminadas,
      hoy: hoy,
    );
  }

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

    // Activas pero ya sin nada que pagar (se reabrió una pagada, o se bajó
    // el monto a lo ya pagado): no hay plan posible, hay que cerrarlas.
    if (widget.activas.every((r) => r.saldo <= 0)) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(widget.margen),
        child: _avisoEnCero(context, widget.activas),
      );
    }

    final hoy = DateTime.now();
    final elegido = _elegir(hoy);
    final plan = elegido.plan;
    final planOtra = elegido.otra;
    final avisos = _avisos(context, plan, hoy);
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
        final controles = _tarjetaControles(context, elegido, hoy);
        final libre = _tarjetaLibre(context, plan, hoy);
        final intereses = _tarjetaIntereses(
          context,
          plan,
          // Con una sola deuda las dos estrategias son lo mismo.
          plan.orden.length > 1 ? planOtra : null,
        );
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

  /// Este extra solo alcanza si se empieza a pagar este mes.
  String _avisoDesdeEsteMes(SugerenciaExtra s) => s.soloDesdeEsteMes
      ? ' Cuenta con que abones ese extra desde este mes: si empiezas el '
            'mes que viene, ya no alcanza.'
      : '';

  /// Avisos discretos (se ven como una tarjeta más, solo el ícono lleva el
  /// color de marca): deudas sin pago mínimo, deudas que no bajan, deudas
  /// que terminarían después de su fecha límite.
  List<Widget> _avisos(BuildContext context, PlanPago plan, DateTime hoy) {
    final avisos = <Widget>[];
    final enCero = [
      for (final r in widget.activas)
        if (r.saldo <= 0) r,
    ];
    if (enCero.isNotEmpty) avisos.add(_avisoEnCero(context, enCero));
    final liberada = _avisoLiberada(context, plan, hoy);
    if (liberada != null) avisos.add(liberada);
    final sinMinimo = [
      for (final p in plan.orden)
        if (p.resumen.pagoMinimo == null) p.resumen,
    ];
    if (sinMinimo.isNotEmpty) {
      avisos.add(_avisoSinMinimo(context, sinMinimo, hoy));
    }

    // Si ninguna tiene pago ni hay extra, la tarjeta grande ya lo explica.
    final noBajan = plan.presupuestoMensual == 0
        ? <PasoPlan>[]
        : plan.sinTerminar;
    if (noBajan.isNotEmpty) {
      final nombres = _lista(
        noBajan.map((p) => p.resumen.deuda.acreedorNombre),
      );
      final una = noBajan.length == 1;
      final conInteres = noBajan.any((p) => p.resumen.tieneInteres);
      final s = plan.paraTerminar;
      avisos.add(
        _aviso(
          context,
          llave: 'plan-no-baja',
          icono: Icons.trending_up,
          titulo: conInteres
              ? (una ? '$nombres no baja' : '$nombres no bajan')
              : (una ? '$nombres no termina' : '$nombres no terminan'),
          texto:
              '${conInteres ? 'Con lo que se paga al mes, el interés crece más rápido que los pagos.' : 'Con lo que se paga al mes tardaría más de 50 años.'} '
              'Puedes subir su pago mínimo'
              '${s == null ? '.' : ' o poner ${formatCOP(s.extra)} de extra al mes (terminas todo en ${formatMesAnio(s.fechaLibre)}).${_avisoDesdeEsteMes(s)}'}',
          extra: s?.extra,
          cuotas: [
            for (final p in noBajan)
              if (p.resumen.pagoMinimo != null)
                if (p.resumen.sugerirCuotas(hoy)?.minimo case final m?)
                  (p.resumen.deuda, m),
          ],
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
              '${s == null ? 'Ni con mucho extra se alcanza: habla con quien te prestó para mover la fecha.' : 'Con ${formatCOP(s.extra)} de extra al mes llegas a tiempo.${_avisoDesdeEsteMes(s)}'}',
          extra: s?.extra,
        ),
      );
    }

    // Terminan justo en el mes del límite, pero su día de pago cae después.
    for (final p in plan.orden) {
      if (p.tarde || p.meses == null || p.meses != p.mesLimite) continue;
      final antesDe = p.resumen.pagarAntesDe(hoy);
      if (antesDe == null) continue;
      avisos.add(
        _aviso(
          context,
          llave: 'plan-pagar-antes-${p.resumen.deuda.id}',
          icono: Icons.event_outlined,
          titulo:
              'Paga ${p.resumen.deuda.acreedorNombre} antes del '
              '${formatFechaLegible(antesDe)}',
          texto:
              'Tu día de pago (${p.resumen.deuda.diaPago}) cae después de tu '
              'fecha límite: ese pago tiene que salir antes.',
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
              : 'Las fechas límite de $nombres ya pasaron',
          texto: vencidas.length == 1
              ? 'El plan la sigue pagando como las demás. Si acordaste una '
                    'fecha nueva, edita la deuda para cambiarla.'
              : 'El plan las sigue pagando como las demás. Si acordaste '
                    'fechas nuevas, edita cada deuda para cambiarlas.',
        ),
      );
    }
    return avisos;
  }

  /// Deudas activas que ya no deben nada: se ofrece pasarlas a "Pagadas".
  Widget _avisoEnCero(BuildContext context, List<ResumenDeuda> deudas) {
    final nombres = _lista(deudas.map((r) => r.deuda.acreedorNombre));
    final marcar = widget.onMarcarPagada;
    return _cajaAviso(
      context,
      key: const ValueKey('plan-en-cero'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloAviso(
            context,
            Icons.check_circle_outline,
            deudas.length == 1
                ? '$nombres ya no debe nada'
                : '$nombres ya no deben nada',
          ),
          const SizedBox(height: 6),
          Text(
            deudas.length == 1
                ? 'Sigue en activas, pero su saldo es \$0.'
                : 'Siguen en activas, pero su saldo es \$0.',
            style: _gris(context),
          ),
          if (marcar != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final r in deudas)
                  OutlinedButton(
                    key: ValueKey('plan-en-cero-${r.deuda.id}'),
                    onPressed: () => marcar(r.deuda),
                    style: _estiloBoton,
                    child: Text(
                      'Pasar ${r.deuda.acreedorNombre} a pagadas',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Una deuda se acaba de terminar y su cuota quedó libre: ofrece seguir
  /// pagándola a las demás (nunca se suma sola). No sale si no adelanta
  /// nada.
  Widget? _avisoLiberada(BuildContext context, PlanPago plan, DateTime hoy) {
    for (final c in _prefs.cuotasLiberadas(widget.terminadas, hoy)) {
      // Solo con la estrategia en uso: es una vista previa. Se guarda: la
      // pantalla se redibuja sin que cambie nada de esto.
      final diferido = _prefs.extraDiferido(hoy) + c.diferidoEn(hoy);
      final con =
          _previasLiberadas[(
            deuda: c.deuda.id,
            monto: c.monto,
            diferido: diferido,
            estrategia: plan.estrategia,
          )] ??= PlanPago.simular(
            deudas: widget.activas,
            estrategia: plan.estrategia,
            extraMensual: _extra + c.monto,
            extraDiferido: diferido,
            terminadas: widget.terminadas,
            hoy: hoy,
            conSugerencias: false,
          );
      if (!con.alcanza) continue;
      if (plan.alcanza && con.meses! >= plan.meses!) continue;
      return _cajaAviso(
        context,
        key: const ValueKey('plan-liberada'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloAviso(
              context,
              Icons.celebration_outlined,
              'Terminaste ${c.deuda.acreedorNombre}',
            ),
            const SizedBox(height: 6),
            Text(
              'Te quedan ${formatCOP(c.monto)} libres al mes. '
              '${plan.alcanza ? 'Si no los sigues pagando, terminas en ${formatMesAnio(plan.fechaLibre!)}.' : 'Sin ellos el plan no alcanza a terminar.'}',
              style: _gris(context),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  key: const ValueKey('plan-liberada-usar'),
                  onPressed: () => _usarLiberada(c),
                  style: _estiloBoton,
                  child: Text(
                    'Seguir pagándolos: terminas en '
                    '${formatMesAnio(con.fechaLibre!)}',
                  ),
                ),
                TextButton(
                  key: const ValueKey('plan-liberada-no'),
                  onPressed: () => _descartarLiberada(c),
                  child: const Text('Ahora no'),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return null;
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
    List<(Deuda, SugerenciaCuota)> cuotas = const [],
  }) {
    final ponerCuota = widget.onPonerCuota;
    return _cajaAviso(
      context,
      key: ValueKey(llave),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloAviso(context, icono, titulo),
          const SizedBox(height: 6),
          Text(texto, style: _gris(context)),
          if (extra != null || (cuotas.isNotEmpty && ponerCuota != null)) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (ponerCuota != null)
                  for (final (d, s) in cuotas)
                    OutlinedButton(
                      key: ValueKey('$llave-cuota-${d.id}'),
                      onPressed: () => ponerCuota(d, s.cuota),
                      style: _estiloBoton,
                      child: Text(
                        'Subir el mínimo de ${d.acreedorNombre} a '
                        '${formatCOP(s.cuota)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                if (extra != null)
                  OutlinedButton(
                    key: ValueKey('$llave-usar'),
                    onPressed: () => _ponerExtra(extra),
                    style: _estiloBoton,
                    child: Text('Usar ${formatCOP(extra)} de extra'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Aviso de las deudas que no tienen pago mínimo. Sin ese dato el plan no
  /// sabe cuánto se les paga cada mes: solo reciben "lo que sobra", y si
  /// ninguna lo tiene, el plan no puede dar fecha.
  static final _estiloBoton = OutlinedButton.styleFrom(
    minimumSize: const Size(0, 38),
    padding: const EdgeInsets.symmetric(horizontal: 14),
  );

  Widget _avisoSinMinimo(
    BuildContext context,
    List<ResumenDeuda> faltan,
    DateTime hoy,
  ) {
    final theme = Theme.of(context);
    final una = faltan.length == 1;
    final ponerCuota = widget.onPonerCuota;
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
            'Sin ese dato el plan no sabe cuánto pagarle cada mes. Elige una '
            'de las cuotas que te sugerimos o escribe la tuya.',
            style: _gris(context),
          ),
          for (final r in faltan) ...[
            const SizedBox(height: 14),
            Text(
              r.deuda.acreedorNombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (ponerCuota != null)
                  if (r.sugerirCuotas(hoy) case final s?) ...[
                    OutlinedButton(
                      key: ValueKey('plan-sin-minimo-minima-${r.deuda.id}'),
                      onPressed: () => ponerCuota(r.deuda, s.minimo.cuota),
                      style: _estiloBoton,
                      child: Text(
                        'Mínimo ${formatCOP(s.minimo.cuota)} · '
                        '${formatMesAnioCorto(s.minimo.fecha)}',
                      ),
                    ),
                    if (s.rapido case final rapido?)
                      OutlinedButton(
                        key: ValueKey('plan-sin-minimo-rapida-${r.deuda.id}'),
                        onPressed: () => ponerCuota(r.deuda, rapido.cuota),
                        style: _estiloBoton,
                        child: Text(
                          'Más rápido ${formatCOP(rapido.cuota)} · '
                          '${formatMesAnioCorto(rapido.fecha)}',
                        ),
                      ),
                  ],
                TextButton.icon(
                  onPressed: widget.onEditar == null
                      ? null
                      : () => widget.onEditar!(r.deuda),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(
                    ponerCuota == null
                        ? 'Poner pago mínimo a ${r.deuda.acreedorNombre}'
                        : 'Otro monto',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────── Libre de deudas ─────────────────────────

  /// Tarjeta destacada: cuándo se queda libre de deudas y cuánto se gana
  /// frente a pagar solo los mínimos.
  Widget _tarjetaLibre(BuildContext context, PlanPago plan, DateTime hoy) {
    final c = context.colores;
    final String grande;
    final String detalle;
    if (plan.alcanza) {
      final meses = plan.meses!;
      grande = formatMesAnio(plan.fechaLibre!);
      // El total de un mes cualquiera puede no ser el de este mes (parte ya
      // pagada, una cuota que aún no empieza): se dicen los dos para que no
      // parezca que el plan pide más de lo que toca hoy.
      final proximos = plan.proximosPagos;
      final totalProximo = proximos.pagos.fold<int>(0, (s, p) => s + p.$2);
      final cuando = proximos.esteMes
          ? 'Este mes'
          : 'En ${formatMesAnio(DateTime(hoy.year, hoy.month + 1)).split(' de ').first}';
      final distinto =
          proximos.pagos.isNotEmpty && totalProximo != plan.presupuestoMensual;
      detalle =
          '${meses == 0 ? 'Este mismo mes' : 'En $meses ${meses == 1 ? 'mes' : 'meses'}'}, '
          'pagando ${formatCOP(plan.presupuestoMensual)} al mes entre todas.'
          '${distinto ? ' $cuando te tocan ${formatCOP(totalProximo)}: abajo ves a cuál.' : ''}';
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
      // Sin recortar al saldo de hoy: el último pago lleva el interés hasta
      // el día de pago y sigue siendo "mínimo", no extra.
      final minimo = proximos.esteMes
          ? r.faltaDelPagoEsteMes(hoy, r.deuda.cuotaMensual)
          : (r.deuda.cuotaMensual ?? 0);
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
              Text(
                plan.orden.any((p) => p.resumen.pagadoEsteMes(hoy) > 0)
                    ? 'Lo de este mes ya está pago.'
                    : 'Este mes todavía no toca pagar: tu primer pago es el '
                          'mes que viene.',
                style: _gris(context),
              ),
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
    PlanElegido elegido,
    DateTime hoy,
  ) {
    final theme = Theme.of(context);
    final c = context.colores;
    final plan = elegido.plan;
    // Con una sola deuda el orden no cambia nada: no hay qué elegir.
    final variasDeudas = plan.orden.length > 1;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(_relleno(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (variasDeudas) ...[
              _rotulo(context, 'Estrategia'),
              const SizedBox(height: 10),
              GrupoPildoras<EstrategiaPago?>(
                opciones: {
                  null: 'Automática',
                  for (final e in EstrategiaPago.values) e: e.nombre,
                },
                valor: _elegida,
                onElegir: _elegirEstrategia,
              ),
              const SizedBox(height: 10),
              Text(
                plan.estrategia.resumen,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  height: 1.5,
                  color: c.textoSecundario,
                ),
              ),
              _notaEstrategia(context, elegido),
              const SizedBox(height: 26),
            ],
            _rotulo(context, 'Extra al mes'),
            const SizedBox(height: 6),
            Text(
              'Lo que puedes pagar cada mes además del pago mínimo de cada '
              'deuda. Si no te sobra nada, déjalo en 0.',
              style: _gris(context),
            ),
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
                  inputFormatters: [CopInputFormatter()],
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
            const SizedBox(height: 26),
            _rotulo(context, 'Orden de pago'),
            const SizedBox(height: 6),
            Text(
              variasDeudas
                  ? 'El número dice a cuál va primero tu extra, no cuál '
                        'terminas antes: el mes en que terminas cada una '
                        'está a la derecha.'
                  : 'A la derecha, el mes en que la terminas.',
              key: const ValueKey('plan-orden-ayuda'),
              style: _gris(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            Column(
              key: const ValueKey('plan-orden'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, paso) in plan.orden.indexed)
                  _filaOrden(context, i, paso, plan.estrategia),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('plan-como-funciona'),
                onPressed: () =>
                    setState(() => _verComoFunciona = !_verComoFunciona),
                icon: Icon(
                  _verComoFunciona ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: const Text('¿Cómo funciona?'),
              ),
            ),
            if (_verComoFunciona)
              Text(
                'Cada mes pagas el mínimo de todas las deudas y lo que sobra '
                '(el extra) va completo a la primera de la lista. Cuando '
                'terminas una, lo que le pagabas pasa a la siguiente, así que '
                'lo que pagas al mes no baja pero cada vez rinde más. Lo que '
                'sobra va primero a las deudas vencidas y a las que tienen su '
                'fecha límite a 3 meses o menos. La cuota de cada deuda no '
                'cambia.'
                '\n\n'
                'Avalancha busca el orden con el que pagas menos intereses. '
                'Bola de nieve, la más pequeña: terminas '
                'deudas antes y eso anima. En "Automática" Valtiq elige primero '
                'la que cumple más fechas límite y después la que menos '
                'intereses te cobra; si cuestan casi lo mismo, elige bola de '
                'nieve.\n\n'
                'Las fechas son un estimado con las tasas de hoy y cuentan el '
                'pago de este mes si todavía no lo has hecho.',
                style: _gris(context),
              ),
          ],
        ),
      ),
    );
  }

  /// Debajo de las píldoras: qué eligió Valtiq y por qué (en
  /// "Automática"), o si la elegida a mano es la recomendada; si no lo es,
  /// cuánto se ahorraría con la recomendada y un botón para volver a
  /// "Automática".
  Widget _notaEstrategia(BuildContext context, PlanElegido e) {
    final c = context.colores;
    final plan = e.plan;
    final otra = e.otra;
    final reco = e.recomendada;
    final nombreOtra = otra.estrategia.nombre.toLowerCase();
    final ahorro = (otra.interesesTotales - plan.interesesTotales).abs();
    final comparables = plan.alcanza && otra.alcanza;
    final String texto;
    final bool bien;
    if (e.automatica) {
      bien = true;
      final nombre = plan.estrategia.nombre.toLowerCase();
      if (!comparables) {
        texto = plan.alcanza
            ? 'Valtiq eligió $nombre: con ella sí terminas de pagar.'
            : 'Valtiq usa $nombre mientras el plan no alcance para terminar.';
      } else if (e.difierenEnFechas) {
        texto = 'Valtiq eligió $nombre: es la que cumple más fechas límite.';
      } else if (e.casiIgual) {
        texto =
            'Valtiq eligió $nombre: las dos te cobran casi lo mismo y así '
            'terminas deudas más pronto.';
      } else {
        texto =
            'Valtiq eligió $nombre: te cobra ${formatCOP(ahorro)} menos en '
            'intereses que $nombreOtra.';
      }
    } else if (!plan.alcanza && !otra.alcanza) {
      bien = true;
      texto = 'Con ninguna de las dos terminas todavía: mira el aviso.';
    } else if (plan.estrategia == reco) {
      bien = true;
      texto = 'Es la que Valtiq recomienda para tus deudas.';
    } else {
      bien = false;
      texto = !comparables
          ? 'Con ${reco.nombre.toLowerCase()} sí terminas de pagar.'
          : e.difierenEnFechas
          ? '${reco.nombre} cumple más fechas límite.'
          : e.casiIgual
          ? '${reco.nombre} cuesta casi lo mismo y terminas deudas más '
                'pronto: es la que Valtiq recomienda.'
          : '${reco.nombre} te ahorraría ${formatCOP(ahorro)} en intereses.';
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        key: const ValueKey('plan-cual-ahorra'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bien ? c.positivo.withValues(alpha: 0.12) : c.relieve,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              e.automatica
                  ? Icons.auto_awesome_outlined
                  : bien
                  ? Icons.check_circle_outline
                  : Icons.savings_outlined,
              size: 17,
              color: bien ? c.positivo : c.acento,
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
            if (!bien)
              TextButton(
                key: const ValueKey('plan-usar-automatica'),
                onPressed: () => _elegirEstrategia(null),
                child: const Text('Que elija Valtiq'),
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
    // Lo mismo que pasa al tocarlo: en "Automática" Valtiq puede cambiar de
    // estrategia con más extra. Se guarda junto al plan, porque la pantalla
    // se redibuja sin que cambie nada de esto.
    final con = _vistasPrevias[monto] ??= PlanPago.elegir(
      deudas: widget.activas,
      elegida: _elegida,
      extraMensual: _extra + monto,
      extraDiferido: _prefs.extraDiferido(hoy),
      terminadas: widget.terminadas,
      hoy: hoy,
      conSugerencias: false,
    ).plan;
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

  Widget _filaOrden(
    BuildContext context,
    int i,
    PasoPlan paso,
    EstrategiaPago estrategia,
  ) {
    final theme = Theme.of(context);
    final c = context.colores;
    final pequeno = theme.textTheme.bodySmall?.copyWith(
      color: c.textoSecundario,
    );
    final r = paso.resumen;
    // En avalancha se explica por qué una deuda va antes que otra con más
    // tasa: lo que cuesta de verdad cada peso que se debe.
    final costoDistinto =
        estrategia == EstrategiaPago.avalancha &&
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
          : paso.priorizadaPorLimite
          ? 'primero por su límite'
          : paso.meses == 0
          ? 'este mes'
          : 'liquidada';
    }
    final alerta = !paso.termina || paso.tarde;
    final fila = Container(
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
    final abrir = widget.onAbrirDeuda;
    if (abrir == null) return fila;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: ValueKey('plan-orden-${r.deuda.id}'),
        onTap: () => abrir(r.deuda.id),
        child: fila,
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

  /// Cuánto se debe mes a mes, con un punto y el nombre de la deuda en el
  /// mes en que se termina cada una. `null` si no hay curva que mostrar (el
  /// plan no alcanza o se termina todo en uno o dos meses).
  Widget? _tarjetaGrafica(BuildContext context, PlanPago plan) {
    if (!plan.alcanza || plan.saldoPorMes.length < 4) return null;
    final c = context.colores;
    final theme = Theme.of(context);
    final marcas = [
      for (final p in plan.orden)
        if (p.meses != null)
          (mes: p.meses!, nombre: p.resumen.deuda.acreedorNombre),
    ];
    final pequeno = theme.textTheme.bodySmall?.copyWith(
      fontSize: 11.5,
      color: c.textoSecundario,
    );
    final fuerte = monoStyle(fontSize: 12.5, fontWeight: FontWeight.w600);
    final fin = formatMesAnioCorto(plan.fechaLibre!);
    return Card(
      key: const ValueKey('plan-grafica'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(_relleno(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextoKicker('Cuánto debes mes a mes', color: c.acento),
            const SizedBox(height: 6),
            Text(
              'Cada punto es el mes en que terminas esa deuda.',
              style: _gris(context),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label:
                  'Gráfica: lo que debes baja de '
                  '${formatCOP(plan.saldoPorMes.first)} hoy a cero en '
                  '${formatMesAnio(plan.fechaLibre!)}. '
                  '${[for (final p in plan.orden)
                    if (p.fecha != null) '${p.resumen.deuda.acreedorNombre} termina en ${formatMesAnio(p.fecha!)}'].join('; ')}.',
              child: SizedBox(
                height: 170,
                child: CustomPaint(
                  painter: _PintorSaldo(
                    saldos: plan.saldoPorMes,
                    marcas: marcas,
                    linea: c.acento,
                    guia: c.divisor,
                    texto: c.texto,
                    fondo: c.superficie,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    key: const ValueKey('plan-grafica-hoy'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hoy', style: pequeno),
                      Text(formatCOP(plan.saldoPorMes.first), style: fuerte),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  key: const ValueKey('plan-grafica-fin'),
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(fin, style: pequeno),
                    Text(
                      formatCOP(0),
                      style: fuerte.copyWith(color: c.positivo),
                    ),
                  ],
                ),
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
  /// [otra] es `null` con una sola deuda (no hay con qué comparar).
  Widget _tarjetaIntereses(
    BuildContext context,
    PlanPago plan,
    PlanPago? otra,
  ) {
    final theme = Theme.of(context);
    final c = context.colores;
    final comparable = otra != null && plan.alcanza && otra.alcanza;
    final diferencia = comparable
        ? otra.interesesTotales - plan.interesesTotales
        : 0;
    final nombreOtra = otra?.estrategia.nombre.toLowerCase() ?? '';

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

/// Curva de lo que se debe (área suave debajo) con un punto y el nombre de
/// la deuda en el mes en que se termina cada una. `saldos[0]` es hoy y
/// `saldos[k+1]` el cierre del mes k (el mes 0 es el actual).
class _PintorSaldo extends CustomPainter {
  _PintorSaldo({
    required this.saldos,
    required this.marcas,
    required this.linea,
    required this.guia,
    required this.texto,
    required this.fondo,
  });

  final List<int> saldos;
  final List<({int mes, String nombre})> marcas;
  final Color linea;
  final Color guia;
  final Color texto;
  final Color fondo;

  static const _radio = 4.5;
  static const _anchoEtiqueta = 170.0;

  @override
  void paint(Canvas canvas, Size size) {
    final maximo = saldos.reduce(math.max).toDouble();
    if (maximo <= 0 || saldos.length < 2) return;
    // Aire arriba y a los lados para que puntos y nombres no se corten.
    const arriba = 22.0;
    const lado = _radio + 2;
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

    // Primero todos los puntos, luego los nombres encima de la curva.
    final ordenadas = [...marcas]..sort((a, b) => a.mes.compareTo(b.mes));
    final puntos = [
      for (final m in ordenadas) punto((m.mes + 1).clamp(0, ultimo)),
    ];
    for (final p in puntos) {
      canvas.drawCircle(p, _radio + 1.5, Paint()..color = fondo);
      canvas.drawCircle(p, _radio, Paint()..color = linea);
    }

    // Cada nombre va arriba a la derecha de su punto (a la izquierda si no
    // cabe). Si choca con otro ya puesto, se corre hacia arriba o hacia
    // abajo hasta encontrar un hueco; si no hay, se pone donde iba.
    final puestos = <Rect>[];
    for (final (k, m) in ordenadas.indexed) {
      final p = puntos[k];
      final pintor = TextPainter(
        text: TextSpan(
          text: m.nombre,
          style: TextStyle(
            fontFamily: fuenteTexto,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: texto,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: math.min(_anchoEtiqueta, size.width * 0.45));
      final w = pintor.width + 8;
      final h = pintor.height + 3;
      final aLaDerecha = p.dx + 6 + w <= size.width;
      final x = aLaDerecha ? p.dx + 6 : math.max(0.0, p.dx - 6 - w);
      final yBase = p.dy - 4 - h;
      Rect enY(double y) => Rect.fromLTWH(x, y, w, h);
      bool libre(Rect r) =>
          r.top >= 0 &&
          r.bottom <= size.height &&
          !puestos.any((o) => o.inflate(1).overlaps(r));
      var rect = enY(yBase.clamp(0, size.height - h));
      if (!libre(rect)) {
        for (var paso = 1; paso <= 8; paso++) {
          final arribaR = enY(yBase - paso * (h + 2));
          if (libre(arribaR)) {
            rect = arribaR;
            break;
          }
          final abajoR = enY(yBase + paso * (h + 2));
          if (libre(abajoR)) {
            rect = abajoR;
            break;
          }
        }
      }
      puestos.add(rect);
      // Guía del punto al nombre cuando quedó lejos.
      final borde = Offset(
        aLaDerecha ? rect.left : rect.right,
        rect.center.dy.clamp(rect.top, rect.bottom),
      );
      if ((borde - p).distance > 14) {
        canvas.drawLine(
          p,
          borde,
          Paint()
            ..color = guia
            ..strokeWidth = 1,
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = fondo.withValues(alpha: 0.92),
      );
      pintor.paint(canvas, rect.topLeft + const Offset(4, 1.5));
      pintor.dispose();
    }
  }

  @override
  bool shouldRepaint(_PintorSaldo old) =>
      old.saldos != saldos ||
      old.marcas != marcas ||
      old.linea != linea ||
      old.guia != guia ||
      old.texto != texto ||
      old.fondo != fondo;
}
