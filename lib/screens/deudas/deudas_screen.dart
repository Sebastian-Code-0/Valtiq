import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/deudas_calculos.dart';
import '../../services/interes_calculator.dart';
import '../../theme/theme.dart';
import '../../utils/confirmar.dart';
import '../../utils/date_format.dart';
import '../../utils/encabezado_pantalla.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../../utils/notificaciones.dart';
import '../../utils/selector_pildoras.dart';
import 'deuda_detalle.dart';
import 'deuda_form.dart';
import 'deuda_widgets.dart';
import 'plan_pago_tab.dart';

/// Pantalla de Deudas, con tres pestañas:
/// - **Activas**: totales arriba y una cuadrícula de tarjetas (hasta 3 por
///   fila). Al tocar una se abre su detalle: en PC, como panel a la derecha;
///   en celular, como página.
/// - **Plan de pago**: en qué orden pagar y cuándo se queda libre de deudas.
/// - **Pagadas**: las deudas ya liquidadas.
class DeudasScreen extends StatefulWidget {
  const DeudasScreen({super.key, required this.db});

  final AppDatabase db;

  /// Ancho mínimo del área de Deudas para abrir el detalle como panel al
  /// lado de las tarjetas. Por debajo, el detalle se abre como página.
  static const anchoMinimoPanel = 800.0;

  /// Ancho del panel de detalle.
  static const anchoPanel = 440.0;

  @override
  State<DeudasScreen> createState() => _DeudasScreenState();
}

class _DeudasScreenState extends State<DeudasScreen> {
  static const _pestanas = [
    OpcionPildora('Activas'),
    OpcionPildora('Plan de pago'),
    OpcionPildora('Pagadas'),
  ];

  late final Stream<List<ResumenDeuda>> _stream;
  int _pestana = 0;

  /// Deuda abierta en el panel de detalle (solo PC).
  int? _seleccionada;

  @override
  void initState() {
    super.initState();
    _stream = _observarDeudas();
  }

  // Join sin agregar (en vez de groupBy + sum) porque el modo de
  // amortización 'saldo_insoluto' necesita la fecha de cada abono, no solo
  // la suma — ver InteresCalculator. La agrupación por deuda se hace en Dart
  // a partir de las filas planas del join.
  Stream<List<ResumenDeuda>> _observarDeudas() {
    final d = widget.db.deudas;
    final pd = widget.db.pagosDeuda;
    final query = widget.db.select(d).join([
      leftOuterJoin(pd, pd.deudaId.equalsExp(d.id)),
    ]);
    return query.watch().map((rows) {
      final deudas = <int, Deuda>{};
      final abonos = <int, List<AbonoInteres>>{};
      for (final row in rows) {
        final deuda = row.readTable(d);
        deudas[deuda.id] = deuda;
        final pago = row.readTableOrNull(pd);
        if (pago != null) {
          (abonos[deuda.id] ??= []).add(
            AbonoInteres(fecha: pago.fechaPago, monto: pago.montoAbonado),
          );
        }
      }
      final hoy = DateTime.now();
      return [
        for (final deuda in deudas.values)
          ResumenDeuda.calcular(deuda, abonos[deuda.id] ?? const [], hoy: hoy),
      ]..sort((a, b) => b.deuda.fechaPrestamo.compareTo(a.deuda.fechaPrestamo));
    });
  }

