import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/form_widgets.dart';

const kCategoriasGasto = [
  'Alimentación',
  'Ropa',
  'Transporte',
  'Entretenimiento',
  'Salud',
  'Educación',
  'Hogar',
  'Otros',
];

class GastoVariableForm extends StatefulWidget {
  const GastoVariableForm({super.key, required this.db, this.gasto});

  final AppDatabase db;
  final GastosVariable? gasto;

  @override
  State<GastoVariableForm> createState() => _GastoVariableFormState();
}

class _GastoVariableFormState extends State<GastoVariableForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _notasCtrl;

  late String? _categoria;
  late DateTime _fecha;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final g = widget.gasto;
    _descripcionCtrl = TextEditingController(text: g?.descripcion ?? '');
    _montoCtrl = TextEditingController(
      text: g != null ? formatCOPInput(g.monto) : '',
    );
    _notasCtrl = TextEditingController(text: g?.notas ?? '');
    _categoria = g?.categoria;
    _fecha = g?.fecha ?? DateTime.now();
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
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

    final descripcion = _descripcionCtrl.text.trim();
    final monto = parseCOP(_montoCtrl.text);
    if (monto == null) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monto inválido. Verifica el valor ingresado.'),
          ),
        );
      }
      return;
    }
    final notas = _notasCtrl.text.trim();

    final dao = widget.db.gastosVariablesDao;
    try {
      if (widget.gasto == null) {
        await dao.insertGastoVariable(
          GastosVariablesCompanion.insert(
            descripcion: descripcion,
            monto: monto,
            categoria: _categoria!,
            fecha: _fecha,
            notas: Value(notas.isEmpty ? null : notas),
          ),
        );
      } else {
        await dao.updateGastoVariable(
          widget.gasto!.copyWith(
            descripcion: descripcion,
            monto: monto,
            categoria: _categoria!,
            fecha: _fecha,
            notas: Value(notas.isEmpty ? null : notas),
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.gasto != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          esEdicion ? 'Editar gasto variable' : 'Nuevo gasto variable',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            FormSection(
              title: 'Datos del gasto',
              icon: Icons.receipt_long_outlined,
              children: [
                TextFormField(
                  controller: _descripcionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Mercado, ropa, taxi...',
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
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: _categoria,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: kCategoriasGasto
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoria = v),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FormSection(
              title: 'Fecha',
              icon: Icons.calendar_today,
              children: [
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
