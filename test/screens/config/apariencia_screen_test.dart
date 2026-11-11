import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/main.dart' as app;
import 'package:valtiq/screens/config/apariencia_screen.dart';
import 'package:valtiq/theme/theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    app.themeModeNotifier.value = ThemeMode.system;
  });

  tearDown(() => app.themeModeNotifier.value = ThemeMode.system);

  Future<void> montar(WidgetTester tester, Size tamano) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark(), home: const AparienciaScreen()),
    );
    await tester.pumpAndSettle();
  }

  for (final (nombre, tamano) in [
    ('celular angosto (320x640)', const Size(320, 640)),
    ('celular (412x915)', const Size(412, 915)),
    ('PC (1280x800)', const Size(1280, 800)),
  ]) {
    testWidgets('las tres opciones caben sin desbordarse en $nombre', (
      tester,
    ) async {
      await montar(tester, tamano);

      expect(tester.takeException(), isNull);
      expect(find.text('Sistema'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);
    });
  }

  testWidgets('tocar una opción cambia el tema y lo guarda', (tester) async {
    await montar(tester, const Size(412, 915));

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();
    expect(app.themeModeNotifier.value, ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('valtiq_theme'), 'dark');

    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();
    expect(app.themeModeNotifier.value, ThemeMode.light);
    expect(prefs.getString('valtiq_theme'), 'light');
  });
}
