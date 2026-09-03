import 'dart:async';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/app_lock_service.dart';
import 'lock_screen.dart';

/// Envuelve TODO el contenido de la app (vía `MaterialApp.builder`, no
/// `home`) para poder mostrar `LockScreen` encima de cualquier pantalla sin
/// importar la profundidad de navegación — un `Navigator.push` normal no
/// alcanzaría a cubrir diálogos u otras rutas ya abiertas.
///
/// Se renderiza dentro de un `Overlay` propio (no un `Stack` suelto): sin
/// esto, el `TextField` del PIN en `LockScreen` queda como HERMANO del
/// `Navigator` de la app (no descendiente), y le falta el `Overlay`
/// ancestro que todo `EditableText` necesita para sus handles de
/// selección — tocar el campo tira "No Overlay widget found" en cadena.
/// Este `Overlay` propio le da ese ancestro sin depender del que ya trae el
/// `Navigator` interno (que queda más abajo, dentro de `widget.child`).
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

  // `OverlayEntry.builder` se re-ejecuta con `markNeedsBuild()`, leyendo
  // `_bloqueado`/`widget.child` en el momento — no hace falta recrear la
  // entry, alcanza con avisarle que se invalidó.
  late final OverlayEntry _entry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        widget.child,
        if (_bloqueado) LockScreen(onUnlocked: _desbloquear),
      ],
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant AppLockOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `widget.child` pudo cambiar de identidad (ej. MaterialApp se
    // reconstruye por un cambio de tema) — la entry vive fuera del ciclo
    // normal de rebuild, así que hay que invalidarla a mano.
    _entry.markNeedsBuild();
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
    if (!mounted) return;
    _bloqueado = true;
    _entry.markNeedsBuild();
  }

  void _desbloquear() {
    _bloqueado = false;
    _entry.markNeedsBuild();
    appDesbloqueadaNotifier.value = true;
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(initialEntries: [_entry]);
  }
}
