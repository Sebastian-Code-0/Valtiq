import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/date_format.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/format.dart';
import '../../utils/formulario_guardado_mixin.dart';
import '../../utils/notificaciones.dart';

/// Ventana pequeña y centrada para registrar un pago a una deuda.
///
/// Devuelve `true` (vía `Navigator.pop`) si el pago se guardó.
class RegistrarPagoDialog extends StatefulWidget {
  const RegistrarPagoDialog({
    super.key,
    required this.db,
    required this.deudaId,
    required this.nombre,
    required this.saldoPendiente,
    this.pagoMinimo,
    this.pagoDelPlan,
    this.fechaInicio,
    this.saldoEnFecha,
  });

  final AppDatabase db;
  final int deudaId;

  /// Nombre de la deuda a la que se abona ("Tarjeta Nu").
  final String nombre;

  /// Lo que se debe hoy: el tope de lo que se puede abonar.
  final int saldoPendiente;

  /// Pago mínimo del mes; `null` si la deuda no lo tiene definido.
  final int? pagoMinimo;

  /// Lo que el Plan de pago dice pagarle este mes (mínimo + extra, menos lo
  /// ya pagado este mes); resuelve a `null` si este mes no le toca nada.
  final Future<int?>? pagoDelPlan;

  /// Cuándo empezó la deuda: no se puede registrar un pago anterior.
  final DateTime? fechaInicio;

  /// Lo que se debía en una fecha. Con una fecha pasada el tope y "Liquidar"
  /// son los de ese día (todavía no se había causado el interés de después).
  final int Function(DateTime fecha)? saldoEnFecha;

  @override
  State<RegistrarPagoDialog> createState() => _RegistrarPagoDialogState();
}

class _RegistrarPagoDialogState extends State<RegistrarPagoDialog>
    with FormularioGuardadoMixin<RegistrarPagoDialog> {
  final _montoCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();
  int? _delPlan;

  /// El monto escrito salió del botón "Liquidar": sigue al saldo de la fecha.
  bool _esLiquidar = false;

  int get _saldo => widget.saldoEnFecha?.call(_fecha) ?? widget.saldoPendiente;

  @override
  void initState() {
    super.initState();
    widget.pagoDelPlan?.then((v) {
      if (mounted) setState(() => _delPlan = v);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  void _ponerMonto(int monto, {bool liquidar = false}) {
    _esLiquidar = liquidar;
    final texto = formatCOPInput(monto);
    _montoCtrl.value = TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
    formKey.currentState?.validate();
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicio = widget.fechaInicio == null
        ? null
        : fechaCivilGuardada(widget.fechaInicio!);
    var primera = inicio == null
        ? DateTime(2000)
        : DateTime(inicio.year, inicio.month, inicio.day);
    // Una deuda que empieza en el futuro solo deja elegir hoy.
    if (primera.isAfter(hoy)) primera = hoy;
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha.isBefore(primera) ? primera : _fecha,
      firstDate: primera,
      lastDate: ahora,
      locale: const Locale('es', 'CO'),
    );
    if (f == null || !mounted) return;
    setState(() => _fecha = f);
    if (_esLiquidar) {
      _ponerMonto(_saldo, liquidar: true);
    } else if (_montoCtrl.text.isNotEmpty) {
      formKey.currentState?.validate();
    }
  }

  String? _validar(String? v) {
    final n = parseCOP(v ?? '');
    if (n == null) return 'Monto inválido';
    if (n <= 0) return 'Escribe un monto mayor a 0';
    // Margen de $1 por redondeo del interés, igual que antes.
    final saldo = _saldo;
    if (n - saldo > 1) {
      return 'No puedes pagar más de lo que debías en esa fecha '
          '(${formatCOP(saldo)})';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!formKey.currentState!.validate()) return;
    final monto = parseCOP(_montoCtrl.text);
    if (monto == null) {
      mostrarAlerta(context, 'Monto inválido. Verifica el valor ingresado.');
      return;
    }
    await ejecutarGuardado(() async {
      await widget.db.pagosDeudaDao.insertPago(
        PagosDeudaCompanion.insert(
          deudaId: widget.deudaId,
          montoAbonado: monto,
          fechaPago: normalizarFechaCivil(_fecha),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    final hoy = DateTime.now();
    final esHoy =
        _fecha.year == hoy.year &&
        _fecha.month == hoy.month &&
        _fecha.day == hoy.day;
    final saldo = _saldo;
    final minimo = widget.pagoMinimo == null
        ? null
        : math.min(widget.pagoMinimo!, saldo);
    // Solo si dice algo distinto de "Mínimo" y "Liquidar".
    final delPlan = _delPlan;
    final mostrarPlan =
        delPlan != null && delPlan > 0 && delPlan != minimo && delPlan < saldo;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registrar pago',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${widget.nombre} · Saldo ${formatCOP(saldo)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    color: c.textoSecundario,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Monto',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: c.textoSecundario,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _montoCtrl,
                  autofocus: true,
                  style: monoStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: '0',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    prefixText: r'$ ',
                    prefixStyle: monoStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: c.textoSecundario,
                    ),
                    errorMaxLines: 2,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [CopInputFormatter()],
                  validator: _validar,
                  onChanged: (_) => _esLiquidar = false,
                  onFieldSubmitted: (_) => _guardar(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (minimo != null)
                      ActionChip(
                        label: Text('Mínimo ${formatCOP(minimo)}'),
                        onPressed: () => _ponerMonto(minimo),
                      ),
                    if (mostrarPlan)
                      ActionChip(
                        key: const ValueKey('pago-del-plan'),
                        label: Text('Lo del plan ${formatCOP(delPlan)}'),
                        onPressed: () => _ponerMonto(delPlan),
                      ),
                    ActionChip(
                      label: Text('Liquidar ${formatCOP(saldo)}'),
                      onPressed: () => _ponerMonto(saldo, liquidar: true),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _elegirFecha,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      esHoy
                          ? 'Fecha: hoy, ${formatDiaMesCorto(_fecha)}'
                          : 'Fecha: ${formatFecha(_fecha)}',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // A la derecha, uno al lado del otro; si no caben (celular
                // angosto), uno debajo del otro.
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  overflowAlignment: OverflowBarAlignment.end,
                  spacing: AppSpacing.sm,
                  overflowSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton(
                      onPressed: guardando
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: guardando ? null : _guardar,
                      child: Text(guardando ? 'Guardando...' : 'Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