  Future<void> _nuevaDeuda() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => DeudaForm(db: widget.db)),
  );

  /// Elimina todas las deudas pagadas (con sus pagos), tras confirmar.
  Future<void> _limpiarHistorial(int cuantas) async {
    final ok = await confirmar(
      context,
      titulo: 'Limpiar historial',
      mensaje:
          'Se ${cuantas == 1 ? 'eliminará la deuda pagada' : 'eliminarán las $cuantas deudas pagadas'} '
          'y todos sus pagos registrados. Tus deudas activas no se tocan. '
          'No se puede deshacer.',
      accion: 'Limpiar historial',
      peligro: true,
    );
    if (!ok || !mounted) return;
    try {
      final n = await widget.db.deudasDao.deleteDeudasPagadas();
      if (!mounted) return;
      setState(() => _seleccionada = null);
      mostrarExito(
        context,
        n == 1
            ? 'Se eliminó 1 deuda pagada.'
            : 'Se eliminaron $n deudas pagadas.',
      );
    } catch (_) {
      if (mounted) mostrarAlerta(context, 'No se pudo limpiar el historial.');
    }
  }

  void _abrir(int deudaId, {required bool enPanel}) {
    if (enPanel) {
      setState(() => _seleccionada = deudaId);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeudaDetalle(db: widget.db, deudaId: deudaId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<ResumenDeuda>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error al cargar los datos.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final todas = snapshot.data!;
            final activas = [
              for (final r in todas)
                if (r.deuda.estado == 'activa') r,
            ];
            final pagadas = [
              for (final r in todas)
                if (r.deuda.estado != 'activa') r,
            ];
            return LayoutBuilder(
              builder: (context, constraints) {
                final ancho = constraints.maxWidth;
                final conPanel = ancho >= DeudasScreen.anchoMinimoPanel;
                // El panel solo tiene sentido en la pestaña de la deuda
                // elegida, y si esa deuda sigue existiendo.
                final lista = _pestana == 2 ? pagadas : activas;
                final panelAbierto =
                    conPanel &&
                    _pestana != 1 &&
                    lista.any((r) => r.deuda.id == _seleccionada);
                final margen = conPanel ? AppSpacing.xl : AppSpacing.md;

                final principal = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _encabezado(context, activas.length, margen),
                    // Pestañas a la izquierda y, en "Pagadas", el botón
                    // de limpiar el historial a la derecha, en la misma fila.
                    Row(
                      children: [
                        Expanded(
                          child: SelectorPildoras(
                            opciones: _pestanas,
                            seleccionada: _pestana,
                            margen: margen,
                            repartirEnCelular: true,
                            onElegir: (i) => setState(() {
                              _pestana = i;
                              _seleccionada = null;
                            }),
                          ),
                        ),
                        if (_pestana == 2 && pagadas.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(right: margen),
                            child: BotonLimpiarHistorial(
                              onPressed: () =>
                                  _limpiarHistorial(pagadas.length),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: conPanel ? AppSpacing.md : AppSpacing.sm),
                    Expanded(
                      child: switch (_pestana) {
                        0 => _Activas(
                          activas: activas,
                          margen: margen,
                          seleccionada: panelAbierto ? _seleccionada : null,
                          onAbrir: (id) => _abrir(id, enPanel: conPanel),
                        ),
                        1 => PlanPagoTab(
                          activas: activas,
                          margen: margen,
                          onEditar: (deuda) => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DeudaForm(
                                db: widget.db,
                                deuda: deuda,
                                irAPagoMinimo: true,
                              ),
                            ),
                          ),
                        ),
                        _ => _Pagadas(
                          pagadas: pagadas,
                          margen: margen,
                          seleccionada: panelAbierto ? _seleccionada : null,
                          onAbrir: (id) => _abrir(id, enPanel: conPanel),
                        ),
                      },
                    ),
                  ],
                );

                // En pantallas muy anchas el contenido no se estira más
                // allá de un ancho cómodo de leer.
                final acotado = Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppSpacing.anchoContenido + 2 * margen,
                    ),
                    child: principal,
                  ),
                );
                if (!panelAbierto) return acotado;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: acotado),
                    Container(
                      key: const ValueKey('panel-deuda'),
                      width: DeudasScreen.anchoPanel,
                      decoration: BoxDecoration(
                        color: context.colores.superficie,
                        border: Border(
                          left: BorderSide(
                            color: context.colores.divisor,
                            width: AppSpacing.borde,
                          ),
                        ),
                      ),
                      child: DeudaDetalleContenido(
                        // Clave por deuda: al elegir otra, el panel arranca
                        // limpio con sus propios datos.
                        key: ValueKey(_seleccionada),
                        db: widget.db,
                        deudaId: _seleccionada!,
                        onSalir: () => setState(() => _seleccionada = null),
                        onCerrar: () => setState(() => _seleccionada = null),
                        onVerPlan: () => setState(() {
                          _pestana = 1;
                          _seleccionada = null;
                        }),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _encabezado(BuildContext context, int activas, double margen) {
    return Padding(
      padding: EdgeInsets.fromLTRB(margen, margen, margen, AppSpacing.lg),
      child: EncabezadoPantalla(
        kicker: switch (activas) {
          0 => 'Sin deudas activas',
          1 => '1 activa',
          _ => '$activas activas',
        },
        titulo: 'Deudas',
        accion: BotonCrear(
          texto: 'Nueva deuda',
          heroTag: 'fab_deudas',
          onPressed: _nuevaDeuda,
        ),
      ),
    );
  }
}

/// Mensaje centrado para una pestaña sin nada que mostrar.
class _Vacio extends StatelessWidget {
  const _Vacio(this.mensaje);

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          mensaje,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: context.colores.textoSecundario,
          ),
        ),
      ),
    );
  }
}

class _Activas extends StatelessWidget {
  const _Activas({
    required this.activas,
    required this.margen,
    required this.seleccionada,
    required this.onAbrir,
  });

  final List<ResumenDeuda> activas;
  final double margen;
  final int? seleccionada;
  final ValueChanged<int> onAbrir;

  /// Alto fijo de cada tarjeta de la cuadrícula.
  static const _altoTarjeta = 208.0;

