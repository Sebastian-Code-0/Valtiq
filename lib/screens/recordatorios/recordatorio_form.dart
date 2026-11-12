import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../../utils/formulario_guardado_mixin.dart';
import '../../utils/notificaciones.dart';
import '../../utils/selector_hora.dart';
import '../../utils/selector_pildoras.dart';

class RecordatorioForm extends StatefulWidget {
  const RecordatorioForm({super.key, required this.db, this.recordatorio});

  final AppDatabase db;
  final Recordatorio? recordatorio;

  @override
  State<RecordatorioForm> createState() => _RecordatorioFormState();
}

class _RecordatorioFormState extends State<RecordatorioForm>
    with FormularioGuardadoMixin<RecordatorioForm> {
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _diasCtrl;

  late DateTime _fechaAlerta;
  late String _tipoNotificacion;
  late bool _repetir;
  late String _tipoReferencia;
  int? _referenciaId;

  late int _horaAviso;
  late int _minutoAviso;
  late String _frecuenciaAviso;

  List<Deuda> _deudas = const [];
  List<Prestamo> _prestamos = const [];
  List<GastosFijo> _gastosFijos = const [];
  bool _cargandoReferencias = false;

  @override
  void initState() {
    super.initState();
    final r = widget.recordatorio;
    _tituloCtrl = TextEditingController(text: r?.titulo ?? '');
    _diasCtrl = TextEditingController(
      text: (r?.diasAnticipacion ?? 3).toString(),
    );
    _fechaAlerta = r != null
        ? fechaCivilGuardada(r.fechaAlerta)
        : DateTime.now().add(const Duration(days: 1));
    _tipoNotificacion = r?.tipoNotificacion ?? 'sistema';
    _repetir = r?.repetir ?? false;
    _tipoReferencia = r?.referenciaTabla ?? 'ninguna';
    _horaAviso = r?.horaAviso ?? 12;
    _minutoAviso = r?.minutoAviso ?? 0;
    _frecuenciaAviso = r?.frecuenciaAviso ?? 'unica';
    _referenciaId = r?.referenciaId;

    if (_tipoReferencia != 'ninguna') {
      _cargarReferencias(_tipoReferencia);
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _diasCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarReferencias(String tipo) async {
    setState(() => _cargandoReferencias = true);
    switch (tipo) {
      case 'deuda':
        _deudas = await widget.db.deudasDao.getDeudasActivas();
        break;
      case 'prestamo':
        _prestamos = await widget.db.prestamosDao.getPrestamosActivos();
        break;
      case 'gasto':
        _gastosFijos = await widget.db.gastosFijosDao.getGastosFijosActivos();
        break;
    }
    if (mounted) setState(() => _cargandoReferencias = false);
  }

  Future<void> _seleccionarFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fechaAlerta,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'CO'),
    );
    if (f != null) setState(() => _fechaAlerta = f);
  }

  Future<void> _seleccionarHora() async {
    final elegida = await mostrarSelectorHora(
      context,
      hora: _horaAviso,
      minuto: _minutoAviso,
      titulo: 'Hora del aviso',
    );
    if (elegida == null) return;
    setState(() {
      _horaAviso = elegida.hora;
      _minutoAviso = elegida.minuto;
    });
  }

  void _onTipoReferenciaChanged(String? nuevo) {
    if (nuevo == null) return;
    setState(() {
      _tipoReferencia = nuevo;
      _referenciaId = null;
    });
    if (nuevo != 'ninguna') {
      _cargarReferencias(nuevo);
    }
  }

  Future<void> _guardar() async {
    if (!formKey.currentState!.validate()) return;
    if (_tipoReferencia != 'ninguna' && _referenciaId == null) {
      mostrarAlerta(context, 'Selecciona el elemento referenciado');
      return;
    }

    final titulo = _tituloCtrl.text.trim();
    final dias = int.tryParse(_diasCtrl.text.trim()) ?? 3;
    final refTabla = _tipoReferencia == 'ninguna' ? null : _tipoReferencia;
    final refId = _tipoReferencia == 'ninguna' ? null : _referenciaId;

    final dao = widget.db.recordatoriosDao;
    final fechaAlerta = normalizarFechaCivil(_fechaAlerta);
    await ejecutarGuardado(() async {
      if (widget.recordatorio == null) {
        await dao.insertRecordatorio(
          RecordatoriosCompanion.insert(
            titulo: titulo,
            fechaAlerta: fechaAlerta,
            diasAnticipacion: Value(dias),
            tipoNotificacion: Value(_tipoNotificacion),
            repetir: Value(_repetir),
            referenciaTabla: Value(refTabla),
            referenciaId: Value(refId),
            horaAviso: Value(_horaAviso),
            minutoAviso: Value(_minutoAviso),
            frecuenciaAviso: Value(_frecuenciaAviso),
          ),
        );
      } else {
        await dao.updateRecordatorio(
          widget.recordatorio!.copyWith(
            titulo: titulo,
            fechaAlerta: fechaAlerta,
            diasAnticipacion: dias,
            tipoNotificacion: _tipoNotificacion,
            repetir: _repetir,
            referenciaTabla: Value(refTabla),
            referenciaId: Value(refId),
            horaAviso: _horaAviso,
            minutoAviso: _minutoAviso,
            frecuenciaAviso: _frecuenciaAviso,
          ),
        );
        // DateTime.== también compara el flag isUtc (no solo el instante):
        // fechaAlerta guardado viene de drift como local pero representa
        // medianoche UTC, y el `fechaAlerta` recién normalizado aquí es
        // UTC-flagged — hay que comparar el instante con
        // isAtSameMomentAs, no con !=, o esto dispararía siempre.
        // Cambiar la hora también cuenta: si no, un recordatorio de aviso
        // único que ya sonó no volvería a sonar a la hora nueva.
        if (!widget.recordatorio!.fechaAlerta.isAtSameMomentAs(fechaAlerta) ||
            widget.recordatorio!.horaAviso != _horaAviso ||
            widget.recordatorio!.minutoAviso != _minutoAviso) {
          await dao.resetearDeduplicacion(widget.recordatorio!.id);
        }
      }
    });
  }

  Widget? _buildReferenciaSelector() {
    if (_tipoReferencia == 'ninguna') return null;
    if (_cargandoReferencias) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    switch (_tipoReferencia) {
      case 'deuda':
        if (_deudas.isEmpty) {
          return const Text('No tienes deudas activas');
        }
        return DropdownButtonFormField<int>(
          value: _referenciaId,
          decoration: const InputDecoration(
            labelText: 'Deuda',
            prefixIcon: Icon(Icons.credit_card),
          ),
          isExpanded: true,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          items: _deudas
              .map(
                (d) => DropdownMenuItem(
                  value: d.id,
                  child: Text(
                    '${d.acreedorNombre} — ${formatCOP(d.montoOriginal)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _referenciaId = v),
        );
      case 'prestamo':
        if (_prestamos.isEmpty) {
          return const Text('No tienes préstamos activos');
        }
        return DropdownButtonFormField<int>(
          value: _referenciaId,
          decoration: const InputDecoration(
            labelText: 'Préstamo',
            prefixIcon: Icon(Icons.handshake_outlined),
          ),
          isExpanded: true,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          items: _prestamos
              .map(
                (p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(
                    '${p.deudorNombre} — ${formatCOP(p.montoPrestado)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _referenciaId = v),
        );
      case 'gasto':
        if (_gastosFijos.isEmpty) {
          return const Text('No tienes gastos fijos activos');
        }
        return DropdownButtonFormField<int>(
          value: _referenciaId,
          decoration: const InputDecoration(
            labelText: 'Gasto fijo',
            prefixIcon: Icon(Icons.receipt_long),
          ),
          isExpanded: true,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          items: _gastosFijos
              .map(
                (g) => DropdownMenuItem(
                  value: g.id,
                  child: Text(
                    '${g.concepto} — ${formatCOP(g.monto)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _referenciaId = v),
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.recordatorio != null;
    final refSelector = _buildReferenciaSelector();
    final c = context.colores;
    const espacio = SizedBox(height: AppSpacing.md);

    return PaginaFormulario(
      formKey: formKey,
      kicker: 'Recordatorio',
      titulo: esEdicion ? 'Editar recordatorio' : 'Nuevo recordatorio',
      children: [
        FormSection(
          title: 'Detalles',
          icon: Icons.notifications_outlined,
          children: [
            CampoEtiquetado(
              etiqueta: 'Título',
              child: TextFormField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(
                  hintText: 'Pago de Netflix, cobrar a Juan...',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
            ),
            espacio,
            FilaCampos(
              children: [
                CampoEtiquetado(
                  etiqueta: 'Fecha de alerta',
                  child: DatePickerField(
                    label: 'Fecha de alerta',
                    mostrarEtiqueta: false,
                    icon: Icons.calendar_today,
                    value: _fechaAlerta,
                    onTap: _seleccionarFecha,
                  ),
                ),
                CampoEtiquetado(
                  etiqueta: 'Hora del aviso',
                  // Mismo aspecto que el campo de fecha.
                  child: Material(
                    color: c.relieve,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusCampo,
                      ),
                      side: BorderSide(
                        color: c.divisor,
                        width: AppSpacing.borde,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _seleccionarHora,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 50),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 18,
                                color: c.textoSecundario,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  formatHora12(_horaAviso, _minutoAviso),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: c.textoSecundario,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            espacio,
            CampoEtiquetado(
              etiqueta: 'Días de anticipación',
              ayuda: '¿Cuántos días antes de la fecha quieres el aviso?',
              child: TextFormField(
                controller: _diasCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) {
                    return 'Mínimo 1 día de anticipación';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        espacio,
        FormSection(
          title: 'Notificación',
          icon: Icons.notifications_active_outlined,
          children: [
            FilaCampos(
              children: [
                CampoEtiquetado(
                  etiqueta: '¿Cómo te avisamos?',
                  child: GrupoPildoras<String>(
                    opciones: const {
                      'sistema': 'Sistema',
                      'correo': 'Correo',
                      'ambos': 'Ambos',
                    },
                    valor: _tipoNotificacion,
                    onElegir: (v) => setState(() => _tipoNotificacion = v),
                  ),
                ),
                CampoEtiquetado(
                  etiqueta: '¿Cuántas veces?',
                  child: GrupoPildoras<String>(
                    opciones: const {
                      'unica': 'Un solo aviso',
                      'diaria': 'Cada día',
                    },
                    valor: _frecuenciaAviso,
                    onElegir: (v) => setState(() => _frecuenciaAviso = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _frecuenciaAviso == 'unica'
                  ? 'Un solo aviso: te avisa una sola vez.'
                  : 'Cada día: te recuerda todos los días hasta la fecha.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: c.textoSecundario),
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchTile(
              icon: Icons.repeat,
              title: '¿Se repite cada mes?',
              subtitle: 'Si está activo, se reprogramará automáticamente',
              value: _repetir,
              onChanged: (v) => setState(() => _repetir = v),
            ),
          ],
        ),
        espacio,
        FormSection(
          title: 'Referencia',
          icon: Icons.link,
          children: [
            CampoEtiquetado(
              etiqueta: 'Vincular con (opcional)',
              child: GrupoPildoras<String>(
                opciones: const {
                  'ninguna': 'Nada',
                  'deuda': 'Deuda',
                  'prestamo': 'Préstamo',
                  'gasto': 'Gasto fijo',
                },
                valor: _tipoReferencia,
                onElegir: _onTipoReferenciaChanged,
              ),
            ),
            if (refSelector != null) ...[espacio, refSelector],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        FormSaveButton(
          onPressed: _guardar,
          loading: guardando,
          label: esEdicion ? 'Guardar cambios' : 'Guardar recordatorio',
        ),
      ],
    );
  }
}
