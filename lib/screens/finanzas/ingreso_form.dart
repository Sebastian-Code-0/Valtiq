import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/form_widgets.dart';

class IngresoForm extends StatefulWidget {
  const IngresoForm({super.key, required this.db, this.ingreso});

  final AppDatabase db;
  final Ingreso? ingreso;

  @override
  State<IngresoForm> createState() => _IngresoFormState();
}

class _IngresoFormState extends State<IngresoForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _conceptoCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _notasCtrl;

  late String _frecuencia;
  late DateTime _fecha;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final i = widget.ingreso;
    _conceptoCtrl = TextEditingController(text: i?.concepto ?? '');
    _montoCtrl = TextEditingController(
      text: i != null ? formatCOPInput(i.monto) : '',
    );
    _notasCtrl = TextEditingController(text: i?.notas ?? '');
    _frecuencia = i?.frecuencia ?? 'mensual';
    _fecha = i?.fecha ?? DateTime.now();
  }

  @override
  void dispose() {
    _conceptoCtrl.dispose();
    _montoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'CO'),
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final concepto = _conceptoCtrl.text.trim();
    final monto = parseCOP(_montoCtrl.text);
    if (monto == null) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Monto inválido. Verifica el valor ingresado.')),
        );
      }
      return;
    }
    final notas = _notasCtrl.text.trim();

    final dao = widget.db.ingresosDao;
    try {
      if (widget.ingreso == null) {
        await dao.insertIngreso(
          IngresosCompanion.insert(
            concepto: concepto,
            monto: monto,
            frecuencia: Value(_frecuencia),
            fecha: _fecha,
            notas: Value(notas),
          ),
        );
      } else {
        await dao.updateIngreso(
          widget.ingreso!.copyWith(
            concepto: concepto,
            monto: monto,
            frecuencia: _frecuencia,
            fecha: _fecha,
            notas: notas,
            actualizadoEn: DateTime.now(),
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.ingreso != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar ingreso' : 'Nuevo ingreso'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            FormSection(
              title: 'Datos del ingreso',
              icon: Icons.trending_up,
              children: [
                TextFormField(
                  controller: _conceptoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Concepto',
                    hintText: 'Sueldo, freelance, venta...',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _montoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
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
              title: 'Frecuencia y fecha',
              icon: Icons.event_repeat,
              children: [
                DropdownButtonFormField<String>(
                  value: _frecuencia,
                  decoration: const InputDecoration(
                    labelText: 'Frecuencia',
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'mensual',
                      child: Text('Mensual'),
                    ),
                    DropdownMenuItem(
                      value: 'quincenal',
                      child: Text('Quincenal'),
                    ),
                    DropdownMenuItem(
                      value: 'semanal',
                      child: Text('Semanal'),
                    ),
                    DropdownMenuItem(value: 'unico', child: Text('Único')),
                  ],
                  onChanged: (v) =>
                      setState(() => _frecuencia = v ?? 'mensual'),
                ),
                const SizedBox(height: AppSpacing.md),
                DatePickerField(
                  label: 'Fecha',
                  icon: Icons.calendar_today,
                  value: _fecha,
                  onTap: _seleccionarFecha,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FormSection(
              title: 'Notas',
              icon: Icons.notes,
              children: [
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
