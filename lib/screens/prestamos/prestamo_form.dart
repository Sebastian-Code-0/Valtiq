import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/deudas_calculos.dart';
import '../../services/interes_calculator.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/date_format.dart';
import '../../utils/dialogo_meses.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/formulario_guardado_mixin.dart';
import '../../utils/notificaciones.dart';
import '../../utils/selector_pildoras.dart';
import '../../utils/tasa_input.dart';

class PrestamoForm extends StatefulWidget {
  const PrestamoForm({super.key, required this.db, this.prestamo});

  final AppDatabase db;
  final Prestamo? prestamo;

  @override
  State<PrestamoForm> createState() => _PrestamoFormState();
}

class _PrestamoFormState extends State<PrestamoForm>
    with FormularioGuardadoMixin<PrestamoForm> {
  late final TextEditingController _deudorCtrl;
  late final TextEditingController _contactoCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _tasaCtrl;
  late final TextEditingController _notasCtrl;

  late String _tipoInteres;
  late String _modalidadCalculo;
  late String _tipoAmortizacion;
  late DateTime _fechaPrestamo;
  DateTime? _fechaPactada;

  @override
  void initState() {
    super.initState();
    final p = widget.prestamo;
    _deudorCtrl = TextEditingController(text: p?.deudorNombre ?? '');
    _contactoCtrl = TextEditingController(text: p?.deudorContacto ?? '');
    _montoCtrl = TextEditingController(
      text: p != null ? formatCOPInput(p.montoPrestado) : '',
    );
    // Sin "0" inicial: así no hay que borrarlo antes de escribir la tasa.
    _tasaCtrl = TextEditingController(text: tasaParaCampo(p?.tasaInteres ?? 0));
    _notasCtrl = TextEditingController(text: p?.notas ?? '');
    _tipoInteres = p?.tipoInteres ?? 'ninguno';
    _modalidadCalculo = p?.modalidadCalculo ?? 'simple';
    _tipoAmortizacion = p?.tipoAmortizacion ?? 'saldo_original';
    _fechaPrestamo = p != null
        ? fechaCivilGuardada(p.fechaPrestamo)
        : DateTime.now();
    _fechaPactada = p?.fechaPactadaPago == null
        ? null
        : fechaCivilGuardada(p!.fechaPactadaPago!);
  }

  @override
  void dispose() {
    _deudorCtrl.dispose();
    _contactoCtrl.dispose();
    _montoCtrl.dispose();
    _tasaCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  bool get _tieneInteres => parseTasa(_tasaCtrl.text) > 0;

  /// Hay tasa pero falta decir si es mensual o anual (sin eso el interés no
  /// se calcula).
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

  Future<void> _seleccionarFechaPactada() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fechaPactada != null && !_fechaPactada!.isBefore(_inicioDia)
          ? _fechaPactada!
          : _inicioDia,
      firstDate: _inicioDia,
      lastDate: DateTime(2100),
      locale: const Locale('es', 'CO'),
    );
    if (f != null) setState(() => _fechaPactada = f);
  }

  /// Calculadora de cuota: en cuántos meses quieres que te terminen de
  /// pagar → cuánto deberían pagarte al mes. Usa lo que te deben HOY (con
  /// los pagos ya recibidos) y el mismo motor de intereses de toda la app,
  /// así que respeta interés sobre lo que falta o sobre lo prestado. Sirve
  /// también sin interés.
  Future<void> _calcularCuotaSugerida() async {
    final monto = parseCOP(_montoCtrl.text);
    if (monto == null || monto <= 0) {
      mostrarAlerta(context, 'Ingresa primero el monto prestado.');
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
    final p = widget.prestamo;
    final pagos = p == null
        ? const <PagosRecibido>[]
        : await widget.db.prestamosDao.getPagosDelPrestamo(p.id);
    if (!mounted) return;
    final tasa = parseTasa(_tasaCtrl.text);
    final conInteres = tasa > 0;
    final ahora = DateTime.now();
    // El préstamo visto como una deuda: el cálculo es el mismo.
    final comoDeuda = Deuda(
      id: p?.id ?? 0,
      acreedorNombre: _deudorCtrl.text,
      descripcion: '',
      tipo: 'persona',
      montoOriginal: monto,
      tasaInteres: tasa,
      tipoInteres: conInteres ? _tipoInteres : 'ninguno',
      modalidadCalculo: conInteres ? _modalidadCalculo : 'simple',
      tipoAmortizacion: conInteres ? _tipoAmortizacion : 'saldo_original',
      fechaPrestamo: normalizarFechaCivil(_fechaPrestamo),
      fechaLimite: _fechaPactada == null
          ? null
          : normalizarFechaCivil(_fechaPactada!),
      notas: '',
      estado: 'activa',
      creadoEn: ahora,
      actualizadoEn: ahora,
    );
    final r = ResumenDeuda.calcular(comoDeuda, [
      for (final pago in pagos)
        AbonoInteres(fecha: pago.fechaPago, monto: pago.montoAbonado),
    ], hoy: ahora);
    final calculada = r.cuotaParaPagos(numeroCuotas, ahora);
    if (calculada == null) {
      mostrarInfo(context, 'Este préstamo ya no tiene saldo por cobrar.');
      return;
    }
    final cuota = calculada.cuota;
    final fin = r.liquidacionCon(cuota, ahora).fecha;
    final cuando = fin == null
        ? 'en $numeroCuotas meses'
        : 'en ${formatMesAnio(fin)}';
    mostrarExito(
      context,
      calculada.porLimite
          ? 'La fecha pactada llega antes de $numeroCuotas meses: para que '
                'te terminen de pagar $cuando, la cuota sería de '
                '${formatCOP(cuota)} al mes.'
          : 'Para que te terminen de pagar $cuando, la cuota sería de '
                '${formatCOP(cuota)} al mes.',
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
    if (_fechaPactada != null &&
        DateTime(
          _fechaPactada!.year,
          _fechaPactada!.month,
          _fechaPactada!.day,
        ).isBefore(_inicioDia)) {
      mostrarAlerta(
        context,
        'La fecha pactada no puede ser anterior a la fecha del préstamo.',
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

    final dao = widget.db.prestamosDao;
    final fechaPrestamo = normalizarFechaCivil(_fechaPrestamo);
    final fechaPactada = _fechaPactada == null
        ? null
        : normalizarFechaCivil(_fechaPactada!);
    await ejecutarGuardado(() async {
      if (widget.prestamo == null) {
        await dao.insertPrestamo(
          PrestamosCompanion.insert(
            deudorNombre: _deudorCtrl.text.trim(),
            deudorContacto: Value(_contactoCtrl.text.trim()),
            montoPrestado: monto,
            tasaInteres: Value(tasa),
            tipoInteres: Value(tipo),
            modalidadCalculo: Value(modalidad),
            tipoAmortizacion: Value(amortizacion),
            fechaPrestamo: fechaPrestamo,
            fechaPactadaPago: Value(fechaPactada),
            notas: Value(_notasCtrl.text.trim()),
          ),
        );
      } else {
        await dao.updatePrestamo(
          widget.prestamo!.copyWith(
            deudorNombre: _deudorCtrl.text.trim(),
            deudorContacto: _contactoCtrl.text.trim(),
            montoPrestado: monto,
            tasaInteres: tasa,
            tipoInteres: tipo,
            modalidadCalculo: modalidad,
            tipoAmortizacion: amortizacion,
            fechaPrestamo: fechaPrestamo,
            fechaPactadaPago: Value(fechaPactada),
            notas: _notasCtrl.text.trim(),
            actualizadoEn: DateTime.now(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.prestamo != null;
    final tieneInteres = _tieneInteres;
    const espacio = SizedBox(height: AppSpacing.md);

    return PaginaFormulario(
      formKey: formKey,
      kicker: 'Préstamo',
      titulo: esEdicion ? 'Editar préstamo' : 'Nuevo préstamo',
      children: [
        FormSection(
          title: '¿A quién le prestaste?',
          icon: Icons.person_outline,
          children: [
            FilaCampos(
              children: [
                CampoEtiquetado(
                  etiqueta: 'Nombre',
                  child: TextFormField(
                    controller: _deudorCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ej.: Pedro, mi hermana',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
                CampoEtiquetado(
                  etiqueta: 'Contacto (opcional)',
                  child: TextFormField(
                    controller: _contactoCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Teléfono, correo...',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        espacio,
        FormSection(
          title: 'Monto e intereses',
          icon: Icons.attach_money,
          children: [
            FilaCampos(
              children: [
                CampoEtiquetado(
                  etiqueta: 'Monto prestado',
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
              ],
            ),
            espacio,
            FilaCampos(
              children: [
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
                CampoEtiquetado(
                  etiqueta: 'Modalidad de cálculo',
                  child: GrupoPildoras<String>(
                    opciones: const {
                      'simple': 'Simple',
                      'compuesto': 'Compuesto',
                    },
                    valor: _modalidadCalculo,
                    onElegir: tieneInteres
                        ? (v) => setState(() => _modalidadCalculo = v)
                        : null,
                  ),
                ),
              ],
            ),
            espacio,
            CampoEtiquetado(
              etiqueta: 'Interés sobre',
              ayuda: !tieneInteres
                  ? 'Escribe una tasa mayor a 0 para elegir cómo se calcula '
                        'el interés.'
                  : _tipoAmortizacion == 'saldo_insoluto'
                  ? 'El interés de cada mes se calcula sobre lo que '
                        'aún te deben, no sobre el monto original — '
                        'así funciona un crédito bancario.'
                  : 'El interés siempre se calcula sobre el monto '
                        'original completo, sin importar los pagos '
                        'que reciban — pensado para préstamos '
                        'informales sin pagos periódicos garantizados.',
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
                    child: Text('Lo que falta por pagar (baja con cada abono)'),
                  ),
                ],
                onChanged: tieneInteres
                    ? (v) => setState(
                        () => _tipoAmortizacion = v ?? 'saldo_original',
                      )
                    : null,
              ),
            ),
            if (tieneInteres) ...[
              espacio,
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _calcularCuotaSugerida,
                  icon: const Icon(Icons.calculate_outlined, size: 18),
                  label: const Text('Calcular la cuota para N meses'),
                ),
              ),
            ],
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
                  etiqueta: 'Fecha del préstamo',
                  child: DatePickerField(
                    label: 'Fecha del préstamo',
                    mostrarEtiqueta: false,
                    icon: Icons.calendar_today,
                    value: _fechaPrestamo,
                    onTap: _seleccionarFechaPrestamo,
                  ),
                ),
                CampoEtiquetado(
                  etiqueta: 'Fecha pactada de pago (opcional)',
                  child: DatePickerField(
                    label: 'Fecha pactada de pago',
                    mostrarEtiqueta: false,
                    icon: Icons.event_available,
                    value: _fechaPactada,
                    onTap: _seleccionarFechaPactada,
                    onClear: () => setState(() => _fechaPactada = null),
                    placeholder: 'Sin fecha pactada',
                  ),
                ),
              ],
            ),
          ],
        ),
        espacio,
        FormSection(
          title: 'Notas',
          icon: Icons.notes,
          children: [
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
          label: esEdicion ? 'Guardar cambios' : 'Guardar préstamo',
        ),
      ],
    );
  }
}
