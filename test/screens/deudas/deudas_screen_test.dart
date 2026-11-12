import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/screens/deudas/deuda_detalle.dart';
import 'package:valtiq/screens/deudas/deuda_form.dart';
import 'package:valtiq/screens/deudas/deudas_screen.dart';
import 'package:valtiq/screens/deudas/plan_pago_tab.dart';
import 'package:valtiq/theme/theme.dart';
import 'package:valtiq/utils/fecha_civil.dart';
import 'package:valtiq/utils/form_widgets.dart';
import 'package:valtiq/utils/format.dart';

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

  /// Tres deudas activas (una con pagos) y una pagada.
  Future<({int nu, int juan, int carro, int celular})> sembrar() async {
    final nu = await db.deudasDao.insertDeuda(
      DeudasCompanion.insert(
        acreedorNombre: 'Tarjeta Nu',
        descripcion: const Value('Nu tarjeta de crédito'),
        tipo: const Value('tarjeta'),
        diaPago: const Value(12),
        montoOriginal: 1200000,
        tasaInteres: const Value(24),
        tipoInteres: const Value('anual'),
        tipoAmortizacion: const Value('saldo_insoluto'),
        fechaPrestamo: normalizarFechaCivil(hoy),
        cuotaMensual: const Value(150000),
      ),
    );
    final juan = await db.deudasDao.insertDeuda(
      DeudasCompanion.insert(
        acreedorNombre: 'Juan',
        tipo: const Value('persona'),
        montoOriginal: 400000,
        fechaPrestamo: haceMeses(2),
        cuotaMensual: const Value(100000),
      ),
    );
    await db.pagosDeudaDao.insertPago(
      PagosDeudaCompanion.insert(
        deudaId: juan,
        montoAbonado: 100000,
        fechaPago: haceMeses(1),
      ),
    );
    final carro = await db.deudasDao.insertDeuda(
      DeudasCompanion.insert(
        acreedorNombre: 'Crédito del carro con un nombre bastante largo',
        descripcion: const Value('Banco de Bogotá, crédito de vehículo'),
        tipo: const Value('banco'),
        montoOriginal: 45000000,
        tasaInteres: const Value(1.5),
        tipoInteres: const Value('mensual'),
        tipoAmortizacion: const Value('saldo_insoluto'),
        fechaPrestamo: normalizarFechaCivil(hoy),
        cuotaMensual: const Value(1200000),
        fechaLimite: Value(haceMeses(-36)),
      ),
    );
    final celular = await db.deudasDao.insertDeuda(
      DeudasCompanion.insert(
        acreedorNombre: 'Celular a meses',
        descripcion: const Value('Claro'),
        tipo: const Value('tienda'),
        montoOriginal: 900000,
        fechaPrestamo: haceMeses(8),
      ),
    );
    await db.pagosDeudaDao.insertPago(
      PagosDeudaCompanion.insert(
        deudaId: celular,
        montoAbonado: 900000,
        fechaPago: haceMeses(2),
      ),
    );
    await db.deudasDao.marcarComoPagada(celular, haceMeses(2));
    return (nu: nu, juan: juan, carro: carro, celular: celular);
  }

  Future<void> montar(WidgetTester tester, Size tamano) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: RepaintBoundary(child: DeudasScreen(db: db)),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Guarda una captura si se pide con CAPTURAS=<carpeta> (para revisar el
  /// diseño a ojo); sin esa variable no hace nada.
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

  for (final (nombre, tamano) in [
    ('celular (360x640)', const Size(360, 640)),
    ('PC con menú (1102x768)', const Size(1102, 768)),
    ('PC grande (1656x1000)', const Size(1656, 1000)),
  ]) {
    testWidgets('Deudas en $nombre: las tres pestañas se dibujan sin '
        'desbordarse', (tester) async {
      await sembrar();
      await montar(tester, tamano);
      expect(tester.takeException(), isNull);

      expect(find.text('3 ACTIVAS'), findsOneWidget);
      expect(find.text('Total de las deudas'), findsOneWidget);
      expect(find.text('Pagos mínimos al mes'), findsOneWidget);
      expect(find.text('Pagado del total'), findsOneWidget);
      expect(find.text('Tarjeta Nu'), findsOneWidget);
      expect(find.text('24% anual'), findsOneWidget);
      await captura(tester, 'activas-${tamano.width.round()}');

      await tester.tap(find.text('Plan de pago'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Estrategia'), findsOneWidget);
      expect(find.text('LIBRE DE DEUDAS EN'), findsOneWidget);
      await captura(tester, 'plan-${tamano.width.round()}');

      await tester.tap(find.text('Pagadas'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Celular a meses'), findsOneWidget);
      expect(find.textContaining('Claro · Liquidada'), findsOneWidget);
      expect(find.text(formatCOP(900000)), findsOneWidget);
      await captura(tester, 'pagadas-${tamano.width.round()}');
      await _cerrar(tester);
    });
  }

  testWidgets('los totales de arriba salen de los datos reales', (
    tester,
  ) async {
    await sembrar();
    await montar(tester, const Size(1102, 768));

    // Nu 1.200.000 + Juan 300.000 + carro 45.000.000 (empezaron hoy: sin
    // interés todavía).
    expect(find.text(formatCOP(46500000)), findsOneWidget);
    // Mínimos: 150.000 + 100.000 + 1.200.000.
    expect(find.text(formatCOP(1450000)), findsOneWidget);
    // Pagado: 100.000 de 46.600.000 → 0 %.
    expect(find.text('0%'), findsOneWidget);
    await _cerrar(tester);
  });

  testWidgets('en PC, tocar una tarjeta abre el detalle en un panel a la '
      'derecha y la X lo cierra', (tester) async {
    await sembrar();
    await montar(tester, const Size(1366, 768));

    expect(find.byKey(const ValueKey('panel-deuda')), findsNothing);
    await tester.tap(find.text('Tarjeta Nu'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final panel = find.byKey(const ValueKey('panel-deuda'));
    expect(panel, findsOneWidget);
    // A la derecha: pegado al borde derecho de la ventana.
    expect(tester.getTopRight(panel).dx, 1366);
    for (final texto in [
      'Tasa',
      'Pago mínimo',
      'Próximo pago',
      'Liquidación estimada',
      'Pagos recientes',
      'Registrar pago',
    ]) {
      expect(
        find.descendant(of: panel, matching: find.text(texto)),
        findsOneWidget,
        reason: texto,
      );
    }
    await captura(tester, 'panel-1366');

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(panel, findsNothing);
    await _cerrar(tester);
  });

  testWidgets('en celular, tocar una tarjeta abre el detalle como página', (
    tester,
  ) async {
    await sembrar();
    await montar(tester, const Size(360, 640));

    // Una tarjeta por fila: la de Juan queda más abajo.
    await tester.scrollUntilVisible(
      find.text('Juan'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    // Si la tarjeta ya estaba construida (debajo del borde de la pantalla),
    // scrollUntilVisible la trae a la vista pero no redibuja.
    await tester.pump();
    await tester.tap(find.text('Juan'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DeudaDetalle), findsOneWidget);
    expect(find.byKey(const ValueKey('panel-deuda')), findsNothing);
    expect(find.text('Registrar pago'), findsOneWidget);
    await captura(tester, 'detalle-360');
    await _cerrar(tester);
  });

  testWidgets('Registrar pago: "Mínimo" y "Liquidar" llenan el monto, no deja '
      'pagar de más y al guardar el mínimo baja el saldo', (tester) async {
    final ids = await sembrar();
    await montar(tester, const Size(1366, 768));
    await tester.tap(find.text('Juan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar pago'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // A qué se abona y cuánto se debe.
    expect(find.text('Juan · Saldo ${formatCOP(300000)}'), findsOneWidget);
    final campo = find.byType(TextFormField);
    String monto() => tester.widget<TextFormField>(campo).controller!.text;
    expect(monto(), isEmpty);
    await captura(tester, 'registrar-pago');

    // Pagar de más no se puede.
    await tester.enterText(campo, '300002');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No puedes pagar más'), findsOneWidget);
    expect(await db.pagosDeudaDao.getTotalAbonado(ids.juan), 100000);

    // Solo números: letras y signos se descartan.
    await tester.enterText(campo, '-5a0');
    expect(monto(), '50');

    await tester.tap(find.text('Liquidar ${formatCOP(300000)}'));
    await tester.pump();
    expect(monto(), '300.000');

    await tester.tap(find.text('Mínimo ${formatCOP(100000)}'));
    await tester.pump();
    expect(monto(), '100.000');

    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(await db.pagosDeudaDao.getTotalAbonado(ids.juan), 200000);
    expect((await db.deudasDao.getDeudaById(ids.juan))!.estado, 'activa');
    await _cerrar(tester);
  });

  testWidgets('Registrar pago: "Cancelar" no guarda nada', (tester) async {
    final ids = await sembrar();
    await montar(tester, const Size(1366, 768));
    await tester.tap(find.text('Juan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar pago'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Liquidar ${formatCOP(300000)}'));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await db.pagosDeudaDao.getTotalAbonado(ids.juan), 100000);
    await _cerrar(tester);
  });

  testWidgets('liquidar una deuda desde el panel la pasa a Pagadas y cierra '
      'el panel', (tester) async {
    final ids = await sembrar();
    await montar(tester, const Size(1366, 768));
    await tester.tap(find.text('Juan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar pago'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Liquidar ${formatCOP(300000)}'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect((await db.deudasDao.getDeudaById(ids.juan))!.estado, 'pagada');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('panel-deuda')), findsNothing);
    expect(find.text('2 ACTIVAS'), findsOneWidget);
    await _cerrar(tester);
  });

  testWidgets('Plan de pago: cambiar de estrategia cambia el orden y se '
      'recuerda; el extra adelanta la fecha', (tester) async {
    await sembrar();
    await montar(tester, const Size(1366, 768));
    await tester.tap(find.text('Plan de pago'));
    await tester.pumpAndSettle();

    double arriba(String texto) => tester.getTopLeft(find.text(texto).last).dy;

    // Avalancha (por defecto): Nu (2 % mensual) va antes que Juan (0 %).
    expect(find.textContaining('tasa más alta'), findsOneWidget);
    expect(arriba('Tarjeta Nu') < arriba('Juan'), isTrue);

    await tester.tap(find.text('Bola de nieve'));
    await tester.pumpAndSettle();
    expect(find.textContaining('deuda más pequeña'), findsOneWidget);
    // Bola de nieve: Juan (300.000) va antes que Nu (1.200.000).
    expect(arriba('Juan') < arriba('Tarjeta Nu'), isTrue);

    await tester.enterText(find.byKey(const ValueKey('plan-extra')), '5000000');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(PlanPagoTab.claveEstrategia), 'bola_de_nieve');
    expect(prefs.getInt(PlanPagoTab.claveExtra), 5000000);
    await _cerrar(tester);
  });

  testWidgets('Pagadas: "Limpiar historial" pide confirmación y borra solo '
      'las pagadas, con sus pagos', (tester) async {
    final ids = await sembrar();
    await montar(tester, const Size(1366, 768));
    await tester.tap(find.text('Pagadas'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Limpiar historial'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await db.deudasDao.getDeudaById(ids.celular), isNotNull);

    await tester.tap(find.text('Limpiar historial'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Limpiar historial'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(await db.deudasDao.getDeudaById(ids.celular), isNull);
    expect(await db.deudasDao.getDeudaById(ids.juan), isNotNull);
    expect(await db.deudasDao.getDeudasActivas(), hasLength(3));
    await tester.pumpAndSettle();
    expect(find.textContaining('Todavía no has terminado'), findsOneWidget);
    await _cerrar(tester);
  });

  testWidgets('Plan de pago: avisa de las deudas sin pago mínimo y ofrece '
      'ponérselo', (tester) async {
    await sembrar();
    await db.deudasDao.insertDeuda(
      DeudasCompanion.insert(
        acreedorNombre: 'Sin cuota',
        montoOriginal: 90000,
        fechaPrestamo: normalizarFechaCivil(hoy),
      ),
    );
    await montar(tester, const Size(1366, 768));
    await tester.tap(find.text('Plan de pago'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('plan-sin-minimo')), findsOneWidget);
    expect(find.text('A 1 deuda le falta el pago mínimo'), findsOneWidget);
    await captura(tester, 'plan-sin-minimo');
    await tester.tap(find.text('Poner pago mínimo a Sin cuota'));
    await tester.pumpAndSettle();
    expect(find.byType(DeudaForm), findsOneWidget);
    // El formulario baja solo hasta "Pago mínimo", lo resalta un momento y
    // deja el cursor ahí.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    final campo = find.widgetWithText(
      CampoEtiquetado,
      'Pago mínimo al mes (opcional)',
    );
    expect(campo.hitTestable(), findsOneWidget);
    final editable = tester.widget<EditableText>(
      find.descendant(of: campo, matching: find.byType(EditableText)),
    );
    expect(editable.focusNode.hasFocus, isTrue);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _cerrar(tester);
  });

  testWidgets('sin deudas: mensajes de vacío en las tres pestañas', (
    tester,
  ) async {
    await montar(tester, const Size(360, 640));
    expect(find.text('SIN DEUDAS ACTIVAS'), findsOneWidget);
    expect(find.textContaining('No tienes deudas activas'), findsOneWidget);
    await tester.tap(find.text('Plan de pago'));
    await tester.pumpAndSettle();
    expect(find.textContaining('nada que planear'), findsOneWidget);
    await tester.tap(find.text('Pagadas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Todavía no has terminado'), findsOneWidget);
    await _cerrar(tester);
  });
}
