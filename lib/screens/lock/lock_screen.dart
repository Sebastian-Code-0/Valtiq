import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/app_lock_service.dart';
import '../../theme/theme.dart';
import 'teclado_pin.dart';

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
  bool _listo = false;
  int? _largo;
  bool _biometriaDisponible = false;

  @override
  void initState() {
    super.initState();
    _preparar();
  }

  Future<void> _preparar() async {
    final largo = await AppLockService.largoPin();
    final usaBio = await AppLockService.usaBiometria();
    final disponible = usaBio && await AppLockService.biometriaDisponible();
    if (!mounted) return;
    setState(() {
      _largo = largo;
      _biometriaDisponible = disponible;
      _listo = true;
    });
    if (disponible) {
      // Se dispara solo al entrar a la pantalla; si el usuario la cancela o
      // falla, sigue viendo el teclado sin ningún paso extra.
      unawaited(_intentarBiometria());
    }
  }

  Future<void> _intentarBiometria() async {
    final ok = await AppLockService.autenticarConBiometria();
    if (ok && mounted) widget.onUnlocked();
  }

  Future<String?> _verificar(String pin) async {
    if (await AppLockService.verificarPin(pin)) {
      widget.onUnlocked();
      return null;
    }
    return 'PIN incorrecto';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: context.colores.fondo,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: !_listo
                  ? const SizedBox.shrink()
                  : EntradaPin(
                      encabezado: const IconoValtiq(),
                      titulo: 'Ingresa tu PIN',
                      subtitulo: 'Valtiq está bloqueado',
                      largo: _largo,
                      onBiometria: _biometriaDisponible
                          ? _intentarBiometria
                          : null,
                      onEnviar: _verificar,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
