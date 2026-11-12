import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/screens/config/acerca_de_screen.dart';
import 'package:valtiq/screens/config/apariencia_screen.dart';
import 'package:valtiq/screens/config/perfil_screen.dart';
import 'package:valtiq/screens/config/settings_screen.dart';
import 'package:valtiq/services/perfil_service.dart';
import 'package:valtiq/theme/theme.dart';
import 'package:valtiq/utils/selector_pildoras.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    PerfilService.perfil.value = const Perfil();
  });

  tearDown(() async {
    PerfilService.perfil.value = const Perfil();
    await db.close();
  });

  Future<void> montar(WidgetTester tester, Size tamano) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: SettingsScreen(db: db),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (nombre, tamano) in [
    ('celular (360x640)', const Size(360, 640)),
    ('PC (1100x700)', const Size(1100, 700)),
  ]) {
    testWidgets('Ajustes en $nombre: abre en Perfil y el selector cambia de '
        'sección sin abrir páginas nuevas', (tester) async {
      await montar(tester, tamano);
      expect(tester.takeException(), isNull);
      expect(find.byType(PerfilScreen), findsOneWidget);

      await tester.tap(find.text('Apariencia'));
      await tester.pumpAndSettle();
      expect(find.byType(AparienciaScreen), findsOneWidget);
      expect(find.byType(PerfilScreen), findsNothing);
      // Sigue siendo la misma página: una sola barra, la de "Ajustes".
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Ajustes'), findsOneWidget);

      // Si no caben todas en una línea, la última sección queda fuera de
      // la vista: hay que deslizar el selector (con el dedo o el ratón).
      if (find.text('Acerca de').hitTestable().evaluate().isEmpty) {
        await tester.dragUntilVisible(
          find.text('Acerca de').hitTestable(),
          find.byType(SelectorPildoras),
          const Offset(-150, 0),
        );
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Acerca de'));
      await tester.pumpAndSettle();
      expect(find.byType(AcercaDeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Perfil: guardar nombre y apellido los publica y los conserva', (
    tester,
  ) async {
    await montar(tester, const Size(412, 900));

    await tester.enterText(
      find.byKey(const ValueKey('perfil-nombre')),
      ' Sofía ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('perfil-apellido')),
      'Rojas',
    );
    await tester.pump();
    // La vista previa del saludo sigue lo que se escribe.
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('perfil-saludo'))).data,
      endsWith(', Sofía'),
    );
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(PerfilService.perfil.value.nombre, 'Sofía');
    expect(PerfilService.perfil.value.nombreCompleto, 'Sofía Rojas');
    expect(PerfilService.perfil.value.inicial, 'S');

    // Como si se cerrara y abriera la app.
    PerfilService.perfil.value = const Perfil();
    await PerfilService.cargar();
    expect(PerfilService.perfil.value.nombre, 'Sofía');
    expect(PerfilService.perfil.value.apellido, 'Rojas');
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
