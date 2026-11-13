import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/screens/config/presupuestos_screen.dart';
import 'package:valtiq/screens/dashboard/dashboard_screen.dart';
import 'package:valtiq/theme/theme.dart';

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

/// Guarda una captura si se pide con `CAPTURAS=<carpeta>`.
Future<void> _captura(WidgetTester tester, String nombre) async {
  final carpeta = Platform.environment['CAPTURAS'];
  if (carpeta == null) return;
  await tester.runAsync(() async {
    final limite =
        tester.renderObject(find.byType(RepaintBoundary).first)
            as RenderRepaintBoundary;
    final imagen = await limite.toImage();
    final bytes = await imagen.toByteData(format: ImageByteFormat.png);
    File('$carpeta/$nombre.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createInMemoryDb();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> montarPresupuestos(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: PresupuestosScreen(db: db)));
    await tester.pumpAndSettle();
  }

  Future<void> escribirLimite(WidgetTester tester, String texto) async {
    await tester.enterText(
      find.byKey(const ValueKey('categoria-limite')),
      texto,
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'PresupuestosScreen: poner, cambiar (mismo upsert) y quitar un límite '
    'desde la ventana de la categoría',
    (tester) async {
      await montarPresupuestos(tester);

      await tester.tap(find.text('Alimentación'));
      await tester.pumpAndSettle();
      await escribirLimite(tester, '200000');
      expect(find.text('\$200.000'), findsOneWidget);

      // Cambiarlo: antes fallaba con "UNIQUE constraint failed" porque el
      // upsert apuntaba al conflicto de "id" en vez de "categoria".
      await tester.tap(find.text('Alimentación'));
      await tester.pumpAndSettle();
      await escribirLimite(tester, '250000');
      expect(find.text('\$250.000'), findsOneWidget);
      final trasEditar = await db.presupuestosCategoriasDao
          .getAllPresupuestos();
      expect(trasEditar.single.limiteMensual, 250000);

      // Dejarlo vacío = sin límite.
      await tester.tap(find.text('Alimentación'));
      await tester.pumpAndSettle();
      await escribirLimite(tester, '');
      expect(find.text('\$250.000'), findsNothing);
      expect(await db.presupuestosCategoriasDao.getAllPresupuestos(), isEmpty);

      await _cerrar(tester);
    },
  );

  testWidgets('crear una categoría nueva; un nombre repetido no se acepta', (
    tester,
  ) async {
    await montarPresupuestos(tester);

    await tester.tap(find.byKey(const ValueKey('nueva-categoria')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('categoria-nombre')),
      'Casa',
    );
    await escribirLimite(tester, '100000');
    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('\$100.000'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nueva-categoria')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('categoria-nombre')),
      ' casa ',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Ya tienes una categoría con ese nombre'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(
      (await db.categoriasDao.getCategorias()).where((c) => c.nombre == 'Casa'),
      hasLength(1),
    );
    await _cerrar(tester);
  });

  for (final mover in [false, true]) {
    testWidgets(
      'borrar una categoría con gastos: explica todo antes y dice lo que '
      'hizo (${mover ? 'pasando los gastos a Otros' : 'borrando los gastos'})',
      (tester) async {
        await db.categoriasDao.crear(
          nombre: 'Casa',
          icono: 'hogar',
          color: 0xFFA6754D,
        );
        await db.presupuestosCategoriasDao.upsertPresupuesto(
          PresupuestosCategoriasCompanion.insert(
            categoria: 'Casa',
            limiteMensual: 100000,
          ),
        );
        await db.gastosVariablesDao.insertGastoVariable(
          GastosVariablesCompanion.insert(
            descripcion: 'Escoba',
            monto: 60000,
            categoria: 'Casa',
            fecha: DateTime.utc(2026, 1, 10),
          ),
        );
        await montarPresupuestos(tester);

        await tester.tap(find.text('Casa'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Eliminar categoría'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Antes de borrar: qué se pierde y que no hay papelera.
        expect(find.textContaining('1 gasto del día a día'), findsOneWidget);
        expect(find.textContaining('\$60.000'), findsWidgets);
        expect(find.textContaining('\$100.000'), findsWidgets);
        expect(find.textContaining('No hay papelera'), findsOneWidget);

        await tester.tap(
          find.byKey(
            ValueKey(
              mover ? 'borrar-categoria-mover' : 'borrar-categoria-confirmar',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Después, en la misma ventana: lo que se hizo.
        expect(find.text('Listo'), findsOneWidget);
        expect(find.textContaining('Se borró la categoría "Casa"'), findsOne);
        expect(
          find.textContaining(mover ? 'pasó a "Otros"' : 'Se borró 1 gasto'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('borrar-categoria-listo')));
        await tester.pumpAndSettle();

        final gastos = await db.gastosVariablesDao.getAllGastosVariables();
        expect(gastos.map((g) => g.categoria), mover ? ['Otros'] : isEmpty);
        expect(
          await db.presupuestosCategoriasDao.getAllPresupuestos(),
          isEmpty,
        );
        expect(find.text('Casa'), findsNothing);
        await _cerrar(tester);
      },
    );
  }

  testWidgets('en celular (360x780) las ventanas de editar y de borrar se '
      'dibujan sin desbordarse', (tester) async {
    await db.categoriasDao.crear(
      nombre: 'Casa',
      icono: 'hogar',
      color: 0xFFA6754D,
    );
    await db.gastosVariablesDao.insertGastoVariable(
      GastosVariablesCompanion.insert(
        descripcion: 'Escoba',
        monto: 60000,
        categoria: 'Casa',
        fecha: DateTime.utc(2026, 1, 10),
      ),
    );
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // La captura abarca toda la app: las ventanas van encima de la
    // pantalla, fuera de ella.
    await tester.pumpWidget(
      RepaintBoundary(
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: PresupuestosScreen(db: db),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Casa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Casa'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _captura(tester, 'categoria-editar-360');
    await tester.ensureVisible(find.text('Eliminar categoría'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar categoría'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _captura(tester, 'categoria-borrar-360');
    await tester.tap(find.byKey(const ValueKey('borrar-categoria-confirmar')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _captura(tester, 'categoria-borrada-360');
    await _cerrar(tester);
  });

  testWidgets('"Otros" no muestra el botón de eliminar', (tester) async {
    await montarPresupuestos(tester);
    await tester.tap(find.text('Otros'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminar categoría'), findsNothing);
    expect(find.textContaining('no se puede renombrar ni borrar'), findsOne);
    await _cerrar(tester);
  });

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
