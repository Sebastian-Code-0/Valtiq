import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/error_messages.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';

class RecordatorioForm extends StatefulWidget {
  const RecordatorioForm({super.key, required this.db, this.recordatorio});

  final AppDatabase db;
  final Recordatorio? recordatorio;

  @override
  State<RecordatorioForm> createState() => _RecordatorioFormState();
}

class _RecordatorioFormState extends State<RecordatorioForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tituloCtrl;
  late final TextEditingController _diasCtrl;

  late DateTime _fechaAlerta;
  late String _tipoNotificacion;
  late bool _repetir;
  late String _tipoReferencia;
  int? _referenciaId;
  bool _guardando = false;

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
    _fechaAlerta =
        r?.fechaAlerta ?? DateTime.now().add(const Duration(days: 1));
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
    if (!_formKey.currentState!.validate()) return;
    if (_tipoReferencia != 'ninguna' && _referenciaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el elemento referenciado')),
      );
      return;
    }
    setState(() => _guardando = true);

    final titulo = _tituloCtrl.text.trim();
    final dias = int.tryParse(_diasCtrl.text.trim()) ?? 3;
    final refTabla = _tipoReferencia == 'ninguna' ? null : _tipoReferencia;
    final refId = _tipoReferencia == 'ninguna' ? null : _referenciaId;

    final dao = widget.db.recordatoriosDao;
    try {
      if (widget.recordatorio == null) {
        await dao.insertRecordatorio(
          RecordatoriosCompanion.insert(
            titulo: titulo,
            fechaAlerta: _fechaAlerta,
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
            fechaAlerta: _fechaAlerta,
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
        if (widget.recordatorio!.fechaAlerta != _fechaAlerta) {
          await dao.resetearDeduplicacion(widget.recordatorio!.id);
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensajeAmigableGuardado(e))));
      }
    }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar recordatorio' : 'Nuevo recordatorio'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            FormSection(
              title: 'Detalles',
              icon: Icons.notifications_outlined,
              children: [
                TextFormField(
                  controller: _tituloCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Pago de Netflix, cobrar a Juan...',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DatePickerField(
                  label: 'Fecha de alerta',
                  icon: Icons.calendar_today,
                  value: _fechaAlerta,
                  onTap: _seleccionarFecha,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _diasCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Días de anticipación',
                    hintText: '¿Cuántos días antes quieres el aviso?',
                    prefixIcon: Icon(Icons.alarm),
                  ),
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
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FormSection(
              title: 'Notificación',
              icon: Icons.notifications_active_outlined,
              children: [
                DropdownButtonFormField<String>(
                  value: _tipoNotificacion,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de notificación',
                    prefixIcon: Icon(Icons.send_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'sistema', child: Text('Sistema')),
                    DropdownMenuItem(value: 'correo', child: Text('Correo')),
                    DropdownMenuItem(value: 'ambos', child: Text('Ambos')),
                  ],
                  onChanged: (v) =>
                      setState(() => _tipoNotificacion = v ?? 'sistema'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: _frecuenciaAviso,
                  decoration: const InputDecoration(
                    labelText: 'Frecuencia del aviso',
                    prefixIcon: Icon(Icons.repeat_one_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'unica',
                      child: Text('Un solo aviso'),
                    ),
                    DropdownMenuItem(
                      value: 'diaria',
                      child: Text('Avisar cada día'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _frecuenciaAviso = v ?? 'unica'),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Único: avisa una sola vez. Diario: te recuerda cada día hasta la fecha.',
                  style: Theme.of(context).textTheme.bodySmall,
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
            const SizedBox(height: AppSpacing.md),
            FormSection(
              title: 'Referencia',
              icon: Icons.link,
              children: [
                DropdownButtonFormField<String>(
                  value: _tipoReferencia,
                  decoration: const InputDecoration(
                    labelText: 'Vincular con',
                    prefixIcon: Icon(Icons.link),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'ninguna',
                      child: Text('Sin referencia'),
                    ),
                    DropdownMenuItem(value: 'deuda', child: Text('Deuda')),
                    DropdownMenuItem(
                      value: 'prestamo',
                      child: Text('Préstamo'),
                    ),
                    DropdownMenuItem(value: 'gasto', child: Text('Gasto fijo')),
                  ],
                  onChanged: _onTipoReferenciaChanged,
                ),
                if (refSelector != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  refSelector,
                ],
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
