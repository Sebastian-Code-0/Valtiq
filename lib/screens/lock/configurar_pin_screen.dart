import 'package:flutter/material.dart';

import '../../services/app_lock_service.dart';
import '../../theme/theme.dart';

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
  final _ctrl = TextEditingController();
  String? _pinNuevoTemporal;
  String? _error;
  bool _procesando = false;

  static const _minLargo = 4;

  String get _titulo => switch (_paso) {
    _Paso.pinActual => 'Ingresa tu PIN actual',
    _Paso.pinNuevo => 'Elige un PIN nuevo',
    _Paso.confirmarPinNuevo => 'Confirma el PIN nuevo',
  };

  Future<void> _continuar() async {
    final valor = _ctrl.text;
    setState(() => _error = null);

    switch (_paso) {
      case _Paso.pinActual:
        if (valor.isEmpty) return;
        setState(() => _procesando = true);
        final ok = await AppLockService.verificarPin(valor);
        if (!mounted) return;
        setState(() => _procesando = false);
        if (!ok) {
          setState(() => _error = 'PIN incorrecto');
          _ctrl.clear();
          return;
        }
        _ctrl.clear();
        setState(() => _paso = _Paso.pinNuevo);

      case _Paso.pinNuevo:
        if (valor.length < _minLargo) {
          setState(() => _error = 'Mínimo $_minLargo dígitos');
          return;
        }
        _pinNuevoTemporal = valor;
        _ctrl.clear();
        setState(() => _paso = _Paso.confirmarPinNuevo);

      case _Paso.confirmarPinNuevo:
        if (valor != _pinNuevoTemporal) {
          setState(() => _error = 'No coincide con el PIN anterior');
          _ctrl.clear();
          return;
        }
        setState(() => _procesando = true);
        if (widget.esCambio) {
          await AppLockService.cambiarPin(valor);
        } else {
          await AppLockService.activarConPin(valor);
        }
        if (!mounted) return;
        Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titulo)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(letterSpacing: 4),
              decoration: InputDecoration(
                labelText: 'PIN',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _continuar(),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _procesando ? null : _continuar,
              child: _procesando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
