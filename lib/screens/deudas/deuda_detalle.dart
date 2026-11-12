import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/deudas_calculos.dart';
import '../../services/interes_calculator.dart';
import '../../theme/theme.dart';
import '../../utils/date_format.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../../utils/notificaciones.dart';
import 'deuda_form.dart';
import 'deuda_widgets.dart';
import 'registrar_pago_dialog.dart';

/// Detalle de una deuda como PÁGINA (celular, o ventanas angostas). En PC
/// el mismo contenido ([DeudaDetalleContenido]) va en un panel a la derecha
/// de la lista de deudas.
class DeudaDetalle extends StatelessWidget {
  const DeudaDetalle({super.key, required this.db, required this.deudaId});

  final AppDatabase db;
  final int deudaId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deuda')),
      body: SafeArea(
        child: DeudaDetalleContenido(
          db: db,
          deudaId: deudaId,
          onSalir: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}

/// La tarjeta completa de una deuda: saldo, avance, tasa, pago mínimo,
/// próximo pago, liquidación estimada, pagos recientes y el botón para
/// registrar un pago.
class DeudaDetalleContenido extends StatefulWidget {
  const DeudaDetalleContenido({
    super.key,
    required this.db,
    required this.deudaId,
    required this.onSalir,
    this.onCerrar,
    this.onVerPlan,
  });

  final AppDatabase db;
  final int deudaId;

  /// Si no es `null`, junto a "Registrar pago" va "Ver en plan" (panel de
  /// PC: lleva a la pestaña Plan de pago).
  final VoidCallback? onVerPlan;

  /// La deuda dejó de estar en la lista que se estaba viendo (se pagó, se
  /// reactivó o se eliminó): la página vuelve atrás, el panel se cierra.
  final VoidCallback onSalir;

  /// Si no es `null`, se muestra una X para cerrar (panel de PC).
  final VoidCallback? onCerrar;

  @override
  State<DeudaDetalleContenido> createState() => _DeudaDetalleContenidoState();
}

class _DeudaDetalleContenidoState extends State<DeudaDetalleContenido> {
  /// Cuántos pagos se muestran antes de "Ver todos".
  static const _pagosVisibles = 5;

  late final Stream<Deuda?> _deudaStream;
  late final Stream<List<PagosDeudaData>> _abonosStream;
  bool _verTodosLosPagos = false;

  @override
  void initState() {
    super.initState();
    _deudaStream = (widget.db.select(
      widget.db.deudas,
    )..where((d) => d.id.equals(widget.deudaId))).watchSingleOrNull();
    _abonosStream = widget.db.pagosDeudaDao.watchPagosDeDeuda(widget.deudaId);
  }

  Future<void> _editar(Deuda deuda) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DeudaForm(db: widget.db, deuda: deuda),
    ),
  );

