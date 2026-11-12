import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/interes_calculator.dart';
import '../../theme/theme.dart';
import '../../utils/confirmar.dart';
import '../../utils/date_format.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../../utils/notificaciones.dart';
import '../deudas/deuda_widgets.dart' show fechaCorta;
import 'prestamo_form.dart';
import 'prestamo_widgets.dart';
import 'registrar_abono.dart';

/// Detalle de un préstamo como PÁGINA (celular, o ventanas angostas). En PC
/// el mismo contenido ([PrestamoDetalleContenido]) va en un panel a la
/// derecha de la lista de préstamos.
class PrestamoDetalle extends StatelessWidget {
  const PrestamoDetalle({
    super.key,
    required this.db,
    required this.prestamoId,
  });

  final AppDatabase db;
  final int prestamoId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Préstamo')),
      body: SafeArea(
        child: PrestamoDetalleContenido(
          db: db,
          prestamoId: prestamoId,
          onSalir: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}

/// La tarjeta completa de un préstamo: lo que falta por cobrar, avance,
/// tasa, fechas, lo abonado, los pagos recibidos y el botón para registrar
/// un abono.
class PrestamoDetalleContenido extends StatefulWidget {
  const PrestamoDetalleContenido({
    super.key,
    required this.db,
    required this.prestamoId,
    required this.onSalir,
    this.onCerrar,
  });

  final AppDatabase db;
  final int prestamoId;

  /// El préstamo dejó de estar en la lista que se estaba viendo (se cobró,
  /// se reactivó o se eliminó): la página vuelve atrás, el panel se cierra.
  final VoidCallback onSalir;

  /// Si no es `null`, se muestra una X para cerrar (panel de PC).
  final VoidCallback? onCerrar;

  @override
  State<PrestamoDetalleContenido> createState() =>
      _PrestamoDetalleContenidoState();
}

class _PrestamoDetalleContenidoState extends State<PrestamoDetalleContenido> {
  /// Cuántos pagos se muestran antes de "Ver todos".
  static const _pagosVisibles = 5;

  late final Stream<Prestamo?> _prestamoStream;
  late final Stream<List<PagosRecibido>> _pagosStream;
  bool _verTodosLosPagos = false;

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

  Future<void> _editar(Prestamo prestamo) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PrestamoForm(db: widget.db, prestamo: prestamo),
    ),
  );

  Future<void> _marcarComoPagado(Prestamo prestamo) async {
    final ok = await confirmar(
      context,
      titulo: 'Marcar como pagado',
      mensaje:
          '¿Confirmas que el préstamo a ${prestamo.deudorNombre} ya fue '
          'pagado por completo?',
      accion: 'Confirmar',
    );
    if (!ok) return;
    await widget.db.prestamosDao.marcarComoPagado(
      widget.prestamoId,
      normalizarFechaCivil(DateTime.now()),
    );
    if (mounted) widget.onSalir();
  }

  Future<void> _reactivar(Prestamo prestamo) async {
    final ok = await confirmar(
      context,
      titulo: 'Reactivar préstamo',
      mensaje:
          '¿Volver a marcar como activo el préstamo a '
          '${prestamo.deudorNombre}?',
      accion: 'Confirmar',
    );
    if (!ok) return;
    await widget.db.prestamosDao.reactivarPrestamo(widget.prestamoId);
    if (mounted) widget.onSalir();
  }

