import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../services/interes_calculator.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/date_format.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/format.dart';
import '../../utils/formulario_guardado_mixin.dart';
import '../../utils/notificaciones.dart';

/// Congela el cálculo de interés en la fecha real de pago para un préstamo
/// ya pagado — sin esto, `InteresCalculator` sigue calculando hasta HOY por
/// defecto (ver `fechaFin` en `interes_calculator.dart`), y un préstamo
/// cerrado hace meses mostraría interés creciendo para siempre.
DateTime? fechaFinCongeladaPrestamo(Prestamo prestamo) {
  if (prestamo.estado != 'pagado' || prestamo.fechaPagoReal == null) {
    return null;
  }
  return fechaCivilGuardada(prestamo.fechaPagoReal!);
}

/// Abre la ventana para registrar un abono a [prestamo] y, si con ese abono
/// quedó en cero, lo marca como pagado (pasa solo a "Cobrados") y avisa.
///
/// [abonos] son los abonos que el préstamo ya tiene. Devuelve `true` si el
/// préstamo quedó pagado por completo.
Future<bool> registrarAbonoPrestamo(
  BuildContext context,
  AppDatabase db,
  Prestamo prestamo,
  List<AbonoInteres> abonos,
) async {
  final totalAbonado = abonos.fold<int>(0, (s, a) => s + a.monto);
  final resumen = InteresCalculator.resumenPrestamo(
    montoPrestado: prestamo.montoPrestado,
    tasaInteres: prestamo.tasaInteres,
    tipoInteres: prestamo.tipoInteres,
    modalidadCalculo: prestamo.modalidadCalculo,
    fechaPrestamo: prestamo.fechaPrestamo,
    totalAbonado: totalAbonado,
    tipoAmortizacion: prestamo.tipoAmortizacion,
    abonos: abonos,
    fechaFin: fechaFinCongeladaPrestamo(prestamo),
  );
  // Sin recortar a 0: resumen['saldoPendiente'] sí lo recorta (para no
  // mostrar saldo negativo en la UI), pero eso permitiría abonar de a $1
  // indefinidamente una vez saldado el préstamo, ya que el recorte nunca
  // deja ver que ya se sobrepasó.
  final saldoPendiente = resumen['totalConInteres']! - resumen['totalAbonado']!;
  final guardado = await showDialog<bool>(
    context: context,
    builder: (_) => RegistrarAbonoDialog(
      db: db,
      prestamoId: prestamo.id,
      nombre: prestamo.deudorNombre,
      saldoPendiente: saldoPendiente,
    ),
  );
  if (guardado != true || !context.mounted) return false;

  final pagosActuales = await db.prestamosDao.getPagosDelPrestamo(prestamo.id);
  final totalAbonadoActual = pagosActuales.fold<int>(
    0,
    (sum, p) => sum + p.montoAbonado,
  );
  final resumenActual = InteresCalculator.resumenPrestamo(
    montoPrestado: prestamo.montoPrestado,
    tasaInteres: prestamo.tasaInteres,
    tipoInteres: prestamo.tipoInteres,
    modalidadCalculo: prestamo.modalidadCalculo,
    fechaPrestamo: prestamo.fechaPrestamo,
    totalAbonado: totalAbonadoActual,
    tipoAmortizacion: prestamo.tipoAmortizacion,
    abonos: pagosActuales
        .map((p) => AbonoInteres(fecha: p.fechaPago, monto: p.montoAbonado))
        .toList(),
  );
  final saldoPendienteActual =
      resumenActual['totalConInteres']! - resumenActual['totalAbonado']!;
  if (saldoPendienteActual > 0) return false;

  await db.prestamosDao.marcarComoPagado(
    prestamo.id,
    normalizarFechaCivil(DateTime.now()),
  );
  if (context.mounted) {
    mostrarExito(
      context,
      'Préstamo "${prestamo.deudorNombre}" ha sido pagado por completo '
      'y se movió a cobrados.',
    );
  }
  return true;
}

/// Ventana pequeña y centrada para registrar un abono recibido.
///
/// Devuelve `true` (vía `Navigator.pop`) si el abono se guardó.
class RegistrarAbonoDialog extends StatefulWidget {
  const RegistrarAbonoDialog({
    super.key,
    required this.db,
    required this.prestamoId,
    required this.nombre,
    required this.saldoPendiente,
  });

  final AppDatabase db;
  final int prestamoId;

  /// A quién se le prestó.
  final String nombre;

  /// Lo que falta por cobrar hoy: el tope de lo que se puede abonar.
  final int saldoPendiente;

  @override
  State<RegistrarAbonoDialog> createState() => _RegistrarAbonoDialogState();
}

class _RegistrarAbonoDialogState extends State<RegistrarAbonoDialog>
    with FormularioGuardadoMixin<RegistrarAbonoDialog> {
  final _montoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notasCtrl.dispose();
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
    if (v == null || v.trim().isEmpty) return 'Requerido';
    final n = parseCOP(v);
    if (n == null || n <= 0) return 'Escribe un monto mayor a 0';
    // Margen de $1 por redondeo del interés.
    if (n - widget.saldoPendiente > 1) {
      return 'No puede superar el saldo pendiente '
          '(${formatCOP(widget.saldoPendiente)})';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!formKey.currentState!.validate()) return;
    final monto = parseCOP(_montoCtrl.text);
    if (monto == null) {
      mostrarAlerta(context, 'Monto inválido. El máximo es $textoMaxMonto.');
      return;
    }
    await ejecutarGuardado(() async {
      await widget.db.prestamosDao.insertPago(
        PagosRecibidosCompanion.insert(
          prestamoId: widget.prestamoId,
          montoAbonado: monto,
          fechaPago: normalizarFechaCivil(_fecha),
          notas: Value(_notasCtrl.text.trim()),
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
    final saldo = widget.saldoPendiente;
    final rotulo = theme.textTheme.bodySmall?.copyWith(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: c.textoSecundario,
    );

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
                  'Registrar abono',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${widget.nombre} · Pendiente ${formatCOP(saldo)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    color: c.textoSecundario,
                  ),
                ),
                const SizedBox(height: 18),
                Text('Monto', style: rotulo),
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CopInputFormatter(),
                  ],
                  validator: _validar,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (saldo > 1)
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      ActionChip(
                        label: Text('Mitad ${formatCOP((saldo / 2).round())}'),
                        onPressed: () => _ponerMonto((saldo / 2).round()),
                      ),
                      ActionChip(
                        label: Text('Todo ${formatCOP(saldo)}'),
                        onPressed: () => _ponerMonto(saldo),
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
                const SizedBox(height: AppSpacing.sm),
                Text('Notas (opcional)', style: rotulo),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(controller: _notasCtrl, maxLines: 2),
                const SizedBox(height: AppSpacing.md),
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
