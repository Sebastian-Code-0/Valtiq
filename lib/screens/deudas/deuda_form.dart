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
  late final TextEditingController _montoCtrl;
  late final TextEditingController _tasaCtrl;
  late final TextEditingController _cuotaCtrl;
  late final TextEditingController _notasCtrl;

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
    _fechaPrestamo = d?.fechaPrestamo ?? DateTime.now();
    _fechaLimite = d?.fechaLimite;
  }

  @override
  void dispose() {
    _acreedorCtrl.dispose();
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

    return Scaffold(
      appBar: AppBar(title: Text(esEdicion ? 'Editar deuda' : 'Nueva deuda')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            FormSection(
              title: 'Datos básicos',
              icon: Icons.info_outline,
              children: [
                TextFormField(
                  controller: _acreedorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Acreedor',
                    hintText: '¿A quién le debes?',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _montoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Monto original',
                    prefixIcon: Icon(Icons.attach_money),
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
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FormSection(
              title: 'Intereses',
              icon: Icons.percent,
              children: [
                TextFormField(
                  controller: _tasaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tasa de interés (%)',
                    prefixIcon: Icon(Icons.percent),
                  ),
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
                    final tasa = double.tryParse(v.trim().replaceAll(',', '.'));
                    if (tasa == null) return 'Ingresa un número válido';
                    if (tasa < 0) return 'La tasa no puede ser negativa';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: _tipoInteres,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de interés',
                    prefixIcon: Icon(Icons.swap_horiz),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ninguno', child: Text('Ninguno')),
                    DropdownMenuItem(value: 'mensual', child: Text('Mensual')),
                    DropdownMenuItem(value: 'anual', child: Text('Anual')),
                  ],
                  onChanged: tieneInteres
                      ? (v) => setState(() => _tipoInteres = v ?? 'ninguno')
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: _modalidadCalculo,
                  decoration: const InputDecoration(
                    labelText: 'Modalidad de cálculo',
                    prefixIcon: Icon(Icons.calculate_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'simple', child: Text('Simple')),
                    DropdownMenuItem(
                      value: 'compuesto',
                      child: Text('Compuesto'),
                    ),
                  ],
                  onChanged: tieneInteres
                      ? (v) => setState(() => _modalidadCalculo = v ?? 'simple')
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: _tipoAmortizacion,
                  decoration: const InputDecoration(
                    labelText: 'Interés sobre',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'saldo_original',
                      child: Text('Saldo original (hasta pagar todo)'),
                    ),
                    DropdownMenuItem(
                      value: 'saldo_insoluto',
                      child: Text('Saldo insoluto (baja con cada abono)'),
                    ),
                  ],
                  onChanged: tieneInteres
                      ? (v) => setState(
                          () => _tipoAmortizacion = v ?? 'saldo_original',
                        )
                      : null,
                ),
                if (tieneInteres) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Text(
                      _tipoAmortizacion == 'saldo_insoluto'
                          ? 'El interés de cada mes se calcula sobre lo que '
                                'aún debes, no sobre el monto original — así '
                                'funciona un crédito bancario.'
                          : 'El interés siempre se calcula sobre el monto '
                                'original completo, sin importar los abonos '
                                'que hagas — pensado para deuda informal sin '
                                'abonos periódicos garantizados.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorSecundario,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FormSection(
              title: 'Fechas',
              icon: Icons.event,
              children: [
                DatePickerField(
                  label: 'Fecha del préstamo',
                  icon: Icons.calendar_today,
                  value: _fechaPrestamo,
                  onTap: _seleccionarFechaPrestamo,
                ),
                const SizedBox(height: AppSpacing.sm),
                DatePickerField(
                  label: 'Fecha límite de pago',
                  icon: Icons.event_busy,
                  value: _fechaLimite,
                  onTap: _seleccionarFechaLimite,
                  onClear: () => setState(() => _fechaLimite = null),
                  placeholder: 'Sin fecha límite',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FormSection(
              title: 'Pagos y notas',
              icon: Icons.payments_outlined,
              children: [
                TextFormField(
                  controller: _cuotaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Cuota mensual pactada',
                    hintText: 'Opcional',
                    prefixIcon: const Icon(Icons.payment),
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
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _notasCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    hintText: 'Opcional',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FormSaveButton(onPressed: _guardar, loading: guardando),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
