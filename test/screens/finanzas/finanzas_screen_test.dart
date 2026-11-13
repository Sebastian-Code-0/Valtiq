import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/screens/finanzas/finanzas_screen.dart';
import 'package:valtiq/screens/finanzas/gasto_fijo_form.dart';
import 'package:valtiq/screens/finanzas/gasto_variable_form.dart';
import 'package:valtiq/screens/finanzas/ingreso_form.dart';
import 'package:valtiq/services/categorias_service.dart';
import 'package:valtiq/theme/theme.dart';
import 'package:valtiq/utils/fecha_civil.dart';
import 'package:valtiq/utils/format.dart';

// Los StreamBuilder de drift dejan un Timer de limpieza pendiente al
// desmontarse; este pump adicional lo drena.
Future<void> _cerrar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  late AppDatabase db;
  final hoy = normalizarFechaCivil(DateTime.now());

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> sembrar() async {
    await db.ingresosDao.insertIngreso(
      IngresosCompanion.insert(
        concepto: 'Sueldo',
        monto: 2500000,
        frecuencia: const Value('mensual'),
        fecha: hoy,
      ),
    );
    await db.ingresosDao.insertIngreso(
      IngresosCompanion.insert(
        concepto: 'Trabajo de fin de semana con nombre largo',
        monto: 150000,
        frecuencia: const Value('semanal'),
        fecha: hoy,
      ),
    );
    await db.gastosFijosDao.insertGastoFijo(
      GastosFijosCompanion.insert(
        concepto: 'Arriendo',
        monto: 900000,
        frecuencia: const Value('mensual'),
        diaCobro: const Value(5),
      ),
    );
    await db.gastosVariablesDao.insertGastoVariable(
      GastosVariablesCompanion.insert(
        descripcion: 'Mercado',
        monto: 180000,
        categoria: 'Alimentación',
        fecha: hoy,
      ),
    );
    await db.gastosVariablesDao.insertGastoVariable(
      GastosVariablesCompanion.insert(
        descripcion: 'Taxi',
        monto: 20000,
        categoria: 'Transporte',
        fecha: hoy,
      ),
    );
  }

  Future<void> montar(WidgetTester tester, Size tamano, {Widget? home}) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: RepaintBoundary(child: home ?? FinanzasScreen(db: db)),
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
    testWidgets('Finanzas en $nombre: las tres secciones se dibujan sin '
        'desbordarse y con sus totales', (tester) async {
      await sembrar();
      await montar(tester, tamano);
      final w = tamano.width.round();
      expect(tester.takeException(), isNull);
      expect(find.text('Ingresos de este mes'), findsOneWidget);
      expect(find.text('Sueldo'), findsOneWidget);
      await captura(tester, 'finanzas-ingresos-$w');

      await tester.tap(find.text('Gastos fijos'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Gastos fijos al mes'), findsOneWidget);
      expect(find.text('Arriendo'), findsOneWidget);
      expect(find.text(formatCOP(900000)), findsNWidgets(2));
      await captura(tester, 'finanzas-fijos-$w');

      await tester.tap(find.text('Día a día'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Gastado en el mes'), findsOneWidget);
      expect(find.text(formatCOP(200000)), findsOneWidget);
      expect(find.text('Por categoría'), findsOneWidget);
      expect(find.text('Mercado'), findsOneWidget);
      await captura(tester, 'finanzas-diaadia-$w');
      await _cerrar(tester);
    });

    testWidgets('formularios de Finanzas en $nombre se dibujan sin '
        'desbordarse', (tester) async {
      for (final (clave, form) in [
        ('ingreso', IngresoForm(key: const ValueKey(1), db: db)),
        ('fijo', GastoFijoForm(key: const ValueKey(2), db: db)),
        ('variable', GastoVariableForm(key: const ValueKey(3), db: db)),
      ]) {
        await montar(tester, tamano, home: form);
        expect(tester.takeException(), isNull, reason: clave);
        await captura(tester, 'finanzas-form-$clave-${tamano.width.round()}');
      }
      await _cerrar(tester);
    });
  }

  testWidgets('gasto del día a día: escribir "d1" sugiere D1 y elegirlo '
      'pone Alimentación; en gastos no salen bancos', (tester) async {
    await tester.runAsync(() => CategoriasService.iniciar(db));
    addTearDown(() => CategoriasService.lista.value = const []);
    await montar(tester, const Size(360, 780), home: GastoVariableForm(db: db));
    await tester.enterText(
      find.byKey(const ValueKey('gasto-descripcion')),
      'd1',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('D1').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Alimentación'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('gasto-descripcion')),
      'bancol',
    );
    await tester.pumpAndSettle();
    expect(find.text('Bancolombia'), findsNothing);
    await _cerrar(tester);
  });

  testWidgets('gasto fijo: "netf" sugiere Netflix', (tester) async {
    await montar(tester, const Size(360, 780), home: GastoFijoForm(db: db));
    await tester.enterText(
      find.byKey(const ValueKey('gasto-fijo-concepto')),
      'netf',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Netflix').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey('gasto-fijo-concepto')),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      'Netflix',
    );
    await _cerrar(tester);
  });

  testWidgets('el botón de crear cambia con la sección y desactivar un '
      'ingreso lo saca del conteo', (tester) async {
    await sembrar();
    await montar(tester, const Size(1366, 768));
    expect(find.text('Nuevo ingreso'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // Activos

    await tester.tap(find.byTooltip('Acciones').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desactivar'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('Gastos fijos'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo gasto fijo'), findsOneWidget);
    await tester.tap(find.text('Día a día'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo gasto'), findsOneWidget);
    await _cerrar(tester);
  });
}
