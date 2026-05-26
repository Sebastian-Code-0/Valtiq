import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';

class GastoFijoForm extends StatefulWidget {
  const GastoFijoForm({super.key, required this.db, this.gasto});

  final AppDatabase db;
  final GastosFijo? gasto;

  @override
  State<GastoFijoForm> createState() => _GastoFijoFormState();
}

class _GastoFijoFormState extends State<GastoFijoForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _conceptoCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _diaCobroCtrl;
  late final TextEditingController _notasCtrl;

  late String _frecuencia;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final g = widget.gasto;
    _conceptoCtrl = TextEditingController(text: g?.concepto ?? '');
    _montoCtrl = TextEditingController(
      text: g != null ? formatCOPInput(g.monto) : '',
    );
    _diaCobroCtrl = TextEditingController(
      text: g?.diaCobro?.toString() ?? '',
    );
    _notasCtrl = TextEditingController(text: g?.notas ?? '');
    _frecuencia = g?.frecuencia ?? 'mensual';
  }

  @override
  void dispose() {
    _conceptoCtrl.dispose();
    _montoCtrl.dispose();
    _diaCobroCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final concepto = _conceptoCtrl.text.trim();
    final monto = parseCOP(_montoCtrl.text)!;
    final notas = _notasCtrl.text.trim();
    final diaCobroText = _diaCobroCtrl.text.trim();
    final diaCobro = diaCobroText.isEmpty ? null : int.tryParse(diaCobroText);

    final dao = widget.db.gastosFijosDao;
    if (widget.gasto == null) {
      await dao.insertGastoFijo(
        GastosFijosCompanion.insert(
          concepto: concepto,
          monto: monto,
          frecuencia: Value(_frecuencia),
          diaCobro: Value(diaCobro),
          notas: Value(notas),
        ),
      );
    } else {
      await dao.updateGastoFijo(
        widget.gasto!.copyWith(
          concepto: concepto,
          monto: monto,
          frecuencia: _frecuencia,
          diaCobro: Value(diaCobro),
          notas: notas,
          actualizadoEn: DateTime.now(),
        ),
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.gasto != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar gasto fijo' : 'Nuevo gasto fijo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextFormField(
              controller: _conceptoCtrl,
              decoration: const InputDecoration(
                labelText: 'Concepto',
                hintText: 'Netflix, Arriendo, Luz...',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _montoCtrl,
              decoration: const InputDecoration(labelText: 'Monto'),
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
              value: _frecuencia,
              decoration: const InputDecoration(labelText: 'Frecuencia'),
              items: const [
                DropdownMenuItem(value: 'mensual', child: Text('Mensual')),
                DropdownMenuItem(value: 'quincenal', child: Text('Quincenal')),
                DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
              ],
              onChanged: (v) => setState(() => _frecuencia = v ?? 'mensual'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _diaCobroCtrl,
              decoration: const InputDecoration(
                labelText: 'Día de cobro (opcional)',
                hintText: '¿Qué día del mes se cobra?',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v.trim());
                if (n == null || n < 1 || n > 31) return 'Entre 1 y 31';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notasCtrl,
              decoration:
                  const InputDecoration(labelText: 'Notas (opcional)'),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: Text(_guardando ? 'Guardando...' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
