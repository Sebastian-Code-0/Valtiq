import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/form_widgets.dart';

class DeudaForm extends StatefulWidget {
  const DeudaForm({super.key, required this.db, this.deuda});

  final AppDatabase db;
  final Deuda? deuda;

  @override
  State<DeudaForm> createState() => _DeudaFormState();
}

class _DeudaFormState extends State<DeudaForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _acreedorCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _tasaCtrl;
  late final TextEditingController _cuotaCtrl;
  late final TextEditingController _notasCtrl;

  late String _tipoInteres;
  late DateTime _fechaPrestamo;
  DateTime? _fechaLimite;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final d = widget.deuda;
    _acreedorCtrl = TextEditingController(text: d?.acreedorNombre ?? '');
    _montoCtrl = TextEditingController(
      text: d != null ? formatCOPInput(d.montoOriginal) : '',
    );
    _tasaCtrl = TextEditingController(
      text: d != null ? _formatTasaInicial(d.tasaInteres) : '0',
    );
    _cuotaCtrl = TextEditingController(
      text: d?.cuotaMensual != null ? formatCOPInput(d!.cuotaMensual!) : '',
    );
    _notasCtrl = TextEditingController(text: d?.notas ?? '');
    _tipoInteres = d?.tipoInteres ?? 'ninguno';
    _fechaPrestamo = d?.fechaPrestamo ?? DateTime.now();
    _fechaLimite = d?.fechaLimite;
  }

  String _formatTasaInicial(double t) {
    if (t == t.truncateToDouble()) return t.toStringAsFixed(0);
    return t.toStringAsFixed(2);
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
    );
    if (f != null) setState(() => _fechaPrestamo = f);
  }

  Future<void> _seleccionarFechaLimite() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fechaLimite ?? _fechaPrestamo,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (f != null) setState(() => _fechaLimite = f);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final monto = parseCOP(_montoCtrl.text)!;
    final tasa = double.tryParse(_tasaCtrl.text.replaceAll(',', '.')) ?? 0;
    final tipo = tasa > 0 ? _tipoInteres : 'ninguno';
    final cuotaText = _cuotaCtrl.text.trim();
    final cuota = cuotaText.isEmpty ? null : parseCOP(cuotaText);
    final notas = _notasCtrl.text.trim();
    final acreedor = _acreedorCtrl.text.trim();

    final dao = widget.db.deudasDao;
    if (widget.deuda == null) {
      await dao.insertDeuda(
        DeudasCompanion.insert(
          acreedorNombre: acreedor,
          montoOriginal: monto,
          tasaInteres: Value(tasa),
          tipoInteres: Value(tipo),
          fechaPrestamo: _fechaPrestamo,
          fechaLimite: Value(_fechaLimite),
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
          fechaPrestamo: _fechaPrestamo,
          fechaLimite: Value(_fechaLimite),
          cuotaMensual: Value(cuota),
          notas: notas,
          actualizadoEn: DateTime.now(),
        ),
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.deuda != null;
    final tieneInteres = _tieneInteres;

    return Scaffold(
      appBar: AppBar(title: Text(esEdicion ? 'Editar deuda' : 'Nueva deuda')),
      body: Form(
        key: _formKey,
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
                    if (!_tieneInteres) _tipoInteres = 'ninguno';
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: _tipoInteres,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de interés',
                    prefixIcon: Icon(Icons.swap_horiz),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'ninguno',
                      child: Text('Ninguno'),
                    ),
                    DropdownMenuItem(
                      value: 'mensual',
                      child: Text('Mensual'),
                    ),
                    DropdownMenuItem(value: 'anual', child: Text('Anual')),
                  ],
                  onChanged: tieneInteres
                      ? (v) => setState(() => _tipoInteres = v ?? 'ninguno')
                      : null,
                ),
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
                  decoration: const InputDecoration(
                    labelText: 'Cuota mensual pactada',
                    hintText: 'Opcional',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CopInputFormatter(),
                  ],
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
            FormSaveButton(onPressed: _guardar, loading: _guardando),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
