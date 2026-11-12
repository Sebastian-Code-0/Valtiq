import 'dart:async';

import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/dashboard_service.dart';
import '../../services/perfil_service.dart';
import '../../theme/theme.dart';
import '../../utils/date_format.dart';
import '../../utils/encabezado_pantalla.dart';
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
      nota: 'Lo que debes hoy',
      icono: Icons.credit_card,
      colorIcono: context.colores.alerta,
      stream: _streamDeudas,
      compacta: compacta,
    ),
    _ResumenCard(
      titulo: 'Prestado activo',
      nota: 'Lo que te deben hoy',
      icono: Icons.handshake_outlined,
      colorIcono: Theme.of(context).colorScheme.primary,
      stream: _streamPrestamos,
      compacta: compacta,
    ),
    _ResumenCard(
      titulo: 'Ingresos mensuales',
      nota: 'Lo que entra este mes',
      icono: Icons.trending_up,
      colorIcono: context.colores.positivo,
      stream: _streamIngresos,
      compacta: compacta,
    ),
    _ResumenCard(
      titulo: 'Gastos fijos mensuales',
      nota: 'Lo que sale cada mes',
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
            padding: EdgeInsets.all(escritorio ? AppSpacing.xl : AppSpacing.md),
            child: escritorio
                // En monitores grandes el contenido no se estira de más.
                ? Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.anchoContenido,
                      ),
                      child: _contenidoEscritorio(context, ocultos),
                    ),
                  )
                : _contenidoCelular(context, ocultos),
          ),
        ),
      ),
    );
  }

  Widget _botonOcultar(bool ocultos, {required bool conTexto}) {
    final icono = Icon(
      ocultos ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      size: conTexto ? 18 : null,
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

  /// Fecha de hoy (rótulo) + saludo (título grande).
  Widget _encabezado({Widget? accion}) => ValueListenableBuilder<Perfil>(
    valueListenable: PerfilService.perfil,
    builder: (context, perfil, _) => EncabezadoPantalla(
      kicker: formatFechaEncabezado(DateTime.now()),
      // Solo el nombre (sin apellido): más cercano.
      titulo: perfil.nombre.isEmpty
          ? saludoSegunHora(DateTime.now())
          : '${saludoSegunHora(DateTime.now())}, ${perfil.nombre}',
      accion: accion,
    ),
  );

  Widget _contenidoEscritorio(BuildContext context, bool ocultos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _encabezado(accion: _botonOcultar(ocultos, conTexto: true)),
        const SizedBox(height: 28),
        // Cuatro tarjetas pequeñas, una al lado de la otra. (La de "gastos
        // del día a día" se quitó aquí: con cinco se rompía la fila.)
        SizedBox(
          height: 132,
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
              height: 28,
              color: Theme.of(context).colorScheme.primary,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(width: 10),
            Text(
              'Valtiq',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const Spacer(),
            _botonOcultar(ocultos, conTexto: false),
            const SizedBox(width: AppSpacing.xs),
            // A Ajustes se entra por la foto, igual que en el menú de PC.
            Tooltip(
              message: 'Ajustes',
              child: InkWell(
                key: const ValueKey('inicio-ajustes'),
                onTap: _abrirAjustes,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ValueListenableBuilder<Perfil>(
                    valueListenable: PerfilService.perfil,
                    builder: (context, perfil, _) =>
                        FotoPerfil(perfil: perfil, radio: 19),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: _encabezado(),
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
                nota: 'Lo que llevas gastado este mes',
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

/// Tarjeta de un total: rótulo con ícono arriba, la cifra grande y una
/// nota corta debajo.
class _ResumenCard extends StatelessWidget {
  const _ResumenCard({
    required this.titulo,
    required this.nota,
    required this.icono,
    required this.colorIcono,
    required this.stream,
    this.compacta = false,
  });

  /// Versión de la fila de cuatro en PC: cifra más grande.
  final bool compacta;

  final String titulo;
  final String nota;
  final IconData icono;
  final Color colorIcono;
  final Stream<double> stream;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compacta ? 20 : AppSpacing.md,
          vertical: compacta ? 18 : AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icono, color: colorIcono, size: 16),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    titulo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12.5,
                      color: c.textoSecundario,
                    ),
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
                    style: monoStyle(
                      fontSize: compacta ? 26 : 20,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                  ),
                );
              },
            ),
            Text(
              nota,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: c.textoSecundario,
              ),
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
        padding: const EdgeInsets.all(26),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatMonto(disponible),
                              style: monoStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
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
        padding: const EdgeInsets.all(26),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatMonto(neto),
                              style: monoStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
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
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13.5,
              color: context.colores.textoSecundario,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            valor,
            style: monoStyle(
              fontSize: 14.5,
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
