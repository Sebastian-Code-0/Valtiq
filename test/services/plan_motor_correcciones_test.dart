import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/deudas_calculos.dart';
import 'package:valtiq/services/interes_calculator.dart';
import 'package:valtiq/utils/currency_input.dart';
import 'package:valtiq/utils/format.dart';
import 'package:valtiq/utils/tasa_input.dart';

final _hoy = DateTime(2026, 11, 21);

Deuda _d({
  int id = 1,
  int monto = 1000000,
  double tasa = 0,
  String mod = 'simple',
  String am = 'saldo_original',
  required DateTime inicio,
  DateTime? limite,
  int? cuota,
  int? dia,
}) => Deuda(
  id: id,
  acreedorNombre: 'D$id',
  descripcion: '',
  tipo: 'otro',
  diaPago: dia,
  montoOriginal: monto,
  tasaInteres: tasa,
  tipoInteres: tasa > 0 ? 'mensual' : 'ninguno',
  modalidadCalculo: mod,
  tipoAmortizacion: am,
  fechaPrestamo: inicio,
  fechaLimite: limite,
  cuotaMensual: cuota,
  notas: '',
  estado: 'activa',
  creadoEn: DateTime(2026),
  actualizadoEn: DateTime(2026),
);

AbonoInteres _a(int y, int m, int d, int monto) =>
    AbonoInteres(fecha: DateTime.utc(y, m, d), monto: monto);

Map<String, int> _insoluto(
  List<AbonoInteres> abonos,
  DateTime fin, {
  String mod = 'simple',
  double tasa = 2,
  DateTime? inicio,
}) => InteresCalculator.resumenPrestamo(
  montoPrestado: 1000000,
  tasaInteres: tasa,
  tipoInteres: 'mensual',
  modalidadCalculo: mod,
  fechaPrestamo: inicio ?? DateTime.utc(2026, 6, 1),
  totalAbonado: abonos.fold(0, (s, a) => s + a.monto),
  tipoAmortizacion: 'saldo_insoluto',
  abonos: abonos,
  fechaFin: fin,
);

