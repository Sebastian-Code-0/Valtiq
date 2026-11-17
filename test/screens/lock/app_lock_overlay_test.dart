import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/screens/lock/app_lock_overlay.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('escribir el PIN en LockScreen no lanza excepciones — bug real: '
      'LockScreen vivía como HERMANO del Navigator de la app dentro de un '
      'Stack suelto, sin Overlay ancestro (los tooltips del teclado y '
      'cualquier campo de texto lo necesitan). AppLockOverlay ahora se '
      'renderiza dentro de un Overlay propio.', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: Text('contenido real')),
        builder: (context, child) =>
            AppLockOverlay(initiallyLocked: true, child: child!),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Valtiq está bloqueado'), findsOneWidget);
    // El contenido real de la app sigue montado detrás (no se destruye
    // al bloquear), solo tapado visualmente por LockScreen.
    expect(find.text('contenido real'), findsOneWidget);

    for (final d in ['1', '2', '3', '4']) {
      await tester.tap(find.text(d));
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('sin bloqueo activo (initiallyLocked: false) se ve directo el '
      'contenido real, sin LockScreen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: Text('contenido real')),
        builder: (context, child) =>
            AppLockOverlay(initiallyLocked: false, child: child!),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('contenido real'), findsOneWidget);
    expect(find.text('Valtiq está bloqueado'), findsNothing);
  });

  testWidgets('con timeout "Inmediato" (0s), pasar a segundo plano y volver '
      're-bloquea la app — verifica el mecanismo real de paused→resumed, '
      'no solo la aritmética de Duration', (tester) async {
    SharedPreferences.setMockInitialValues({
      'valtiq_lock_enabled': true,
      'valtiq_lock_timeout_seconds': 0,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: Text('contenido real')),
        builder: (context, child) =>
            AppLockOverlay(initiallyLocked: false, child: child!),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Valtiq está bloqueado'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Valtiq está bloqueado'), findsOneWidget);
  });

  testWidgets('con timeout largo (15 minutos), volver de segundo plano casi al '
      'instante NO re-bloquea — el timeout elegido sí se respeta', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'valtiq_lock_enabled': true,
      'valtiq_lock_timeout_seconds': 900, // 15 minutos
    });

    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: Text('contenido real')),
        builder: (context, child) =>
            AppLockOverlay(initiallyLocked: false, child: child!),
      ),
    );
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    // Volvió casi al instante (mucho menos que 15 minutos reales) →
    // sigue desbloqueada.
    expect(find.text('Valtiq está bloqueado'), findsNothing);
    expect(find.text('contenido real'), findsOneWidget);
  });

  testWidgets(
    'en escritorio (Linux/Windows) minimizar la ventana llega como "hidden", '
    'nunca como "paused" — hidden→resumed también debe re-bloquear. Antes '
    'solo se miraba paused y en PC la app nunca se volvía a bloquear',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'valtiq_lock_enabled': true,
        'valtiq_lock_timeout_seconds': 0,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(body: Text('contenido real')),
          builder: (context, child) =>
              AppLockOverlay(initiallyLocked: false, child: child!),
        ),
      );
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Valtiq está bloqueado'), findsOneWidget);
    },
  );

  testWidgets(
    'perder el foco sin minimizar (solo "inactive") NO re-bloquea: abrir un '
    'selector de archivos o el diálogo de huella no debe bloquear la app',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'valtiq_lock_enabled': true,
        'valtiq_lock_timeout_seconds': 0,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(body: Text('contenido real')),
          builder: (context, child) =>
              AppLockOverlay(initiallyLocked: false, child: child!),
        ),
      );
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Valtiq está bloqueado'), findsNothing);
    },
  );
}
