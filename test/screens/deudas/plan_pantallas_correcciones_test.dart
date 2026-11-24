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
import 'package:valtiq/screens/deudas/registrar_pago_dialog.dart';
import 'package:valtiq/screens/prestamos/registrar_abono.dart';
import 'package:valtiq/services/backup_service.dart';
import 'package:valtiq/services/plan_pago_preferencias.dart';
import 'package:valtiq/theme/theme.dart';
import 'package:valtiq/utils/fecha_civil.dart';
import 'package:valtiq/utils/form_widgets.dart';

final _ahora = DateTime.now();
DateTime _atras(int meses) =>
    normalizarFechaCivil(DateTime(_ahora.year, _ahora.month - meses, 1));

void main() {
  late AppDatabase db;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> app(
    WidgetTester t,
    Widget home, {
    Size size = const Size(1366, 900),
    double escala = 1,
  }) async {
    t.view.physicalSize = size;
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
        supportedLocales: const [Locale('es', 'CO'), Locale('en')],
        builder: (c, w) => MediaQuery(
          data: MediaQuery.of(
            c,
          ).copyWith(textScaler: TextScaler.linear(escala)),
          child: w!,
        ),
        home: home,
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> fin(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 10));
  }

  Finder campo(String etiqueta) => find
      .descendant(
        of: find
            .ancestor(
              of: find.text(etiqueta),
              matching: find.byType(CampoEtiquetado),
            )
            .first,
        matching: find.byType(TextField),
      )
      .first;

  Future<void> escribir(WidgetTester t, String etiqueta, String v) async {
    await t.ensureVisible(campo(etiqueta));
    await t.pumpAndSettle();
    await t.enterText(campo(etiqueta), v);
    await t.pump();
  }

  Future<void> guardar(WidgetTester t, String label) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    await t.ensureVisible(find.text(label));
    await t.pumpAndSettle();
    await t.tap(find.text(label));
    await t.pumpAndSettle();
  }

  Future<int> deuda({
    String n = 'D',
    int monto = 1000000,
    double tasa = 0,
    String ti = 'ninguno',
    String mod = 'simple',
    String am = 'saldo_original',
    DateTime? inicio,
    int? cuota,
    int? dia,
    DateTime? limite,
  }) => db.deudasDao.insertDeuda(
    DeudasCompanion.insert(
      acreedorNombre: n,
      montoOriginal: monto,
      tasaInteres: Value(tasa),
      tipoInteres: Value(ti),
      modalidadCalculo: Value(mod),
      tipoAmortizacion: Value(am),
      fechaPrestamo: inicio ?? _atras(3),
      cuotaMensual: Value(cuota),
      diaPago: Value(dia),
      fechaLimite: Value(limite),
    ),
  );

  Future<void> pago(int id, int m, DateTime f) => db.pagosDeudaDao.insertPago(
    PagosDeudaCompanion.insert(deudaId: id, montoAbonado: m, fechaPago: f),
  );

  Future<void> irPlan(WidgetTester t) async {
    await t.tap(find.text('Plan de pago'));
    await t.pumpAndSettle();
  }

  testWidgets('B1: activa en \$0 no rompe el Plan y se puede cerrar', (
    t,
  ) async {
    final id = await deuda(n: 'Cero', monto: 100000, cuota: 50000);
    await pago(id, 100000, _atras(1));
    await app(t, DeudasScreen(db: db));
    await irPlan(t);
    expect(t.takeException(), isNull);
    expect(find.text('Cero ya no debe nada'), findsOneWidget);
    await t.tap(find.byKey(ValueKey('plan-en-cero-$id')));
    await t.pumpAndSettle();
    expect((await db.deudasDao.getDeudaById(id))!.estado, 'pagada');
    await t.pump(const Duration(seconds: 6));
    await fin(t);
  });

  testWidgets('B1: bajar el monto a lo ya pagado la pasa a pagadas', (t) async {
    final id = await deuda(monto: 500000, cuota: 100000);
    await pago(id, 300000, _atras(1));
    await app(t, DeudaForm(db: db, deuda: await db.deudasDao.getDeudaById(id)));
    await escribir(t, 'Monto original', '300000');
    await escribir(t, 'Pago mínimo al mes (opcional)', '');
    await guardar(t, 'Guardar cambios');
    final pagada = (await db.deudasDao.getDeudaById(id))!;
    expect(pagada.estado, 'pagada');
    // Se terminó con su último pago, no hoy.
    expect(fechaCivilGuardada(pagada.fechaPagoReal!), _atras(1));
    await t.pump(const Duration(seconds: 6));
    await fin(t);
  });

  testWidgets('B2 y A5: borrar la tasa un momento no pierde lo elegido, y '
      'abrir y guardar no la cambia', (t) async {
    final id = await deuda(
      tasa: 1.875,
      ti: 'mensual',
      mod: 'compuesto',
      am: 'saldo_insoluto',
    );
    await app(t, DeudaForm(db: db, deuda: await db.deudasDao.getDeudaById(id)));
    await guardar(t, 'Guardar cambios');
    expect((await db.deudasDao.getDeudaById(id))!.tasaInteres, 1.875);
    await fin(t);

    await app(t, DeudaForm(db: db, deuda: await db.deudasDao.getDeudaById(id)));
    await escribir(t, 'Tasa de interés', '');
    await escribir(t, 'Tasa de interés', '2,5');
    await guardar(t, 'Guardar cambios');
    final d = (await db.deudasDao.getDeudaById(id))!;
    expect(d.tasaInteres, 2.5);
    expect(d.tipoInteres, 'mensual');
    expect(d.modalidadCalculo, 'compuesto');
    expect(d.tipoAmortizacion, 'saldo_insoluto');
    await fin(t);
  });

  group('B3: interés sobre', () {
    Future<void> elegirTipo(WidgetTester t, String nombre) async {
      final selector = find.byType(DropdownButtonFormField<String>).first;
      await t.ensureVisible(selector);
      await t.pumpAndSettle();
      await t.tap(selector);
      await t.pumpAndSettle();
      await t.tap(find.text(nombre).last);
      await t.pumpAndSettle();
    }

    testWidgets('Banco preselecciona lo que falta por pagar', (t) async {
      await app(t, DeudaForm(db: db));
      await escribir(t, 'Nombre', 'Crédito');
      await escribir(t, 'Monto original', '1000000');
      await elegirTipo(t, 'Banco o crédito');
      await escribir(t, 'Tasa de interés', '2');
      await t.ensureVisible(find.text('Mensual'));
      await t.pumpAndSettle();
      await t.tap(find.text('Mensual'));
      await t.pump();
      await guardar(t, 'Guardar deuda');
      final d = (await db.deudasDao.getAllDeudas()).single;
      expect(d.tipoAmortizacion, 'saldo_insoluto');
      await fin(t);
    });

    testWidgets('persona deja el valor y hace visible la elección', (t) async {
      await app(t, DeudaForm(db: db));
      await escribir(t, 'Tasa de interés', '2');
      await t.pumpAndSettle();
      expect(find.textContaining('Revisa esto'), findsOneWidget);
      await fin(t);
    });

    testWidgets('al editar no cambia lo guardado', (t) async {
      final id = await db.deudasDao.insertDeuda(
        DeudasCompanion.insert(
          acreedorNombre: 'Banco viejo',
          tipo: const Value('banco'),
          montoOriginal: 1000000,
          tasaInteres: const Value(2),
          tipoInteres: const Value('mensual'),
          fechaPrestamo: _atras(2),
        ),
      );
      await app(
        t,
        DeudaForm(db: db, deuda: await db.deudasDao.getDeudaById(id)),
      );
      await elegirTipo(t, 'Tarjeta de crédito');
      await guardar(t, 'Guardar cambios');
      final d = (await db.deudasDao.getDeudaById(id))!;
      expect(d.tipoAmortizacion, 'saldo_original');
      await fin(t);
    });
  });

  testWidgets('B5: Liquidar sigue la fecha elegida y congela ahí', (t) async {
    // Empezó hace 3 meses, el día 1; se liquida el día 1 del mes pasado.
    final id = await deuda(
      n: 'Banco',
      tasa: 3,
      ti: 'mensual',
      am: 'saldo_insoluto',
      inicio: _atras(3),
    );
    await app(t, DeudaDetalle(db: db, deudaId: id));
    await t.tap(find.text('Registrar pago'));
    await t.pumpAndSettle();
    final dialogo = t.state<State<RegistrarPagoDialog>>(
      find.byType(RegistrarPagoDialog),
    );
    expect(dialogo.widget, isA<RegistrarPagoDialog>());
    final w = t.widget<RegistrarPagoDialog>(find.byType(RegistrarPagoDialog));
    final corte = _atras(1);
    // Dos meses a 3 %.
    expect(w.saldoEnFecha!(corte), 1060000);
    expect(fechaCivilGuardada(w.fechaInicio!), _atras(3));
    await fin(t);
  });

  testWidgets('B6: sin pagos y con primer pago el mes que viene', (t) async {
    await deuda(
      monto: 600000,
      cuota: 100000,
      inicio: normalizarFechaCivil(_ahora),
    );
    await app(t, DeudasScreen(db: db));
    await irPlan(t);
    expect(find.textContaining('Lo de este mes ya está pago'), findsNothing);
    expect(find.textContaining('tu primer pago es'), findsOneWidget);
    await fin(t);
  });

  testWidgets('B9: sin interés no se culpa al interés', (t) async {
    final id = await deuda(n: 'Lenta', monto: 900000000, cuota: 1);
    await app(t, DeudaDetalle(db: db, deudaId: id));
    expect(find.textContaining('el interés'), findsNothing);
    expect(find.textContaining('más de 50 años'), findsOneWidget);
    await fin(t);
    await app(t, DeudasScreen(db: db));
    await irPlan(t);
    expect(find.text('Lenta no termina'), findsOneWidget);
    expect(find.textContaining('el interés crece'), findsNothing);
    await fin(t);
  });

  testWidgets('B10: si ninguna termina no promete que la otra sí', (t) async {
    await deuda(
      n: 'A',
      monto: 10000000,
      tasa: 5,
      ti: 'mensual',
      am: 'saldo_insoluto',
      cuota: 1000,
    );
    await deuda(
      n: 'B',
      monto: 5000000,
      tasa: 5,
      ti: 'mensual',
      am: 'saldo_insoluto',
      cuota: 1000,
    );
    await app(t, DeudasScreen(db: db));
    await irPlan(t);
    await t.tap(find.text('Bola de nieve').first);
    await t.pumpAndSettle();
    expect(find.textContaining('sí terminas de pagar'), findsNothing);
    expect(find.textContaining('Con ninguna de las dos'), findsOneWidget);
    await fin(t);
  });

  testWidgets('B11: restaurar con el Plan abierto recarga', (t) async {
    await deuda(monto: 2000000, cuota: 100000);
    await app(t, DeudasScreen(db: db));
    await irPlan(t);
    await t.enterText(find.byKey(const ValueKey('plan-extra')), '50000');
    await t.pumpAndSettle();
    final deudas = (await db.deudasDao.getAllDeudas())
        .map((e) => e.toJson())
        .toList();
    await BackupService(db).importarDatos({
      'datos': {'deudas': deudas},
      'planPago': {'estrategia': 'bola_de_nieve', 'extra': 300000},
    });
    await t.pumpAndSettle();
    final texto = t
        .widget<TextField>(find.byKey(const ValueKey('plan-extra')))
        .controller!
        .text;
    expect(texto, '300.000');
    await fin(t);
  });

  testWidgets('B12: el formulario de una pagada no sugiere cuotas', (t) async {
    final id = await deuda(tasa: 3, ti: 'mensual');
    await db.deudasDao.marcarComoPagada(id, _atras(1));
    await app(t, DeudaForm(db: db, deuda: await db.deudasDao.getDeudaById(id)));
    expect(find.byKey(const ValueKey('cuota-sugerencias')), findsNothing);
    await fin(t);
  });

  testWidgets('B14: no guarda una fecha límite anterior al inicio', (t) async {
    final inicio = _atras(1);
    final id = await deuda(inicio: inicio, limite: _atras(2), cuota: 100000);
    await app(t, DeudaForm(db: db, deuda: await db.deudasDao.getDeudaById(id)));
    await escribir(t, 'Nombre', 'Cambiada');
    await guardar(t, 'Guardar cambios');
    expect(find.textContaining('no puede ser anterior'), findsOneWidget);
    expect((await db.deudasDao.getDeudaById(id))!.acreedorNombre, 'D');
    await t.pump(const Duration(seconds: 6));
    await fin(t);
  });

  testWidgets('B15: plural de fechas vencidas', (t) async {
    await deuda(n: 'A', monto: 500000, cuota: 100000, limite: _atras(1));
    await deuda(n: 'B', monto: 400000, cuota: 100000, limite: _atras(1));
    await app(t, DeudasScreen(db: db));
    await irPlan(t);
    expect(find.textContaining('Las fechas límite de'), findsOneWidget);
    expect(find.textContaining('ya pasaron'), findsOneWidget);
    await fin(t);
  });

  testWidgets('B15: sin pagos no dice "lo que vienes pagando"', (t) async {
    final id = await deuda(monto: 600000, cuota: 100000);
    await app(t, DeudaDetalle(db: db, deudaId: id));
    expect(find.textContaining('lo que vienes pagando'), findsNothing);
    await fin(t);
  });

  testWidgets('B15: la cuota no puede pasar de lo que se debe', (t) async {
    final id = await deuda(monto: 1000000);
    await pago(id, 900000, _atras(1));
    await app(t, DeudaForm(db: db, deuda: await db.deudasDao.getDeudaById(id)));
    await escribir(t, 'Pago mínimo al mes (opcional)', '500000');
    await guardar(t, 'Guardar cambios');
    expect((await db.deudasDao.getDeudaById(id))!.cuotaMensual, isNot(500000));
    await fin(t);
  });

  testWidgets('B15: 360 px con texto al 130 % no se desborda', (t) async {
    const largo = 'Crédito de libre inversión con un nombre larguísimo';
    final a = await deuda(
      n: largo,
      monto: 999999999999,
      tasa: 2.75,
      ti: 'mensual',
      am: 'saldo_insoluto',
      cuota: 1000,
      dia: 28,
    );
    await app(t, DeudasScreen(db: db), size: const Size(360, 640), escala: 1.3);
    expect(t.takeException(), isNull);
    await fin(t);
    await app(
      t,
      DeudaForm(db: db, deuda: await db.deudasDao.getDeudaById(a)),
      size: const Size(360, 640),
      escala: 1.3,
    );
    expect(t.takeException(), isNull);
    await fin(t);
  });

  testWidgets('B16: tras un pago parcial, Mínimo ofrece lo que falta', (
    t,
  ) async {
    final id = await deuda(monto: 1000000, cuota: 100000);
    await pago(id, 30000, normalizarFechaCivil(_ahora));
    await app(t, DeudaDetalle(db: db, deudaId: id));
    await t.tap(find.text('Registrar pago'));
    await t.pumpAndSettle();
    expect(find.text(r'Mínimo $70.000'), findsOneWidget);
    await fin(t);
  });

  testWidgets('B17: el detalle dice que es a tu ritmo actual', (t) async {
    final id = await deuda(monto: 600000, cuota: 100000);
    await app(t, DeudaDetalle(db: db, deudaId: id));
    expect(find.text('Fin a tu ritmo actual'), findsOneWidget);
    expect(find.textContaining('A tu ritmo actual'), findsOneWidget);
    await fin(t);
  });

  testWidgets('D1: restaurar con el Plan abierto conserva lo del respaldo', (
    t,
  ) async {
    final a = await deuda(n: 'A', monto: 100000, cuota: 100000);
    await deuda(n: 'B', monto: 1000000, cuota: 100000);
    final deudas = (await db.deudasDao.getAllDeudas())
        .map((e) => Map<String, dynamic>.from(e.toJson()))
        .toList();
    final ja = deudas.firstWhere((d) => d['id'] == a);
    ja['estado'] = 'pagada';
    ja['fechaPagoReal'] = normalizarFechaCivil(_ahora).millisecondsSinceEpoch;
    await app(t, DeudasScreen(db: db));
    await irPlan(t);
    await BackupService(db).importarDatos({
      'datos': {'deudas': deudas},
      'planPago': {
        'estrategia': 'automatica',
        'extra': 100000,
        'liberadas': [
          {
            'deudaId': a,
            'monto': 100000,
            'desdeMes': _ahora.year * 12 + _ahora.month,
          },
        ],
      },
    });
    await t.pumpAndSettle();
    final p = await PreferenciasPlan.leer();
    expect(p.extra, 100000);
    expect(p.liberadas, hasLength(1));
    await fin(t);
  });

  testWidgets('D5: subir el monto de una pagada la reabre', (t) async {
    final id = await deuda(monto: 300000);
    await pago(id, 300000, _atras(1));
    await db.deudasDao.marcarComoPagada(id, _atras(1));
    await app(t, DeudaForm(db: db, deuda: await db.deudasDao.getDeudaById(id)));
    await escribir(t, 'Monto original', '500000');
    await guardar(t, 'Guardar cambios');
    expect((await db.deudasDao.getDeudaById(id))!.estado, 'activa');
    await t.pump(const Duration(seconds: 6));
    await fin(t);
  });

  testWidgets('D6: pasar a pagadas usa la fecha del último pago', (t) async {
    final a = await deuda(n: 'Cero', monto: 200000, cuota: 50000);
    await pago(a, 200000, _atras(2));
    await deuda(n: 'Otra', monto: 900000, cuota: 100000);
    await app(t, DeudasScreen(db: db));
    await irPlan(t);
    final boton = find.byKey(ValueKey('plan-en-cero-$a'));
    await t.ensureVisible(boton);
    await t.pumpAndSettle();
    await t.tap(boton);
    await t.pumpAndSettle();
    final d = (await db.deudasDao.getDeudaById(a))!;
    expect(fechaCivilGuardada(d.fechaPagoReal!), _atras(2));
    expect(find.textContaining('Terminaste'), findsNothing);
    await t.pump(const Duration(seconds: 6));
    await fin(t);
  });

  testWidgets('E2: la cuota de la calculadora se puede guardar', (t) async {
    await app(t, DeudaForm(db: db));
    await escribir(t, 'Nombre', 'Banco X');
    await escribir(t, 'Monto original', '1000000');
    await escribir(t, 'Tasa de interés', '5');
    await t.ensureVisible(find.text('Mensual'));
    await t.pumpAndSettle();
    await t.tap(find.text('Mensual'));
    await t.pumpAndSettle();
    final calc = find.byTooltip('Calcular la cuota para terminar en N meses');
    await t.ensureVisible(calc);
    await t.pumpAndSettle();
    await t.tap(calc);
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).last, '1');
    await t.tap(find.text('Calcular'));
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
    await guardar(t, 'Guardar deuda');
    final g = (await db.deudasDao.getAllDeudas()).single;
    expect(g.cuotaMensual, 1050000);
    await fin(t);
  });

  testWidgets('E3: el abono de un préstamo usa el saldo de esa fecha', (
    t,
  ) async {
    final id = await db.prestamosDao.insertPrestamo(
      PrestamosCompanion.insert(
        deudorNombre: 'Ana',
        montoPrestado: 1000000,
        tasaInteres: const Value(3),
        tipoInteres: const Value('mensual'),
        tipoAmortizacion: const Value('saldo_insoluto'),
        fechaPrestamo: _atras(3),
      ),
    );
    await app(
      t,
      Scaffold(
        body: RegistrarAbonoDialog(
          db: db,
          prestamoId: id,
          nombre: 'Ana',
          saldoPendiente: 2000000,
          fechaInicio: _atras(3),
        ),
      ),
    );
    await t.pumpAndSettle();
    // Sin fecha pasada el tope ya es el saldo real, no el valor recibido.
    await t.enterText(find.byType(TextFormField).first, '1900000');
    await t.tap(find.text('Guardar'));
    await t.pumpAndSettle();
    expect(await db.prestamosDao.getPagosDelPrestamo(id), isEmpty);
    expect(find.textContaining('No puede superar'), findsOneWidget);
    await fin(t);
  });

  group('E4: propuesta de "Interés sobre"', () {
    Future<void> tipo(WidgetTester t, String clave) async {
      final dd = find.byType(DropdownButtonFormField<String>).first;
      await t.ensureVisible(dd);
      await t.pumpAndSettle();
      await t.tap(dd);
      await t.pumpAndSettle();
      await t.tap(
        find
            .descendant(
              of: find.byWidgetPredicate(
                (w) => w is DropdownMenuItem<String> && w.value == clave,
              ),
              matching: find.byType(Text),
            )
            .last,
      );
      await t.pumpAndSettle();
    }

    testWidgets('Banco guardado sin tasa: al ponerla avisa', (t) async {
      final id = await db.deudasDao.insertDeuda(
        DeudasCompanion.insert(
          acreedorNombre: 'Banco',
          tipo: const Value('banco'),
          montoOriginal: 5000000,
          fechaPrestamo: _atras(1),
        ),
      );
      await app(
        t,
        DeudaForm(db: db, deuda: await db.deudasDao.getDeudaById(id)),
      );
      await escribir(t, 'Tasa de interés', '2');
      await t.pumpAndSettle();
      expect(find.textContaining('Revisa esto'), findsOneWidget);
      await fin(t);
    });

    testWidgets('Banco y luego Persona quita la propuesta', (t) async {
      await app(t, DeudaForm(db: db));
      await escribir(t, 'Nombre', 'Juan');
      await escribir(t, 'Monto original', '100000');
      await escribir(t, 'Tasa de interés', '2');
      await t.ensureVisible(find.text('Mensual'));
      await t.pumpAndSettle();
      await t.tap(find.text('Mensual'));
      await t.pumpAndSettle();
      await tipo(t, 'banco');
      await tipo(t, 'persona');
      await guardar(t, 'Guardar deuda');
      final g = (await db.deudasDao.getAllDeudas()).single;
      expect(g.tipoAmortizacion, 'saldo_original');
      await fin(t);
    });
  });

  testWidgets('E5: inicio anterior a 2000 no rompe el selector', (t) async {
    final id = await deuda(inicio: normalizarFechaCivil(DateTime(1999, 6, 1)));
    await app(t, DeudaForm(db: db, deuda: await db.deudasDao.getDeudaById(id)));
    final fecha = find.descendant(
      of: find
          .ancestor(
            of: find.text('Fecha en que empezó'),
            matching: find.byType(CampoEtiquetado),
          )
          .first,
      matching: find.byType(DatePickerField),
    );
    await t.ensureVisible(fecha);
    await t.pumpAndSettle();
    await t.tap(fecha);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await fin(t);
  });

  testWidgets('R20: el aviso sale tras el pago y explica las dos fechas', (
    t,
  ) async {
    final a = await deuda(n: 'A', monto: 100000, cuota: 100000);
    final b = await deuda(n: 'B', monto: 1000000, cuota: 100000);
    final hoyC = normalizarFechaCivil(_ahora);
    await pago(a, 100000, hoyC);
    await pago(b, 100000, hoyC);
    await db.deudasDao.marcarComoPagada(a, hoyC);
    await app(t, DeudasScreen(db: db));
    await irPlan(t);
    expect(find.text('Terminaste A'), findsOneWidget);
    expect(find.textContaining('Si no los sigues pagando'), findsOneWidget);
    await fin(t);
  });
}
