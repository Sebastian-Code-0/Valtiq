import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/app_lock_service.dart';
import '../../theme/theme.dart';
import '../../utils/encabezado_pantalla.dart';

/// El ícono de la app (el logo sobre negro, con las esquinas redondeadas),
/// igual al que se ve en el celular. Se ve bien en tema claro y oscuro.
class IconoValtiq extends StatelessWidget {
  const IconoValtiq({super.key, this.tamano = 64});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(tamano * 0.28),
      child: Image.asset(
        'assets/logo_app.png',
        width: tamano,
        height: tamano,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Pantalla de PIN: encabezado, puntos y teclado numérico propio (no el
/// del sistema). En PC también se puede escribir con el teclado físico.
///
/// [onEnviar] recibe el PIN y devuelve el mensaje de error, o `null` si
/// salió bien. Con error, los puntos se sacuden y se borran solos.
///
/// Si se sabe el [largo] del PIN, entra sola al escribir el último número;
/// si no, aparece el botón [textoBoton].
class EntradaPin extends StatefulWidget {
  const EntradaPin({
    super.key,
    required this.titulo,
    required this.onEnviar,
    this.kicker,
    this.subtitulo,
    this.encabezado,
    this.largo,
    this.largoMaximo = AppLockService.largoMaximoVerificar,
    this.textoBoton = 'Entrar',
    this.onBiometria,
  });

  final String titulo;
  final String? kicker;
  final String? subtitulo;

  /// Lo que va encima del título (el ícono de la app).
  final Widget? encabezado;

  final Future<String?> Function(String pin) onEnviar;
  final int? largo;
  final int largoMaximo;
  final String textoBoton;

  /// Si no es `null`, la tecla de abajo a la izquierda es la huella.
  final VoidCallback? onBiometria;

  @override
  State<EntradaPin> createState() => _EntradaPinState();
}

class _EntradaPinState extends State<EntradaPin>
    with SingleTickerProviderStateMixin {
  final _foco = FocusNode(debugLabel: 'EntradaPin');
  late final _sacudida = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  String _pin = '';
  String? _error;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    // Toma el foco aunque otra cosa de la app lo tenga (la pantalla de
    // bloqueo se pinta encima de todo), para que el teclado físico sirva.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _foco.requestFocus();
    });
  }

  @override
  void dispose() {
    _foco.dispose();
    _sacudida.dispose();
    super.dispose();
  }

