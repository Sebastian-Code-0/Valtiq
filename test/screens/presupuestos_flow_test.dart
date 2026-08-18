import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/screens/config/presupuestos_screen.dart';
import 'package:valtiq/screens/dashboard/dashboard_screen.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

// Los StreamBuilder de estas pantallas usan streams .watch() de drift, que
// al cancelarse agendan un Timer de duración cero para limpieza interna.
// Sin este pump extra tras desmontar el árbol, ese timer queda "pendiente"
// y el framework de test lo reporta como fallo aunque la app funcione bien.
Future<void> _cerrar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  // Duration.zero explícito (no pump() a secas) para que el reloj falso de
  // test avance lo suficiente y dispare el timer de limpieza de drift.
  await tester.pump(Duration.zero);
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createInMemoryDb();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'PresupuestosScreen: crear, editar (mismo upsert) y quitar un límite '
    'sin excepciones',
    (tester) async {
      await tester.pumpWidget(MaterialApp(home: PresupuestosScreen(db: db)));
      await tester.pumpAndSettle();

      // Crear.
      await tester.tap(find.text('Alimentación'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '200000');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('\$200.000'), findsOneWidget);

      // Editar la misma categoría: antes fallaba con "UNIQUE constraint
      // failed" porque el upsert apuntaba al conflicto de "id" en vez de
      // "categoria".
      await tester.tap(find.text('Alimentación'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '250000');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('\$250.000'), findsOneWidget);

      final trasEditar = await db.presupuestosCategoriasDao
          .getAllPresupuestos();
      expect(trasEditar.length, 1);
      expect(trasEditar.single.limiteMensual, 250000.0);

      // Quitar límite.
      await tester.tap(find.text('Alimentación'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitar límite'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('\$250.000'), findsNothing);
      expect(await db.presupuestosCategoriasDao.getAllPresupuestos(), isEmpty);

      await _cerrar(tester);
    },
  );

  testWidgets(
    'Dashboard: sin presupuestos no muestra la card; con gasto por encima '
    'del límite muestra "Superado"',
    (tester) async {
      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Presupuestos del mes'), findsNothing);

      final ahora = DateTime.now();
      await db.presupuestosCategoriasDao.upsertPresupuesto(
        PresupuestosCategoriasCompanion.insert(
          categoria: 'Alimentación',
          limiteMensual: 100000,
        ),
      );
      await db.gastosVariablesDao.insertGastoVariable(
        GastosVariablesCompanion.insert(
          descripcion: 'Mercado',
          monto: 150000,
          categoria: 'Alimentación',
          fecha: DateTime(ahora.year, ahora.month, 15),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Presupuestos del mes'), findsOneWidget);
      expect(find.text('Superado'), findsOneWidget);
      expect(find.text('de \$100.000'), findsOneWidget);

      await _cerrar(tester);
    },
  );
}
