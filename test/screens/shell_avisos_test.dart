import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/main.dart' as app;
import 'package:valtiq/screens/shell.dart';
import 'package:valtiq/services/notification_service.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

// Ver deuda_detalle_flow_test.dart: los StreamBuilder de drift (acá,
// ShellScreen monta DashboardScreen con varios) dejan un Timer de limpieza
// pendiente al desmontarse; sin drenarlo, el framework de test lanza "A
// Timer is still pending" y el test cuelga hasta el timeout de 10 minutos
// en vez de fallar rápido.
Future<void> _cerrar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createInMemoryDb();
    NotificationService.ingresosUnicosDesactivados = [];
    app.appDesbloqueadaNotifier.value = true;
  });

  tearDown(() async {
    NotificationService.ingresosUnicosDesactivados = [];
    app.appDesbloqueadaNotifier.value = true;
    await db.close();
  });

  testWidgets(
    'con la app todavía bloqueada (appDesbloqueadaNotifier=false), el '
    'aviso de ingresos únicos desactivados NO se muestra — hueco de '
    'seguridad real: ShellScreen monta igual con el bloqueo PIN/biometría '
    'activo (es solo un overlay visual encima, SplashScreen navega ahí '
    'con su propio timer sin esperar el desbloqueo), así que sin este '
    'chequeo el mensaje se dispararía antes de que alguien probara el PIN',
    (tester) async {
      NotificationService.ingresosUnicosDesactivados = ['Freelance junio'];
      app.appDesbloqueadaNotifier.value = false;

      // `pump()` con duraciones fijas en vez de `pumpAndSettle()`: el
      // Dashboard real tiene varios StreamBuilder/animaciones que nunca
      // terminan de "asentarse" del todo, así que `pumpAndSettle` cuelga.
      await tester.pumpWidget(MaterialApp(home: ShellScreen(db: db)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Freelance junio'), findsNothing);

      // Al desbloquear (mismo evento que dispara AppLockOverlay._desbloquear
      // en la app real), el aviso pendiente debe aparecer recién ahí. En la
      // app real, desbloquear SIEMPRE agenda un frame (AppLockOverlay llama
      // `_entry.markNeedsBuild()` en el mismo paso, al sacar LockScreen de
      // encima) — acá hay que forzarlo a mano porque el `ValueNotifier` por
      // sí solo no agenda nada, y `pump()` no dispara un frame si no hay
      // ninguno agendado (ver `TestWidgetsFlutterBinding.pump`: solo corre
      // `handleBeginFrame`/`handleDrawFrame` cuando `hasScheduledFrame` es
      // true — si no, únicamente avanza el reloj falso y vacía microtasks).
      app.appDesbloqueadaNotifier.value = true;
      tester.binding.scheduleFrame();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Freelance junio'), findsOneWidget);
      await _cerrar(tester);
    },
  );

  testWidgets(
    'sin bloqueo activo (appDesbloqueadaNotifier=true desde el arranque, '
    'el caso normal hoy), el aviso se muestra de inmediato al montar '
    'ShellScreen, sin esperar ningún evento adicional',
    (tester) async {
      NotificationService.ingresosUnicosDesactivados = ['Bono trabajo'];

      await tester.pumpWidget(MaterialApp(home: ShellScreen(db: db)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Bono trabajo'), findsOneWidget);
      await _cerrar(tester);
    },
  );
}
