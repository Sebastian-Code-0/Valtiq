import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/screens/deudas/deuda_form.dart';
import 'package:valtiq/screens/deudas/deudas_screen.dart';
import 'package:valtiq/theme/theme.dart';
import 'package:valtiq/utils/fecha_civil.dart';
import 'package:valtiq/utils/form_widgets.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> asentar(WidgetTester t) async {
    for (var i = 0; i < 4; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 15)),
      );
      await t.pump(const Duration(milliseconds: 50));
    }
    await t.pumpAndSettle();
  }

  Future<void> app(WidgetTester t, Widget home, Size size) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: const Locale('es', 'CO'),
        supportedLocales: const [Locale('es', 'CO'), Locale('en')],
        home: home,
      ),
    );
    await asentar(t);
  }

  Finder campo(String etiqueta) => find
      .descendant(
        of: find
            .ancestor(
              of: find.text(etiqueta),
              matching: find.byType(CampoEtiquetado),
            )
            .first,
        matching: find.byType(TextField),
      )
      .first;

  Future<void> tocar(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await asentar(t);
  }

  for (final tam in const [Size(360, 640), Size(1366, 768)]) {
    testWidgets('tras la calculadora, Guardar responde al primer toque '
        '(${tam.width.toInt()}x${tam.height.toInt()})', (t) async {
      await app(t, DeudaForm(db: db), tam);
      await t.enterText(campo('Nombre'), 'Banco X');
      await t.enterText(campo('Monto original'), '1000000');
      await t.enterText(campo('Tasa de interés'), '5');
      await t.pump();
      await tocar(t, find.text('Mensual'));
      await tocar(
        t,
        find.byTooltip('Calcular la cuota para terminar en N meses'),
      );
      await t.enterText(find.byType(TextField).last, '12');
      await t.tap(find.text('Calcular'));
      await t.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byKey(const ValueKey('cuota-calculada')), findsOneWidget);
      await tocar(t, find.text('Guardar deuda'));
      final guardadas = (await t.runAsync(db.deudasDao.getAllDeudas))!;
      expect(guardadas, hasLength(1));
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 10));
    });
  }

  testWidgets('el resultado de la calculadora se limpia al cambiar un dato', (
    t,
  ) async {
    await app(t, DeudaForm(db: db), const Size(1366, 2600));
    await t.enterText(campo('Nombre'), 'Banco X');
    await t.enterText(campo('Monto original'), '1000000');
    await t.enterText(campo('Tasa de interés'), '2');
    await t.pump();
    await tocar(t, find.text('Mensual'));
    await tocar(
      t,
      find.byTooltip('Calcular la cuota para terminar en N meses'),
    );
    await t.enterText(find.byType(TextField).last, '12');
    await t.tap(find.text('Calcular'));
    await t.pumpAndSettle();
    final resultado = find.byKey(const ValueKey('cuota-calculada'));
    expect(resultado, findsOneWidget);
    await t.enterText(campo('Monto original'), '5000000');
    await t.pumpAndSettle();
    expect(resultado, findsNothing);
    // Volver al dato anterior no revive el texto.
    await t.enterText(campo('Monto original'), '1000000');
    await t.pumpAndSettle();
    expect(resultado, findsNothing);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('el aviso "no baja" dice que el extra debe empezar este mes', (
    t,
  ) async {
    final ahora = DateTime.now();
    await db.deudasDao.insertDeuda(
      DeudasCompanion.insert(
        acreedorNombre: 'No Baja',
        montoOriginal: 1000000,
        tasaInteres: const Value(5),
        tipoInteres: const Value('mensual'),
        tipoAmortizacion: const Value('saldo_insoluto'),
        fechaPrestamo: normalizarFechaCivil(ahora),
        cuotaMensual: const Value(10000),
      ),
    );
    await app(t, DeudasScreen(db: db), const Size(1366, 900));
    await tocar(t, find.text('Plan de pago'));
    expect(find.textContaining('Cuenta con que abones'), findsOneWidget);
    expect(find.textContaining('este mes, ('), findsNothing);
    expect(find.textContaining('si empiezas el mes que viene'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 10));
  });
}