  Future<bool> _confirmar({
    required String titulo,
    required String mensaje,
    required String accion,
    bool peligro = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              accion,
              style: peligro ? TextStyle(color: ctx.colores.alerta) : null,
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _marcarComoPagada(Deuda deuda) async {
    final ok = await _confirmar(
      titulo: 'Marcar como pagada',
      mensaje:
          '¿Confirmas que ya pagaste por completo "${deuda.acreedorNombre}"?',
      accion: 'Confirmar',
    );
    if (!ok) return;
    await widget.db.deudasDao.marcarComoPagada(
      widget.deudaId,
      normalizarFechaCivil(DateTime.now()),
    );
    if (mounted) widget.onSalir();
  }

  Future<void> _reactivar(Deuda deuda) async {
    final ok = await _confirmar(
      titulo: 'Reactivar deuda',
      mensaje: '¿Volver a marcar como activa "${deuda.acreedorNombre}"?',
      accion: 'Confirmar',
    );
    if (!ok) return;
    await widget.db.deudasDao.marcarComoActiva(widget.deudaId);
    if (mounted) widget.onSalir();
  }

  Future<void> _eliminar(Deuda deuda) async {
    final ok = await _confirmar(
      titulo: 'Eliminar deuda',
      mensaje:
          '¿Eliminar "${deuda.acreedorNombre}"? También se eliminarán sus '
          'pagos registrados.',
      accion: 'Eliminar',
      peligro: true,
    );
    if (!ok) return;
    try {
      await widget.db.deudasDao.deleteDeudaConPagos(widget.deudaId);
      if (mounted) widget.onSalir();
    } catch (_) {
      if (mounted) mostrarAlerta(context, 'No se pudo eliminar la deuda.');
    }
  }

  Future<void> _registrarPago(ResumenDeuda r) async {
    final deuda = r.deuda;
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => RegistrarPagoDialog(
        db: widget.db,
        deudaId: widget.deudaId,
        nombre: deuda.acreedorNombre,
        saldoPendiente: r.saldo,
        pagoMinimo: r.pagoMinimo,
      ),
    );
    if (guardado != true || !mounted) return;

    // ¿Con este pago quedó en cero? Entonces pasa sola a "Pagadas".
    final pagos = await widget.db.pagosDeudaDao.getPagosDeDeuda(widget.deudaId);
    final actual = ResumenDeuda.calcular(deuda, [
      for (final p in pagos)
        AbonoInteres(fecha: p.fechaPago, monto: p.montoAbonado),
    ], hoy: DateTime.now());
    if (actual.saldo > 0) return;
    await widget.db.deudasDao.marcarComoPagada(
      widget.deudaId,
      // Fecha civil (medianoche UTC), igual que el botón manual: con el
      // instante crudo, un pago hecho de noche (UTC-5) se leía como el día
      // siguiente y la deuda pagada mostraba un día de interés de más.
      normalizarFechaCivil(DateTime.now()),
    );
    if (!mounted) return;
    mostrarExito(
      context,
      'Deuda "${deuda.acreedorNombre}" ha sido pagada por completo '
      'y se movió a pagadas.',
    );
    widget.onSalir();
  }

  Future<void> _eliminarPago(PagosDeudaData pago) async {
    final ok = await _confirmar(
      titulo: 'Eliminar pago',
      mensaje: '¿Eliminar este pago de ${formatCOP(pago.montoAbonado)}?',
      accion: 'Eliminar',
      peligro: true,
    );
    if (ok) await widget.db.pagosDeudaDao.deletePago(pago.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Deuda?>(
      stream: _deudaStream,
      builder: (context, deudaSnap) {
        if (deudaSnap.hasError) {
          return const Center(child: Text('Error al cargar los datos.'));
        }
        if (!deudaSnap.hasData &&
            deudaSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final deuda = deudaSnap.data;
        if (deuda == null) {
          return const Center(child: Text('Deuda no encontrada'));
        }
        return StreamBuilder<List<PagosDeudaData>>(
          stream: _abonosStream,
          builder: (context, abonosSnap) {
            if (abonosSnap.hasError) {
              return const Center(child: Text('Error al cargar los datos.'));
            }
            final pagos = abonosSnap.data ?? const <PagosDeudaData>[];
            final hoy = DateTime.now();
            final resumen = ResumenDeuda.calcular(deuda, [
              for (final p in pagos)
                AbonoInteres(fecha: p.fechaPago, monto: p.montoAbonado),
            ], hoy: hoy);
            return _contenido(context, resumen, pagos, hoy);
          },
        );
      },
    );
  }

  Widget _contenido(
    BuildContext context,
    ResumenDeuda r,
    List<PagosDeudaData> pagos,
    DateTime hoy,
  ) {
    final theme = Theme.of(context);
    final c = context.colores;
    final deuda = r.deuda;
    final activa = deuda.estado == 'activa';
    final vence = activa ? r.vencimiento(hoy) : null;
    final porcentaje = (r.fraccionPagada * 100).round();

    final enPanel = widget.onCerrar != null;
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: enPanel ? AppSpacing.lg : AppSpacing.md,
        vertical: enPanel ? 28 : AppSpacing.md,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImagenDeuda(tipo: deuda.tipo, lado: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deuda.acreedorNombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (deuda.descripcion.isNotEmpty)
                    Text(
                      deuda.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: c.textoSecundario,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Editar',
              onPressed: () => _editar(deuda),
            ),
            PopupMenuButton<String>(
              tooltip: 'Más acciones',
              onSelected: (v) => switch (v) {
                'pagada' => _marcarComoPagada(deuda),
                'activa' => _reactivar(deuda),
                _ => _eliminar(deuda),
              },
              itemBuilder: (_) => [
                if (activa)
                  const PopupMenuItem(
                    value: 'pagada',
                    child: Text('Marcar como pagada'),
                  )
                else
                  const PopupMenuItem(
                    value: 'activa',
                    child: Text('Reactivar deuda'),
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
        Text(
          activa ? 'Saldo pendiente' : 'Total pagado',
          style: theme.textTheme.bodySmall?.copyWith(color: c.textoSecundario),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatCOP(activa ? r.saldo : r.abonado),
            style: monoStyle(
              fontSize: 38,
              fontWeight: FontWeight.w600,
              color: activa ? c.texto : c.positivo,
            ),
          ),
        ),
        const SizedBox(height: 12),
        BarraProgreso(fraccion: r.fraccionPagada, color: c.positivo),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                '$porcentaje% pagado de ${formatCOP(r.total)}',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: c.textoSecundario,
                ),
              ),
            ),
            if (vence != null)
              Text(
                '${vence.vencida ? 'Venció' : 'Vence'} '
                '${fechaCorta(vence.fecha, hoy)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: vence.vencida ? c.alerta : c.textoSecundario,
                  fontWeight: vence.vencida ? FontWeight.bold : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._datos(context, r, hoy),
        if (activa) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _registrarPago(r),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: const Text('Registrar pago'),
                ),
              ),
              if (widget.onVerPlan != null) ...[
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: widget.onVerPlan,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Ver en plan'),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Pagos recientes',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.textoSecundario,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ..._pagos(context, pagos, hoy),
        if (r.tieneInteres) ...[
          const SizedBox(height: AppSpacing.md),
          InteresDesgloseCard(
            tramos: InteresCalculator.desglosePrestamo(
              montoPrestado: deuda.montoOriginal,
              tasaInteres: deuda.tasaInteres,
              tipoInteres: deuda.tipoInteres,
              modalidadCalculo: deuda.modalidadCalculo,
              fechaPrestamo: deuda.fechaPrestamo,
              tipoAmortizacion: deuda.tipoAmortizacion,
              abonos: r.abonos,
              fechaFin: activa || deuda.fechaPagoReal == null
                  ? null
                  : fechaCivilGuardada(deuda.fechaPagoReal!),
            ),
            modalidadCalculo: deuda.modalidadCalculo,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _masInformacion(context, r),
      ],
    );
  }

  /// Los cuatro recuadros: tasa, pago mínimo, próximo pago y liquidación
  /// estimada (o, en una deuda ya pagada, cuándo se liquidó).
  List<Widget> _datos(BuildContext context, ResumenDeuda r, DateTime hoy) {
    final c = context.colores;
    final deuda = r.deuda;
    final activa = deuda.estado == 'activa';
    final minimo = r.pagoMinimo;
    final proximo = r.proximoPago(hoy);
    final estimada = r.liquidacionEstimada(hoy);

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

    if (!activa) {
      final pagada = deuda.fechaPagoReal;
      return [
        fila(
          _Dato(titulo: 'Tasa', valor: etiquetaTasa(deuda)),
          _Dato(
            titulo: 'Liquidada',
            valor: pagada == null
                ? 'Sin fecha'
                : formatMesAnioCorto(fechaCivilGuardada(pagada)),
          ),
        ),
      ];
    }

    final String textoEstimada;
    if (estimada.noBaja) {
      textoEstimada = 'No baja';
    } else if (estimada.fecha == null) {
      textoEstimada = 'Sin estimar';
    } else {
      textoEstimada = formatMesAnioCorto(estimada.fecha!);
    }

    return [
      fila(
        _Dato(titulo: 'Tasa', valor: etiquetaTasa(deuda)),
        _Dato(
          titulo: 'Pago mínimo',
          valor: minimo == null ? 'Sin definir' : formatCOP(minimo),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      fila(
        _Dato(
          titulo: 'Próximo pago',
          valor: proximo == null ? 'Sin fecha' : fechaCorta(proximo, hoy),
        ),
        _Dato(
          titulo: 'Liquidación estimada',
          valor: textoEstimada,
          colorValor: estimada.noBaja ? c.alerta : null,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        estimada.noBaja
            ? 'Pagando ${formatCOP(estimada.ritmo!)} al mes la deuda no baja: '
                  'el interés de cada mes es mayor que el pago.'
            : estimada.fecha != null
            ? 'Estimada con ${formatCOP(estimada.ritmo!)} al mes, que es lo '
                  'que vienes pagando. Si pagas más, se adelanta; si pagas '
                  'menos o te saltas un mes, se atrasa.'
            : 'Para estimar cuándo terminas, edita la deuda y ponle un pago '
                  'mínimo al mes.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: estimada.noBaja ? c.alerta : c.textoSecundario,
        ),
      ),
    ];
  }

  List<Widget> _pagos(
    BuildContext context,
    List<PagosDeudaData> pagos,
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

  Widget _masInformacion(BuildContext context, ResumenDeuda r) {
    final theme = Theme.of(context);
    final colorSec = theme.colorSecundario;
    final deuda = r.deuda;
    InfoRow fila(String label, String valor) =>
        InfoRow(label: label, valor: valor, colorSec: colorSec, theme: theme);

    return Card(
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
            fila('Monto original:', formatCOP(deuda.montoOriginal)),
            // Solo con interés: sin él valen cero o repiten el monto.
            if (r.tieneInteres) ...[
              fila(
                'Interés acumulado:',
                formatCOP(r.total - deuda.montoOriginal),
              ),
              fila('Total con interés:', formatCOP(r.total)),
            ],
            fila('Total pagado:', formatCOP(r.abonado)),
            if (r.tieneInteres) ...[
              fila('Modalidad:', deuda.modalidadCalculo),
              fila(
                'Interés sobre:',
                deuda.tipoAmortizacion == 'saldo_insoluto'
                    ? 'Lo que falta por pagar'
                    : 'Lo prestado al inicio',
              ),
            ],
            fila(
              'Fecha de inicio:',
              formatFecha(fechaCivilGuardada(deuda.fechaPrestamo)),
            ),
            fila(
              'Fecha límite:',
              deuda.fechaLimite != null
                  ? formatFecha(fechaCivilGuardada(deuda.fechaLimite!))
                  : 'Sin fecha',
            ),
            if (deuda.diaPago != null)
              fila('Día de pago:', 'El ${deuda.diaPago} de cada mes'),
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
