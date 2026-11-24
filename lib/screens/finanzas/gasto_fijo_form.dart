import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/campo_nombre_sugerencias.dart';
import '../../utils/currency_input.dart';
import '../../utils/form_widgets.dart';
import '../../utils/formulario_guardado_mixin.dart';
import '../../utils/nombres_conocidos.dart';
import '../../utils/notificaciones.dart';
import '../../utils/selector_pildoras.dart';

class GastoFijoForm extends StatefulWidget {
  const GastoFijoForm({super.key, required this.db, this.gasto});

  final AppDatabase db;
  final GastosFijo? gasto;

  @override
  State<GastoFijoForm> createState() => _GastoFijoFormState();
}

class _GastoFijoFormState extends State<GastoFijoForm>
    with FormularioGuardadoMixin<GastoFijoForm> {
  late final TextEditingController _conceptoCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _diaCobroCtrl;
  late final TextEditingController _notasCtrl;

  late String _frecuencia;

  @override
  void initState() {
    super.initState();
    final g = widget.gasto;
    _conceptoCtrl = TextEditingController(text: g?.concepto ?? '');
    _montoCtrl = TextEditingController(
      text: g != null ? formatCOPInput(g.monto) : '',
    );
    _diaCobroCtrl = TextEditingController(text: g?.diaCobro?.toString() ?? '');
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
    final diaCobroText = _diaCobroCtrl.text.trim();
    final diaCobro = diaCobroText.isEmpty ? null : int.tryParse(diaCobroText);

    final dao = widget.db.gastosFijosDao;
    await ejecutarGuardado(() async {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.gasto != null;
    const espacio = SizedBox(height: AppSpacing.md);

    return PaginaFormulario(
      formKey: formKey,
      kicker: 'Gasto fijo',
      titulo: esEdicion ? 'Editar gasto fijo' : 'Nuevo gasto fijo',
      children: [
        FormSection(
          title: 'Datos del gasto',
          icon: Icons.trending_down,
          children: [
            FilaCampos(
              children: [
                CampoEtiquetado(
                  etiqueta: 'Concepto',
                  child: CampoNombreConSugerencias(
                    key: const ValueKey('gasto-fijo-concepto'),
                    controller: _conceptoCtrl,
                    grupos: esGrupoDeGasto,
                    decoration: const InputDecoration(
                      hintText: 'Netflix, arriendo, luz...',
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
              ],
            ),
          ],
        ),
        espacio,
        FormSection(
          title: 'Frecuencia',
          icon: Icons.event_repeat,
          children: [
            FilaCampos(
              children: [
                CampoEtiquetado(
                  etiqueta: '¿Cada cuánto se paga?',
                  child: GrupoPildoras<String>(
                    opciones: const {
                      'mensual': 'Mensual',
                      'quincenal': 'Quincenal',
                      'semanal': 'Semanal',
                    },
                    valor: _frecuencia,
                    onElegir: (v) => setState(() => _frecuencia = v),
                  ),
                ),
                CampoEtiquetado(
                  etiqueta: 'Día de cobro (opcional)',
                  child: TextFormField(
                    controller: _diaCobroCtrl,
                    decoration: const InputDecoration(
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
          label: esEdicion ? 'Guardar cambios' : 'Guardar gasto fijo',
        ),
      ],
    );
  }
}
