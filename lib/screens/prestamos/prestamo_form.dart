import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/date_format.dart';

class PrestamoForm extends StatefulWidget {
  const PrestamoForm({super.key, required this.db, this.prestamo});

  final AppDatabase db;
  final Prestamo? prestamo;

  @override
  State<PrestamoForm> createState() => _PrestamoFormState();
}

class _PrestamoFormState extends State<PrestamoForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _deudorCtrl;
  late final TextEditingController _contactoCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _tasaCtrl;
  late final TextEditingController _notasCtrl;

  late String _tipoInteres;
  late String _modalidadCalculo;
  late DateTime _fechaPrestamo;
  DateTime? _fechaPactada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final p = widget.prestamo;
    _deudorCtrl = TextEditingController(text: p?.deudorNombre ?? '');
    _contactoCtrl = TextEditingController(text: p?.deudorContacto ?? '');
    _montoCtrl = TextEditingController(
      text: p != null ? formatCOPInput(p.montoPrestado) : '',
    );
    _tasaCtrl = TextEditingController(
      text: p != null ? _fmtTasa(p.tasaInteres) : '0',
    );
    _notasCtrl = TextEditingController(text: p?.notas ?? '');
    _tipoInteres = p?.tipoInteres ?? 'ninguno';
    _modalidadCalculo = p?.modalidadCalculo ?? 'simple';
    _fechaPrestamo = p?.fechaPrestamo ?? DateTime.now();
    _fechaPactada = p?.fechaPactadaPago;
  }

  String _fmtTasa(double t) {
    if (t == t.truncateToDouble()) return t.toStringAsFixed(0);
    return t.toStringAsFixed(2);
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

  Future<void> _seleccionarFechaPactada() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fechaPactada ?? _fechaPrestamo,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (f != null) setState(() => _fechaPactada = f);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final monto = parseCOP(_montoCtrl.text)!;
    final tasa = double.tryParse(_tasaCtrl.text.replaceAll(',', '.')) ?? 0;
    final tipo = tasa > 0 ? _tipoInteres : 'ninguno';
    final modalidad = tasa > 0 ? _modalidadCalculo : 'simple';

    final dao = widget.db.prestamosDao;
    if (widget.prestamo == null) {
      await dao.insertPrestamo(
        PrestamosCompanion.insert(
          deudorNombre: _deudorCtrl.text.trim(),
          deudorContacto: Value(_contactoCtrl.text.trim()),
          montoPrestado: monto,
          tasaInteres: Value(tasa),
          tipoInteres: Value(tipo),
          modalidadCalculo: Value(modalidad),
          fechaPrestamo: _fechaPrestamo,
          fechaPactadaPago: Value(_fechaPactada),
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
          fechaPrestamo: _fechaPrestamo,
          fechaPactadaPago: Value(_fechaPactada),
          notas: _notasCtrl.text.trim(),
          actualizadoEn: DateTime.now(),
        ),
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.prestamo != null;
    final tieneInteres = _tieneInteres;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar préstamo' : 'Nuevo préstamo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextFormField(
              controller: _deudorCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del deudor',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _contactoCtrl,
              decoration: const InputDecoration(
                labelText: 'Contacto (opcional)',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _montoCtrl,
              decoration: const InputDecoration(labelText: 'Monto prestado'),
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
            TextFormField(
              controller: _tasaCtrl,
              decoration:
                  const InputDecoration(labelText: 'Tasa de interés (%)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {
                if (!_tieneInteres) {
                  _tipoInteres = 'ninguno';
                  _modalidadCalculo = 'simple';
                }
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _tipoInteres,
              decoration:
                  const InputDecoration(labelText: 'Tipo de interés'),
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
              decoration:
                  const InputDecoration(labelText: 'Modalidad de cálculo'),
              items: const [
                DropdownMenuItem(value: 'simple', child: Text('Simple')),
                DropdownMenuItem(value: 'compuesto', child: Text('Compuesto')),
              ],
              onChanged: tieneInteres
                  ? (v) => setState(() => _modalidadCalculo = v ?? 'simple')
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: _seleccionarFechaPrestamo,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha del préstamo',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(formatFecha(_fechaPrestamo)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: _seleccionarFechaPactada,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha pactada de pago (opcional)',
                  suffixIcon: _fechaPactada != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () =>
                              setState(() => _fechaPactada = null),
                        )
                      : const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _fechaPactada != null
                      ? formatFecha(_fechaPactada!)
                      : 'Sin fecha pactada',
                ),
              ),
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
