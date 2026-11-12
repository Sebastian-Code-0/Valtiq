import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../../theme/theme.dart';
import '../../utils/preferencia_menu.dart';
import '../../utils/selector_pildoras.dart';
import '../barra_lateral.dart';
import 'settings_screen.dart';

/// A partir de este ancho la pantalla se considera "de PC": las vistas
/// previas muestran la app como ventana (con menú lateral) en vez de como
/// celular (con barra inferior).
const double _anchoEscritorio = 600;

/// Ancho máximo de la tarjeta en PC: en un monitor grande, a todo lo ancho
/// las miniaturas quedaban enormes. Va centrada.
const double _anchoMaximo = 1240;

class AparienciaScreen extends StatefulWidget {
  const AparienciaScreen({super.key});

  @override
  State<AparienciaScreen> createState() => _AparienciaScreenState();
}

class _AparienciaScreenState extends State<AparienciaScreen> {
  ThemeMode _modoActual = themeModeNotifier.value;

  Future<void> _cambiarTema(ThemeMode modo) async {
    setState(() => _modoActual = modo);
    themeModeNotifier.value = modo;
    final prefs = await SharedPreferences.getInstance();
    final key = switch (modo) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString('valtiq_theme', key);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: barraAjustes(context, 'Apariencia'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final escritorio = constraints.maxWidth >= _anchoEscritorio;
          final separacion = escritorio ? AppSpacing.lg : AppSpacing.sm;
          // Las miniaturas se estiran para aprovechar la pantalla: se
          // calcula cuánto ancho le toca a cada una y cuánto alto queda
          // libre, y de ahí sale su proporción — dentro de límites, para
          // que sigan pareciendo un celular (alto) o una ventana (ancha).
          // Si la ventana es bajita, la tarjeta simplemente se desplaza.
          final anchoTarjeta = (constraints.maxWidth - 2 * AppSpacing.md).clamp(
            0.0,
            _anchoMaximo,
          );
          final anchoOpcion =
              (anchoTarjeta - 2 * AppSpacing.md - 2 * separacion) / 3 - 10;
          final altoLibre = constraints.maxHeight - 4 * AppSpacing.md - 170;
          final proporcion = altoLibre <= 0
              ? (escritorio ? 2.1 : 0.62)
              : (anchoOpcion / altoLibre).clamp(
                  // En PC, ventanas apaisadas (nunca casi cuadradas): la tarjeta
                  // queda ancha y baja.
                  escritorio ? 1.55 : 0.46,
                  escritorio ? 2.1 : 0.62,
                );
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _anchoMaximo),
                  // Cada ajuste de Apariencia va en su propia tarjeta: cuando
                  // se agreguen más (además del tema), cada uno queda
                  // separado y se entiende a qué pertenece.
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tema',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Elige cómo se ve Valtiq. Así se verá cada uno:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.colores.textoSecundario,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _OpcionTema(
                                  nombre: 'Sistema',
                                  detalle: 'Igual que tu dispositivo',
                                  icono: Icons.brightness_auto,
                                  seleccionado: _modoActual == ThemeMode.system,
                                  escritorio: escritorio,
                                  proporcion: proporcion,
                                  onTap: () => _cambiarTema(ThemeMode.system),
                                  vistaPrevia: _VistaPreviaDividida(
                                    escritorio: escritorio,
                                  ),
                                ),
                              ),
                              SizedBox(width: separacion),
                              Expanded(
                                child: _OpcionTema(
                                  nombre: 'Claro',
                                  detalle: 'Beige lino',
                                  icono: Icons.light_mode,
                                  seleccionado: _modoActual == ThemeMode.light,
                                  escritorio: escritorio,
                                  proporcion: proporcion,
                                  onTap: () => _cambiarTema(ThemeMode.light),
                                  vistaPrevia: _VistaPrevia(
                                    colores: ValtiqColores.claro,
                                    escritorio: escritorio,
                                  ),
                                ),
                              ),
                              SizedBox(width: separacion),
                              Expanded(
                                child: _OpcionTema(
                                  nombre: 'Oscuro',
                                  detalle: 'Negro puro',
                                  icono: Icons.dark_mode,
                                  seleccionado: _modoActual == ThemeMode.dark,
                                  escritorio: escritorio,
                                  proporcion: proporcion,
                                  onTap: () => _cambiarTema(ThemeMode.dark),
                                  vistaPrevia: _VistaPrevia(
                                    colores: ValtiqColores.oscuro,
                                    escritorio: escritorio,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Solo en pantallas grandes: en celular el menú va abajo y no
              // hay nada que elegir.
              if (MediaQuery.sizeOf(context).width >= anchoMinimoBarraLateral)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _anchoMaximo),
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Menú',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Dónde va el menú de secciones en esta '
                                'pantalla: a la izquierda o arriba.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: context.colores.textoSecundario,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ValueListenableBuilder<bool>(
                                valueListenable: menuSuperiorNotifier,
                                builder: (context, arriba, _) =>
                                    GrupoPildoras<bool>(
                                      opciones: const {
                                        false: 'A la izquierda',
                                        true: 'Arriba',
                                      },
                                      valor: arriba,
                                      onElegir: setMenuSuperior,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Una opción de tema: la vista previa enmarcada + su nombre debajo. Toda
/// la tarjeta es tocable; la elegida se marca con borde vino y un check.
class _OpcionTema extends StatelessWidget {
  const _OpcionTema({
    required this.nombre,
    required this.detalle,
    required this.icono,
    required this.seleccionado,
    required this.escritorio,
    required this.proporcion,
    required this.onTap,
    required this.vistaPrevia,
  });

  final String nombre;
  final String detalle;
  final IconData icono;
  final bool seleccionado;
  final bool escritorio;

  /// Ancho ÷ alto de la miniatura.
  final double proporcion;
  final VoidCallback onTap;
  final Widget vistaPrevia;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final theme = Theme.of(context);
    final colorTitulo = seleccionado ? c.acento : c.texto;
    return Semantics(
      button: true,
      selected: seleccionado,
      label: 'Tema $nombre',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              // El borde elegido es más grueso; el relleno compensa la
              // diferencia para que la miniatura no cambie de tamaño (antes
              // daba un saltico al seleccionar).
              padding: EdgeInsets.all(seleccionado ? 4 : 5.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: seleccionado ? c.acento : c.divisor,
                  width: seleccionado ? 2.5 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: AspectRatio(
                  aspectRatio: proporcion,
                  child: ExcludeSemantics(child: vistaPrevia),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  seleccionado ? Icons.check_circle : icono,
                  size: 18,
                  color: seleccionado ? c.acento : c.textoSecundario,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    nombre,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorTitulo,
                      fontWeight: seleccionado
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (escritorio) ...[
              const SizedBox(height: 2),
              Text(
                detalle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: c.textoSecundario,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

/// "Sistema": mitad claro, mitad oscuro, cortado en diagonal.
class _VistaPreviaDividida extends StatelessWidget {
  const _VistaPreviaDividida({required this.escritorio});

  final bool escritorio;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _VistaPrevia(colores: ValtiqColores.claro, escritorio: escritorio),
        ClipPath(
          clipper: const _MitadDiagonal(),
          child: _VistaPrevia(
            colores: ValtiqColores.oscuro,
            escritorio: escritorio,
          ),
        ),
      ],
    );
  }
}

class _MitadDiagonal extends CustomClipper<Path> {
  const _MitadDiagonal();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Miniatura de la pantalla de Inicio pintada con los colores REALES de un
/// tema ([ValtiqColores.claro] / [ValtiqColores.oscuro]) — si la paleta
/// cambia, esta vista previa cambia sola. No lleva texto: son bloques que
/// imitan el saldo, las tarjetas de resumen, un botón y la navegación.
class _VistaPrevia extends StatelessWidget {
  const _VistaPrevia({required this.colores, required this.escritorio});

  final ValtiqColores colores;
  final bool escritorio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Unidad de medida relativa al tamaño real de la miniatura, para
        // que se vea igual de proporcionada en un celular angosto y en una
        // ventana grande.
        final u = constraints.maxWidth / (escritorio ? 40 : 18);
        return ColoredBox(
          color: colores.fondo,
          child: escritorio ? _escritorio(u) : _celular(u),
        );
      },
    );
  }

  Widget _celular(double u) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(u * 1.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _punto(colores.acento, u * 1.6),
                    const Spacer(),
                    _punto(colores.textoSecundario, u * 1.1),
                  ],
                ),
                SizedBox(height: u),
                Expanded(flex: 5, child: _tarjetaSaldo(u)),
                SizedBox(height: u * 0.8),
                Expanded(
                  flex: 4,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _tarjetaResumen(u, colores.positivo)),
                      SizedBox(width: u * 0.8),
                      Expanded(child: _tarjetaResumen(u, colores.alerta)),
                    ],
                  ),
                ),
                SizedBox(height: u * 0.8),
                Expanded(flex: 4, child: _tarjetaBarras(u)),
                SizedBox(height: u),
                _boton(u),
              ],
            ),
          ),
        ),
        Container(
          height: u * 2.6,
          decoration: BoxDecoration(
            color: colores.superficie,
            border: Border(top: BorderSide(color: colores.divisor)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _punto(colores.acento, u * 1.2),
              for (var i = 0; i < 3; i++)
                _punto(colores.textoSecundario, u * 1.2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _escritorio(double u) {
    return Row(
      children: [
        Container(
          width: u * 6,
          decoration: BoxDecoration(
            color: colores.superficie,
            border: Border(right: BorderSide(color: colores.divisor)),
          ),
          padding: EdgeInsets.all(u),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _punto(colores.acento, u * 1.8),
              SizedBox(height: u * 1.5),
              _linea(colores.acento, u * 0.7, 1),
              for (var i = 0; i < 3; i++) ...[
                SizedBox(height: u),
                _linea(colores.textoSecundario, u * 0.7, 0.75),
              ],
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(u * 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: _tarjetaSaldo(u)),
                      SizedBox(width: u),
                      Expanded(
                        flex: 2,
                        child: _tarjetaResumen(u, colores.positivo),
                      ),
                      SizedBox(width: u),
                      Expanded(
                        flex: 2,
                        child: _tarjetaResumen(u, colores.alerta),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: u),
                Expanded(flex: 6, child: _tarjetaBarras(u)),
                SizedBox(height: u),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(width: u * 10, child: _boton(u)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tarjeta(double u, Widget child) {
    return Container(
      padding: EdgeInsets.all(u),
      decoration: BoxDecoration(
        color: colores.superficie,
        borderRadius: BorderRadius.circular(u),
        border: Border.all(color: colores.divisor),
      ),
      child: child,
    );
  }

  Widget _tarjetaSaldo(double u) {
    return _tarjeta(
      u,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _linea(colores.textoSecundario, u * 0.6, 0.4),
          SizedBox(height: u * 0.8),
          _linea(colores.texto, u * 1.3, 0.75),
        ],
      ),
    );
  }

  Widget _tarjetaResumen(double u, Color color) {
    return _tarjeta(
      u,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _punto(color, u * 1.1),
          SizedBox(height: u * 0.7),
          _linea(colores.texto, u * 0.7, 0.8),
        ],
      ),
    );
  }

  Widget _tarjetaBarras(double u) {
    return _tarjeta(
      u,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _linea(colores.acento, u * 0.7, 0.9),
          _linea(colores.secundario, u * 0.7, 0.6),
          _linea(colores.textoSecundario, u * 0.7, 0.35),
        ],
      ),
    );
  }

  Widget _boton(double u) {
    return Container(
      height: u * 2.2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colores.acentoRelleno,
        borderRadius: BorderRadius.circular(u * 0.8),
      ),
      child: FractionallySizedBox(
        widthFactor: 0.45,
        child: Container(
          height: u * 0.6,
          decoration: BoxDecoration(
            color: colores.sobreAcento,
            borderRadius: BorderRadius.circular(u),
          ),
        ),
      ),
    );
  }

  Widget _punto(Color color, double tamano) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  /// Barra horizontal que imita una línea de texto; [ancho] es la fracción
  /// del espacio disponible que ocupa.
  Widget _linea(Color color, double alto, double ancho) {
    return FractionallySizedBox(
      widthFactor: ancho,
      child: Container(
        height: alto,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(alto),
        ),
      ),
    );
  }
}
