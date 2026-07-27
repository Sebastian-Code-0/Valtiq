import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../services/interes_calculator.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/date_format.dart';
import '../../utils/error_messages.dart';
import '../../utils/format.dart';
import 'deuda_form.dart';

class DeudaDetalle extends StatefulWidget {
  const DeudaDetalle({super.key, required this.db, required this.deudaId});

  final AppDatabase db;
  final int deudaId;

  @override
  State<DeudaDetalle> createState() => _DeudaDetalleState();
}

class _DeudaDetalleState extends State<DeudaDetalle> {
  Stream<Deuda?> _deudaStream() {
    return (widget.db.select(
      widget.db.deudas,
    )..where((d) => d.id.equals(widget.deudaId))).watchSingleOrNull();
  }

  Stream<List<PagosDeudaData>> _abonosStream() {
    return widget.db.pagosDeudaDao.watchPagosDeDeuda(widget.deudaId);
  }

  Future<void> _editar(Deuda deuda) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeudaForm(db: widget.db, deuda: deuda),
      ),
    );
  }

  Future<void> _marcarComoPagada() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como pagada'),
        content: const Text(
          '¿Confirmas que ya pagaste esta deuda por completo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.db.deudasDao.marcarComoPagada(widget.deudaId, DateTime.now());
    if (mounted) Navigator.pop(context);
  }

  Future<void> _registrarAbono() async {
    await showDialog<bool>(
      context: context,
      builder: (_) =>
          _RegistrarAbonoDialog(db: widget.db, deudaId: widget.deudaId),
    );
  }

  Future<void> _confirmarEliminarAbono(PagosDeudaData pago) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar abono'),
        content: Text(
          '¿Eliminar este abono de ${formatCOP(pago.montoAbonado)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.alerta),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.db.pagosDeudaDao.deletePago(pago.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Deuda?>(
      stream: _deudaStream(),
      builder: (context, deudaSnap) {
        if (deudaSnap.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Error al cargar los datos.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }
        if (!deudaSnap.hasData &&
            deudaSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final deuda = deudaSnap.data;
        if (deuda == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Deuda')),
            body: const Center(child: Text('Deuda no encontrada')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(deuda.acreedorNombre),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Editar',
                onPressed: () => _editar(deuda),
              ),
              if (deuda.estado == 'activa')
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'pagada') _marcarComoPagada();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'pagada',
                      child: Text('Marcar como pagada'),
                    ),
                  ],
                ),
            ],
          ),
          body: StreamBuilder<List<PagosDeudaData>>(
            stream: _abonosStream(),
            builder: (context, abonosSnap) {
              if (abonosSnap.hasError) {
                return Center(
                  child: Text(
                    'Error al cargar los datos.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              final abonos = abonosSnap.data ?? const <PagosDeudaData>[];
              final totalAbonado = abonos.fold<double>(
                0,
                (sum, p) => sum + p.montoAbonado,
              );
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ResumenCard(deuda: deuda, totalAbonado: totalAbonado),
                    const SizedBox(height: AppSpacing.md),
                    _InfoCard(deuda: deuda),
                    const SizedBox(height: AppSpacing.md),
                    _AbonosSection(
                      abonos: abonos,
                      onRegistrar: _registrarAbono,
                      onEliminar: _confirmarEliminarAbono,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ResumenCard extends StatelessWidget {
  const _ResumenCard({required this.deuda, required this.totalAbonado});

  final Deuda deuda;
  final double totalAbonado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorSec = isDark
        ? AppColors.textoSecundarioOscuro
        : AppColors.textoSecundarioClaro;

    final resumen = InteresCalculator.resumenPrestamo(
      montoPrestado: deuda.montoOriginal,
      tasaInteres: deuda.tasaInteres,
      tipoInteres: deuda.tipoInteres,
      modalidadCalculo: deuda.modalidadCalculo,
      fechaPrestamo: deuda.fechaPrestamo,
      totalAbonado: totalAbonado,
    );
    final interes = resumen['interesAcumulado']!;
    final totalConInteres = resumen['totalConInteres']!;
    final saldoReal = resumen['saldoPendiente']!;
    final colorSaldo = saldoReal > 0 ? AppColors.alerta : AppColors.positivo;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fila('Monto original:', deuda.montoOriginal, colorSec, theme),
            const SizedBox(height: AppSpacing.sm),
            _fila(
              'Interés acumulado:',
              interes,
              colorSec,
              theme,
              colorValor: AppColors.alerta,
            ),
            const SizedBox(height: AppSpacing.sm),
            _fila(
              'Total con interés:',
              totalConInteres,
              colorSec,
              theme,
              negrita: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            _fila(
              'Total abonado:',
              totalAbonado,
              colorSec,
              theme,
              colorValor: AppColors.positivo,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo pendiente:',
                  style: theme.textTheme.titleSmall?.copyWith(color: colorSec),
                ),
                Flexible(
                  child: Text(
                    formatCOP(saldoReal),
                    style: monoStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorSaldo,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fila(
    String label,
    double valor,
    Color colorSec,
    ThemeData theme, {
    Color? colorValor,
    bool negrita = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: colorSec),
        ),
        Flexible(
          child: Text(
            formatCOP(valor),
            style: monoStyle(
              fontSize: 15,
              fontWeight: negrita ? FontWeight.bold : FontWeight.w500,
              color: colorValor,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.deuda});

  final Deuda deuda;

  String _fmtTasa(double t) {
    if (t == t.truncateToDouble()) return t.toStringAsFixed(0);
    return t.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorSec = isDark
        ? AppColors.textoSecundarioOscuro
        : AppColors.textoSecundarioClaro;
    final tieneInteres = deuda.tasaInteres > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _fila(
              'Tasa:',
              tieneInteres ? '${_fmtTasa(deuda.tasaInteres)}%' : 'Sin interés',
              colorSec,
              theme,
            ),
            _fila('Tipo:', deuda.tipoInteres, colorSec, theme),
            _fila('Modalidad:', deuda.modalidadCalculo, colorSec, theme),
            _fila(
              'Fecha préstamo:',
              formatFecha(deuda.fechaPrestamo),
              colorSec,
              theme,
            ),
            _fila(
              'Fecha límite:',
              deuda.fechaLimite != null
                  ? formatFecha(deuda.fechaLimite!)
                  : 'Sin fecha',
              colorSec,
              theme,
            ),
            if (deuda.cuotaMensual != null)
              _fila(
                'Cuota mensual:',
                formatCOP(deuda.cuotaMensual!),
                colorSec,
                theme,
              ),
            if (deuda.notas.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Notas:',
                style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
              ),
              const SizedBox(height: 2),
              Text(deuda.notas, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fila(String label, String valor, Color colorSec, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.labelColumnWidth,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
            ),
          ),
          Expanded(child: Text(valor, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _AbonosSection extends StatelessWidget {
  const _AbonosSection({
    required this.abonos,
    required this.onRegistrar,
    required this.onEliminar,
  });

  final List<PagosDeudaData> abonos;
  final VoidCallback onRegistrar;
  final Future<void> Function(PagosDeudaData) onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorSec = isDark
        ? AppColors.textoSecundarioOscuro
        : AppColors.textoSecundarioClaro;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Abonos realizados',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onRegistrar,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Registrar abono',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (abonos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: Text(
                    'Sin abonos registrados',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorSec,
                    ),
                  ),
                ),
              )
            else
              ...abonos.map(
                (p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onLongPress: () => onEliminar(p),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                        horizontal: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.payments,
                            size: 18,
                            color: AppColors.positivo,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatFecha(p.fechaPago),
                                  style: theme.textTheme.bodyMedium,
                                ),
                                if (p.notas.isNotEmpty)
                                  Text(
                                    p.notas,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorSec,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Text(
                              formatCOP(p.montoAbonado),
                              style: monoStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.positivo,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RegistrarAbonoDialog extends StatefulWidget {
  const _RegistrarAbonoDialog({required this.db, required this.deudaId});

  final AppDatabase db;
  final int deudaId;

  @override
  State<_RegistrarAbonoDialog> createState() => _RegistrarAbonoDialogState();
}

class _RegistrarAbonoDialogState extends State<_RegistrarAbonoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();
  bool _guardando = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'CO'),
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
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
    try {
      await widget.db.pagosDeudaDao.insertPago(
        PagosDeudaCompanion.insert(
          deudaId: widget.deudaId,
          montoAbonado: monto,
          fechaPago: _fecha,
          notas: Value(_notasCtrl.text.trim()),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar abono'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  if (n == null || n <= 0) return 'Debe ser > 0';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: _pickFecha,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(formatFecha(_fecha)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: Text(_guardando ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}
