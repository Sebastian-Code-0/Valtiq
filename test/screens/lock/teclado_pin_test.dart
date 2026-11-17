import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/screens/lock/configurar_pin_screen.dart';
import 'package:valtiq/screens/lock/lock_screen.dart';
import 'package:valtiq/screens/lock/teclado_pin.dart';
import 'package:valtiq/services/app_lock_service.dart';
import 'package:valtiq/theme/theme.dart';

Future<void> _teclear(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    // La última de las teclas: con el mismo número a la vista (ojito),
    // la del teclado es la de abajo.
    final tecla = find.text(d).last;
    await tester.ensureVisible(tecla);
    await tester.tap(tecla);
    await tester.pump();
  }
}

/// El hash del PIN corre en otro isolate (`compute`): hay que dejar pasar
/// tiempo real para que termine, el reloj falso de los tests no lo mueve.
Future<void> _esperarHash(WidgetTester tester, bool Function() listo) async {
  for (var i = 0; i < 150 && !listo(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Widget _app(Widget home) => MaterialApp(theme: AppTheme.light(), home: home);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('con el largo conocido, entra sola al escribir el último '
      'número', (tester) async {
    final enviados = <String>[];
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: EntradaPin(
            titulo: 'Ingresa tu PIN',
            largo: 4,
            onEnviar: (pin) async {
              enviados.add(pin);
              return null;
            },
          ),
        ),
      ),
    );
    await _teclear(tester, '1234');
    await tester.pumpAndSettle();
    expect(enviados, ['1234']);
    // Sin largo conocido no hay botón de entrar.
    expect(find.text('Entrar'), findsNothing);
  });

  testWidgets('PIN incorrecto muestra el error y borra los puntos', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: EntradaPin(
            titulo: 'Ingresa tu PIN',
            largo: 4,
            onEnviar: (_) async => 'PIN incorrecto',
          ),
        ),
      ),
    );
    await _teclear(tester, '9999');
    await tester.pumpAndSettle();
    expect(find.text('PIN incorrecto'), findsOneWidget);
    // Al escribir de nuevo el error se va.
    await _teclear(tester, '1');
    expect(find.text('PIN incorrecto'), findsNothing);
  });

  testWidgets('sin largo conocido usa el botón, que pide mínimo 4 números', (
    tester,
  ) async {
    String? enviado;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: SingleChildScrollView(
            child: EntradaPin(
              titulo: 'Crea tu PIN',
              textoBoton: 'Continuar',
              onEnviar: (pin) async {
                enviado = pin;
                return null;
              },
            ),
          ),
        ),
      ),
    );
    await _teclear(tester, '123');
    final boton = find.widgetWithText(FilledButton, 'Continuar');
    expect(tester.widget<FilledButton>(boton).onPressed, isNull);
    await _teclear(tester, '45');
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    await tester.pumpAndSettle();
    expect(enviado, '12345');
  });

  testWidgets('el teclado físico también escribe y borra (PC)', (tester) async {
    final enviados = <String>[];
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: EntradaPin(
            titulo: 'Ingresa tu PIN',
            largo: 4,
            onEnviar: (pin) async {
              enviados.add(pin);
              return null;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit9);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.pumpAndSettle();
    expect(enviados, ['1234']);
  });

  testWidgets('crear PIN: dos pasos, guarda el PIN y su largo', (tester) async {
    await tester.pumpWidget(_app(const ConfigurarPinScreen(esCambio: false)));
    await tester.pumpAndSettle();
    expect(find.text('Crea tu PIN'), findsOneWidget);

    await _teclear(tester, '2468');
    final continuar = find.widgetWithText(FilledButton, 'Continuar');
    await tester.ensureVisible(continuar);
    await tester.tap(continuar);
    await tester.pumpAndSettle();

    expect(find.text('Repite el PIN'), findsOneWidget);
    // Confirmar entra solo al llegar a 4 números.
    await _teclear(tester, '2468');
    // Al guardar, la pantalla se cierra sola.
    await _esperarHash(
      tester,
      () => find.text('Repite el PIN').evaluate().isEmpty,
    );

    await tester.runAsync(() async {
      expect(await AppLockService.verificarPin('2468'), isTrue);
      expect(await AppLockService.largoPin(), 4);
      expect(await AppLockService.bloqueoActivo(), isTrue);
    });
  });

  testWidgets('un PIN de antes (sin largo guardado) aprende el largo al '
      'primer desbloqueo correcto', (tester) async {
    await tester.runAsync(() async {
      await AppLockService.activarConPin('135790');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('valtiq_lock_pin_largo');
    });

    var desbloqueado = false;
    await tester.pumpWidget(
      _app(LockScreen(onUnlocked: () => desbloqueado = true)),
    );
    await tester.pumpAndSettle();
    // Sin largo: hay botón.
    await _teclear(tester, '135790');
    final entrar = find.widgetWithText(FilledButton, 'Entrar');
    await tester.ensureVisible(entrar);
    await tester.tap(entrar);
    await _esperarHash(tester, () => desbloqueado);

    expect(desbloqueado, isTrue);
    expect(await tester.runAsync(AppLockService.largoPin), 6);
  });

  testWidgets('el ojito muestra y vuelve a ocultar los números', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: EntradaPin(
            titulo: 'Ingresa tu PIN',
            largo: 6,
            onEnviar: (_) async => null,
          ),
        ),
      ),
    );
    await _teclear(tester, '58');
    // Ocultos: "5" y "8" solo existen como teclas.
    expect(find.text('5'), findsOneWidget);

    await tester.tap(find.byTooltip('Ver PIN'));
    await tester.pump();
    expect(find.text('5'), findsNWidgets(2));
    expect(find.text('8'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Ocultar PIN'));
    await tester.pump();
    expect(find.text('5'), findsOneWidget);
  });
}
