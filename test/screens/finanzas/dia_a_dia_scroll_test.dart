import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/screens/finanzas/finanzas_screen.dart';
import 'package:valtiq/theme/theme.dart';
import 'package:valtiq/utils/categoria_gasto.dart';
import 'package:valtiq/utils/fecha_civil.dart';
import 'package:valtiq/utils/form_widgets.dart';

Future<void> _cerrar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> montar(WidgetTester tester, Size tamano) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Un gasto en CADA categoría: el peor caso para el resumen de barras.
    final hoy = normalizarFechaCivil(DateTime.now());
    for (final (i, c) in CategoriaGasto.values.indexed) {
      await db.gastosVariablesDao.insertGastoVariable(
        GastosVariablesCompanion.insert(
          descripcion: 'Gasto ${c.nombre}',
          monto: 10000 * (i + 1),
          categoria: c.nombre,
          fecha: hoy,
        ),
      );
    }
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark(), home: FinanzasScreen(db: db)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Día a día'));
    await tester.pumpAndSettle();
  }

  for (final (nombre, tamano) in [
    ('celular (360x640)', const Size(360, 640)),
    ('PC (1280x720)', const Size(1280, 720)),
  ]) {
    testWidgets(
      'Día a día en $nombre con gastos en las 8 categorías: se puede bajar '
      'hasta el último gasto — antes las barras quedaban fijas arriba y la '
      'lista de gastos se quedaba sin espacio para desplazarse',
      (tester) async {
        await montar(tester, tamano);
        expect(tester.takeException(), isNull);

        // Solo las 3 categorías más grandes; el resto, plegado.
        expect(find.byType(BarraCategoria), findsNWidgets(3));

        // 'Alimentación' es el gasto más chico de hoy: queda al final.
        await tester.scrollUntilVisible(
          find.text('Gasto Alimentación'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('Gasto Alimentación'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _cerrar(tester);
      },
    );
  }

  testWidgets('"Ver N categorías más" despliega y vuelve a plegar el resumen', (
    tester,
  ) async {
    await montar(tester, const Size(360, 640));

    await tester.tap(find.text('Ver 5 categorías más'));
    await tester.pumpAndSettle();
    expect(find.text('Ver menos'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Con las 8 barras desplegadas el botón queda más abajo del borde de
    // la pantalla: hay que desplazarse hasta él, igual que haría el usuario.
    await tester.ensureVisible(find.text('Ver menos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver menos'));
    await tester.pumpAndSettle();
    // Volver arriba: el resumen es el primer elemento de la lista.
    await tester.drag(find.byType(Scrollable).last, const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(find.byType(BarraCategoria), findsNWidgets(3));
    await _cerrar(tester);
  });

  for (final (nombre, tamano) in [
    ('celular (360x640)', const Size(360, 640)),
    ('PC (1280x720)', const Size(1280, 720)),
  ]) {
    testWidgets(
      'en $nombre el monto de cada barra queda pegado al borde derecho '
      '(donde termina la barra), no flotando en el centro',
      (tester) async {
        await montar(tester, tamano);

        final barra = find.byType(BarraCategoria).first;
        final monto = find.descendant(
          of: barra,
          matching: find.textContaining(r'$'),
        );
        expect(
          tester.getTopRight(monto).dx,
          closeTo(tester.getTopRight(barra).dx, 1),
        );
        await _cerrar(tester);
      },
    );
  }
}
