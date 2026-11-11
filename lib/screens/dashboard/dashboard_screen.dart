import 'dart:async';

import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/dashboard_service.dart';
import '../../services/perfil_service.dart';
import '../../theme/theme.dart';
import '../../utils/date_format.dart';
import '../../utils/form_widgets.dart';
import '../../utils/format.dart';
import '../barra_lateral.dart';
import '../config/settings_screen.dart';
import 'widgets/balance_donut.dart';
import 'widgets/comparativo_categorias.dart';
import 'widgets/presupuestos_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timerDia;
  late final Stream<double> _streamDeudas;
  late final Stream<double> _streamPrestamos;
  late final Stream<double> _streamIngresos;
  late final Stream<double> _streamGastos;
  late final Stream<double> _streamGastosVariables;
  late final Stream<({double ingresos, double gastos, double variables})>
  _streamBalance;

  @override
  void initState() {
    super.initState();
    final db = widget.db;

    _streamDeudas = DashboardService.watchTotalDeudasActivas(db);
    _streamPrestamos = DashboardService.watchTotalPrestamosActivos(db);
    _streamIngresos = DashboardService.watchIngresosMensuales(db);
    _streamGastos = DashboardService.watchGastosFijosMensuales(db);
    _streamGastosVariables = DashboardService.watchGastosVariablesMes(db);
    _streamBalance = DashboardService.watchBalanceMensual(db);
    _programarCambioDeDia();
  }

  /// Reconstruye la pantalla justo al cambiar el día o el saludo (mañana,
  /// tarde, noche), para que el encabezado esté siempre al día aunque la
  /// app quede abierta.
  void _programarCambioDeDia() {
    final ahora = DateTime.now();
    _timerDia = Timer(
      proximoCambioDeSaludo(ahora).difference(ahora) +
          const Duration(seconds: 1),
      () {
        if (!mounted) return;
        setState(() {});
        _programarCambioDeDia();
      },
    );
  }

  @override
  void dispose() {
    _timerDia?.cancel();
    super.dispose();
  }

  void _abrirAjustes() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => SettingsScreen(db: widget.db)),
  );

  List<Widget> _tarjetasResumen(
    BuildContext context, {
    required bool compacta,
  }) => [
    _ResumenCard(
      titulo: 'Deudas activas',
      icono: Icons.credit_card,
      colorIcono: context.colores.alerta,
      stream: _streamDeudas,
      compacta: compacta,
    ),
    _ResumenCard(
      titulo: 'Prestado activo',
      icono: Icons.handshake_outlined,
      colorIcono: Theme.of(context).colorScheme.primary,
      stream: _streamPrestamos,
      compacta: compacta,
    ),
    _ResumenCard(
      titulo: 'Ingresos mensuales',
      icono: Icons.trending_up,
      colorIcono: context.colores.positivo,
      stream: _streamIngresos,
      compacta: compacta,
    ),
    _ResumenCard(
      titulo: 'Gastos fijos mensuales',
      icono: Icons.trending_down,
      colorIcono: context.colores.alerta,
      stream: _streamGastos,
      compacta: compacta,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // En PC (ventana ancha) Inicio va junto al menú lateral y cambia de
    // forma: encabezado con fecha + saludo, cuatro tarjetas pequeñas en una
    // fila y el resto en dos columnas. En celular se conserva el diseño de
    // siempre.
    final escritorio =
        MediaQuery.sizeOf(context).width >= anchoMinimoBarraLateral;
    return ValueListenableBuilder<bool>(
      valueListenable: montosOcultosNotifier,
      builder: (context, ocultos, _) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(escritorio ? AppSpacing.lg : AppSpacing.md),
            child: escritorio
                ? _contenidoEscritorio(context, ocultos)
                : _contenidoCelular(context, ocultos),
          ),
        ),
      ),
    );
  }

  Widget _botonOcultar(bool ocultos, {required bool conTexto}) {
    final icono = Icon(
      ocultos ? Icons.visibility_outlined : Icons.visibility_off_outlined,
    );
    final texto = ocultos ? 'Mostrar montos' : 'Ocultar montos';
    return conTexto
        ? OutlinedButton.icon(
            onPressed: () => setMontosOcultos(!ocultos),
            icon: icono,
            label: Text(texto),
          )
        : IconButton(
            onPressed: () => setMontosOcultos(!ocultos),
            icon: icono,
            tooltip: texto,
          );
  }

  Widget _contenidoEscritorio(BuildContext context, bool ocultos) {
    final theme = Theme.of(context);
    final c = context.colores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatFechaEncabezado(DateTime.now()),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: c.textoSecundario,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ValueListenableBuilder<Perfil>(
                    valueListenable: PerfilService.perfil,
                    builder: (context, perfil, _) => Text(
                      // Solo el nombre (sin apellido): más cercano.
                      perfil.nombre.isEmpty
                          ? saludoSegunHora(DateTime.now())
                          : '${saludoSegunHora(DateTime.now())}, '
                                '${perfil.nombre}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _botonOcultar(ocultos, conTexto: true),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Cuatro tarjetas pequeñas, una al lado de la otra. (La de "gastos
        // del día a día" se quitó aquí: con cinco se rompía la fila.)
        SizedBox(
          height: 104,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, tarjeta) in _tarjetasResumen(
                context,
                compacta: true,
              ).indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: tarjeta),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _PosicionPrestamosCard(
                    streamPrestamos: _streamPrestamos,
                    streamDeudas: _streamDeudas,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PresupuestosCard(db: widget.db),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                children: [
                  _BalanceMensualCard(streamBalance: _streamBalance),
                  const SizedBox(height: AppSpacing.md),
                  ComparativoCategorias(db: widget.db),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _contenidoCelular(BuildContext context, bool ocultos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/logo_icono.png',
              height: 32,
              color: Theme.of(context).colorScheme.primary,
              colorBlendMode: BlendMode.srcIn,
            ),
            const Spacer(),
            _botonOcultar(ocultos, conTexto: false),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Configuración',
              onPressed: _abrirAjustes,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.25,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _tarjetasResumen(context, compacta: false),
        ),
        const SizedBox(height: AppSpacing.md),
        Builder(
          builder: (context) {
            final anchoDisponible =
                MediaQuery.sizeOf(context).width - AppSpacing.md * 2;
            final anchoCelda = (anchoDisponible - AppSpacing.md) / 2;
            final altoFila = anchoCelda / 1.25;
            return SizedBox(
              width: double.infinity,
              height: altoFila,
              child: _ResumenCard(
                titulo: 'Gastos del día a día (mes)',
                icono: Icons.shopping_bag_outlined,
                colorIcono: context.colores.alerta,
                stream: _streamGastosVariables,
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _PosicionPrestamosCard(
          streamPrestamos: _streamPrestamos,
          streamDeudas: _streamDeudas,
        ),
        const SizedBox(height: AppSpacing.md),
        _BalanceMensualCard(streamBalance: _streamBalance),
        const SizedBox(height: AppSpacing.md),
        ComparativoCategorias(db: widget.db),
        const SizedBox(height: AppSpacing.md),
        PresupuestosCard(db: widget.db),
      ],
    );
  }
}

class _ResumenCard extends StatelessWidget {
  const _ResumenCard({
    required this.titulo,
    required this.icono,
    required this.colorIcono,
    required this.stream,
    this.compacta = false,
  });

  /// Versión pequeña (fila de cuatro en PC): menos relleno.
  final bool compacta;

  final String titulo;
  final IconData icono;
  final Color colorIcono;
  final Stream<double> stream;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: compacta ? 12 : AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icono, color: colorIcono, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    titulo,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            StreamBuilder<double>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar los datos.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  // Sin esto, el primer valor real (que puede tardar un rato
                  // en llegar por el join con InteresCalculator) se ve como
                  // "$0" antes de saltar al monto correcto — un estado
                  // engañoso, no solo lento.
                  return const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final valor = snapshot.data!;
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatMonto(valor),
                    style: monoStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceMensualCard extends StatelessWidget {
  const _BalanceMensualCard({required this.streamBalance});

  final Stream<({double ingresos, double gastos, double variables})>
  streamBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child:
            StreamBuilder<({double ingresos, double gastos, double variables})>(
              stream: streamBalance,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar los datos.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const SizedBox(
                    height: 130,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final ingresos = snap.data?.ingresos ?? 0.0;
                final gastos = snap.data?.gastos ?? 0.0;
                final gastosVariables = snap.data?.variables ?? 0.0;
                final disponible = ingresos - gastos - gastosVariables;
                final disponibleColor = disponible >= 0
                    ? context.colores.positivo
                    : context.colores.alerta;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance mensual',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Pantallas angostas no tienen espacio para el
                        // anillo y las tres filas de montos lado a lado
                        // sin desbordar; ahí se apilan verticalmente.
                        final angosto = constraints.maxWidth < 360;
                        final donut = BalanceDonut(
                          ingresos: ingresos,
                          gastos: gastos,
                          gastosVariables: gastosVariables,
                          disponible: disponible,
                          disponibleColor: disponibleColor,
                          diametro: angosto ? 160 : 130,
                        );
                        final filas = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FilaMonto(
                              label: 'Ingresos',
                              valor: formatMonto(ingresos),
                              color: context.colores.positivo,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _FilaMonto(
                              label: 'Gastos fijos',
                              valor: '-${formatMonto(gastos)}',
                              color: context.colores.alerta,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _FilaMonto(
                              label: 'Gastos del día a día',
                              valor: '-${formatMonto(gastosVariables)}',
                              color: context.colores.alerta,
                            ),
                          ],
                        );

                        if (angosto) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(child: donut),
                              const SizedBox(height: AppSpacing.md),
                              filas,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            donut,
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: filas),
                          ],
                        );
                      },
                    ),
                    const Divider(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Disponible',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatMonto(disponible),
                              style: monoStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: disponibleColor,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
      ),
    );
  }
}

