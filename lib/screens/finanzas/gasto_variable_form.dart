import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/categorias_service.dart';
import '../../theme/theme.dart';
import '../../utils/campo_nombre_sugerencias.dart';
import '../../utils/currency_input.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/form_widgets.dart';
import '../../utils/formulario_guardado_mixin.dart';
import '../../utils/nombres_conocidos.dart';
import '../../utils/notificaciones.dart';

class GastoVariableForm extends StatefulWidget {
  const GastoVariableForm({super.key, required this.db, this.gasto});

  final AppDatabase db;
  final GastosVariable? gasto;

  @override
  State<GastoVariableForm> createState() => _GastoVariableFormState();
}

class _GastoVariableFormState extends State<GastoVariableForm>
    with FormularioGuardadoMixin<GastoVariableForm> {
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _notasCtrl;

  late String? _categoria;
  late DateTime _fecha;

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
    _fecha = g != null ? fechaCivilGuardada(g.fecha) : DateTime.now();
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
    if (!formKey.currentState!.validate()) return;
    setState(() => guardando = true);

    final descripcion = _descripcionCtrl.text.trim();
    final monto = parseCOP(_montoCtrl.text);
    if (monto == null) {
      setState(() => guardando = false);
      if (mounted) {
        mostrarAlerta(context, 'Monto inválido. Verifica el valor ingresado.');
      }
      return;
    }
    final notas = _notasCtrl.text.trim();

    String? categoriaExcedida;
    final presupuesto = await widget.db.presupuestosCategoriasDao
        .getPresupuestoPorCategoria(_categoria!);
    if (presupuesto != null) {
      final totales = await widget.db.gastosVariablesDao
          .watchTotalPorCategoria(_fecha.year, _fecha.month)
          .first;
      var totalCategoria = totales[_categoria!] ?? 0.0;
      // Al editar un gasto que ya cae en el mismo mes/categoría que el valor
      // nuevo, `totales` ya incluye su monto VIEJO — hay que restarlo antes
      // de sumar el nuevo, o se contaría dos veces (mismo patrón que la
      // validación de saldo pendiente en abonos: ver memoria del proyecto).
      final original = widget.gasto;
      if (original != null &&
          original.categoria == _categoria &&
          original.fecha.year == _fecha.year &&
          original.fecha.month == _fecha.month) {
        totalCategoria -= original.monto;
      }
      final proyectado = totalCategoria + monto;
      if (proyectado > presupuesto.limiteMensual) {
        categoriaExcedida = _categoria;
      }
    }
    final mesExcedido = _fecha;

    final dao = widget.db.gastosVariablesDao;
    final fecha = normalizarFechaCivil(_fecha);
    await ejecutarGuardado(
      () async {
        if (widget.gasto == null) {
          await dao.insertGastoVariable(
            GastosVariablesCompanion.insert(
              descripcion: descripcion,
              monto: monto,
              categoria: _categoria!,
              fecha: fecha,
              notas: Value(notas.isEmpty ? null : notas),
            ),
          );
        } else {
          await dao.updateGastoVariable(
            widget.gasto!.copyWith(
              descripcion: descripcion,
              monto: monto,
              categoria: _categoria!,
              fecha: fecha,
              notas: Value(notas.isEmpty ? null : notas),
            ),
          );
        }
      },
      resultadoExtra: () => categoriaExcedida == null
          ? null
          : (categoria: categoriaExcedida, mes: mesExcedido),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.gasto != null;
    const espacio = SizedBox(height: AppSpacing.md);

    return PaginaFormulario(
      formKey: formKey,
      kicker: 'Gasto del día a día',
      titulo: esEdicion ? 'Editar gasto' : 'Nuevo gasto',
      children: [
        FormSection(
          title: 'Datos del gasto',
          icon: Icons.receipt_long_outlined,
          children: [
            FilaCampos(
              children: [
                CampoEtiquetado(
                  etiqueta: 'Descripción',
                  child: CampoNombreConSugerencias(
                    key: const ValueKey('gasto-descripcion'),
                    controller: _descripcionCtrl,
                    grupos: esGrupoDeGasto,
                    decoration: const InputDecoration(
                      hintText: 'Mercado, ropa, taxi...',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    // Elegir "D1" pone Alimentación (si esa categoría
                    // existe); se puede cambiar después.
                    alElegir: (s) {
                      final cat = s.categoria;
                      if (cat != null &&
                          CategoriasService.nombres.contains(cat)) {
                        setState(() => _categoria = cat);
                      }
                    },
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
            espacio,
            FilaCampos(
              children: [
                CampoEtiquetado(
                  etiqueta: 'Categoría',
                  child: DropdownButtonFormField<String>(
                    value: _categoria,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusRecuadro,
                    ),
                    hint: const Text('Elige una categoría'),
                    // Las categorías actuales (editables en Ajustes →
                    // Presupuestos). Si el gasto trae una que ya no está, se
                    // agrega para que el campo no quede vacío.
                    items: [
                      for (final c in {
                        ...CategoriasService.nombres,
                        ?_categoria,
                      })
                        DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Icon(
                                CategoriasService.iconoPara(c),
                                size: 18,
                                color: CategoriasService.colorPara(c),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(c, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _categoria = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                ),
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
          label: esEdicion ? 'Guardar cambios' : 'Guardar gasto',
        ),
      ],
    );
  }
}
