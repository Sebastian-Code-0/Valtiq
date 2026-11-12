import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/interes_calculator.dart';
import '../../theme/theme.dart';
import '../../utils/confirmar.dart';
import '../../utils/date_format.dart';
import '../../utils/encabezado_pantalla.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import 'prestamo_form.dart';
import 'registrar_abono.dart';

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
    final ok = await confirmar(
      context,
      titulo: 'Marcar como pagado',
      mensaje: '¿Confirmas que este préstamo ya fue pagado por completo?',
      accion: 'Confirmar',
    );
    if (!ok) return;
    await widget.db.prestamosDao.marcarComoPagado(
      widget.prestamoId,
      normalizarFechaCivil(DateTime.now()),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _registrarPago(
    Prestamo prestamo,
    List<AbonoInteres> abonos,
  ) async {
    final pagado = await registrarAbonoPrestamo(
      context,
      widget.db,
      prestamo,
      abonos,
    );
    // Quedó en cero: ya pasó a "Cobrados", se vuelve a la lista.
    if (pagado && mounted) Navigator.pop(context);
  }

  Future<void> _confirmarEliminarPago(PagosRecibido pago) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar pago',
      mensaje: '¿Eliminar este pago de ${formatCOP(pago.montoAbonado)}?',
      accion: 'Eliminar',
      peligro: true,
    );
    if (ok) await widget.db.prestamosDao.deletePago(pago.id);
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
        final activo = prestamo.estado == 'activo';
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 48,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Editar',
                onPressed: () => _editar(prestamo),
              ),
              if (activo)
                PopupMenuButton<String>(
                  tooltip: 'Más acciones',
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
              const SizedBox(width: AppSpacing.sm),
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
              final abonosInteres = pagos
                  .map(
                    (p) =>
                        AbonoInteres(fecha: p.fechaPago, monto: p.montoAbonado),
                  )
                  .toList();
              final ancho = MediaQuery.sizeOf(context).width >= 600;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  ancho ? AppSpacing.lg : AppSpacing.md,
                  AppSpacing.sm,
                  ancho ? AppSpacing.lg : AppSpacing.md,
                  AppSpacing.xl,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: PaginaFormulario.anchoMaximo,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EncabezadoPantalla(
                          kicker: activo
                              ? 'Préstamo por cobrar'
                              : 'Préstamo cobrado',
                          titulo: prestamo.deudorNombre,
                        ),
                        SizedBox(height: ancho ? AppSpacing.lg : AppSpacing.md),
                        _ResumenCard(
                          prestamo: prestamo,
                          totalAbonado: totalAbonado,
                          abonos: abonosInteres,
                          onRegistrar: activo
                              ? () => _registrarPago(prestamo, abonosInteres)
                              : null,
                        ),
                        if (prestamo.tasaInteres > 0) ...[
                          const SizedBox(height: AppSpacing.md),
                          InteresDesgloseCard(
                            tramos: InteresCalculator.desglosePrestamo(
                              montoPrestado: prestamo.montoPrestado,
                              tasaInteres: prestamo.tasaInteres,
                              tipoInteres: prestamo.tipoInteres,
                              modalidadCalculo: prestamo.modalidadCalculo,
                              fechaPrestamo: prestamo.fechaPrestamo,
                              tipoAmortizacion: prestamo.tipoAmortizacion,
                              abonos: abonosInteres,
                              fechaFin: fechaFinCongeladaPrestamo(prestamo),
                            ),
                            modalidadCalculo: prestamo.modalidadCalculo,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        _PagosSection(
                          pagos: pagos,
                          onEliminar: _confirmarEliminarPago,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _InfoCard(prestamo: prestamo),
                      ],
                    ),
                  ),
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
  const _ResumenCard({
    required this.prestamo,
    required this.totalAbonado,
    required this.abonos,
    required this.onRegistrar,
  });

  final Prestamo prestamo;
  final int totalAbonado;
  final List<AbonoInteres> abonos;

  /// `null` si el préstamo ya está cobrado (no se muestra el botón).
  final VoidCallback? onRegistrar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    final colorSec = c.textoSecundario;

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

    final saldo = resumen['saldoPendiente']!;
    final total = resumen['totalConInteres']!;
    final fraccion = total > 0 ? totalAbonado / total : 0.0;
    final sinInteres = prestamo.montoPrestado - totalAbonado;
    final ancho = MediaQuery.sizeOf(context).width >= 600;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(ancho ? 26 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              saldo > 0 ? 'Saldo pendiente' : 'Total cobrado',
              style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatCOP(saldo > 0 ? saldo : totalAbonado),
                style: monoStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                  color: saldo > 0 ? c.texto : c.positivo,
                ),
              ),
            ),
            const SizedBox(height: 12),
            BarraProgreso(fraccion: fraccion, color: c.positivo),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${(fraccion * 100).round()}% cobrado de ${formatCOP(total)}',
              style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
            ),
            if (onRegistrar != null) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: onRegistrar,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(200, 48),
                  ),
                  child: const Text('Registrar abono'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Divider(height: 1, color: c.divisor),
            const SizedBox(height: AppSpacing.md),
            _filaResumen(
              label: 'Monto prestado',
              valor: resumen['montoPrestado']!,
              colorSec: colorSec,
            ),
            const SizedBox(height: AppSpacing.sm),
            _filaResumen(
              label: 'Interés acumulado',
              valor: resumen['interesAcumulado']!,
              colorSec: colorSec,
            ),
            const SizedBox(height: AppSpacing.sm),
            _filaResumen(
              label: 'Total con interés',
              valor: total,
              negrita: true,
              colorSec: colorSec,
            ),
            const SizedBox(height: AppSpacing.sm),
            _filaResumen(
              label: 'Total abonado',
              valor: resumen['totalAbonado']!,
              colorValor: c.positivo,
              colorSec: colorSec,
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: c.divisor),
            const SizedBox(height: AppSpacing.md),
            _filaResumen(
              label: 'Sin interés debería',
              valor: sinInteres < 0 ? 0 : sinInteres,
              colorSec: colorSec,
              chico: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            _filaResumen(
              label: 'Diferencia por interés',
              valor: resumen['gananciaInteres']!,
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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
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
            if (tieneInteres)
              InfoRow(
                label: 'Interés sobre:',
                valor: prestamo.tipoAmortizacion == 'saldo_insoluto'
                    ? 'Lo que falta por pagar'
                    : 'Lo prestado al inicio',
                colorSec: colorSec,
                theme: theme,
              ),
            InfoRow(
              label: 'Fecha préstamo:',
              valor: formatFecha(fechaCivilGuardada(prestamo.fechaPrestamo)),
              colorSec: colorSec,
              theme: theme,
            ),
            InfoRow(
              label: 'Fecha pactada:',
              valor: prestamo.fechaPactadaPago != null
                  ? formatFecha(fechaCivilGuardada(prestamo.fechaPactadaPago!))
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
  const _PagosSection({required this.pagos, required this.onEliminar});

  final List<PagosRecibido> pagos;
  final Future<void> Function(PagosRecibido) onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    final colorSec = c.textoSecundario;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pagos recibidos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (pagos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'Aún no has registrado pagos.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorSec),
                ),
              )
            else ...[
              for (final p in pagos)
                InkWell(
                  onLongPress: () => onEliminar(p),
                  onSecondaryTap: () => onEliminar(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: c.divisor, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatFecha(fechaCivilGuardada(p.fechaPago)),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorSec,
                                ),
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
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          formatCOP(p.montoAbonado),
                          style: monoStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Para eliminar un pago, mantenlo presionado (o clic derecho).',
                style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