class _PosicionPrestamosCard extends StatelessWidget {
  const _PosicionPrestamosCard({
    required this.streamPrestamos,
    required this.streamDeudas,
  });

  final Stream<double> streamPrestamos;
  final Stream<double> streamDeudas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StreamBuilder<double>(
          stream: streamPrestamos,
          builder: (context, snapPres) {
            if (snapPres.hasError) {
              return Center(
                child: Text(
                  'Error al cargar los datos.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }
            return StreamBuilder<double>(
              stream: streamDeudas,
              builder: (context, snapDeu) {
                if (snapDeu.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar los datos.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                if (!snapPres.hasData || !snapDeu.hasData) {
                  return const SizedBox(
                    height: 130,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final prestado = snapPres.data ?? 0.0;
                final deudas = snapDeu.data ?? 0.0;
                final totalPosicion = prestado + deudas;
                final fraccionPrestado = totalPosicion == 0
                    ? 0.0
                    : prestado / totalPosicion;
                final fraccionDeudas = totalPosicion == 0
                    ? 0.0
                    : deudas / totalPosicion;
                final neto = prestado - deudas;
                final netoColor = neto >= 0
                    ? context.colores.positivo
                    : context.colores.alerta;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Posición de préstamos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FilaMonto(
                      label: 'Total prestado',
                      valor: formatMonto(prestado),
                      color: context.colores.positivo,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    BarraProgreso(
                      fraccion: fraccionPrestado,
                      color: context.colores.positivo,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _FilaMonto(
                      label: 'Total deudas',
                      valor: formatMonto(deudas),
                      color: context.colores.alerta,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    BarraProgreso(
                      fraccion: fraccionDeudas,
                      color: context.colores.alerta,
                    ),
                    const Divider(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Neto',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatMonto(neto),
                              style: monoStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: netoColor,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
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

class _FilaMonto extends StatelessWidget {
  const _FilaMonto({
    required this.label,
    required this.valor,
    required this.color,
  });

  final String label;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            valor,
            style: monoStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