  void _agregar(String digito) {
    if (_enviando || _pin.length >= widget.largoMaximo) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += digito;
      _error = null;
    });
    if (widget.largo != null && _pin.length == widget.largo) _enviar();
  }

  void _borrar({bool todo = false}) {
    if (_enviando || _pin.isEmpty) return;
    setState(() {
      _pin = todo ? '' : _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    if (_pin.length < AppLockService.largoMinimo) {
      _fallo('Mínimo ${AppLockService.largoMinimo} números');
      return;
    }
    setState(() => _enviando = true);
    final error = await widget.onEnviar(_pin);
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _pin = '';
    });
    if (error != null) _fallo(error);
  }

  void _fallo(String mensaje) {
    HapticFeedback.mediumImpact();
    setState(() {
      _error = mensaje;
      _pin = '';
    });
    _sacudida.forward(from: 0);
  }

  KeyEventResult _tecla(FocusNode _, KeyEvent evento) {
    if (evento is! KeyDownEvent && evento is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final caracter = evento.character;
    if (caracter != null && RegExp(r'^\d$').hasMatch(caracter)) {
      _agregar(caracter);
      return KeyEventResult.handled;
    }
    final k = evento.logicalKey;
    if (k == LogicalKeyboardKey.backspace) {
      _borrar();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      _enviar();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final error = _error;
    final hayBoton = widget.largo == null;

    return Focus(
      focusNode: _foco,
      onKeyEvent: _tecla,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.encabezado != null) ...[
              widget.encabezado!,
              const SizedBox(height: AppSpacing.lg),
            ],
            if (widget.kicker != null) ...[
              TextoKicker(widget.kicker!),
              const SizedBox(height: 6),
            ],
            Text(
              widget.titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: fuenteTexto,
                fontSize: 26,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: c.texto,
              ),
            ),
            if (widget.subtitulo != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.subtitulo!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: fuenteTexto,
                  fontSize: 14,
                  height: 1.4,
                  color: c.textoSecundario,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AnimatedBuilder(
              animation: _sacudida,
              builder: (context, child) {
                final t = _sacudida.value;
                final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: _Puntos(
                escritos: _pin.length,
                total: widget.largo ?? math.max(4, _pin.length),
                color: error != null ? c.alerta : c.acento,
              ),
            ),
            SizedBox(
              height: 36,
              child: Center(
                child: Text(
                  error ?? (_enviando && !hayBoton ? 'Verificando…' : ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: fuenteTexto,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: error != null ? c.alerta : c.textoSecundario,
                  ),
                ),
              ),
            ),
            _Teclado(
              onDigito: _agregar,
              onBorrar: () => _borrar(),
              onBorrarTodo: () => _borrar(todo: true),
              onBiometria: widget.onBiometria,
            ),
            if (hayBoton) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: 264,
                height: 48,
                child: FilledButton(
                  onPressed:
                      _enviando || _pin.length < AppLockService.largoMinimo
                      ? null
                      : _enviar,
                  child: _enviando
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.textoSecundario,
                          ),
                        )
                      : Text(widget.textoBoton),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Un punto por número: relleno los escritos, solo el borde los que faltan.
class _Puntos extends StatelessWidget {
  const _Puntos({
    required this.escritos,
    required this.total,
    required this.color,
  });

  final int escritos;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Semantics(
      label: '$escritos de $total números escritos',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              margin: const EdgeInsets.symmetric(horizontal: 7),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < escritos ? color : Colors.transparent,
                border: Border.all(
                  color: i < escritos
                      ? color
                      : c.textoSecundario.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Teclado extends StatelessWidget {
  const _Teclado({
    required this.onDigito,
    required this.onBorrar,
    required this.onBorrarTodo,
    required this.onBiometria,
  });

  final ValueChanged<String> onDigito;
  final VoidCallback onBorrar;
  final VoidCallback onBorrarTodo;
  final VoidCallback? onBiometria;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    Widget fila(List<Widget> teclas) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(mainAxisSize: MainAxisSize.min, children: teclas),
    );
    Widget digito(String d) => _Tecla(
      onTap: () => onDigito(d),
      conFondo: true,
      child: Text(
        d,
        style: TextStyle(
          fontFamily: fuenteTexto,
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: c.texto,
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        fila([digito('1'), digito('2'), digito('3')]),
        fila([digito('4'), digito('5'), digito('6')]),
        fila([digito('7'), digito('8'), digito('9')]),
        fila([
          if (onBiometria != null)
            _Tecla(
              onTap: onBiometria!,
              tooltip: 'Usar huella o rostro',
              child: Icon(Icons.fingerprint, size: 30, color: c.acento),
            )
          else
            const _Tecla.vacia(),
          digito('0'),
          _Tecla(
            onTap: onBorrar,
            onLongPress: onBorrarTodo,
            tooltip: 'Borrar',
            child: Icon(
              Icons.backspace_outlined,
              size: 24,
              color: c.textoSecundario,
            ),
          ),
        ]),
      ],
    );
  }
}

class _Tecla extends StatelessWidget {
  const _Tecla({
    required VoidCallback this.onTap,
    required Widget this.child,
    this.onLongPress,
    this.tooltip,
    this.conFondo = false,
  });

  const _Tecla.vacia()
    : onTap = null,
      child = null,
      onLongPress = null,
      tooltip = null,
      conFondo = false;

  static const double tamano = 72;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? child;
  final String? tooltip;

  /// Los números llevan fondo y borde; borrar y huella van sueltos.
  final bool conFondo;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    Widget tecla = SizedBox(width: tamano, height: tamano);
    if (child != null) {
      tecla = Material(
        color: conFondo ? c.superficie : Colors.transparent,
        shape: CircleBorder(
          side: conFondo
              ? BorderSide(color: c.divisor, width: AppSpacing.borde)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          // El teclado propio maneja el foco; las teclas no lo roban.
          canRequestFocus: false,
          child: SizedBox(
            width: tamano,
            height: tamano,
            child: Center(child: child),
          ),
        ),
      );
      if (tooltip != null) tecla = Tooltip(message: tooltip!, child: tecla);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: tecla,
    );
  }
}
