import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../services/interes_calculator.dart';
import '../../theme/theme.dart';
import '../../utils/currency_input.dart';
import '../../utils/date_format.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../../utils/formulario_guardado_mixin.dart';
import '../../utils/notificaciones.dart';
import 'prestamo_form.dart';

class PrestamoDetalle extends StatefulWidget {
  const PrestamoDetalle({
    super.key,
    required this.db,
    required this.prestamoId,
  });

  final AppDatabase db;
  final int prestamoId;

  @override
  State<PrestamoDetalle> createState() => _PrestamoDetalleState();
}

class _PrestamoDetalleState extends State<PrestamoDetalle> {
  late final Stream<Prestamo?> _prestamoStream;
  late final Stream<List<PagosRecibido>> _pagosStream;

  @override
  void initState() {
    super.initState();
    _prestamoStream = (widget.db.select(
      widget.db.prestamos,
    )..where((p) => p.id.equals(widget.prestamoId))).watchSingleOrNull();
    _pagosStream =
        (widget.db.select(widget.db.pagosRecibidos)
              ..where((p) => p.prestamoId.equals(widget.prestamoId))
              ..orderBy([(p) => OrderingTerm.desc(p.fechaPago)]))
            .watch();
  }

  Future<void> _editar(Prestamo prestamo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrestamoForm(db: widget.db, prestamo: prestamo),
      ),
    );
  }

  Future<void> _marcarComoPagado() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como pagado'),
        content: const Text(
          '¿Confirmas que este préstamo ya fue pagado por completo?',
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
    await widget.db.prestamosDao.marcarComoPagado(widget.prestamoId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _registrarPago(Prestamo prestamo, int totalAbonado) async {
    final resumen = InteresCalculator.resumenPrestamo(
      montoPrestado: prestamo.montoPrestado,
      tasaInteres: prestamo.tasaInteres,
      tipoInteres: prestamo.tipoInteres,
      modalidadCalculo: prestamo.modalidadCalculo,
      fechaPrestamo: prestamo.fechaPrestamo,
      totalAbonado: totalAbonado,
    );
    // Sin recortar a 0: resumen['saldoPendiente'] sí lo recorta (para no
    // mostrar saldo negativo en la UI), pero eso permitiría abonar de a $1
    // indefinidamente una vez saldado el préstamo, ya que el recorte nunca
    // deja ver que ya se sobrepasó.
    final saldoPendiente =
        resumen['totalConInteres']! - resumen['totalAbonado']!;
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => _RegistrarPagoDialog(
        db: widget.db,
        prestamoId: widget.prestamoId,
        saldoPendiente: saldoPendiente,
      ),
    );
    if (guardado == true && mounted) {
      final totalAbonadoActual = await widget.db.prestamosDao.getTotalAbonado(
        widget.prestamoId,
      );
      final resumenActual = InteresCalculator.resumenPrestamo(
        montoPrestado: prestamo.montoPrestado,
        tasaInteres: prestamo.tasaInteres,
        tipoInteres: prestamo.tipoInteres,
        modalidadCalculo: prestamo.modalidadCalculo,
        fechaPrestamo: prestamo.fechaPrestamo,
        totalAbonado: totalAbonadoActual,
      );
      final saldoPendienteActual =
          resumenActual['totalConInteres']! - resumenActual['totalAbonado']!;
      if (saldoPendienteActual <= 0) {
        await widget.db.prestamosDao.marcarComoPagado(widget.prestamoId);
        if (mounted) {
          mostrarExito(
            context,
            'Préstamo "${prestamo.deudorNombre}" ha sido pagado por completo '
            'y se movió a pagados.',
          );
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _confirmarEliminarPago(PagosRecibido pago) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar pago'),
        content: Text(
          '¿Eliminar este pago de ${formatCOP(pago.montoAbonado)}?',
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
      await widget.db.prestamosDao.deletePago(pago.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Prestamo?>(
      stream: _prestamoStream,
      builder: (context, prestamoSnap) {
        if (prestamoSnap.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Error al cargar los datos.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }
        if (!prestamoSnap.hasData &&
            prestamoSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final prestamo = prestamoSnap.data;
        if (prestamo == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Préstamo')),
            body: const Center(child: Text('Préstamo no encontrado')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(prestamo.deudorNombre),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Editar',
                onPressed: () => _editar(prestamo),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'pagado') _marcarComoPagado();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'pagado',
                    child: Text('Marcar como pagado'),
                  ),
                ],
              ),
            ],
          ),
          body: StreamBuilder<List<PagosRecibido>>(
            stream: _pagosStream,
            builder: (context, pagosSnap) {
              if (pagosSnap.hasError) {
                return Center(
                  child: Text(
                    'Error al cargar los datos.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              final pagos = pagosSnap.data ?? const <PagosRecibido>[];
              final totalAbonado = pagos.fold<int>(
                0,
                (sum, p) => sum + p.montoAbonado,
              );
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ResumenCard(
                      prestamo: prestamo,
                      totalAbonado: totalAbonado,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InfoCard(prestamo: prestamo),
                    const SizedBox(height: AppSpacing.md),
                    _PagosSection(
                      pagos: pagos,
                      onRegistrar: () => _registrarPago(prestamo, totalAbonado),
                      onEliminar: _confirmarEliminarPago,
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
  const _ResumenCard({required this.prestamo, required this.totalAbonado});

  final Prestamo prestamo;
  final int totalAbonado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorSec = theme.colorSecundario;

    final resumen = InteresCalculator.resumenPrestamo(
      montoPrestado: prestamo.montoPrestado,
      tasaInteres: prestamo.tasaInteres,
      tipoInteres: prestamo.tipoInteres,
      modalidadCalculo: prestamo.modalidadCalculo,
      fechaPrestamo: prestamo.fechaPrestamo,
      totalAbonado: totalAbonado,
    );

    final saldo = resumen['saldoPendiente']!;
    final colorSaldo = saldo > 0 ? AppColors.alerta : AppColors.positivo;
    final sinInteres = prestamo.montoPrestado - totalAbonado;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _filaResumen(
              label: 'Monto prestado:',
              valor: resumen['montoPrestado']!,
              colorSec: colorSec,
            ),
            const SizedBox(height: AppSpacing.sm),
            _filaResumen(
              label: 'Interés acumulado:',
              valor: resumen['interesAcumulado']!,
              colorValor: theme.colorScheme.primary,
              colorSec: colorSec,
            ),
            const SizedBox(height: AppSpacing.sm),
            _filaResumen(
              label: 'Total con interés:',
              valor: resumen['totalConInteres']!,
              negrita: true,
              colorSec: colorSec,
            ),
            const SizedBox(height: AppSpacing.sm),
            _filaResumen(
              label: 'Total abonado:',
              valor: resumen['totalAbonado']!,
              colorValor: AppColors.positivo,
              colorSec: colorSec,
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
                    formatCOP(saldo),
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
            const Divider(height: AppSpacing.lg),
            _filaResumen(
              label: 'Sin interés debería:',
              valor: sinInteres < 0 ? 0 : sinInteres,
              colorSec: colorSec,
              chico: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            _filaResumen(
              label: 'Diferencia por interés:',
              valor: resumen['gananciaInteres']!,
              colorValor: theme.colorScheme.primary,
              colorSec: colorSec,
              chico: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaResumen({
    required String label,
    required int valor,
    required Color colorSec,
    Color? colorValor,
    bool negrita = false,
    bool chico = false,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style:
                  (chico
                          ? theme.textTheme.bodySmall
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(color: colorSec),
            ),
            Flexible(
              child: Text(
                formatCOP(valor),
                style: monoStyle(
                  fontSize: chico ? 13 : 15,
                  fontWeight: negrita ? FontWeight.bold : FontWeight.w500,
                  color: colorValor,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.prestamo});

  final Prestamo prestamo;

  String _fmtTasa(double t) {
    if (t == t.truncateToDouble()) return t.toStringAsFixed(0);
    return t.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorSec = theme.colorSecundario;

    final tieneInteres = prestamo.tasaInteres > 0;

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
            InfoRow(
              label: 'Tasa:',
              valor: tieneInteres
                  ? '${_fmtTasa(prestamo.tasaInteres)}%'
                  : 'Sin interés',
              colorSec: colorSec,
              theme: theme,
            ),
            InfoRow(
              label: 'Tipo:',
              valor: prestamo.tipoInteres,
              colorSec: colorSec,
              theme: theme,
            ),
            InfoRow(
              label: 'Modalidad:',
              valor: prestamo.modalidadCalculo,
              colorSec: colorSec,
              theme: theme,
            ),
            InfoRow(
              label: 'Fecha préstamo:',
              valor: formatFecha(prestamo.fechaPrestamo),
              colorSec: colorSec,
              theme: theme,
            ),
            InfoRow(
              label: 'Fecha pactada:',
              valor: prestamo.fechaPactadaPago != null
                  ? formatFecha(prestamo.fechaPactadaPago!)
                  : 'Sin fecha',
              colorSec: colorSec,
              theme: theme,
            ),
            if (prestamo.deudorContacto.isNotEmpty)
              InfoRow(
                label: 'Contacto:',
                valor: prestamo.deudorContacto,
                colorSec: colorSec,
                theme: theme,
              ),
            if (prestamo.notas.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Notas:',
                style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
              ),
              const SizedBox(height: 2),
              Text(prestamo.notas, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class _PagosSection extends StatelessWidget {
  const _PagosSection({
    required this.pagos,
    required this.onRegistrar,
    required this.onEliminar,
  });

  final List<PagosRecibido> pagos;
  final VoidCallback onRegistrar;
  final Future<void> Function(PagosRecibido) onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorSec = theme.colorSecundario;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Pagos recibidos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onRegistrar,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Registrar pago',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (pagos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: Text(
                    'Sin pagos registrados',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorSec,
                    ),
                  ),
                ),
              )
            else
              ...pagos.map(
                (p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onLongPress: () => onEliminar(p),
                    onSecondaryTap: () => onEliminar(p),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                        horizontal: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
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

class _RegistrarPagoDialog extends StatefulWidget {
  const _RegistrarPagoDialog({
    required this.db,
    required this.prestamoId,
    required this.saldoPendiente,
  });

  final AppDatabase db;
  final int prestamoId;
  final int saldoPendiente;

  @override
  State<_RegistrarPagoDialog> createState() => _RegistrarPagoDialogState();
}

class _RegistrarPagoDialogState extends State<_RegistrarPagoDialog>
    with FormularioGuardadoMixin<_RegistrarPagoDialog> {
  final _montoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();

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
    if (!formKey.currentState!.validate()) return;
    setState(() => guardando = true);
    final monto = parseCOP(_montoCtrl.text);
    if (monto == null) {
      setState(() => guardando = false);
      if (mounted) {
        mostrarAlerta(context, 'Monto inválido. Verifica el valor ingresado.');
      }
      return;
    }
    await ejecutarGuardado(() async {
      await widget.db.prestamosDao.insertPago(
        PagosRecibidosCompanion.insert(
          prestamoId: widget.prestamoId,
          montoAbonado: monto,
          fechaPago: _fecha,
          notas: Value(_notasCtrl.text.trim()),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar pago'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: formKey,
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
                  if (n - widget.saldoPendiente > 1) {
                    return 'No puede superar el saldo pendiente '
                        '(${formatCOP(widget.saldoPendiente)})';
                  }
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
          onPressed: guardando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: guardando ? null : _guardar,
          child: Text(guardando ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}
