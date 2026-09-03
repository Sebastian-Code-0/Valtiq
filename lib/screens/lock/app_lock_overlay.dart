import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/app_lock_service.dart';
import 'lock_screen.dart';

/// Envuelve TODO el contenido de la app (vía `MaterialApp.builder`, no
/// `home`) para poder mostrar `LockScreen` encima de cualquier pantalla sin
/// importar la profundidad de navegación — un `Navigator.push` normal no
/// alcanzaría a cubrir diálogos u otras rutas ya abiertas.
///
/// `initiallyLocked` se calcula en `main()` ANTES de `runApp` (misma
/// convención que `themeModeNotifier`/`acentoNotifier`) para que el primer
/// frame ya sepa si debe arrancar bloqueado — evita un parpadeo de
/// contenido real sin proteger mientras se resuelve un `Future` async.
class AppLockOverlay extends StatefulWidget {
  const AppLockOverlay({
    super.key,
    required this.child,
    required this.initiallyLocked,
  });

  final Widget child;
  final bool initiallyLocked;

  @override
  State<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends State<AppLockOverlay>
    with WidgetsBindingObserver {
  late bool _bloqueado = widget.initiallyLocked;
  DateTime? _pausadoEn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausadoEn = DateTime.now();
      return;
    }
    if (state != AppLifecycleState.resumed) return;

    final pausadoEn = _pausadoEn;
    _pausadoEn = null;
    if (_bloqueado || pausadoEn == null) return;

    unawaited(_evaluarReloqueo(pausadoEn));
  }

  Future<void> _evaluarReloqueo(DateTime pausadoEn) async {
    if (!await AppLockService.bloqueoActivo()) return;
    final timeout = await AppLockService.timeoutReloqueo();
    if (DateTime.now().difference(pausadoEn) < timeout) return;
    if (mounted) setState(() => _bloqueado = true);
  }

  void _desbloquear() {
    setState(() => _bloqueado = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_bloqueado) LockScreen(onUnlocked: _desbloquear),
      ],
    );
  }
}