  @override
  Widget build(BuildContext context) {
    if (activas.isEmpty) {
      return const _Vacio(
        'No tienes deudas activas.\nToca + para registrar una.',
      );
    }
    final totales = TotalesDeudas(activas);
    final hoy = DateTime.now();
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth - 2 * margen;
        final columnas = ancho >= 900 ? 3 : (ancho >= 560 ? 2 : 1);
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(margen, AppSpacing.sm, margen, 0),
              sliver: SliverToBoxAdapter(child: _Totales(totales: totales)),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                margen,
                AppSpacing.lg,
                margen,
                margen,
              ),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnas,
                  mainAxisExtent: _altoTarjeta,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: activas.length,
                itemBuilder: (context, i) {
                  final r = activas[i];
                  return _TarjetaDeuda(
                    key: ValueKey(r.deuda.id),
                    resumen: r,
                    hoy: hoy,
                    elegida: r.deuda.id == seleccionada,
                    onTap: () => onAbrir(r.deuda.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Los tres datos de arriba, sueltos (sin tarjeta): total de las deudas,
/// pagos mínimos al mes y qué porcentaje del total ya se pagó.
class _Totales extends StatelessWidget {
  const _Totales({required this.totales});

  final TotalesDeudas totales;

  @override
  Widget build(BuildContext context) {
    final porcentaje = (totales.fraccionPagada * 100).round();
    return Wrap(
      spacing: 40,
      runSpacing: AppSpacing.md,
      children: [
        _Total(
          titulo: 'Total de las deudas',
          valor: formatCOP(totales.totalDeudas),
        ),
        _Total(
          titulo: 'Pagos mínimos al mes',
          valor: formatCOP(totales.pagosMinimosMes),
        ),
        _Total(titulo: 'Pagado del total', valor: '$porcentaje%'),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ancho = MediaQuery.sizeOf(context).width >= 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titulo,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.colores.textoSecundario,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: monoStyle(
            fontSize: ancho ? 28 : 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de una deuda en la cuadrícula: imagen, nombre y descripción,
/// etiqueta con la tasa, lo que se debe, barra de avance y, debajo, cuánto
/// se ha pagado y cuándo vence.
class _TarjetaDeuda extends StatelessWidget {
  const _TarjetaDeuda({
    super.key,
    required this.resumen,
    required this.hoy,
    required this.elegida,
    required this.onTap,
  });

  final ResumenDeuda resumen;
  final DateTime hoy;
  final bool elegida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    final deuda = resumen.deuda;
    final vence = resumen.vencimiento(hoy);
    final porcentaje = (resumen.fraccionPagada * 100).round();
    final pequeno = theme.textTheme.bodySmall?.copyWith(
      color: c.textoSecundario,
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusTarjeta),
        side: BorderSide(
          color: elegida ? c.acento : c.divisor,
          width: elegida ? 1.5 : AppSpacing.borde,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ImagenDeuda(tipo: deuda.tipo, lado: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deuda.acreedorNombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          deuda.descripcion.isEmpty
                              ? 'Desde ${fechaCorta(fechaCivilGuardada(deuda.fechaPrestamo), hoy)}'
                              : deuda.descripcion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: pequeno,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppChip(label: etiquetaTasa(deuda), neutra: true),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatCOP(resumen.saldo),
                  style: monoStyle(fontSize: 28, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),
              BarraProgreso(
                fraccion: resumen.fraccionPagada,
                color: c.positivo,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$porcentaje% de ${formatCOP(resumen.total)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: pequeno,
                    ),
                  ),
                  if (vence != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${vence.vencida ? 'Venció' : 'Vence'} '
                      '${fechaCorta(vence.fecha, hoy)}',
                      style: pequeno?.copyWith(
                        color: vence.vencida ? c.alerta : null,
                        fontWeight: vence.vencida ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pagadas extends StatelessWidget {
  const _Pagadas({
    required this.pagadas,
    required this.margen,
    required this.seleccionada,
    required this.onAbrir,
  });

  final List<ResumenDeuda> pagadas;
  final double margen;
  final int? seleccionada;
  final ValueChanged<int> onAbrir;

  @override
  Widget build(BuildContext context) {
    if (pagadas.isEmpty) {
      return const _Vacio('Todavía no has terminado de pagar ninguna deuda.');
    }
    final c = context.colores;
    // Las liquidadas más recientemente, primero.
    final ordenadas = [...pagadas]
      ..sort((a, b) {
        final fa = a.deuda.fechaPagoReal ?? a.deuda.actualizadoEn;
        final fb = b.deuda.fechaPagoReal ?? b.deuda.actualizadoEn;
        return fb.compareTo(fa);
      });
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(margen, AppSpacing.sm, margen, margen),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (final (i, r) in ordenadas.indexed) ...[
              if (i > 0)
                Divider(height: 1, indent: 22, endIndent: 22, color: c.divisor),
              _fila(context, r),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fila(BuildContext context, ResumenDeuda r) {
    final theme = Theme.of(context);
    final c = context.colores;
    final deuda = r.deuda;
    final pagada = deuda.fechaPagoReal;
    final detalle = [
      if (deuda.descripcion.isNotEmpty) deuda.descripcion,
      pagada == null
          ? 'Liquidada'
          : 'Liquidada ${formatMesAnioCorto(fechaCivilGuardada(pagada))}',
    ].join(' · ');
    return Material(
      key: ValueKey(deuda.id),
      color: deuda.id == seleccionada ? c.relieve : Colors.transparent,
      child: InkWell(
        onTap: () => onAbrir(deuda.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.verified, size: 24, color: c.positivo),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deuda.acreedorNombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      detalle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: c.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                formatCOP(r.abonado),
                style: monoStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
