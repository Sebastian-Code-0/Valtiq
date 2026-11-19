import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/screens/prestamos/prestamo_detalle.dart';
import 'package:valtiq/screens/prestamos/prestamo_form.dart';
import 'package:valtiq/screens/prestamos/prestamos_screen.dart';
import 'package:valtiq/theme/theme.dart';
import 'package:valtiq/utils/fecha_civil.dart';
import 'package:valtiq/utils/format.dart';
import 'package:valtiq/utils/tasa_input.dart';

// Los StreamBuilder de drift dejan un Timer de limpieza pendiente al
// desmontarse; este pump adicional lo drena.
Future<void> _cerrar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  late AppDatabase db;
  final hoy = DateTime.now();
  DateTime haceMeses(int n) =>
      normalizarFechaCivil(DateTime(hoy.year, hoy.month - n, 1));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  /// Dos préstamos por cobrar (uno vencido, con un abono) y uno cobrado.
  Future<({int ana, int pedro, int luis})> sembrar() async {
    final ana = await db.prestamosDao.insertPrestamo(
      PrestamosCompanion.insert(
        deudorNombre: 'Ana María Rojas',
        deudorContacto: const Value('300 123 4567'),
        montoPrestado: 500000,
        fechaPrestamo: normalizarFechaCivil(hoy),
      ),
    );
    final pedro = await db.prestamosDao.insertPrestamo(
      PrestamosCompanion.insert(
        deudorNombre: 'Pedro',
        montoPrestado: 200000,
        fechaPrestamo: haceMeses(3),
        fechaPactadaPago: Value(haceMeses(1)),
      ),
    );
    await db.prestamosDao.insertPago(
      PagosRecibidosCompanion.insert(
        prestamoId: pedro,
        montoAbonado: 50000,
        fechaPago: haceMeses(2),
      ),
    );
    final luis = await db.prestamosDao.insertPrestamo(
      PrestamosCompanion.insert(
        deudorNombre: 'Luis',
        montoPrestado: 80000,
        fechaPrestamo: haceMeses(5),
      ),
    );
    await db.prestamosDao.insertPago(
      PagosRecibidosCompanion.insert(
        prestamoId: luis,
        montoAbonado: 80000,
        fechaPago: haceMeses(4),
      ),
    );
    await db.prestamosDao.marcarComoPagado(luis, haceMeses(4));
    return (ana: ana, pedro: pedro, luis: luis);
  }

  Future<void> montar(WidgetTester tester, Size tamano, {Widget? home}) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: RepaintBoundary(child: home ?? PrestamosScreen(db: db)),
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
    ('celular (360x640)', Size(360, 640)),
    ('PC (1102x768)', Size(1102, 768)),
  ]) {
    testWidgets('Préstamos en $nombre: las dos pestañas se dibujan sin '
        'desbordarse', (tester) async {
      await sembrar();
      await montar(tester, tamano);
      expect(tester.takeException(), isNull);
      expect(find.text('2 POR COBRAR'), findsOneWidget);
      expect(find.text('Te deben'), findsOneWidget);
      expect(find.text(formatCOP(650000)), findsOneWidget);
      expect(find.text('Ana María Rojas'), findsOneWidget);
      await captura(tester, 'prestamos-${tamano.width.round()}');

      await tester.tap(find.text('Cobrados'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Luis'), findsOneWidget);
      // En la fila de las pestañas, a la derecha: con texto en PC, solo el
      // ícono en celular.
      expect(
        tamano.width < 600
            ? find.byTooltip('Limpiar historial')
            : find.text('Limpiar historial'),
        findsOneWidget,
      );
      await captura(tester, 'prestamos-cobrados-${tamano.width.round()}');
      await _cerrar(tester);
    });
  }

  testWidgets('"Registrar abono" desde la tarjeta: "Todo" llena el saldo, y '
      'al guardarlo el préstamo pasa a Cobrados', (tester) async {
    final ids = await sembrar();
    await montar(tester, const Size(1366, 768));

    // Pedro debe 150.000 (200.000 − 50.000). Su tarjeta es la segunda.
    await tester.tap(find.text('Registrar abono').last);
    await tester.pumpAndSettle();
    expect(find.text('Pedro · Pendiente ${formatCOP(150000)}'), findsOneWidget);
    await captura(tester, 'prestamos-abono');
    await tester.tap(find.text('Todo ${formatCOP(150000)}'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(
      (await db.prestamosDao.getPrestamoById(ids.pedro))!.estado,
      'pagado',
    );
    await tester.pumpAndSettle();
    expect(find.text('1 POR COBRAR'), findsOneWidget);
    await _cerrar(tester);
  });

  testWidgets('en PC, tocar una tarjeta abre el detalle en un panel a la '
      'derecha; en celular, como página', (tester) async {
    await sembrar();
    await montar(tester, const Size(1366, 768));
    await tester.tap(find.text('Pedro'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final panel = find.byKey(const ValueKey('panel-prestamo'));
    expect(panel, findsOneWidget);
    expect(find.byType(PrestamoDetalle), findsNothing);
    for (final texto in [
      'Falta por cobrar',
      'Tasa',
      'Abonado',
      'Prestado el',
    ]) {
      expect(
        find.descendant(of: panel, matching: find.text(texto)),
        findsOneWidget,
      );
    }
    await captura(tester, 'prestamos-panel');
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(panel, findsNothing);
    await _cerrar(tester);

    await montar(tester, const Size(360, 640));
    await tester.tap(find.text('Ana María Rojas'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(PrestamoDetalle), findsOneWidget);
    expect(find.byKey(const ValueKey('panel-prestamo')), findsNothing);
    await _cerrar(tester);
  });

  testWidgets('"Más información": las filas de interés solo salen si el '
      'préstamo tiene interés', (tester) async {
    final sin = await db.prestamosDao.insertPrestamo(
      PrestamosCompanion.insert(
        deudorNombre: 'Sin interés',
        montoPrestado: 100000,
        fechaPrestamo: haceMeses(2),
      ),
    );
    final con = await db.prestamosDao.insertPrestamo(
      PrestamosCompanion.insert(
        deudorNombre: 'Con interés',
        montoPrestado: 100000,
        fechaPrestamo: haceMeses(2),
        tasaInteres: const Value(2),
        tipoInteres: const Value('mensual'),
      ),
    );
    const filasInteres = [
      'Interés acumulado:',
      'Total con interés:',
      'Sin interés debería:',
      'Diferencia por interés:',
    ];
    for (final (id, esperado) in [(sin, findsNothing), (con, findsOneWidget)]) {
      await montar(
        tester,
        const Size(360, 1400),
        home: PrestamoDetalle(db: db, prestamoId: id),
      );
      await tester.tap(find.text('Más información'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Monto prestado:'), findsOneWidget);
      expect(find.text('Total abonado:'), findsOneWidget);
      for (final fila in filasInteres) {
        expect(find.text(fila), esperado, reason: fila);
      }
      await _cerrar(tester);
    }
  });

  testWidgets('"Limpiar historial" pide confirmación y borra solo los '
      'cobrados', (tester) async {
    final ids = await sembrar();
    await montar(tester, const Size(1366, 768));
    await tester.tap(find.text('Cobrados'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Limpiar historial'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await db.prestamosDao.getPrestamoById(ids.luis), isNotNull);

    await tester.tap(find.text('Limpiar historial'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Limpiar historial'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(await db.prestamosDao.getPrestamoById(ids.luis), isNull);
    expect(await db.prestamosDao.getPagosDelPrestamo(ids.luis), isEmpty);
    expect(await db.prestamosDao.getPrestamoById(ids.ana), isNotNull);
    expect(await db.prestamosDao.getPrestamoById(ids.pedro), isNotNull);
    await tester.pumpAndSettle();
    expect(find.textContaining('Todavía no has terminado'), findsOneWidget);
    await _cerrar(tester);
  });

  for (final (nombre, tamano) in const [
    ('celular', Size(360, 640)),
    ('PC', Size(1366, 768)),
  ]) {
    testWidgets('detalle y formulario de préstamo en $nombre se dibujan sin '
        'desbordarse', (tester) async {
      final ids = await sembrar();
      await montar(
        tester,
        tamano,
        home: PrestamoDetalle(db: db, prestamoId: ids.pedro),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Registrar abono'), findsOneWidget);
      expect(find.text('Pagos recibidos'), findsOneWidget);
      await captura(tester, 'prestamo-detalle-${tamano.width.round()}');

      await montar(
        tester,
        tamano,
        home: PrestamoForm(
          db: db,
          prestamo: (await db.prestamosDao.getPrestamoById(ids.ana))!,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Editar préstamo'), findsOneWidget);
      await captura(tester, 'prestamo-form-${tamano.width.round()}');
      await _cerrar(tester);
    });
  }

  testWidgets('préstamo nuevo: con tasa es obligatorio decir si es mensual o '
      'anual', (tester) async {
    await montar(tester, const Size(1366, 900), home: PrestamoForm(db: db));
    await tester.enterText(find.byType(TextFormField).at(0), 'Carla');
    await tester.enterText(find.byType(TextFormField).at(2), '100000');
    await tester.enterText(find.byType(TextFormField).at(3), '3');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar préstamo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar préstamo'));
    await tester.pump();
    expect(await db.prestamosDao.getAllPrestamos(), isEmpty);
    expect(find.text(errorTipoInteres), findsOneWidget);
    // El aviso flotante tapa el botón de guardar: se espera a que se vaya.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Anual'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anual'));
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar préstamo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar préstamo'));
    await tester.pumpAndSettle();

    final p = (await db.prestamosDao.getAllPrestamos()).single;
    expect(p.tasaInteres, 3);
    expect(p.tipoInteres, 'anual');
  });

  testWidgets('calculadora de cuota del préstamo: con interés sobre lo '
      'prestado cubre ese interés fijo', (tester) async {
    await montar(tester, const Size(1366, 900), home: PrestamoForm(db: db));
    await tester.enterText(find.byType(TextFormField).at(2), '1000000');
    await tester.enterText(find.byType(TextFormField).at(3), '2');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mensual'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mensual'));
    await tester.pump();
    final boton = find.text('Calcular la cuota para N meses');
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '36');
    await tester.tap(find.text('Calcular'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // 20.000 de interés fijo al mes: 36·c ≥ 1.000.000 + 36·20.000.
    expect(find.textContaining('48.000 al mes'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