  Future<void> _eliminar(Prestamo prestamo) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar préstamo',
      mensaje:
          '¿Eliminar el préstamo a ${prestamo.deudorNombre}? También se '
          'eliminarán sus pagos registrados.',
      accion: 'Eliminar',
      peligro: true,
    );
    if (!ok) return;
    try {
      await widget.db.prestamosDao.deletePrestamoConPagos(widget.prestamoId);
      if (mounted) widget.onSalir();
    } catch (_) {
      if (mounted) mostrarAlerta(context, 'No se pudo eliminar el préstamo.');
    }
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
    // Quedó en cero: ya pasó a "Cobrados".
    if (pagado && mounted) widget.onSalir();
  }

  Future<void> _eliminarPago(PagosRecibido pago) async {
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
          return const Center(child: Text('Error al cargar los datos.'));
        }
        if (!prestamoSnap.hasData &&
            prestamoSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final prestamo = prestamoSnap.data;
        if (prestamo == null) {
          return const Center(child: Text('Préstamo no encontrado'));
        }
        return StreamBuilder<List<PagosRecibido>>(
          stream: _pagosStream,
          builder: (context, pagosSnap) {
            if (pagosSnap.hasError) {
              return const Center(child: Text('Error al cargar los datos.'));
            }
            final pagos = pagosSnap.data ?? const <PagosRecibido>[];
            return _contenido(context, prestamo, pagos);
          },
        );
      },
    );
  }

  Widget _contenido(
    BuildContext context,
    Prestamo prestamo,
    List<PagosRecibido> pagos,
  ) {
    final theme = Theme.of(context);
    final c = context.colores;
    final hoy = DateTime.now();
    final activo = prestamo.estado == 'activo';
    final abonos = [
      for (final p in pagos)
        AbonoInteres(fecha: p.fechaPago, monto: p.montoAbonado),
    ];
    final totalAbonado = pagos.fold<int>(0, (s, p) => s + p.montoAbonado);
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
    final pactada = prestamo.fechaPactadaPago == null
        ? null
        : fechaCivilGuardada(prestamo.fechaPactadaPago!);
    final vencido =
        activo &&
        pactada != null &&
        pactada.isBefore(normalizarFechaCivil(hoy));
    final enPanel = widget.onCerrar != null;
    final pequeno = theme.textTheme.bodySmall?.copyWith(
      color: c.textoSecundario,
    );

    Widget fila(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: b),
        ],
      ),
    );

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: enPanel ? AppSpacing.lg : AppSpacing.md,
        vertical: enPanel ? 28 : AppSpacing.md,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarPersona(nombre: prestamo.deudorNombre, lado: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prestamo.deudorNombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (prestamo.deudorContacto.isNotEmpty)
                    Text(
                      prestamo.deudorContacto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: pequeno,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Editar',
              onPressed: () => _editar(prestamo),
            ),
            PopupMenuButton<String>(
              tooltip: 'Más acciones',
              onSelected: (v) => switch (v) {
                'pagado' => _marcarComoPagado(prestamo),
                'activo' => _reactivar(prestamo),
                _ => _eliminar(prestamo),
              },
              itemBuilder: (_) => [
                if (activo)
                  const PopupMenuItem(
                    value: 'pagado',
                    child: Text('Marcar como pagado'),
                  )
                else
                  const PopupMenuItem(
                    value: 'activo',
                    child: Text('Reactivar préstamo'),
                  ),
                PopupMenuItem(
                  value: 'eliminar',
                  child: Text('Eliminar', style: TextStyle(color: c.alerta)),
                ),
              ],
            ),
            if (widget.onCerrar != null) ...[
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Cerrar',
                style: IconButton.styleFrom(backgroundColor: c.relieve),
                onPressed: widget.onCerrar,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(activo ? 'Falta por cobrar' : 'Total cobrado', style: pequeno),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatCOP(activo ? saldo : totalAbonado),
            style: monoStyle(
              fontSize: 38,
              fontWeight: FontWeight.w600,
              color: activo ? c.texto : c.positivo,
            ),
          ),
        ),
        const SizedBox(height: 12),
        BarraProgreso(fraccion: fraccion, color: c.positivo),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                '${(fraccion * 100).round()}% cobrado de ${formatCOP(total)}',
                overflow: TextOverflow.ellipsis,
                style: pequeno,
              ),
            ),
            if (activo && pactada != null)
              Text(
                '${vencido ? 'Venció' : 'Vence'} ${fechaCorta(pactada, hoy)}',
                style: pequeno?.copyWith(
                  color: vencido ? c.alerta : null,
                  fontWeight: vencido ? FontWeight.bold : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        fila(
          _Dato(titulo: 'Tasa', valor: etiquetaTasaPrestamo(prestamo)),
          _Dato(titulo: 'Abonado', valor: formatCOP(totalAbonado)),
        ),
        const SizedBox(height: AppSpacing.sm),
        fila(
          _Dato(
            titulo: 'Prestado el',
            valor: fechaCorta(fechaCivilGuardada(prestamo.fechaPrestamo), hoy),
          ),
          activo
              ? _Dato(
                  titulo: 'Fecha pactada',
                  valor: pactada == null
                      ? 'Sin fecha'
                      : fechaCorta(pactada, hoy),
                  colorValor: vencido ? c.alerta : null,
                )
              : _Dato(
                  titulo: 'Cobrado el',
                  valor: prestamo.fechaPagoReal == null
                      ? 'Sin fecha'
                      : fechaCorta(
                          fechaCivilGuardada(prestamo.fechaPagoReal!),
                          hoy,
                        ),
                ),
        ),
        if (activo) ...[
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => _registrarPago(prestamo, abonos),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: const Text('Registrar abono'),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Pagos recibidos',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.textoSecundario,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ..._pagos(context, pagos, hoy),
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
              abonos: abonos,
              fechaFin: fechaFinCongeladaPrestamo(prestamo),
            ),
            modalidadCalculo: prestamo.modalidadCalculo,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _masInformacion(context, prestamo, resumen, totalAbonado),
      ],
    );
  }

  List<Widget> _pagos(
    BuildContext context,
    List<PagosRecibido> pagos,
    DateTime hoy,
  ) {
    final theme = Theme.of(context);
    final c = context.colores;
    if (pagos.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            'Aún no has registrado pagos.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: c.textoSecundario,
            ),
          ),
        ),
      ];
    }
    final visibles = _verTodosLosPagos
        ? pagos
        : pagos.take(_pagosVisibles).toList();
    return [
      for (final p in visibles)
        InkWell(
          onLongPress: () => _eliminarPago(p),
          onSecondaryTap: () => _eliminarPago(p),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.divisor, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fechaCorta(fechaCivilGuardada(p.fechaPago), hoy),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: c.textoSecundario,
                        ),
                      ),
                      if (p.notas.isNotEmpty)
                        Text(
                          p.notas,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: c.textoSecundario,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  formatCOP(p.montoAbonado),
                  style: monoStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      if (pagos.length > _pagosVisibles)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () =>
                setState(() => _verTodosLosPagos = !_verTodosLosPagos),
            child: Text(
              _verTodosLosPagos ? 'Ver menos' : 'Ver los ${pagos.length} pagos',
            ),
          ),
        ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Para eliminar un pago, mantenlo presionado (o clic derecho).',
        style: theme.textTheme.bodySmall?.copyWith(color: c.textoSecundario),
      ),
    ];
  }

  /// Lo que antes eran las tarjetas "Resumen" e "Información", plegado.
  Widget _masInformacion(
    BuildContext context,
    Prestamo prestamo,
    Map<String, int> resumen,
    int totalAbonado,
  ) {
    final theme = Theme.of(context);
    final colorSec = theme.colorSecundario;
    final tieneInteres = prestamo.tasaInteres > 0;
    final sinInteres = prestamo.montoPrestado - totalAbonado;
    InfoRow fila(String label, String valor) =>
        InfoRow(label: label, valor: valor, colorSec: colorSec, theme: theme);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            'Más información',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            fila('Monto prestado:', formatCOP(resumen['montoPrestado']!)),
            fila('Interés acumulado:', formatCOP(resumen['interesAcumulado']!)),
            fila('Total con interés:', formatCOP(resumen['totalConInteres']!)),
            fila('Total abonado:', formatCOP(totalAbonado)),
            fila(
              'Sin interés debería:',
              formatCOP(sinInteres < 0 ? 0 : sinInteres),
            ),
            fila(
              'Diferencia por interés:',
              formatCOP(resumen['gananciaInteres']!),
            ),
            if (tieneInteres) ...[
              fila('Modalidad:', prestamo.modalidadCalculo),
              fila(
                'Interés sobre:',
                prestamo.tipoAmortizacion == 'saldo_insoluto'
                    ? 'Lo que falta por pagar'
                    : 'Lo prestado al inicio',
              ),
            ],
            fila(
              'Fecha préstamo:',
              formatFecha(fechaCivilGuardada(prestamo.fechaPrestamo)),
            ),
            fila(
              'Fecha pactada:',
              prestamo.fechaPactadaPago != null
                  ? formatFecha(fechaCivilGuardada(prestamo.fechaPactadaPago!))
                  : 'Sin fecha',
            ),
            if (prestamo.deudorContacto.isNotEmpty)
              fila('Contacto:', prestamo.deudorContacto),
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

/// Recuadro de bordes suaves con un dato: título pequeño arriba y el valor
/// debajo.
class _Dato extends StatelessWidget {
  const _Dato({required this.titulo, required this.valor, this.colorValor});

  final String titulo;
  final String valor;
  final Color? colorValor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.relieve,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRecuadro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: c.textoSecundario,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colorValor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
