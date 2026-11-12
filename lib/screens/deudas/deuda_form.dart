import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../services/interes_calculator.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/formulario_guardado_mixin.dart';
import '../../utils/notificaciones.dart';
import '../../utils/selector_pildoras.dart';
import '../../utils/tipo_deuda.dart';

class DeudaForm extends StatefulWidget {
  const DeudaForm({super.key, required this.db, this.deuda});

  final AppDatabase db;
  final Deuda? deuda;

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

  late String _tipo;
  late String _tipoInteres;
  late String _modalidadCalculo;
  late String _tipoAmortizacion;
  late DateTime _fechaPrestamo;
  DateTime? _fechaLimite;

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
    _tasaCtrl = TextEditingController(
      text: d != null ? formatTasaInicial(d.tasaInteres) : '0',
    );
    _cuotaCtrl = TextEditingController(
      text: d?.cuotaMensual != null ? formatCOPInput(d!.cuotaMensual!) : '',
    );
    _notasCtrl = TextEditingController(text: d?.notas ?? '');
    _tipoInteres = d?.tipoInteres ?? 'ninguno';
    _modalidadCalculo = d?.modalidadCalculo ?? 'simple';
    _tipoAmortizacion = d?.tipoAmortizacion ?? 'saldo_original';
    _fechaPrestamo = d != null
        ? fechaCivilGuardada(d.fechaPrestamo)
        : DateTime.now();
    _fechaLimite = d?.fechaLimite == null
        ? null
        : fechaCivilGuardada(d!.fechaLimite!);
  }

  @override
  void dispose() {
    _acreedorCtrl.dispose();
    _descripcionCtrl.dispose();
    _diaPagoCtrl.dispose();
    _montoCtrl.dispose();
    _tasaCtrl.dispose();
    _cuotaCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  bool get _tieneInteres {
    final v = double.tryParse(_tasaCtrl.text.replaceAll(',', '.'));
    return v != null && v > 0;
  }

  Future<void> _seleccionarFechaPrestamo() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fechaPrestamo,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'CO'),
    );
    if (f != null) setState(() => _fechaPrestamo = f);
  }

  Future<void> _seleccionarFechaLimite() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fechaLimite ?? _fechaPrestamo,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'CO'),
    );
    if (f != null) setState(() => _fechaLimite = f);
  }

  Future<void> _calcularCuotaSugerida() async {
    final monto = parseCOP(_montoCtrl.text);
    if (monto == null || monto <= 0) {
      mostrarAlerta(context, 'Ingresa primero el monto original.');
      return;
    }
    if (!_tieneInteres) {
      mostrarAlerta(context, 'Ingresa primero una tasa de interés mayor a 0.');
      return;
    }
    final cuotasCtrl = TextEditingController();
    final numeroCuotas = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Calcular cuota sugerida'),
        content: TextField(
          controller: cuotasCtrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: '¿En cuántos meses?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(cuotasCtrl.text)),
            child: const Text('Calcular'),
          ),
        ],
      ),
    );
    if (numeroCuotas == null || numeroCuotas <= 0) return;
    final tasa = double.tryParse(_tasaCtrl.text.replaceAll(',', '.')) ?? 0;
    final cuota = InteresCalculator.calcularCuotaFijaDesdeTasa(
      capital: monto,
      tasaInteres: tasa,
      tipoInteres: _tipoInteres == 'anual' ? 'anual' : 'mensual',
      numeroCuotas: numeroCuotas,
    );
    if (!mounted) return;
    setState(() => _cuotaCtrl.text = formatCOPInput(cuota));
    mostrarExito(
      context,
      'Cuota fija sugerida a $numeroCuotas meses: ${formatCOP(cuota)}.',
    );
  }

  Future<void> _guardar() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => guardando = true);

    final monto = parseCOP(_montoCtrl.text);
    if (monto == null) {
      setState(() => guardando = false);
      if (mounted) {
        mostrarAlerta(context, 'Monto inválido. Verifica el valor ingresado.');
      }
      return;
    }
    final tasa = double.tryParse(_tasaCtrl.text.replaceAll(',', '.')) ?? 0;
    final tipo = tasa > 0 ? _tipoInteres : 'ninguno';
    final modalidad = tasa > 0 ? _modalidadCalculo : 'simple';
    final amortizacion = tasa > 0 ? _tipoAmortizacion : 'saldo_original';
    final cuotaText = _cuotaCtrl.text.trim();
    final cuota = cuotaText.isEmpty ? null : parseCOP(cuotaText);
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
      }
    });
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
                  child: TextFormField(
                    controller: _acreedorCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ej.: Tarjeta Nu, Juan, Crédito del carro',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
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
                        DropdownMenuItem(value: t.clave, child: Text(t.nombre)),
                    ],
                    onChanged: (v) =>
                        setState(() => _tipo = v ?? TipoDeuda.otro.clave),
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
                    decoration: const InputDecoration(suffixText: '%'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {
                      if (!_tieneInteres) {
                        _tipoInteres = 'ninguno';
                        _modalidadCalculo = 'simple';
                        _tipoAmortizacion = 'saldo_original';
                      }
                    }),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final tasa = double.tryParse(
                        v.trim().replaceAll(',', '.'),
                      );
                      if (tasa == null) return 'Ingresa un número válido';
                      if (tasa < 0) return 'La tasa no puede ser negativa';
                      return null;
                    },
                  ),
                ),
                CampoEtiquetado(
                  etiqueta: 'Tipo de interés',
                  child: GrupoPildoras<String>(
                    opciones: const {
                      'ninguno': 'Ninguno',
                      'mensual': 'Mensual',
                      'anual': 'Anual',
                    },
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
                  'Con esto Valtiq te muestra tu próximo pago. Si el mes no '
                  'tiene ese día, cuenta el último.',
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
            CampoEtiquetado(
              etiqueta: 'Pago mínimo al mes (opcional)',
              ayuda:
                  'La cuota que pactaste. El botón de la calculadora te '
                  'sugiere una según la tasa y los meses.',
              child: TextFormField(
                controller: _cuotaCtrl,
                style: monoStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: '0',
                  prefixText: r'$ ',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calculate_outlined),
                    tooltip: 'Calcular cuota sugerida',
                    onPressed: _calcularCuotaSugerida,
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CopInputFormatter(),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final cuota = parseCOP(v);
                  if (cuota == null) return 'Monto inválido';
                  final monto = parseCOP(_montoCtrl.text) ?? 0;
                  if (monto > 0 && cuota > monto) {
                    return 'La cuota no puede superar el monto total';
                  }
                  return null;
                },
              ),
            ),
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
