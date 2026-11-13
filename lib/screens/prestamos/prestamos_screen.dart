import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/interes_calculator.dart';
import '../../theme/theme.dart';
import '../../utils/confirmar.dart';
import '../../utils/encabezado_pantalla.dart';
import '../../utils/fecha_civil.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../../utils/notificaciones.dart';
import '../../utils/selector_pildoras.dart';
import '../deudas/deuda_widgets.dart' show fechaCorta;
import 'prestamo_detalle.dart';
import 'prestamo_form.dart';
import 'prestamo_widgets.dart';
import 'registrar_abono.dart';

/// Pantalla de Préstamos (plata que el usuario le prestó a alguien), con
/// dos pestañas:
/// - **Por cobrar**: totales arriba y una cuadrícula de tarjetas, cada una
///   con su botón "Registrar abono".
/// - **Cobrados**: los préstamos ya pagados, con "Limpiar historial".
class PrestamosScreen extends StatefulWidget {
  const PrestamosScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<PrestamosScreen> createState() => _PrestamosScreenState();
}

/// Un préstamo con sus abonos y las cuentas ya hechas.
class _Resumen {
  _Resumen(this.prestamo, this.abonos)
    : abonado = abonos.fold<int>(0, (sum, a) => sum + a.monto) {
    saldo = InteresCalculator.calcularDeudaTotal(
      montoPrestado: prestamo.montoPrestado,
      tasaInteres: prestamo.tasaInteres,
      tipoInteres: prestamo.tipoInteres,
      modalidadCalculo: prestamo.modalidadCalculo,
      fechaPrestamo: prestamo.fechaPrestamo,
      totalAbonado: abonado,
      tipoAmortizacion: prestamo.tipoAmortizacion,
      abonos: abonos,
      fechaFin: fechaFinCongeladaPrestamo(prestamo),
    );
  }

  final Prestamo prestamo;
  final List<AbonoInteres> abonos;
  final int abonado;

  /// Lo que falta por cobrar hoy (con interés).
  late final int saldo;

  /// Lo prestado más el interés: lo ya cobrado más lo que falta.
  int get total => abonado + saldo;

  double get fraccionCobrada => total > 0 ? abonado / total : 0.0;

  bool get activo => prestamo.estado == 'activo';

  /// Pasó la fecha pactada y sigue sin pagarse.
  bool get vencido =>
      activo &&
      prestamo.fechaPactadaPago != null &&
      fechaCivilGuardada(
        prestamo.fechaPactadaPago!,
      ).isBefore(normalizarFechaCivil(DateTime.now()));
}

class _PrestamosScreenState extends State<PrestamosScreen> {
  static const _pestanas = [
    OpcionPildora('Por cobrar'),
    OpcionPildora('Cobrados'),
  ];

  late final Stream<List<_Resumen>> _stream = _observar();
  int _pestana = 0;

  /// Préstamo abierto en el panel de detalle (solo PC).
  int? _seleccionado;

  /// Ancho mínimo para abrir el detalle como panel al lado de las tarjetas.
  static const _anchoMinimoPanel = 800.0;
  static const _anchoPanel = 440.0;

  // Join sin agregar (en vez de groupBy + sum): el modo de amortización
  // 'saldo_insoluto' necesita la fecha de cada abono, no solo la suma — ver
  // InteresCalculator._resumenSaldoInsoluto. Se agrupa en Dart.
  Stream<List<_Resumen>> _observar() {
    final p = widget.db.prestamos;
    final pr = widget.db.pagosRecibidos;
    final query = widget.db.select(p).join([
      leftOuterJoin(pr, pr.prestamoId.equalsExp(p.id)),
    ]);
    return query.watch().map((rows) {
      final prestamos = <int, Prestamo>{};
      final abonosPorPrestamo = <int, List<AbonoInteres>>{};
      for (final row in rows) {
        final prestamo = row.readTable(p);
        prestamos[prestamo.id] = prestamo;
        final pago = row.readTableOrNull(pr);
        if (pago != null) {
          (abonosPorPrestamo[prestamo.id] ??= []).add(
            AbonoInteres(fecha: pago.fechaPago, monto: pago.montoAbonado),
          );
        }
      }
      return [
        for (final prestamo in prestamos.values)
          _Resumen(prestamo, abonosPorPrestamo[prestamo.id] ?? const []),
      ]..sort(
        (a, b) => b.prestamo.fechaPrestamo.compareTo(a.prestamo.fechaPrestamo),
      );
    });
  }

