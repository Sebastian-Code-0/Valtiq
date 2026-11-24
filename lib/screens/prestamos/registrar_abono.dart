import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

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
      fechaInicio: prestamo.fechaPrestamo,
    ),
  );
  if (guardado != true || !context.mounted) return false;

  final pagosActuales = await db.prestamosDao.getPagosDelPrestamo(prestamo.id);
  final totalAbonadoActual = pagosActuales.fold<int>(
    0,
    (sum, p) => sum + p.montoAbonado,
  );
  // Se mira en la fecha del último abono: si se saldó con una fecha pasada,
  // ahí se congela el interés.
  final ultimoAbono = pagosActuales
      .map((p) => fechaCivilGuardada(p.fechaPago))
      .reduce((a, b) => a.isAfter(b) ? a : b);
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
    fechaFin: ultimoAbono,
  );
  final saldoPendienteActual =
      resumenActual['totalConInteres']! - resumenActual['totalAbonado']!;
  if (saldoPendienteActual > 0) return false;

  await db.prestamosDao.marcarComoPagado(prestamo.id, ultimoAbono);
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
    this.fechaInicio,
  });

  final AppDatabase db;
  final int prestamoId;

  /// A quién se le prestó.
  final String nombre;

  /// Lo que falta por cobrar hoy: el tope de lo que se puede abonar.
  final int saldoPendiente;

  /// Cuándo empezó el préstamo: no se puede registrar un abono anterior.
  final DateTime? fechaInicio;

  @override
  State<RegistrarAbonoDialog> createState() => _RegistrarAbonoDialogState();
}

class _RegistrarAbonoDialogState extends State<RegistrarAbonoDialog>
    with FormularioGuardadoMixin<RegistrarAbonoDialog> {
  final _montoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();

  /// El préstamo y sus abonos, para saber el saldo a una fecha pasada.
  Prestamo? _prestamo;
  List<AbonoInteres> _abonos = const [];

  /// El monto salió de "Todo": sigue al saldo de la fecha.
  bool _esTodo = false;

  /// Lo que deja el préstamo en cero con un abono en la fecha elegida.
  int get _saldo {
    final p = _prestamo;
    if (p == null) return widget.saldoPendiente;
    return InteresCalculator.montoParaLiquidar(
      montoPrestado: p.montoPrestado,
      tasaInteres: p.tasaInteres,
      tipoInteres: p.tipoInteres,
      modalidadCalculo: p.modalidadCalculo,
      fechaPrestamo: p.fechaPrestamo,
      tipoAmortizacion: p.tipoAmortizacion,
      abonos: _abonos,
      fecha: normalizarFechaCivil(_fecha),
    );
  }

  @override
  void initState() {
    super.initState();
    _cargarPrestamo();
  }

  Future<void> _cargarPrestamo() async {
    final p = await widget.db.prestamosDao.getPrestamoById(widget.prestamoId);
    final pagos = await widget.db.prestamosDao.getPagosDelPrestamo(
      widget.prestamoId,
    );
    if (!mounted || p == null) return;
    setState(() {
      _prestamo = p;
      _abonos = [
        for (final a in pagos)
          AbonoInteres(fecha: a.fechaPago, monto: a.montoAbonado),
      ];
    });
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  void _ponerMonto(int monto, {bool todo = false}) {
    _esTodo = todo;
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
    // Un préstamo con fecha futura solo deja elegir hoy.
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
    if (_esTodo) {
      _ponerMonto(_saldo, todo: true);
    } else if (_montoCtrl.text.isNotEmpty) {
      formKey.currentState?.validate();
    }
  }

  String? _validar(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requerido';
    final n = parseCOP(v);
    if (n == null) return 'Monto inválido';
    if (n <= 0) return 'Escribe un monto mayor a 0';
    // Margen de $1 por redondeo del interés.
    final saldo = _saldo;
    if (n - saldo > 1) {
      return 'No puede superar lo que debían en esa fecha '
          '(${formatCOP(saldo)})';
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
    final saldo = _saldo;
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
                  inputFormatters: [CopInputFormatter()],
                  validator: _validar,
                  onChanged: (_) => _esTodo = false,
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
                        onPressed: () => _ponerMonto(saldo, todo: true),
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
