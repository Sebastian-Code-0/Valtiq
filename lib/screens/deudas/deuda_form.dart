import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../services/deudas_calculos.dart';
import '../../services/interes_calculator.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/campo_nombre_sugerencias.dart';
import '../../utils/date_format.dart';
import '../../utils/dialogo_meses.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/formulario_guardado_mixin.dart';
import '../../utils/notificaciones.dart';
import '../../utils/selector_pildoras.dart';
import '../../utils/tasa_input.dart';
import '../../utils/tipo_deuda.dart';

class DeudaForm extends StatefulWidget {
  const DeudaForm({
    super.key,
    required this.db,
    this.deuda,
    this.irAPagoMinimo = false,
  });

  final AppDatabase db;
  final Deuda? deuda;

  /// Al abrir, bajar hasta "Pago mínimo al mes", resaltarlo un momento y
  /// dejar el cursor ahí. Lo usa el aviso del Plan de pago.
  final bool irAPagoMinimo;

  @override
  State<DeudaForm> createState() => _DeudaFormState();
}

class _DeudaFormState extends State<DeudaForm>
    with FormularioGuardadoMixin<DeudaForm> {
  late final TextEditingController _acreedorCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _diaPagoCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _tasaCtrl;
  late final TextEditingController _cuotaCtrl;
  late final TextEditingController _notasCtrl;

  final _clavePagoMinimo = GlobalKey();
  final _focoPagoMinimo = FocusNode();
  bool _resaltarPagoMinimo = false;

  /// El usuario ya eligió a mano sobre qué se calcula el interés.
  late bool _amortizacionElegida;
  final List<Timer> _timers = [];

  late String _tipo;
  late String _tipoInteres;
  late String _modalidadCalculo;
  late String _tipoAmortizacion;
  late DateTime _fechaPrestamo;
  DateTime? _fechaLimite;

  /// Pagos ya registrados (al editar): sin ellos las sugerencias de pago
  /// mínimo se calcularían sobre lo prestado y no sobre lo que se debe hoy.
  List<AbonoInteres> _abonos = const [];

  @override
  void initState() {
    super.initState();
    final d = widget.deuda;
    _acreedorCtrl = TextEditingController(text: d?.acreedorNombre ?? '');
    _descripcionCtrl = TextEditingController(text: d?.descripcion ?? '');
    _diaPagoCtrl = TextEditingController(text: d?.diaPago?.toString() ?? '');
    // Una deuda nueva arranca como "persona" (lo más común al anotar a mano).
    _tipo = d?.tipo ?? TipoDeuda.persona.clave;
    _montoCtrl = TextEditingController(
      text: d != null ? formatCOPInput(d.montoOriginal) : '',
    );
    // Sin "0" inicial: así no hay que borrarlo antes de escribir la tasa.
    _tasaCtrl = TextEditingController(text: tasaParaCampo(d?.tasaInteres ?? 0));
    _cuotaCtrl = TextEditingController(
      text: d?.cuotaMensual != null ? formatCOPInput(d!.cuotaMensual!) : '',
    );
    _notasCtrl = TextEditingController(text: d?.notas ?? '');
    _tipoInteres = d?.tipoInteres ?? 'ninguno';
    _modalidadCalculo = d?.modalidadCalculo ?? 'simple';
    _tipoAmortizacion = d?.tipoAmortizacion ?? 'saldo_original';
    // Al editar se respeta lo guardado; al crear, el tipo propone el valor.
    // Una deuda sin tasa nunca ha elegido esto de verdad.
    _amortizacionElegida = d != null && d.tasaInteres > 0;
    _fechaPrestamo = d != null
        ? fechaCivilGuardada(d.fechaPrestamo)
        : DateTime.now();
    _fechaLimite = d?.fechaLimite == null
        ? null
        : fechaCivilGuardada(d!.fechaLimite!);
    // Las sugerencias y el aviso del pago mínimo se recalculan al escribir.
    for (final ctrl in [_montoCtrl, _tasaCtrl, _cuotaCtrl, _diaPagoCtrl]) {
      ctrl.addListener(_refrescar);
    }
    if (d != null) _cargarAbonos(d.id);
    if (widget.irAPagoMinimo) {
      // Espera a que termine la animación de entrada de la página.
      _timers.add(Timer(const Duration(milliseconds: 350), _irAPagoMinimo));
    }
  }

  /// Banco y tarjeta cobran sobre lo que falta por pagar. En una deuda
  /// nueva se propone eso, salvo que el usuario ya haya elegido.
  void _cambiarTipo(String tipo) {
    setState(() {
      _tipo = tipo;
      if (!_amortizacionElegida) {
        _tipoAmortizacion =
            tipo == TipoDeuda.banco.clave || tipo == TipoDeuda.tarjeta.clave
            ? 'saldo_insoluto'
            : 'saldo_original';
      }
    });
  }

  void _refrescar() {
    if (mounted) setState(() {});
  }

  Future<void> _cargarAbonos(int deudaId) async {
    final pagos = await widget.db.pagosDeudaDao.getPagosDeDeuda(deudaId);
    if (!mounted) return;
    setState(() {
      _abonos = [
        for (final p in pagos)
          AbonoInteres(fecha: p.fechaPago, monto: p.montoAbonado),
      ];
    });
  }

  /// La deuda tal como está escrita en el formulario ahora mismo (con sus
  /// pagos, si se está editando), para calcular sugerencias. `null` si
  /// falta el monto o la tasa no tiene tipo (mensual/anual).
  ResumenDeuda? _resumenFormulario() {
    final monto = parseCOP(_montoCtrl.text);
    if (monto == null || monto <= 0 || _faltaTipoInteres) return null;
    final tasa = parseTasa(_tasaCtrl.text);
    final conInteres = tasa > 0;
    final ahora = DateTime.now();
    final d = widget.deuda;
    final deuda = Deuda(
      id: d?.id ?? 0,
      acreedorNombre: _acreedorCtrl.text,
      descripcion: '',
      tipo: _tipo,
      diaPago: int.tryParse(_diaPagoCtrl.text.trim()),
      montoOriginal: monto,
      tasaInteres: tasa,
      tipoInteres: conInteres ? _tipoInteres : 'ninguno',
      modalidadCalculo: conInteres ? _modalidadCalculo : 'simple',
      tipoAmortizacion: conInteres ? _tipoAmortizacion : 'saldo_original',
      fechaPrestamo: normalizarFechaCivil(_fechaPrestamo),
      fechaLimite: _fechaLimite == null
          ? null
          : normalizarFechaCivil(_fechaLimite!),
      cuotaMensual: parseCOP(_cuotaCtrl.text),
      notas: '',
      estado: d?.estado ?? 'activa',
      fechaPagoReal: d?.fechaPagoReal,
      creadoEn: d?.creadoEn ?? ahora,
      actualizadoEn: ahora,
    );
    return ResumenDeuda.calcular(deuda, _abonos, hoy: ahora);
  }

  void _ponerCuota(int cuota) {
    final texto = formatCOPInput(cuota);
    _cuotaCtrl.value = TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }

  Future<void> _irAPagoMinimo() async {
    final destino = _clavePagoMinimo.currentContext;
    if (!mounted || destino == null) return;
    await Scrollable.ensureVisible(
      destino,
      alignment: 0.35,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
    if (!mounted) return;
    setState(() => _resaltarPagoMinimo = true);
    _focoPagoMinimo.requestFocus();
    _timers.add(
      Timer(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _resaltarPagoMinimo = false);
      }),
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _focoPagoMinimo.dispose();
    _acreedorCtrl.dispose();
    _descripcionCtrl.dispose();
    _diaPagoCtrl.dispose();
    _montoCtrl.dispose();
    _tasaCtrl.dispose();
    _cuotaCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  bool get _tieneInteres => parseTasa(_tasaCtrl.text) > 0;

  /// Hay tasa pero falta decir si es mensual o anual. Sin eso el interés no
  /// se calcula (quedaría guardada como "sin interés" sin que se note).
  bool get _faltaTipoInteres => _tieneInteres && _tipoInteres == 'ninguno';

  /// Se enciende al intentar guardar sin elegir el tipo de interés.
  bool _avisarTipoInteres = false;

  Future<void> _seleccionarFechaPrestamo() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fechaPrestamo,
      // Un respaldo puede traer fechas anteriores a 2000.
      firstDate: _fechaPrestamo.year < 2000 ? _inicioDia : DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'CO'),
    );
    if (f != null) setState(() => _fechaPrestamo = f);
  }

  DateTime get _inicioDia =>
      DateTime(_fechaPrestamo.year, _fechaPrestamo.month, _fechaPrestamo.day);

  /// La fecha límite no puede ser anterior a la fecha en que empezó.
  bool get _limiteAntesDeInicio =>
      _fechaLimite != null &&
      DateTime(
        _fechaLimite!.year,
        _fechaLimite!.month,
        _fechaLimite!.day,
      ).isBefore(_inicioDia);

  Future<void> _seleccionarFechaLimite() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fechaLimite != null && !_fechaLimite!.isBefore(_inicioDia)
          ? _fechaLimite!
          : _inicioDia,
      firstDate: _inicioDia,
      lastDate: DateTime(2100),
      locale: const Locale('es', 'CO'),
    );
    if (f != null) setState(() => _fechaLimite = f);
  }

  /// Calculadora del campo: el usuario dice en cuántos meses quiere
  /// terminar y se calcula la cuota con lo que debe HOY (no con lo que le
  /// prestaron) y con el mismo motor de intereses de toda la app (respeta
  /// interés sobre lo que falta o sobre lo prestado). Sirve también para
  /// deudas sin interés.
  Future<void> _calcularCuotaSugerida() async {
    final monto = parseCOP(_montoCtrl.text);
    if (monto == null || monto <= 0) {
      mostrarAlerta(context, 'Ingresa primero el monto original.');
      return;
    }
    if (_faltaTipoInteres) {
      mostrarAlerta(context, 'Elige primero si la tasa es mensual o anual.');
      return;
    }
    final numeroCuotas = await showDialog<int>(
      context: context,
      builder: (_) => const DialogoMeses(),
    );
    if (numeroCuotas == null || numeroCuotas <= 0 || !mounted) return;
    final r = _resumenFormulario();
    final hoy = DateTime.now();
    if (widget.deuda != null && widget.deuda!.estado != 'activa') {
      mostrarInfo(context, 'Esta deuda ya está pagada.');
      return;
    }
    final calculada = r?.cuotaParaPagos(numeroCuotas, hoy);
    if (r == null || calculada == null) {
      mostrarInfo(context, 'Esta deuda ya no tiene saldo por pagar.');
      return;
    }
    final cuota = calculada.cuota;
    _ponerCuota(cuota);
    final fin = r.liquidacionCon(cuota, hoy).fecha;
    final cuando = fin == null
        ? 'en $numeroCuotas meses'
        : 'en ${formatMesAnio(fin)}';
    // Va debajo del campo y no en un aviso flotante: el aviso tapaba
    // "Guardar deuda" y se perdía el toque.
    setState(() {
      _firmaCalculo = _firmaFormulario();
      _textoCuotaCalculada = calculada.porLimite
          ? 'Tu fecha límite llega antes de $numeroCuotas meses: pagando '
                '${formatCOP(cuota)} al mes terminas $cuando.'
          : 'Pagando ${formatCOP(cuota)} al mes terminas $cuando.';
    });
  }

  String? _firmaCalculo;
  String? _textoCuotaCalculada;

  /// Todo lo que entra en el cálculo de la cuota, más la cuota misma.
  String _firmaFormulario() => [
    _montoCtrl.text,
    _tasaCtrl.text,
    _cuotaCtrl.text,
    _diaPagoCtrl.text,
    _tipo,
    _tipoInteres,
    _modalidadCalculo,
    _tipoAmortizacion,
    _fechaPrestamo,
    _fechaLimite,
  ].join('|');

  /// El resultado de la calculadora, mientras siga siendo cierto.
  Widget? _resultadoCalculadora(BuildContext context) {
    final texto = _textoCuotaCalculada;
    if (texto == null) return null;
    // Cambió algo de lo que se usó para calcularla: ya no es cierto.
    if (_firmaFormulario() != _firmaCalculo) {
      _textoCuotaCalculada = null;
      return null;
    }
    return Padding(
      key: const ValueKey('cuota-calculada'),
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Semantics(
        liveRegion: true,
        child: Text(
          texto,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12.5,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: context.colores.positivo,
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    final camposOk = formKey.currentState!.validate();
    if (_faltaTipoInteres) {
      setState(() => _avisarTipoInteres = true);
      mostrarAlerta(context, '$errorTipoInteres.');
      return;
    }
    if (!camposOk) return;
    if (_limiteAntesDeInicio) {
      mostrarAlerta(
        context,
        'La fecha límite no puede ser anterior a la fecha en que empezó.',
      );
      return;
    }
    setState(() => guardando = true);

    final monto = parseCOP(_montoCtrl.text);
    if (monto == null) {
      setState(() => guardando = false);
      if (mounted) {
        mostrarAlerta(context, 'Monto inválido. El máximo es $textoMaxMonto.');
      }
      return;
    }
    final tasa = parseTasa(_tasaCtrl.text);
    final tipo = tasa > 0 ? _tipoInteres : 'ninguno';
    final modalidad = tasa > 0 ? _modalidadCalculo : 'simple';
    final amortizacion = tasa > 0 ? _tipoAmortizacion : 'saldo_original';
    final cuotaText = _cuotaCtrl.text.trim();
    // Un pago mínimo de $0 es lo mismo que no tener: se guarda vacío.
    final leida = cuotaText.isEmpty ? null : parseCOP(cuotaText);
    final cuota = leida == null || leida <= 0 ? null : leida;
    final notas = _notasCtrl.text.trim();
    final acreedor = _acreedorCtrl.text.trim();
    final descripcion = _descripcionCtrl.text.trim();
    final diaPago = int.tryParse(_diaPagoCtrl.text.trim());

    final dao = widget.db.deudasDao;
    final fechaPrestamo = normalizarFechaCivil(_fechaPrestamo);
    final fechaLimite = _fechaLimite == null
        ? null
        : normalizarFechaCivil(_fechaLimite!);
    await ejecutarGuardado(() async {
      if (widget.deuda == null) {
        await dao.insertDeuda(
          DeudasCompanion.insert(
            acreedorNombre: acreedor,
            descripcion: Value(descripcion),
            tipo: Value(_tipo),
            diaPago: Value(diaPago),
            montoOriginal: monto,
            tasaInteres: Value(tasa),
            tipoInteres: Value(tipo),
            modalidadCalculo: Value(modalidad),
            tipoAmortizacion: Value(amortizacion),
            fechaPrestamo: fechaPrestamo,
            fechaLimite: Value(fechaLimite),
            cuotaMensual: Value(cuota),
            notas: Value(notas),
          ),
        );
      } else {
        await dao.updateDeuda(
          widget.deuda!.copyWith(
            acreedorNombre: acreedor,
            descripcion: descripcion,
            tipo: _tipo,
            diaPago: Value(diaPago),
            montoOriginal: monto,
            tasaInteres: tasa,
            tipoInteres: tipo,
            modalidadCalculo: modalidad,
            tipoAmortizacion: amortizacion,
            fechaPrestamo: fechaPrestamo,
            fechaLimite: Value(fechaLimite),
            cuotaMensual: Value(cuota),
            notas: notas,
            actualizadoEn: DateTime.now(),
          ),
        );
        // Si con el monto nuevo ya no debe nada, pasa a pagadas: una deuda
        // activa en $0 no tendría nada que hacer en el plan.
        final guardada = await dao.getDeudaById(widget.deuda!.id);
        final pagos = await widget.db.pagosDeudaDao.getPagosDeDeuda(
          widget.deuda!.id,
        );
        final abonos = [
          for (final p in pagos)
            AbonoInteres(fecha: p.fechaPago, monto: p.montoAbonado),
        ];
        if (guardada != null && guardada.estado == 'pagada') {
          // Estaba liquidada y con el monto nuevo vuelve a deber: se reabre.
          final antes = ResumenDeuda.calcular(
            widget.deuda!,
            abonos,
            hoy: DateTime.now(),
          );
          final ahora = ResumenDeuda.calcular(
            guardada,
            abonos,
            hoy: DateTime.now(),
          );
          if (antes.saldo <= 1 && ahora.saldo > 1) {
            await dao.marcarComoActiva(guardada.id);
            final activa = ResumenDeuda.calcular(
              guardada.copyWith(
                estado: 'activa',
                fechaPagoReal: const Value(null),
              ),
              abonos,
              hoy: DateTime.now(),
            );
            if (mounted) {
              mostrarInfo(
                context,
                'Con ese monto todavía debes ${formatCOP(activa.saldo)}: la '
                'deuda volvió a activas.',
              );
            }
          }
        }
        if (guardada != null && guardada.estado == 'activa') {
          final r = ResumenDeuda.calcular(
            guardada,
            abonos,
            hoy: DateTime.now(),
          );
          if (r.saldo <= 0) {
            // Igual que al registrar un pago: si ya quedaba en cero con el
            // último pago, se terminó ese día, no hoy.
            var fin = normalizarFechaCivil(DateTime.now());
            if (pagos.isNotEmpty) {
              final ultimo = pagos
                  .map((p) => fechaCivilGuardada(p.fechaPago))
                  .reduce((a, b) => a.isAfter(b) ? a : b);
              final alUltimo = ResumenDeuda.calcular(
                guardada,
                abonos,
                hoy: DateTime(ultimo.year, ultimo.month, ultimo.day),
              );
              if (alUltimo.saldo <= 0) fin = ultimo;
            }
            await dao.marcarComoPagada(guardada.id, fin);
            if (mounted) {
              mostrarInfo(
                context,
                'Con ese monto ya no debes nada: la deuda pasó a pagadas.',
              );
            }
          }
        }
      }
    });
  }

  /// Debajo de "Pago mínimo al mes": las dos cuotas que sugiere la app
  /// (se tocan para usarlas) y, si hay un monto escrito, qué pasa con él:
  /// cuándo terminas, o un aviso si así la deuda nunca baja o terminas
  /// después de la fecha límite. Nunca bloquea el guardado.
  Widget? _ayudaPagoMinimo(BuildContext context) {
    final r = _resumenFormulario();
    if (r == null || r.saldo <= 0 || r.deuda.estado != 'activa') return null;
    final hoy = DateTime.now();
    final sugerencias = r.sugerirCuotas(hoy);
    if (sugerencias == null) return null;
    final c = context.colores;
    final theme = Theme.of(context);
    final gris = theme.textTheme.bodySmall?.copyWith(
      fontSize: 12.5,
      height: 1.4,
      color: c.textoSecundario,
    );

    String plazo(SugerenciaCuota s) => s.meses == 0
        ? 'terminas este mes'
        : 'terminas en ${formatMesAnioCorto(s.fecha)}';

    Widget opcion(String llave, String titulo, SugerenciaCuota s) {
      final elegida = parseCOP(_cuotaCtrl.text) == s.cuota;
      return Material(
        color: elegida ? c.acentoSuave : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: elegida ? c.acento : c.divisor,
            width: AppSpacing.borde,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey(llave),
          onTap: () => _ponerCuota(s.cuota),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: c.textoSecundario,
                  ),
                ),
                Text(
                  formatCOP(s.cuota),
                  style: monoStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(plazo(s), style: gris?.copyWith(fontSize: 11.5)),
              ],
            ),
          ),
        ),
      );
    }

    // Qué pasa con lo que está escrito.
    Widget? efecto;
    final cuota = parseCOP(_cuotaCtrl.text);
    if (cuota != null && cuota > 0) {
      final l = r.liquidacionCon(cuota, hoy);
      final limite = r.deuda.fechaLimite == null
          ? null
          : fechaCivilGuardada(r.deuda.fechaLimite!);
      final mesLimite = r.mesLimite(hoy);
      final String texto;
      var alerta = false;
      if (l.noBaja) {
        alerta = true;
        final interes = r.interesProximoMes;
        texto = !r.tieneInteres
            ? 'Con ${formatCOP(cuota)} al mes tardarías más de 50 años en '
                  'terminar esta deuda. Prueba con una de las sugerencias.'
            : cuota <= interes
            ? 'Con ${formatCOP(cuota)} al mes esta deuda nunca se termina: '
                  'solo el interés es de ${formatCOP(interes)} al mes, así '
                  'que lo que debes crece en vez de bajar.'
            : 'Con ${formatCOP(cuota)} al mes esta deuda no se termina en '
                  'menos de 50 años: el interés se come casi todo el pago.';
      } else if (l.meses != null &&
          mesLimite != null &&
          mesLimite >= 0 &&
          l.meses! > mesLimite) {
        alerta = true;
        final ultimoPago = r.fechaDePagoEn(l.fecha!);
        texto = ultimoPago != null
            ? 'Con este pago tu último pago sería el '
                  '${formatFechaLegible(ultimoPago)}, después de tu fecha '
                  'límite (${formatFechaLegible(limite!)}).'
            : 'Con este pago terminas en ${formatMesAnio(l.fecha!)}, '
                  'después de tu fecha límite (${formatMesAnio(limite!)}).';
      } else if (l.fecha != null) {
        final antesDe = l.meses == mesLimite ? r.pagarAntesDe(hoy) : null;
        final base = l.meses == 0
            ? 'Con este pago terminas este mes.'
            : 'Con este pago terminas en ${formatMesAnio(l.fecha!)} '
                  '(${l.meses} ${l.meses == 1 ? 'mes' : 'meses'}).';
        texto = antesDe == null
            ? base
            : '$base Haz ese pago antes del '
                  '${formatFechaLegible(antesDe)}: tu día de pago cae después '
                  'de tu fecha límite.';
      } else {
        texto = '';
      }
      if (texto.isNotEmpty) {
        efecto = Row(
          key: const ValueKey('cuota-efecto'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                alerta ? Icons.warning_amber_rounded : Icons.event_available,
                size: 17,
                color: alerta ? c.alerta : c.positivo,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                texto,
                style: gris?.copyWith(
                  color: alerta ? c.alerta : c.texto,
                  fontWeight: alerta ? FontWeight.w600 : null,
                ),
              ),
            ),
          ],
        );
      }
    }

    final limite = r.deuda.fechaLimite;
    return Padding(
      key: const ValueKey('cuota-sugerencias'),
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?efecto,
          if (efecto != null) const SizedBox(height: 12),
          Text(
            sugerencias.porLimite && limite != null
                ? 'Sugerencias para pagarla antes de tu fecha límite '
                      '(${formatMesAnio(fechaCivilGuardada(limite))}), según lo '
                      'que debes hoy:'
                : 'Sugerencias según lo que debes hoy '
                      '(${formatCOP(r.saldo)}) y tu tasa:',
            style: gris,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              opcion('cuota-minima', 'Mínimo', sugerencias.minimo),
              if (sugerencias.rapido != null)
                opcion('cuota-rapida', 'Más rápido', sugerencias.rapido!),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.deuda != null;
    final tieneInteres = _tieneInteres;
    const espacio = SizedBox(height: AppSpacing.md);

    return PaginaFormulario(
      formKey: formKey,
      kicker: 'Deuda',
      titulo: esEdicion ? 'Editar deuda' : 'Nueva deuda',
      children: [
        FormSection(
          title: 'Datos básicos',
          icon: Icons.info_outline,
          children: [
            FilaCampos(
              children: [
                CampoEtiquetado(
                  etiqueta: 'Nombre',
                  ayuda: 'Escribe y elige de la lista o pon el que quieras.',
                  // Sugiere bancos, tiendas, billeteras… y al elegir uno
                  // pone su tipo (y su ícono) solo.
                  child: CampoNombreConSugerencias(
                    key: const ValueKey('deuda-nombre'),
                    controller: _acreedorCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ej.: Tarjeta Nu, Juan, Crédito del carro',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    alElegir: (s) => _cambiarTipo(s.grupo.tipoDeuda.clave),
                  ),
                ),
                CampoEtiquetado(
                  etiqueta: 'Descripción (opcional)',
                  child: TextFormField(
                    controller: _descripcionCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ej.: BBVA tarjeta de crédito',
                      counterText: '',
                    ),
                    maxLength: 60,
                  ),
                ),
              ],
            ),
            espacio,
            FilaCampos(
              children: [
                CampoEtiquetado(
                  etiqueta: 'Monto original',
                  child: TextFormField(
                    controller: _montoCtrl,
                    style: monoStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixText: r'$ ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CopInputFormatter()],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido';
                      final n = parseCOP(v);
                      if (n == null) return 'Monto inválido';
                      if (n <= 0) return 'Debe ser mayor a 0';
                      return null;
                    },
                  ),
                ),
                CampoEtiquetado(
                  etiqueta: 'Tipo',
                  child: DropdownButtonFormField<String>(
                    value: _tipo,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusRecuadro,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        TipoDeuda.desdeClave(_tipo).icono,
                        size: 20,
                      ),
                    ),
                    items: [
                      for (final t in TipoDeuda.values)
                        DropdownMenuItem(
                          value: t.clave,
                          child: Text(
                            t.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => _cambiarTipo(v ?? TipoDeuda.otro.clave),
                  ),
                ),
              ],
            ),
          ],
        ),
        espacio,
        FormSection(
          title: 'Intereses',
          icon: Icons.percent,
          children: [
            FilaCampos(
              children: [
                CampoEtiquetado(
                  etiqueta: 'Tasa de interés',
                  child: TextFormField(
                    controller: _tasaCtrl,
                    style: monoStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: '0',
                      suffixText: '%',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    // Sin resetear nada: borrar la tasa un momento no debe
                    // perder lo elegido. Al guardar sin tasa queda sin interés.
                    onChanged: (_) => setState(() {}),
                    validator: validarTasa,
                  ),
                ),
                CampoEtiquetado(
                  etiqueta: 'La tasa es',
                  // Obligatorio cuando hay tasa: sin esto no se sabe cuánto
                  // interés cobrar.
                  error: _avisarTipoInteres && _faltaTipoInteres
                      ? errorTipoInteres
                      : null,
                  child: GrupoPildoras<String>(
                    opciones: const {'mensual': 'Mensual', 'anual': 'Anual'},
                    valor: _tipoInteres,
                    onElegir: tieneInteres
                        ? (v) => setState(() => _tipoInteres = v)
                        : null,
                  ),
                ),
              ],
            ),
            espacio,
            CampoEtiquetado(
              etiqueta: 'Modalidad de cálculo',
              child: GrupoPildoras<String>(
                opciones: const {'simple': 'Simple', 'compuesto': 'Compuesto'},
                valor: _modalidadCalculo,
                onElegir: tieneInteres
                    ? (v) => setState(() => _modalidadCalculo = v)
                    : null,
              ),
            ),
            espacio,
            CampoEtiquetado(
              etiqueta: 'Interés sobre',
              ayuda: !tieneInteres
                  ? 'Escribe una tasa mayor a 0 para elegir cómo se calcula '
                        'el interés.'
                  : !_amortizacionElegida &&
                        _tipoAmortizacion == 'saldo_original'
                  ? 'Revisa esto: ahora el interés se calcula sobre el monto '
                        'original completo, aunque hagas abonos. Si baja con '
                        'cada pago, elige "Lo que falta por pagar".'
                  : _tipoAmortizacion == 'saldo_insoluto'
                  ? 'El interés de cada mes se calcula sobre lo que '
                        'aún debes, no sobre el monto original — así '
                        'funciona un crédito bancario.'
                  : 'El interés siempre se calcula sobre el monto '
                        'original completo, sin importar los abonos '
                        'que hagas — pensado para deuda informal sin '
                        'abonos periódicos garantizados.',
              child: DropdownButtonFormField<String>(
                value: _tipoAmortizacion,
                isExpanded: true,
                borderRadius: BorderRadius.circular(AppSpacing.radiusRecuadro),
                items: const [
                  DropdownMenuItem(
                    value: 'saldo_original',
                    child: Text('Lo prestado al inicio (no baja)'),
                  ),
                  DropdownMenuItem(
                    value: 'saldo_insoluto',
                    child: Text(
                      'Lo que falta por pagar (baja con cada abono)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: tieneInteres
                    ? (v) => setState(() {
                        _amortizacionElegida = true;
                        _tipoAmortizacion = v ?? 'saldo_original';
                      })
                    : null,
              ),
            ),
          ],
        ),
        espacio,
        FormSection(
          title: 'Fechas',
          icon: Icons.event,
          children: [
            FilaCampos(
              children: [
                CampoEtiquetado(
                  etiqueta: 'Fecha en que empezó',
                  child: DatePickerField(
                    label: 'Fecha en que empezó',
                    mostrarEtiqueta: false,
                    icon: Icons.calendar_today,
                    value: _fechaPrestamo,
                    onTap: _seleccionarFechaPrestamo,
                  ),
                ),
                CampoEtiquetado(
                  etiqueta: 'Fecha límite de pago (opcional)',
                  child: DatePickerField(
                    label: 'Fecha límite de pago',
                    mostrarEtiqueta: false,
                    icon: Icons.event_busy,
                    value: _fechaLimite,
                    onTap: _seleccionarFechaLimite,
                    onClear: () => setState(() => _fechaLimite = null),
                    placeholder: 'Sin fecha límite',
                  ),
                ),
              ],
            ),
            espacio,
            CampoEtiquetado(
              etiqueta: 'Día de pago de cada mes (opcional)',
              ayuda:
                  'Valtiq lo usa para mostrarte tu próximo pago y para '
                  'saber cuántos pagos te caben antes de tu fecha límite. '
                  'Si el mes no tiene ese día (31 en febrero), cuenta el '
                  'último.',
              child: TextFormField(
                controller: _diaPagoCtrl,
                decoration: const InputDecoration(hintText: 'Del 1 al 31'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final dia = int.tryParse(v.trim());
                  if (dia == null || dia < 1 || dia > 31) {
                    return 'Escribe un día del 1 al 31';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        espacio,
        FormSection(
          title: 'Pagos y notas',
          icon: Icons.payments_outlined,
          children: [
            // Velo que se enciende y se apaga solo cuando se llega aquí
            // desde el aviso del Plan de pago. Es UNA sola sombra plana (sin
            // relleno encima, que se veía en dos capas) y de tono neutro, no
            // vino. Al ser sombra no mueve nada de su sitio.
            AnimatedContainer(
              key: _clavePagoMinimo,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusCampo),
                boxShadow: [
                  BoxShadow(
                    color: _resaltarPagoMinimo
                        ? context.colores.texto.withValues(alpha: 0.08)
                        : Colors.transparent,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: CampoEtiquetado(
                etiqueta: 'Pago mínimo al mes (opcional)',
                ayuda:
                    'La cuota que pactaste o la que piensas pagar. Abajo te '
                    'sugerimos una; con la calculadora eliges en cuántos '
                    'meses terminar.',
                child: TextFormField(
                  controller: _cuotaCtrl,
                  focusNode: _focoPagoMinimo,
                  style: monoStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixText: r'$ ',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calculate_outlined),
                      tooltip: 'Calcular la cuota para terminar en N meses',
                      onPressed: _calcularCuotaSugerida,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [CopInputFormatter()],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final cuota = parseCOP(v);
                    if (cuota == null) return 'Monto inválido';
                    // Una cuota ya guardada puede quedar mayor que el saldo
                    // en el último pago: no se le exige cambiarla.
                    if (cuota == widget.deuda?.cuotaMensual) return null;
                    // Tope: lo que se debe hoy (o lo escrito, si aún no hay
                    // cómo calcularlo), para atajar un cero de más.
                    final r = _resumenFormulario();
                    // Incluye el interés hasta el primer pago: la cuota que
                    // propone la calculadora siempre se puede guardar.
                    final tope = r != null && r.deuda.estado == 'activa'
                        ? math.max(
                            r.saldo,
                            r.cuotaParaTerminarEn(0, DateTime.now()) ?? 0,
                          )
                        : parseCOP(_montoCtrl.text) ?? 0;
                    if (tope > 0 && cuota > tope) {
                      return 'La cuota no puede superar lo que debes '
                          '(${formatCOP(tope)})';
                    }
                    return null;
                  },
                ),
              ),
            ),
            ?_resultadoCalculadora(context),
            ?_ayudaPagoMinimo(context),
            espacio,
            CampoEtiquetado(
              etiqueta: 'Notas (opcional)',
              child: TextFormField(controller: _notasCtrl, maxLines: 3),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        FormSaveButton(
          onPressed: _guardar,
          loading: guardando,
          label: esEdicion ? 'Guardar cambios' : 'Guardar deuda',
        ),
      ],
    );
  }
}
