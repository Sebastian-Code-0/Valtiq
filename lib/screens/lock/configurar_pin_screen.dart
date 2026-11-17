import 'package:flutter/material.dart';

import '../../services/app_lock_service.dart';
import '../../theme/theme.dart';
import '../config/settings_screen.dart';
import 'teclado_pin.dart';

enum _Paso { pinActual, pinNuevo, confirmarPinNuevo }

/// Flujo de PIN: crear uno nuevo (`esCambio: false`, primera activación) o
/// cambiar el existente (`esCambio: true`, pide el PIN actual antes). Hace
/// `Navigator.pop(true)` si el PIN quedó guardado, `pop(false)`/back si el
/// usuario cancela — el caller (`SeguridadScreen`) decide qué hacer con
/// cada resultado.
class ConfigurarPinScreen extends StatefulWidget {
  const ConfigurarPinScreen({super.key, required this.esCambio});

  final bool esCambio;

  @override
  State<ConfigurarPinScreen> createState() => _ConfigurarPinScreenState();
}

class _ConfigurarPinScreenState extends State<ConfigurarPinScreen> {
  late _Paso _paso = widget.esCambio ? _Paso.pinActual : _Paso.pinNuevo;
  String? _pinNuevoTemporal;
  int? _largoActual;

  @override
  void initState() {
    super.initState();
    if (widget.esCambio) {
      AppLockService.largoPin().then((l) {
        if (mounted) setState(() => _largoActual = l);
      });
    }
  }

  String get _kicker {
    final total = widget.esCambio ? 3 : 2;
    final n = _paso.index + (widget.esCambio ? 1 : 0);
    return 'Paso $n de $total';
  }

  Future<String?> _enviar(String pin) async {
    switch (_paso) {
      case _Paso.pinActual:
        if (!await AppLockService.verificarPin(pin)) return 'PIN incorrecto';
        if (mounted) setState(() => _paso = _Paso.pinNuevo);
        return null;

      case _Paso.pinNuevo:
        _pinNuevoTemporal = pin;
        setState(() => _paso = _Paso.confirmarPinNuevo);
        return null;

      case _Paso.confirmarPinNuevo:
        if (pin != _pinNuevoTemporal) return 'No coincide, inténtalo otra vez';
        if (widget.esCambio) {
          await AppLockService.cambiarPin(pin);
        } else {
          await AppLockService.activarConPin(pin);
        }
        if (mounted) Navigator.pop(context, true);
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (titulo, subtitulo) = switch (_paso) {
      _Paso.pinActual => (
        'Ingresa tu PIN actual',
        'Para confirmar que eres tú.',
      ),
      _Paso.pinNuevo => (
        widget.esCambio ? 'Elige tu PIN nuevo' : 'Crea tu PIN',
        'De ${AppLockService.largoMinimo} a ${AppLockService.largoMaximo} '
            'números. Valtiq te lo pedirá cada vez que la abras.',
      ),
      _Paso.confirmarPinNuevo => (
        'Repite el PIN',
        'Escríbelo otra vez para confirmar.',
      ),
    };
    return Scaffold(
      appBar: barraAjustes(
        context,
        widget.esCambio ? 'Cambiar PIN' : 'Activar bloqueo',
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: EntradaPin(
            // Cada paso arranca con los puntos vacíos.
            key: ValueKey(_paso),
            kicker: _kicker,
            titulo: titulo,
            subtitulo: subtitulo,
            largo: switch (_paso) {
              _Paso.pinActual => _largoActual,
              _Paso.pinNuevo => null,
              _Paso.confirmarPinNuevo => _pinNuevoTemporal?.length,
            },
            largoMaximo: _paso == _Paso.pinActual
                ? AppLockService.largoMaximoVerificar
                : AppLockService.largoMaximo,
            textoBoton: 'Continuar',
            onEnviar: _enviar,
          ),
        ),
      ),
    );
  }
}

/// Pide el PIN actual antes de algo delicado (desactivar el bloqueo). Hace
/// `pop(true)` solo si el PIN es correcto.
class VerificarPinScreen extends StatefulWidget {
  const VerificarPinScreen({super.key, required this.titulo});

  final String titulo;

  @override
  State<VerificarPinScreen> createState() => _VerificarPinScreenState();
}

class _VerificarPinScreenState extends State<VerificarPinScreen> {
  bool _listo = false;
  int? _largo;

  @override
  void initState() {
    super.initState();
    AppLockService.largoPin().then((l) {
      if (mounted) {
        setState(() {
          _largo = l;
          _listo = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraAjustes(context, widget.titulo),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: !_listo
              ? const SizedBox.shrink()
              : EntradaPin(
                  titulo: 'Ingresa tu PIN',
                  subtitulo: 'Para confirmar que eres tú.',
                  largo: _largo,
                  textoBoton: 'Confirmar',
                  onEnviar: (pin) async {
                    if (!await AppLockService.verificarPin(pin)) {
                      return 'PIN incorrecto';
                    }
                    if (context.mounted) Navigator.pop(context, true);
                    return null;
                  },
                ),
        ),
      ),
    );
  }
}
