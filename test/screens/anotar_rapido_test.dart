import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/screens/anotar/anotar_rapido.dart';
import 'package:valtiq/services/categorias_service.dart';
import 'package:valtiq/theme/theme.dart';

Future<void> _cerrar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  late AppDatabase db;
  late int cierres;
  final hoy = DateTime(2026, 11, 12, 15);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    cierres = 0;
  });
  tearDown(() async {
    CategoriasService.lista.value = const [];
    await db.close();
  });

  Future<void> montar(WidgetTester tester, {ThemeData? tema}) async {
    await tester.runAsync(() => CategoriasService.iniciar(db));
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        child: MaterialApp(
          theme: tema ?? AppTheme.dark(),
          home: AnotarRapidoScreen(
            db: db,
            ahora: () => hoy,
            alCerrar: () => cierres++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> captura(WidgetTester tester, String nombre) async {
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

  test('categoriaPropuesta: historial, luego la lista, luego Otros', () {
    const existentes = ['Alimentación', 'Restaurantes', 'Transporte', 'Otros'];
    const historial = [('café', 'Alimentación')];
    expect(categoriaPropuesta('Café', historial, existentes), 'Alimentación');
    expect(categoriaPropuesta('café', const [], existentes), 'Restaurantes');
    expect(categoriaPropuesta('uber', const [], existentes), 'Transporte');
    expect(categoriaPropuesta('rosas', const [], existentes), 'Otros');
    // La lista sugiere una categoría que el usuario borró: Otros.
    expect(categoriaPropuesta('netflix', const [], existentes), 'Otros');
  });

  testWidgets('"cafe 5mil" + Enter: se guarda hoy en la categoría propuesta '
      'y se cierra sola', (tester) async {
    await montar(tester);
    await tester.enterText(
      find.byKey(const ValueKey('anotar-texto')),
      'cafe 5mil',
    );
    await tester.pump();
    expect(find.text(r'$5.000'), findsOneWidget);
    await captura(tester, 'anotar-escribiendo');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Guardado'), findsOneWidget);
    await captura(tester, 'anotar-guardado');
    final g = (await tester.runAsync(
      db.gastosVariablesDao.getAllGastosVariables,
    ))!.single;
    expect(
      (g.descripcion, g.monto, g.categoria),
      ('Cafe', 5000, 'Restaurantes'),
    );
    expect(g.fecha.toUtc(), DateTime.utc(2026, 11, 12));

    expect(cierres, 0);
    await tester.pump(const Duration(seconds: 5));
    expect(cierres, 1);
    await _cerrar(tester);
  });

  testWidgets('aprende: si "café" se anotó en Alimentación, la próxima vez '
      'la propone', (tester) async {
    await tester.runAsync(
      () => db.gastosVariablesDao.insertGastoVariable(
        GastosVariablesCompanion.insert(
          descripcion: 'Café',
          monto: 3000,
          categoria: 'Alimentación',
          fecha: DateTime.utc(2026, 11, 1),
        ),
      ),
    );
    await montar(tester);
    await tester.enterText(
      find.byKey(const ValueKey('anotar-texto')),
      'café 4.500',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('anotar-guardar')));
    await tester.pumpAndSettle();
    final todos = (await tester.runAsync(
      db.gastosVariablesDao.getAllGastosVariables,
    ))!;
    expect(todos.last.categoria, 'Alimentación');
    await _cerrar(tester);
  });

  testWidgets('elegir otra categoría a mano; "Deshacer" borra lo guardado', (
    tester,
  ) async {
    await montar(tester);
    await tester.enterText(
      find.byKey(const ValueKey('anotar-texto')),
      'regalo mamá 80 mil',
    );
    await tester.pump();
    // Con la letra de las pruebas (muy ancha) queda fuera de la vista.
    await tester.ensureVisible(
      find.byKey(const ValueKey('anotar-categoria-Alimentación')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('anotar-categoria-Alimentación')),
    );
    await tester.pump();
    // Seguir escribiendo no cambia la que se eligió a mano.
    await tester.enterText(
      find.byKey(const ValueKey('anotar-texto')),
      'regalo mamá 90 mil',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('anotar-guardar')));
    await tester.pumpAndSettle();
    var todos = (await tester.runAsync(
      db.gastosVariablesDao.getAllGastosVariables,
    ))!;
    expect(
      (todos.single.monto, todos.single.categoria),
      (90000, 'Alimentación'),
    );

    await tester.tap(find.byKey(const ValueKey('anotar-deshacer')));
    await tester.pumpAndSettle();
    todos = (await tester.runAsync(
      db.gastosVariablesDao.getAllGastosVariables,
    ))!;
    expect(todos, isEmpty);
    expect(find.byKey(const ValueKey('anotar-texto')), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(cierres, 0, reason: 'tras deshacer no se cierra sola');
    await _cerrar(tester);
  });

  testWidgets('sin monto no guarda y lo dice; solo el monto queda "Sin '
      'nombre"', (tester) async {
    await montar(tester);
    await tester.enterText(find.byKey(const ValueKey('anotar-texto')), 'café');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('anotar-guardar')));
    await tester.pump();
    expect(find.textContaining('Falta el monto'), findsOneWidget);
    expect(
      await tester.runAsync(db.gastosVariablesDao.getAllGastosVariables),
      isEmpty,
    );

    await tester.enterText(find.byKey(const ValueKey('anotar-texto')), '7000');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('anotar-guardar')));
    await tester.pumpAndSettle();
    final g = (await tester.runAsync(
      db.gastosVariablesDao.getAllGastosVariables,
    ))!.single;
    expect((g.descripcion, g.monto), ('Sin nombre', 7000));
    await _cerrar(tester);
  });

  testWidgets('avisa si con este gasto se pasa el presupuesto del mes', (
    tester,
  ) async {
    await tester.runAsync(
      () => db.presupuestosCategoriasDao.upsertPresupuesto(
        PresupuestosCategoriasCompanion.insert(
          categoria: 'Restaurantes',
          limiteMensual: 10000,
        ),
      ),
    );
    await montar(tester, tema: AppTheme.light());
    await tester.enterText(
      find.byKey(const ValueKey('anotar-texto')),
      'almuerzo 15mil',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('anotar-guardar')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Superaste tu presupuesto de Restaurantes'),
      findsOneWidget,
    );
    await captura(tester, 'anotar-presupuesto-claro');
    await _cerrar(tester);
  });

  testWidgets('tocar fuera de la tarjeta cierra', (tester) async {
    await montar(tester);
    await tester.tapAt(const Offset(180, 40));
    await tester.pump();
    expect(cierres, 1);
    await _cerrar(tester);
  });
}