void main() {
  test('A1: un abono anterior al inicio no agrega interés', () {
    final r = _insoluto([_a(2026, 1, 1, 1)], DateTime.utc(2026, 7, 1));
    expect(r['interesAcumulado'], 20000);
  });

  group('A2: compuesto sobre lo que falta', () {
    final inicio = DateTime.utc(2025, 1, 1);
    final fin = DateTime.utc(2026, 1, 1);

    test('abonos mínimos no borran la capitalización', () {
      final sin = _insoluto(
        [],
        fin,
        mod: 'compuesto',
        tasa: 10,
        inicio: inicio,
      );
      expect(sin['interesAcumulado'], 2138428);
      final con = _insoluto(
        [for (var m = 2; m <= 12; m++) _a(2025, m, 1, 1)],
        fin,
        mod: 'compuesto',
        tasa: 10,
        inicio: inicio,
      );
      expect(con['interesAcumulado'], closeTo(2138428, 40));
    });

    test('si el abono cubre todo el interés no cambia nada', () {
      final con = _insoluto(
        [_a(2025, 2, 1, 100000)],
        DateTime.utc(2025, 3, 1),
        mod: 'compuesto',
        tasa: 10,
        inicio: inicio,
      );
      expect(con['interesAcumulado'], 200000);
      expect(con['saldoPendiente'], 1100000);
    });
  });

  group('A3: la mora no genera interés en la proyección', () {
    final r = ResumenDeuda.calcular(
      _d(
        tasa: 5,
        am: 'saldo_insoluto',
        inicio: DateTime.utc(2024, 11, 21),
        cuota: 60000,
      ),
      const [],
      hoy: _hoy,
    );

    test('liquidación, plan e interés del mes coinciden con el real', () {
      expect(r.saldo, 2200000);
      expect(r.interesPendiente, 1200000);
      expect(r.interesProximoMes, 50000);
      final l = r.liquidacionCon(60000, _hoy);
      expect(l.noBaja, isFalse);
      expect(l.meses, 151);
      final p = PlanPago.simular(
        deudas: [r],
        estrategia: EstrategiaPago.avalancha,
        extraMensual: 0,
        hoy: _hoy,
      );
      expect(p.meses, 151);
    });

    test('la cuota sugerida usa la misma regla', () {
      final cuota = r.cuotaParaTerminarEn(23, _hoy)!;
      expect(r.liquidacionCon(cuota, _hoy).meses, lessThanOrEqualTo(23));
      expect(r.liquidacionCon(cuota - 1000, _hoy).meses, greaterThan(23));
    });
  });

  test('A4: los días no dependen del cambio de hora', () {
    // Cruza el cambio de hora de Nueva York (8 mar) y Madrid (29 mar).
    final a = InteresCalculator.desglosarPeriodo(
      DateTime.utc(2026, 3, 1),
      DateTime.utc(2026, 3, 20),
    );
    expect(a.diasParciales, 19);
    final b = InteresCalculator.desglosarPeriodo(
      DateTime.utc(2026, 3, 20),
      DateTime.utc(2026, 4, 10),
    );
    expect(b.diasParciales, 21);
  });

  group('A5: tasa exacta', () {
    test('conserva todos los decimales, con coma', () {
      expect(tasaParaCampo(1.875), '1,875');
      expect(tasaParaCampo(0.001), '0,001');
      expect(tasaParaCampo(0.0000001), '0,0000001');
      for (final t in [1.875, 0.001, 26.8, 33.33, 0.0000001, 2.0]) {
        expect(parseTasa(tasaParaCampo(t)), t);
      }
    });

    test('no acepta notación científica', () {
      expect(parseTasa('1e2'), 0);
      expect(validarTasa('1e2'), isNotNull);
      expect(validarTasa('NaN'), isNotNull);
      expect(validarTasa('Infinity'), isNotNull);
      expect(validarTasa('1,5'), isNull);
    });
  });

  group('A6: avalancha', () {
    final a = _d(
      id: 1,
      monto: 10000000,
      tasa: 4,
      inicio: DateTime.utc(2026, 8, 23),
      cuota: 800000,
    );
    final b = _d(
      id: 2,
      monto: 10000000,
      tasa: 4,
      inicio: DateTime.utc(2026, 8, 23),
      cuota: 1000000,
    );
    PlanPago plan(List<Deuda> ds) => PlanPago.simular(
      deudas: [
        for (final d in ds) ResumenDeuda.calcular(d, const [], hoy: _hoy),
      ],
      estrategia: EstrategiaPago.avalancha,
      extraMensual: 200000,
      hoy: _hoy,
    );

    test('elige el orden que menos interés cobra', () {
      // Sin día de pago se proyecta con el día en que empezaron (el 23): del
      // 21 al 23 corren $13.333 de interés en cada una.
      expect(plan([a, b]).interesesTotales, 11626667);
    });

    test('no depende del orden de la lista', () {
      final x = plan([a, b]);
      final y = plan([b, a]);
      expect(y.interesesTotales, x.interesesTotales);
      expect(
        y.orden.map((p) => p.resumen.deuda.id),
        x.orden.map((p) => p.resumen.deuda.id),
      );
    });

    test('con muchas deudas responde rápido y no empeora', () {
      final ds = [
        for (var i = 0; i < 12; i++)
          _d(
            id: i + 1,
            monto: 1000000 + i * 300000,
            tasa: 1 + (i % 5) * 0.7,
            am: i.isEven ? 'saldo_original' : 'saldo_insoluto',
            inicio: DateTime.utc(2026, 8, 23),
            cuota: 90000 + i * 15000,
          ),
      ];
      final rs = [
        for (final d in ds) ResumenDeuda.calcular(d, const [], hoy: _hoy),
      ];
      final reloj = Stopwatch()..start();
      final av = PlanPago.simular(
        deudas: rs,
        estrategia: EstrategiaPago.avalancha,
        extraMensual: 100000,
        hoy: _hoy,
      );
      expect(reloj.elapsedMilliseconds, lessThan(3000));
      final bola = PlanPago.simular(
        deudas: rs,
        estrategia: EstrategiaPago.bolaDeNieve,
        extraMensual: 100000,
        hoy: _hoy,
      );
      expect(av.alcanza, isTrue);
      expect(av.interesesTotales, lessThanOrEqualTo(bola.interesesTotales));
    });
  });

  test('A7: cuenta el interés hasta el día de pago', () {
    final r = ResumenDeuda.calcular(
      _d(
        monto: 2000000,
        tasa: 1.5,
        am: 'saldo_insoluto',
        inicio: DateTime.utc(2026, 10, 21),
        dia: 30,
        cuota: 420000,
      ),
      const [],
      hoy: _hoy,
    );
    expect(r.fraccionDelMes(1), closeTo(1 + 9 / 30, 1e-9));
    final p = PlanPago.simular(
      deudas: [r],
      estrategia: EstrategiaPago.avalancha,
      extraMensual: 0,
      hoy: _hoy,
    );
    expect(p.meses, 5);
    expect(r.liquidacionCon(420000, _hoy).meses, 5);
  });

  group('A8', () {
    test('formatCOP en los extremos', () {
      expect(formatCOP(999999999999999), r'$999,99 billones');
      expect(formatCOP(-0.4), r'$0');
      expect(formatCOP(999999999999.6), r'$1 billón');
      expect(formatCOP(double.nan), r'$0');
      expect(formatCOP(1e15), r'$1000 billones');
      expect(formatCOP(5.5e12), r'$5,50 billones');
    });

    test('un abono con fecha futura no cuenta en ningún modo', () {
      for (final am in ['saldo_original', 'saldo_insoluto']) {
        final r = ResumenDeuda.calcular(
          _d(monto: 500000, am: am, inicio: DateTime.utc(2026, 9, 1)),
          [_a(2026, 10, 1, 100000), _a(2027, 3, 1, 200000)],
          hoy: _hoy,
        );
        expect(r.abonado, 100000, reason: am);
        expect(r.saldo, 400000, reason: am);
      }
    });
  });

  group('B4: eliminar un pago de una deuda pagada', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<int> sembrar() async {
      final id = await db.deudasDao.insertDeuda(
        DeudasCompanion.insert(
          acreedorNombre: 'X',
          montoOriginal: 300000,
          fechaPrestamo: DateTime.utc(2026, 8, 1),
          cuotaMensual: const Value(100000),
        ),
      );
      for (final (m, v) in [(9, 200000), (10, 100000)]) {
        await db.pagosDeudaDao.insertPago(
          PagosDeudaCompanion.insert(
            deudaId: id,
            montoAbonado: v,
            fechaPago: DateTime.utc(2026, m, 1),
          ),
        );
      }
      return id;
    }

    test('se reabre y dice cuánto debe', () async {
      final id = await sembrar();
      await db.deudasDao.marcarComoPagada(id, DateTime.utc(2026, 10, 1));
      final ps = await db.pagosDeudaDao.getPagosDeDeuda(id);
      final debe = await db.pagosDeudaDao.eliminarPago(ps.first.id);
      expect(debe, 100000);
      final d = await db.deudasDao.getDeudaById(id);
      expect(d!.estado, 'activa');
      expect(d.fechaPagoReal, isNull);
    });

    test('una deuda activa no cambia de estado', () async {
      final id = await sembrar();
      final ps = await db.pagosDeudaDao.getPagosDeDeuda(id);
      expect(await db.pagosDeudaDao.eliminarPago(ps.first.id), isNull);
      expect((await db.deudasDao.getDeudaById(id))!.estado, 'activa');
    });
  });

  test('B5: el saldo a una fecha pasada', () {
    final r = ResumenDeuda.calcular(
      _d(tasa: 3, am: 'saldo_insoluto', inicio: DateTime.utc(2026, 8, 21)),
      const [],
      hoy: _hoy,
    );
    expect(r.saldoAl(DateTime(2026, 11, 1)), 1071000);
    expect(r.saldoAl(_hoy), r.saldo);
  });

  test('B7: pagado el mes, el próximo pago es el siguiente', () {
    final d = _d(
      monto: 600000,
      inicio: DateTime.utc(2026, 8, 1),
      dia: 24,
      cuota: 100000,
    );
    expect(
      ResumenDeuda.calcular(d, const [], hoy: _hoy).proximoPago(_hoy),
      DateTime(2026, 11, 24),
    );
    expect(
      ResumenDeuda.calcular(d, [
        _a(2026, 11, 21, 100000),
      ], hoy: _hoy).proximoPago(_hoy),
      DateTime(2026, 12, 24),
    );
    // Un abono parcial no cubre el mes.
    expect(
      ResumenDeuda.calcular(d, [
        _a(2026, 11, 21, 40000),
      ], hoy: _hoy).proximoPago(_hoy),
      DateTime(2026, 11, 24),
    );
  });

  test('B8: límite ya pasado con día de pago dice que venció', () {
    final v = ResumenDeuda.calcular(
      _d(
        monto: 500000,
        inicio: DateTime.utc(2026, 8, 1),
        limite: DateTime.utc(2026, 10, 15),
        dia: 28,
      ),
      const [],
      hoy: _hoy,
    ).vencimiento(_hoy)!;
    expect(v.vencida, isTrue);
    expect(v.fecha, DateTime(2026, 10, 15));
  });

  test('B13: montos pegados con centavos', () {
    final f = CopInputFormatter();
    String pegar(String t) => f
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: t))
        .text;
    expect(pegar('1.500.000,50'), '1.500.000');
    expect(pegar('1.500.000,40'), '1.500.000');
    expect(pegar('1500000.50'), '1.500.000');
    expect(pegar('1,500,000.25'), '1.500.000');
    expect(pegar('1.500.000'), '1.500.000');
    expect(pegar(r'$ 2.000'), '2.000');
    // Al borrar un dígito, "1.23" no son decimales.
    expect(
      f
          .formatEditUpdate(
            const TextEditingValue(
              text: '1.234',
              selection: TextSelection.collapsed(offset: 5),
            ),
            const TextEditingValue(
              text: '1.23',
              selection: TextSelection.collapsed(offset: 4),
            ),
          )
          .text,
      '123',
    );
  });

  test('B15: nunca dice 100 % si falta plata', () {
    final r = ResumenDeuda.calcular(_d(inicio: DateTime.utc(2026, 8, 1)), [
      _a(2026, 10, 1, 996000),
    ], hoy: _hoy);
    expect(r.saldo, 4000);
    expect(r.porcentajePagado, 99);
    expect(TotalesDeudas([r]).porcentajePagado, 99);
  });
}
