import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/screens/deudas/deuda_detalle.dart';
import 'package:valtiq/screens/deudas/deuda_form.dart';
import 'package:valtiq/screens/deudas/deudas_screen.dart';
import 'package:valtiq/theme/theme.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> asentar(WidgetTester t) async {
    for (var i = 0; i < 5; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 15)),
      );
      await t.pump(const Duration(milliseconds: 50));
    }
    await t.pumpAndSettle();
  }

  Future<int> abrirPlan(WidgetTester t, Size tam) async {
    final id = (await t.runAsync(
      () => db
          .into(db.deudas)
          .insert(
            DeudasCompanion.insert(
              acreedorNombre: 'Banco X',
              montoOriginal: 1000000,
              fechaPrestamo: DateTime.utc(2026, 1, 1),
              cuotaMensual: const Value(100000),
            ),
          ),
    ))!;
    t.view.physicalSize = tam;
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
        home: DeudasScreen(db: db),
      ),
    );
    await asentar(t);
    await t.tap(find.text('Plan de pago'));
    await asentar(t);
    final fila = find.byKey(ValueKey('plan-orden-$id'));
    await t.ensureVisible(fila);
    await t.pumpAndSettle();
    await t.tap(fila);
    await asentar(t);
    return id;
  }

  testWidgets('en PC, tocar una deuda del orden abre su panel en Activas', (
    t,
  ) async {
    await abrirPlan(t, const Size(1366, 768));
    expect(find.byKey(const ValueKey('panel-deuda')), findsOneWidget);
    expect(find.byType(DeudaDetalleContenido), findsOneWidget);
    expect(find.byKey(const ValueKey('plan-orden')), findsNothing);
    expect(find.byType(DeudaForm), findsNothing);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 1));
  });

  testWidgets('en celular, tocar una deuda del orden abre su detalle', (
    t,
  ) async {
    await abrirPlan(t, const Size(390, 844));
    expect(find.byType(DeudaDetalle), findsOneWidget);
    expect(find.byType(DeudaForm), findsNothing);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 1));
  });
}
