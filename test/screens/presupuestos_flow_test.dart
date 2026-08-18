import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/screens/config/presupuestos_screen.dart';
import 'package:valtiq/screens/dashboard/dashboard_screen.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createInMemoryDb();
  });

  tearDown(() async {
    await db.close();
  });

  group('PresupuestosScreen', () {
    testWidgets('definir un límite nuevo no lanza excepción al cerrar el diálogo', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: PresupuestosScreen(db: db)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin límite'), findsNWidgets(8));

      await tester.tap(find.text('Alimentación'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '200000');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('\$200.000'), findsOneWidget);
      expect(find.text('Sin límite'), findsNWidgets(7));
    });

    testWidgets(
      'editar un límite existente (mismo upsert) no lanza UNIQUE constraint',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: PresupuestosScreen(db: db)),
        );
        await tester.pumpAndSettle();

        // Primer guardado.
        await tester.tap(find.text('Alimentación'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), '200000');
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Reabrir la misma categoría y editar: esto es exactamente el
        // camino que antes fallaba con "UNIQUE constraint failed:
        // presupuestos_categorias.categoria" porque insertOnConflictUpdate
        // apuntaba al conflicto de "id" en vez de "categoria".
        await tester.tap(find.text('Alimentación'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), '250000');
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('\$250.000'), findsOneWidget);

        final todos = await db.presupuestosCategoriasDao.getAllPresupuestos();
        expect(todos.length, 1);
        expect(todos.single.limiteMensual, 250000.0);
      },
    );

    testWidgets('quitar límite lo elimina y vuelve a "Sin límite"', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: PresupuestosScreen(db: db)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alimentación'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '200000');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alimentación'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitar límite'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Sin límite'), findsNWidgets(8));
      expect(
        await db.presupuestosCategoriasDao.getAllPresupuestos(),
        isEmpty,
      );
    });

    testWidgets('cancelar no guarda cambios ni lanza excepción', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: PresupuestosScreen(db: db)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ropa'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '999000');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        await db.presupuestosCategoriasDao.getAllPresupuestos(),
        isEmpty,
      );
    });

    testWidgets('monto vacío o cero no cierra el diálogo (validación)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: PresupuestosScreen(db: db)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salud'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // El diálogo sigue abierto: "Guardar" y "Cancelar" siguen visibles.
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });
  });

  group('Dashboard — _PresupuestosCard', () {
    testWidgets('sin presupuestos definidos, la card no se muestra', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Presupuestos del mes'), findsNothing);
    });

    testWidgets(
      'con gasto por encima del límite, muestra la card y "Superado"',
      (tester) async {
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

        await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Presupuestos del mes'), findsOneWidget);
        expect(find.text('Superado'), findsOneWidget);
        expect(find.text('de \$100.000'), findsOneWidget);
      },
    );
  });
}