  Future<void> _nuevo() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PrestamoForm(db: widget.db)),
  );

  void _abrir(int prestamoId, {required bool enPanel}) {
    if (enPanel) {
      setState(() => _seleccionado = prestamoId);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrestamoDetalle(db: widget.db, prestamoId: prestamoId),
      ),
    );
  }

  Future<void> _marcarPagado(Prestamo prestamo) async {
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
      prestamo.id,
      normalizarFechaCivil(DateTime.now()),
    );
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
    if (ok) await widget.db.prestamosDao.reactivarPrestamo(prestamo.id);
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
      await widget.db.prestamosDao.deletePrestamoConPagos(prestamo.id);
    } catch (_) {
      if (mounted) mostrarAlerta(context, 'No se pudo eliminar el préstamo.');
    }
  }

  /// Elimina todos los préstamos cobrados (con sus pagos), tras confirmar.
  Future<void> _limpiarHistorial(int cuantos) async {
    final ok = await confirmar(
      context,
      titulo: 'Limpiar historial',
      mensaje:
          'Se ${cuantos == 1 ? 'eliminará el préstamo cobrado' : 'eliminarán los $cuantos préstamos cobrados'} '
          'y todos sus pagos registrados. Los préstamos por cobrar no se '
          'tocan. No se puede deshacer.',
      accion: 'Limpiar historial',
      peligro: true,
    );
    if (!ok || !mounted) return;
    try {
      final n = await widget.db.prestamosDao.deletePrestamosPagados();
      if (!mounted) return;
      setState(() => _seleccionado = null);
      mostrarExito(
        context,
        n == 1
            ? 'Se eliminó 1 préstamo cobrado.'
            : 'Se eliminaron $n préstamos cobrados.',
      );
    } catch (_) {
      if (mounted) mostrarAlerta(context, 'No se pudo limpiar el historial.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<_Resumen>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error al cargar los datos.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final todos = snapshot.data!;
            final activos = [
              for (final r in todos)
                if (r.activo) r,
            ];
            final cobrados = [
              for (final r in todos)
                if (!r.activo) r,
            ];
            return LayoutBuilder(
              builder: (context, constraints) {
                final conPanel = constraints.maxWidth >= _anchoMinimoPanel;
                final margen = conPanel ? AppSpacing.xl : AppSpacing.md;
                final lista = _pestana == 0 ? activos : cobrados;
                // El panel solo se muestra si el préstamo elegido sigue en
                // la pestaña que se está viendo.
                final panelAbierto =
                    conPanel &&
                    lista.any((r) => r.prestamo.id == _seleccionado);
                final elegido = panelAbierto ? _seleccionado : null;

                final principal = Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppSpacing.anchoContenido + 2 * margen,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            margen,
                            margen,
                            margen,
                            AppSpacing.lg,
                          ),
                          child: EncabezadoPantalla(
                            kicker: switch (activos.length) {
                              0 => 'Nada por cobrar',
                              _ => '${activos.length} por cobrar',
                            },
                            titulo: 'Préstamos',
                            accion: BotonCrear(
                              texto: 'Nuevo préstamo',
                              heroTag: 'fab_prestamos',
                              onPressed: _nuevo,
                            ),
                          ),
                        ),
                        // Pestañas a la izquierda y, en "Cobrados", el botón
                        // de limpiar el historial a la derecha.
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
                                  _seleccionado = null;
                                }),
                              ),
                            ),
                            if (_pestana == 1 && cobrados.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(right: margen),
                                child: BotonLimpiarHistorial(
                                  onPressed: () =>
                                      _limpiarHistorial(cobrados.length),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(
                          height: conPanel ? AppSpacing.md : AppSpacing.sm,
                        ),
                        Expanded(
                          child: _pestana == 0
                              ? _PorCobrar(
                                  activos: activos,
                                  margen: margen,
                                  seleccionado: elegido,
                                  onAbrir: (id) =>
                                      _abrir(id, enPanel: conPanel),
                                  onAbonar: (r) => registrarAbonoPrestamo(
                                    context,
                                    widget.db,
                                    r.prestamo,
                                    r.abonos,
                                  ),
                                  onMarcarPagado: _marcarPagado,
                                  onEliminar: _eliminar,
                                )
                              : _Cobrados(
                                  cobrados: cobrados,
                                  margen: margen,
                                  seleccionado: elegido,
                                  onAbrir: (id) =>
                                      _abrir(id, enPanel: conPanel),
                                  onReactivar: _reactivar,
                                  onEliminar: _eliminar,
                                ),
                        ),
                      ],
                    ),
                  ),
                );

                if (!panelAbierto) return principal;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: principal),
                    Container(
                      key: const ValueKey('panel-prestamo'),
                      width: _anchoPanel,
                      decoration: BoxDecoration(
                        color: context.colores.superficie,
                        border: Border(
                          left: BorderSide(
                            color: context.colores.divisor,
                            width: AppSpacing.borde,
                          ),
                        ),
                      ),
                      child: PrestamoDetalleContenido(
                        // Clave por préstamo: al elegir otro, el panel
                        // arranca limpio con sus propios datos.
                        key: ValueKey(_seleccionado),
                        db: widget.db,
                        prestamoId: _seleccionado!,
                        onSalir: () => setState(() => _seleccionado = null),
                        onCerrar: () => setState(() => _seleccionado = null),
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

class _PorCobrar extends StatelessWidget {
  const _PorCobrar({
    required this.activos,
    required this.margen,
    required this.seleccionado,
    required this.onAbrir,
    required this.onAbonar,
    required this.onMarcarPagado,
    required this.onEliminar,
  });

  final List<_Resumen> activos;
  final double margen;
  final int? seleccionado;
  final ValueChanged<int> onAbrir;
  final ValueChanged<_Resumen> onAbonar;
  final ValueChanged<Prestamo> onMarcarPagado;
  final ValueChanged<Prestamo> onEliminar;

  /// Alto fijo de cada tarjeta de la cuadrícula.
  static const _altoTarjeta = 236.0;

  @override
  Widget build(BuildContext context) {
    if (activos.isEmpty) {
      return const _Vacio(
        'Nadie te debe dinero por ahora.\nToca + para registrar un préstamo.',
      );
    }
    final teDeben = activos.fold<int>(0, (s, r) => s + r.saldo);
    final personas = {
      for (final r in activos) r.prestamo.deudorNombre.trim().toLowerCase(),
    }.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth - 2 * margen;
        final columnas = ancho >= 900 ? 3 : (ancho >= 560 ? 2 : 1);
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(margen, AppSpacing.sm, margen, 0),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 40,
                  runSpacing: AppSpacing.md,
                  children: [
                    _Total(titulo: 'Te deben', valor: formatCOP(teDeben)),
                    _Total(titulo: 'Personas', valor: '$personas'),
                  ],
                ),
              ),
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
                itemCount: activos.length,
                itemBuilder: (context, i) {
                  final r = activos[i];
                  return _TarjetaPrestamo(
                    key: ValueKey(r.prestamo.id),
                    resumen: r,
                    elegida: r.prestamo.id == seleccionado,
                    onTap: () => onAbrir(r.prestamo.id),
                    onAbonar: () => onAbonar(r),
                    onMarcarPagado: () => onMarcarPagado(r.prestamo),
                    onEliminar: () => onEliminar(r.prestamo),
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

class _Total extends StatelessWidget {
  const _Total({required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width >= 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titulo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

/// Menú de tres puntos de un préstamo.
class _MenuPrestamo extends StatelessWidget {
  const _MenuPrestamo({
    this.onMarcarPagado,
    this.onReactivar,
    required this.onEliminar,
  });

  final VoidCallback? onMarcarPagado;
  final VoidCallback? onReactivar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: c.textoSecundario, size: 20),
        padding: EdgeInsets.zero,
        tooltip: 'Acciones',
        onSelected: (v) => switch (v) {
          'pagado' => onMarcarPagado?.call(),
          'reactivar' => onReactivar?.call(),
          _ => onEliminar(),
        },
        itemBuilder: (_) => [
          if (onMarcarPagado != null)
            const PopupMenuItem(
              value: 'pagado',
              child: Text('Marcar como pagado'),
            ),
          if (onReactivar != null)
            const PopupMenuItem(
              value: 'reactivar',
              child: Text('Reactivar préstamo'),
            ),
          PopupMenuItem(
            value: 'eliminar',
            child: Text('Eliminar', style: TextStyle(color: c.alerta)),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de un préstamo por cobrar: a quién, cuándo vence, lo que falta,
/// barra de avance y el botón para registrar un abono.
class _TarjetaPrestamo extends StatelessWidget {
  const _TarjetaPrestamo({
    super.key,
    required this.resumen,
    required this.elegida,
    required this.onTap,
    required this.onAbonar,
    required this.onMarcarPagado,
    required this.onEliminar,
  });

  final _Resumen resumen;
  final bool elegida;
  final VoidCallback onTap;
  final VoidCallback onAbonar;
  final VoidCallback onMarcarPagado;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    final p = resumen.prestamo;
    final hoy = DateTime.now();
    final pequeno = theme.textTheme.bodySmall?.copyWith(
      color: c.textoSecundario,
    );
    final prestadoEl =
        'Prestado el ${fechaCorta(fechaCivilGuardada(p.fechaPrestamo), hoy)}';
    final pactada = p.fechaPactadaPago == null
        ? null
        : fechaCivilGuardada(p.fechaPactadaPago!);
    final tasa = etiquetaTasaPrestamo(p);

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
        onLongPress: onEliminar,
        onSecondaryTap: onEliminar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarPersona(nombre: p.deudorNombre),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.deudorNombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          p.deudorContacto.isEmpty
                              ? prestadoEl
                              : p.deudorContacto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: pequeno,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (resumen.vencido)
                    _Etiqueta(
                      texto: 'Vencido ${fechaCorta(pactada!, hoy)}',
                      alerta: true,
                    )
                  else if (pactada != null)
                    _Etiqueta(texto: 'Vence ${fechaCorta(pactada, hoy)}'),
                  _MenuPrestamo(
                    onMarcarPagado: onMarcarPagado,
                    onEliminar: onEliminar,
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatCOP(resumen.saldo),
                          style: monoStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'pendiente de ${formatCOP(resumen.total)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: pequeno,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: BarraProgreso(
                  fraccion: resumen.fraccionCobrada,
                  color: c.positivo,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.deudorContacto.isEmpty ? tasa : '$prestadoEl · $tasa',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: pequeno,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: onAbonar,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: const TextStyle(
                          fontFamily: fuenteTexto,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Registrar abono'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta en píldora: gris (un dato) o roja (algo vencido).
class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, this.alerta = false});

  final String texto;
  final bool alerta;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: ShapeDecoration(
        color: alerta ? c.alerta.withValues(alpha: 0.14) : c.relieve,
        shape: const StadiumBorder(),
      ),
      child: Text(
        texto,
        maxLines: 1,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: alerta ? c.alerta : c.textoSecundario,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Cobrados extends StatelessWidget {
  const _Cobrados({
    required this.cobrados,
    required this.margen,
    required this.seleccionado,
    required this.onAbrir,
    required this.onReactivar,
    required this.onEliminar,
  });

  final List<_Resumen> cobrados;
  final double margen;
  final int? seleccionado;
  final ValueChanged<int> onAbrir;
  final ValueChanged<Prestamo> onReactivar;
  final ValueChanged<Prestamo> onEliminar;

  @override
  Widget build(BuildContext context) {
    if (cobrados.isEmpty) {
      return const _Vacio(
        'Todavía no has terminado de cobrar ningún préstamo.',
      );
    }
    final theme = Theme.of(context);
    final c = context.colores;
    // Los cobrados más recientemente, primero.
    final ordenados = [...cobrados]
      ..sort((a, b) {
        final fa = a.prestamo.fechaPagoReal ?? a.prestamo.actualizadoEn;
        final fb = b.prestamo.fechaPagoReal ?? b.prestamo.actualizadoEn;
        return fb.compareTo(fa);
      });
    final hoy = DateTime.now();
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(margen, AppSpacing.sm, margen, margen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, r) in ordenados.indexed) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 22,
                      endIndent: 22,
                      color: c.divisor,
                    ),
                  Material(
                    key: ValueKey(r.prestamo.id),
                    color: r.prestamo.id == seleccionado
                        ? c.relieve
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () => onAbrir(r.prestamo.id),
                      onLongPress: () => onEliminar(r.prestamo),
                      onSecondaryTap: () => onEliminar(r.prestamo),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 12, 10, 12),
                        child: Row(
                          children: [
                            AvatarPersona(
                              nombre: r.prestamo.deudorNombre,
                              lado: 34,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.prestamo.deudorNombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    r.prestamo.fechaPagoReal == null
                                        ? 'Cobrado'
                                        : 'Cobrado ${fechaCorta(fechaCivilGuardada(r.prestamo.fechaPagoReal!), hoy)}',
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
                            const SizedBox(width: AppSpacing.xs),
                            _MenuPrestamo(
                              onReactivar: () => onReactivar(r.prestamo),
                              onEliminar: () => onEliminar(r.prestamo),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
