import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/screens/deudas/deuda_form.dart';
import 'package:valtiq/theme/theme.dart';
import 'package:valtiq/utils/fecha_civil.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> montar(WidgetTester tester, Size tamano, {Deuda? deuda}) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: RepaintBoundary(
          // Clave por deuda: al montar otra, el formulario arranca de cero.
          child: DeudaForm(key: ValueKey(deuda?.id), db: db, deuda: deuda),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Guarda una captura si se pide con CAPTURAS=<carpeta>.
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

  for (final (nombre, tamano) in const [
    ('celular', Size(360, 640)),
    ('PC', Size(1366, 768)),
  ]) {
    testWidgets('formulario de deuda en $nombre: se dibuja sin desbordarse, '
        'nuevo y editando', (tester) async {
      await montar(tester, tamano);
      expect(tester.takeException(), isNull);
      expect(find.text('Nueva deuda'), findsOneWidget);
      expect(find.text('Guardar deuda'), findsOneWidget);
      await captura(tester, 'form-nueva-${tamano.width.round()}');

      final id = await db.deudasDao.insertDeuda(
        DeudasCompanion.insert(
          acreedorNombre: 'Crédito del carro con un nombre bastante largo',
          descripcion: const Value('Banco de Bogotá, crédito de vehículo'),
          tipo: const Value('banco'),
          diaPago: const Value(5),
          montoOriginal: 45000000,
          tasaInteres: const Value(1.5),
          tipoInteres: const Value('mensual'),
          tipoAmortizacion: const Value('saldo_insoluto'),
          fechaPrestamo: normalizarFechaCivil(DateTime(2026, 3, 1)),
          cuotaMensual: const Value(1200000),
        ),
      );
      await montar(
        tester,
        tamano,
        deuda: (await db.deudasDao.getDeudaById(id))!,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Editar deuda'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
      await captura(tester, 'form-editar-${tamano.width.round()}');
    });
  }

  testWidgets('el tipo de interés y la modalidad se eligen con píldoras y se '
      'guardan', (tester) async {
    await montar(tester, const Size(1366, 768));
    await tester.enterText(find.byType(TextFormField).at(0), 'Tarjeta Nu');
    await tester.enterText(find.byType(TextFormField).at(2), '1000000');
    // Tasa > 0 enciende las opciones de interés.
    await tester.enterText(find.byType(TextFormField).at(3), '2');
    await tester.pump();
    await tester.tap(find.text('Mensual'));
    await tester.tap(find.text('Compuesto'));
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar deuda'));
    await tester.pump();
    await tester.tap(find.text('Guardar deuda'));
    await tester.pumpAndSettle();

    final deudas = await db.deudasDao.getAllDeudas();
    expect(deudas, hasLength(1));
    expect(deudas.single.acreedorNombre, 'Tarjeta Nu');
    expect(deudas.single.montoOriginal, 1000000);
    expect(deudas.single.tasaInteres, 2);
    expect(deudas.single.tipoInteres, 'mensual');
    expect(deudas.single.modalidadCalculo, 'compuesto');
  });
}
