import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  });

  final AppDatabase db;
  final int deudaId;

  /// Nombre de la deuda a la que se abona ("Tarjeta Nu").
  final String nombre;

  /// Lo que se debe hoy: el tope de lo que se puede abonar.
  final int saldoPendiente;

  /// Pago mínimo del mes; `null` si la deuda no lo tiene definido.
  final int? pagoMinimo;

  @override
  State<RegistrarPagoDialog> createState() => _RegistrarPagoDialogState();
}

class _RegistrarPagoDialogState extends State<RegistrarPagoDialog>
    with FormularioGuardadoMixin<RegistrarPagoDialog> {
  final _montoCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  void _ponerMonto(int monto) {
    final texto = formatCOPInput(monto);
    _montoCtrl.value = TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
    formKey.currentState?.validate();
  }

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'CO'),
    );
    if (f != null) setState(() => _fecha = f);
  }

  String? _validar(String? v) {
    final n = parseCOP(v ?? '');
    if (n == null || n <= 0) return 'Escribe un monto mayor a 0';
    // Margen de $1 por redondeo del interés, igual que antes.
    if (n - widget.saldoPendiente > 1) {
      return 'No puedes pagar más de lo que debes '
          '(${formatCOP(widget.saldoPendiente)})';
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
    final minimo = widget.pagoMinimo;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registrar pago',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${widget.nombre} · Saldo '
                  '${formatCOP(widget.saldoPendiente)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: c.textoSecundario,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Monto',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _montoCtrl,
                  autofocus: true,
                  style: monoStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixText: r'$ ',
                    prefixStyle: monoStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: c.textoSecundario,
                    ),
                    errorMaxLines: 2,
                  ),
                  keyboardType: TextInputType.number,
                  // Solo dígitos: ni signos, ni letras, ni negativos.
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CopInputFormatter(),
                  ],
                  validator: _validar,
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
                    ActionChip(
                      label: Text(
                        'Liquidar ${formatCOP(widget.saldoPendiente)}',
                      ),
                      onPressed: () => _ponerMonto(widget.saldoPendiente),
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: guardando
                            ? null
                            : () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: guardando ? null : _guardar,
                        child: Text(guardando ? 'Guardando...' : 'Guardar'),
                      ),
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
