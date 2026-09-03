import 'dart:async';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/app_lock_service.dart';
import '../../theme/theme.dart';

/// Pantalla que bloquea el acceso a la app. Se muestra como overlay opaco
/// sobre todo el contenido (ver `AppLockOverlay`) — cubre cualquier
/// pantalla, sin importar qué tan profundo esté el usuario en la
/// navegación. Intenta biometría automáticamente al aparecer si está
/// habilitada y disponible; siempre deja el PIN como alternativa visible.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinCtrl = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;
  bool _verificando = false;
  bool _biometriaDisponible = false;

  @override
  void initState() {
    super.initState();
    _prepararBiometria();
  }

  Future<void> _prepararBiometria() async {
    final usaBio = await AppLockService.usaBiometria();
    if (!usaBio) return;
    final disponible = await AppLockService.biometriaDisponible();
    if (!mounted) return;
    setState(() => _biometriaDisponible = disponible);
    if (disponible) {
      // Se dispara solo al entrar a la pantalla; si el usuario la cancela o
      // falla, sigue viendo el campo de PIN sin ningún paso extra.
      unawaited(_intentarBiometria());
    }
  }

  Future<void> _intentarBiometria() async {
    final ok = await AppLockService.autenticarConBiometria();
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      _focusNode.requestFocus();
    }
  }

  Future<void> _verificarPin() async {
    final pin = _pinCtrl.text;
    if (pin.isEmpty) return;
    setState(() {
      _verificando = true;
      _error = null;
    });
    final ok = await AppLockService.verificarPin(pin);
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
      return;
    }
    setState(() {
      _verificando = false;
      _error = 'PIN incorrecto';
      _pinCtrl.clear();
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.fondoOscuro,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo_icono.png',
                    width: 72,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Valtiq está bloqueado',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: TextField(
                      controller: _pinCtrl,
                      focusNode: _focusNode,
                      autofocus: !_biometriaDisponible,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                      decoration: InputDecoration(
                        labelText: 'PIN',
                        labelStyle: const TextStyle(color: Colors.white70),
                        errorText: _error,
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: acentoNotifier.value),
                        ),
                      ),
                      onSubmitted: (_) => _verificarPin(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: 280,
                    child: FilledButton(
                      onPressed: _verificando ? null : _verificarPin,
                      child: _verificando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Desbloquear'),
                    ),
                  ),
                  if (_biometriaDisponible) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextButton.icon(
                      onPressed: _intentarBiometria,
                      icon: const Icon(
                        Icons.fingerprint,
                        color: Colors.white70,
                      ),
                      label: const Text(
                        'Usar biometría',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
