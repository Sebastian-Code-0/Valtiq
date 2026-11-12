import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/form_widgets.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/formulario_guardado_mixin.dart';
import '../../utils/notificaciones.dart';
import '../../utils/selector_pildoras.dart';

class IngresoForm extends StatefulWidget {
  const IngresoForm({super.key, required this.db, this.ingreso});

  final AppDatabase db;
  final Ingreso? ingreso;

  @override
  State<IngresoForm> createState() => _IngresoFormState();
}

class _IngresoFormState extends State<IngresoForm>
    with FormularioGuardadoMixin<IngresoForm> {
  late final TextEditingController _conceptoCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _notasCtrl;

  late String _frecuencia;
  late DateTime _fecha;

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
    _fecha = i != null ? fechaCivilGuardada(i.fecha) : DateTime.now();
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
    if (!formKey.currentState!.validate()) return;
    setState(() => guardando = true);

    final concepto = _conceptoCtrl.text.trim();
    final monto = parseCOP(_montoCtrl.text);
    if (monto == null) {
      setState(() => guardando = false);
      if (mounted) {
        mostrarAlerta(context, 'Monto inválido. Verifica el valor ingresado.');
      }
      return;
    }
    final notas = _notasCtrl.text.trim();

    final dao = widget.db.ingresosDao;
    final fecha = normalizarFechaCivil(_fecha);
    await ejecutarGuardado(() async {
      if (widget.ingreso == null) {
        await dao.insertIngreso(
          IngresosCompanion.insert(
            concepto: concepto,
            monto: monto,
            frecuencia: Value(_frecuencia),
            fecha: fecha,
            notas: Value(notas),
          ),
        );
      } else {
        await dao.updateIngreso(
          widget.ingreso!.copyWith(
            concepto: concepto,
            monto: monto,
            frecuencia: _frecuencia,
            fecha: fecha,
            notas: notas,
            actualizadoEn: DateTime.now(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.ingreso != null;
    const espacio = SizedBox(height: AppSpacing.md);

    return PaginaFormulario(
      formKey: formKey,
      kicker: 'Ingreso',
      titulo: esEdicion ? 'Editar ingreso' : 'Nuevo ingreso',
      children: [
        FormSection(
          title: 'Datos del ingreso',
          icon: Icons.trending_up,
          children: [
            FilaCampos(
              children: [
                CampoEtiquetado(
                  etiqueta: 'Concepto',
                  child: TextFormField(
                    controller: _conceptoCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Sueldo, freelance, venta...',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
                CampoEtiquetado(
                  etiqueta: 'Monto',
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
              ],
            ),
          ],
        ),
        espacio,
        FormSection(
          title: 'Frecuencia y fecha',
          icon: Icons.event_repeat,
          children: [
            CampoEtiquetado(
              etiqueta: '¿Cada cuánto llega?',
              ayuda: _frecuencia == 'unico'
                  ? 'Un pago de una sola vez: solo cuenta en el mes de su '
                        'fecha.'
                  : null,
              child: GrupoPildoras<String>(
                opciones: const {
                  'mensual': 'Mensual',
                  'quincenal': 'Quincenal',
                  'semanal': 'Semanal',
                  'unico': 'Único',
                },
                valor: _frecuencia,
                onElegir: (v) => setState(() => _frecuencia = v),
              ),
            ),
            espacio,
            CampoEtiquetado(
              etiqueta: 'Fecha',
              child: DatePickerField(
                label: 'Fecha',
                mostrarEtiqueta: false,
                icon: Icons.calendar_today,
                value: _fecha,
                onTap: _seleccionarFecha,
              ),
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
          label: esEdicion ? 'Guardar cambios' : 'Guardar ingreso',
        ),
      ],
    );
  }
}
