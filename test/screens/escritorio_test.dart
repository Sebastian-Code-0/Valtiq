import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/main.dart' as app;
import 'package:valtiq/screens/barra_lateral.dart';
import 'package:valtiq/screens/config/perfil_screen.dart';
import 'package:valtiq/screens/config/settings_screen.dart';
import 'package:valtiq/screens/shell.dart';
import 'package:valtiq/services/notification_service.dart';
import 'package:valtiq/services/perfil_service.dart';
import 'package:valtiq/theme/theme.dart';
import 'package:valtiq/utils/date_format.dart';
import 'package:valtiq/utils/fecha_civil.dart';
import 'package:valtiq/utils/format.dart';

Future<void> _cerrar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    NotificationService.ingresosUnicosDesactivados = [];
    app.appDesbloqueadaNotifier.value = true;
    PerfilService.perfil.value = const Perfil();
    montosOcultosNotifier.value = false;
  });

  tearDown(() async {
    PerfilService.perfil.value = const Perfil();
    montosOcultosNotifier.value = false;
    await db.close();
  });

  Future<void> montar(WidgetTester tester, Size tamano) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark(), home: ShellScreen(db: db)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  test('formatFechaEncabezado: día de la semana, día y mes en mayúsculas', () {
    expect(formatFechaEncabezado(DateTime(2026, 11, 10)), 'MARTES 10 NOVIEMBRE');
    expect(formatFechaEncabezado(DateTime(2026, 3, 1)), 'DOMINGO 1 MARZO');
  });

  testWidgets('en PC (ventana ancha) hay menú lateral con todas las secciones '
      'y Ajustes, y NO hay barra de navegación inferior', (tester) async {
    await montar(tester, const Size(1366, 768));

    expect(tester.takeException(), isNull);
    expect(find.byType(BarraLateral), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    final barra = find.byType(BarraLateral);
    for (final texto in [
      'Valtiq',
      'Inicio',
      'Deudas',
      'Préstamos',
      'Finanzas',
      'Recordatorios',
      'Ajustes',
      'Tu perfil',
    ]) {
      expect(
        find.descendant(of: barra, matching: find.text(texto)),
        findsOneWidget,
        reason: texto,
      );
    }
    await _cerrar(tester);
  });

  testWidgets('en celular (ventana angosta) se conserva la barra inferior y '
      'no hay menú lateral', (tester) async {
    await montar(tester, const Size(412, 900));

    expect(tester.takeException(), isNull);
    expect(find.byType(BarraLateral), findsNothing);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    await _cerrar(tester);
  });

  testWidgets('todo el menú lateral cabe en una ventana bajita (1024x600) '
      'sin desbordarse', (tester) async {
    await montar(tester, const Size(1024, 600));

    expect(tester.takeException(), isNull);
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Tu perfil'), findsOneWidget);
    await _cerrar(tester);
  });

  testWidgets('Inicio en PC: fecha de hoy, saludo con el nombre del perfil y '
      'solo 4 tarjetas de resumen (sin "día a día")', (tester) async {
    PerfilService.perfil.value = const Perfil(nombre: 'Sofía');
    await montar(tester, const Size(1366, 768));

    expect(find.text(formatFechaEncabezado(DateTime.now())), findsOneWidget);
    expect(
      find.text('${saludoSegunHora(DateTime.now())}, Sofía'),
      findsOneWidget,
    );
    expect(find.text('Deudas activas'), findsOneWidget);
    expect(find.text('Gastos fijos mensuales'), findsOneWidget);
    expect(find.text('Gastos del día a día (mes)'), findsNothing);
    await _cerrar(tester);
  });

  testWidgets('Inicio en PC sin nombre en el perfil: saluda sin nombre', (
    tester,
  ) async {
    await montar(tester, const Size(1366, 768));

    expect(find.text(saludoSegunHora(DateTime.now())), findsOneWidget);
    await _cerrar(tester);
  });

  testWidgets('"Ocultar montos" reemplaza las cifras de Inicio y se puede '
      'volver a mostrar; la elección se guarda', (tester) async {
    await db.ingresosDao.insertIngreso(
      IngresosCompanion.insert(
        concepto: 'Salario',
        monto: 1234567,
        fecha: normalizarFechaCivil(DateTime.now()),
      ),
    );
    await montar(tester, const Size(1366, 768));
    await tester.pumpAndSettle();
    expect(find.text(r'$1.234.567'), findsWidgets);

    await tester.tap(find.text('Ocultar montos'));
    await tester.pumpAndSettle();

    expect(find.text(r'$1.234.567'), findsNothing);
    expect(find.text(montoOculto), findsWidgets);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('valtiq_ocultar_montos'), isTrue);

    await tester.tap(find.text('Mostrar montos'));
    await tester.pumpAndSettle();
    expect(find.text(r'$1.234.567'), findsWidgets);
    await _cerrar(tester);
  });

  testWidgets('el menú lateral lleva a cada sección y Ajustes se abre DENTRO '
      'de la misma pantalla, con el menú a la vista', (tester) async {
    await montar(tester, const Size(1366, 768));
    final barra = find.byType(BarraLateral);

    await tester.tap(find.descendant(of: barra, matching: find.text('Ajustes')));
    await tester.pumpAndSettle();

    expect(find.byType(BarraLateral), findsOneWidget);
    expect(find.byType(SettingsScreen), findsOneWidget);
    // Primera sección: Perfil.
    expect(find.byType(PerfilScreen), findsOneWidget);
    // Sin flecha de volver: no es una página aparte.
    expect(find.byType(BackButton), findsNothing);
    expect(tester.takeException(), isNull);
    await _cerrar(tester);
  });

  testWidgets('tocar el perfil del menú abre Ajustes en la sección Perfil', (
    tester,
  ) async {
    await montar(tester, const Size(1366, 768));

    await tester.tap(find.text('Tu perfil'));
    await tester.pumpAndSettle();

    expect(find.byType(PerfilScreen), findsOneWidget);
    await _cerrar(tester);
  });

  testWidgets('la insignia de Recordatorios cuenta los que ya están en su '
      'ventana de aviso o vencidos', (tester) async {
    final hoy = normalizarFechaCivil(DateTime.now());
    for (final dias in [0, 2, -3, 40]) {
      await db.recordatoriosDao.insertRecordatorio(
        RecordatoriosCompanion.insert(
          titulo: 'r$dias',
          fechaAlerta: hoy.add(Duration(days: dias)),
        ),
      );
    }
    await montar(tester, const Size(1366, 768));
    await tester.pumpAndSettle();

    // Hoy, en 2 días y vencido hace 3 → 3. El de dentro de 40 días no.
    expect(
      find.descendant(of: find.byType(BarraLateral), matching: find.text('3')),
      findsOneWidget,
    );
    await _cerrar(tester);
  });
}
