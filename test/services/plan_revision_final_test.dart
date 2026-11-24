import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/deudas_calculos.dart';
import 'package:valtiq/services/interes_calculator.dart';

Deuda _d({
  int id = 1,
  String nombre = 'D',
  int monto = 1000000,
  double tasa = 0,
  String mod = 'simple',
  String am = 'saldo_insoluto',
  required DateTime inicio,
  int? dia,
  int? cuota,
  DateTime? limite,
}) => Deuda(
  id: id,
  acreedorNombre: nombre,
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

AbonoInteres _a(int a, int m, int d, int monto) =>
    AbonoInteres(fecha: DateTime.utc(a, m, d), monto: monto);

PlanPago _plan(
  List<ResumenDeuda> rs,
  DateTime hoy, {
  int extra = 0,
  EstrategiaPago e = EstrategiaPago.avalancha,
}) =>
    PlanPago.simular(deudas: rs, estrategia: e, extraMensual: extra, hoy: hoy);

void main() {
  group('A: el último pago lleva el interés hasta el día de pago', () {
    for (final (nombre, d, abonos) in [
      (
        'sobre lo que falta',
        _d(
          monto: 300000,
          tasa: 3,
          inicio: DateTime.utc(2026, 10, 19),
          dia: 19,
          cuota: 400000,
        ),
        <AbonoInteres>[],
      ),
      (
        'sobre lo prestado, compuesto, día 31',
        _d(
          monto: 3000000,
          tasa: 2.2,
          mod: 'compuesto',
          am: 'saldo_original',
          inicio: DateTime.utc(2026, 6, 30),
          dia: 31,
          cuota: 500000,
        ),
        [
          _a(2026, 7, 31, 900000),
          _a(2026, 8, 31, 900000),
          _a(2026, 9, 30, 900000),
          _a(2026, 10, 31, 500000),
        ],
      ),
    ]) {
      test(nombre, () {
        final hoy = DateTime(2026, 11, 1);
        final r = ResumenDeuda.calcular(d, abonos, hoy: hoy);
        final dia = math.min(d.diaPago!, 30);
        final enElDia = r.saldoAl(DateTime(2026, 11, dia));
        expect(enElDia, greaterThan(r.saldo));
        final plan = _plan([r], hoy);
        final paso = plan.orden.single;
        expect(paso.meses, 0);
        expect((paso.pagoEsteMes - enElDia).abs(), lessThanOrEqualTo(1));
        // Pagando eso en su día, queda en cero.
        final despues = ResumenDeuda.calcular(d, [
          ...abonos,
          _a(2026, 11, dia, paso.pagoEsteMes),
        ], hoy: DateTime(2026, 11, dia));
        expect(despues.saldo, lessThanOrEqualTo(1));
        // La fecha estimada del detalle dice lo mismo.
        expect(r.liquidacionCon(d.cuotaMensual!, hoy).meses, 0);
      });
    }

    test('una cuota que no alcanza con el interés al día de pago no promete '
        'terminar este mes', () {
      final d = _d(
        monto: 800000,
        tasa: 1,
        mod: 'compuesto',
        inicio: DateTime.utc(2026, 5, 27),
        dia: 24,
        cuota: 139000,
      );
      final abonos = [
        _a(2026, 6, 24, 139000),
        _a(2026, 8, 24, 139000),
        _a(2026, 9, 24, 139000),
        _a(2026, 10, 24, 139000),
        _a(2026, 11, 24, 139000),
      ];
      final hoy = DateTime(2026, 12, 1);
      final r = ResumenDeuda.calcular(d, abonos, hoy: hoy);
      expect(r.saldo, lessThan(139000));
      expect(r.saldoAl(DateTime(2026, 12, 24)), greaterThan(139000));
      expect(_plan([r], hoy).meses, 1);
    });
  });

  group('C: sin día de pago, la fecha no depende del día en que se mira', () {
    test('del 24 de noviembre al 1 de diciembre sin pagar nada', () {
      final d = _d(
        monto: 3000000,
        tasa: 4.5,
        am: 'saldo_original',
        inicio: DateTime.utc(2025, 10, 14),
        cuota: 170000,
      );
      final abonos = [
        for (final m in [11, 12]) _a(2025, m, 10, 170000),
        for (final m in [2, 3, 4, 5, 6, 7, 8, 10, 11]) _a(2026, m, 10, 170000),
      ];
      DateTime? libre(DateTime hoy) =>
          _plan([ResumenDeuda.calcular(d, abonos, hoy: hoy)], hoy).fechaLibre;
      expect(libre(DateTime(2026, 11, 24)), libre(DateTime(2026, 12, 1)));
      expect(libre(DateTime(2026, 11, 24)), libre(DateTime(2026, 12, 13)));
    });
  });

  group('B: lo que sobra va primero a las urgentes', () {
    final hoy = DateTime(2026, 11, 24);
    final rs = [
      for (final (d, ab) in [
        (
          _d(
            id: 32,
            nombre: 'Sin Cuota',
            monto: 300000,
            am: 'saldo_original',
            inicio: DateTime.utc(2026, 11, 23),
            cuota: 50000,
          ),
          <AbonoInteres>[],
        ),
        (
          _d(
            id: 33,
            nombre: 'Limite',
            monto: 600000,
            am: 'saldo_original',
            inicio: DateTime.utc(2026, 11, 23),
            cuota: 20000,
            limite: DateTime.utc(2027, 2, 28),
          ),
          <AbonoInteres>[],
        ),
        (
          _d(
            id: 29,
            nombre: 'Amigo',
            monto: 100000,
            am: 'saldo_original',
            inicio: DateTime.utc(2026, 11, 12),
            dia: 30,
            cuota: 34000,
            limite: DateTime.utc(2027, 1, 31),
          ),
          <AbonoInteres>[],
        ),
        (
          _d(
            id: 30,
            nombre: 'Banco',
            monto: 5000000,
            tasa: 1,
            inicio: DateTime.utc(2026, 10, 21),
            dia: 15,
            cuota: 250000,
          ),
          <AbonoInteres>[],
        ),
        (
          _d(
            id: 31,
            nombre: 'Tarjeta',
            monto: 2000000,
            tasa: 2.5,
            inicio: DateTime.utc(2026, 10, 21),
            dia: 25,
            cuota: 120000,
          ),
          [_a(2026, 11, 23, 120000)],
        ),
        (
          _d(
            id: 34,
            nombre: 'Vencida',
            monto: 200000,
            am: 'saldo_original',
            inicio: DateTime.utc(2026, 10, 1),
            cuota: 50000,
            limite: DateTime.utc(2026, 11, 10),
          ),
          <AbonoInteres>[],
        ),
      ])
        ResumenDeuda.calcular(d, ab, hoy: hoy),
    ];

    for (final e in EstrategiaPago.values) {
      test('vencida, luego las de fecha cercana (${e.clave})', () {
        final p = _plan(rs, hoy, extra: 117000, e: e);
        expect(p.orden.take(3).map((o) => o.resumen.deuda.acreedorNombre), [
          'Vencida',
          'Amigo',
          'Limite',
        ]);
      });
    }

    test('una urgente que igual llega tarde no encarece mucho el plan', () {
      final hoy21 = DateTime(2026, 11, 21);
      final caso = [
        _d(
          id: 1,
          monto: 5500000,
          mod: 'compuesto',
          inicio: DateTime.utc(2025, 10, 20),
          dia: 16,
          cuota: 150000,
          limite: DateTime.utc(2026, 12, 9),
        ),
        _d(
          id: 2,
          monto: 3666000,
          tasa: 5,
          inicio: DateTime.utc(2026, 3, 15),
          cuota: 450000,
          limite: DateTime.utc(2028, 1, 3),
        ),
        _d(
          id: 3,
          monto: 2000000,
          am: 'saldo_original',
          inicio: DateTime.utc(2026, 11, 9),
          cuota: 200000,
        ),
        _d(
          id: 4,
          monto: 894511,
          tasa: 5.6,
          mod: 'compuesto',
          am: 'saldo_original',
          inicio: DateTime.utc(2026, 11, 6),
          cuota: 500000,
        ),
      ];
      final r = [
        for (final d in caso) ResumenDeuda.calcular(d, const [], hoy: hoy21),
      ];
      final sin = _plan(r, hoy21);
      final con = _plan(r, hoy21, extra: 50000);
      expect(con.interesesTotales, lessThanOrEqualTo(sin.interesesTotales));
    });
  });

  test('D: en Automática el extra sugerido cumple y promete la fecha real', () {
    final rnd = math.Random(5);
    var revisados = 0;
    for (var c = 0; c < 250; c++) {
      final hoy = DateTime(2026, 11, 1 + rnd.nextInt(28));
      final rs = [
        for (var i = 0; i < 2 + rnd.nextInt(4); i++)
          ResumenDeuda.calcular(
            _d(
              id: i + 1,
              monto: [300000, 1500000, 5000000][rnd.nextInt(3)],
              tasa: [0.0, 1.5, 3.0, 4.5][rnd.nextInt(4)],
              mod: rnd.nextBool() ? 'simple' : 'compuesto',
              am: rnd.nextBool() ? 'saldo_insoluto' : 'saldo_original',
              inicio: DateTime.utc(
                2026,
                1 + rnd.nextInt(10),
                1 + rnd.nextInt(28),
              ),
              dia: rnd.nextInt(3) == 0 ? null : 1 + rnd.nextInt(31),
              cuota: (20 + rnd.nextInt(300)) * 1000,
              limite: rnd.nextInt(3) == 0
                  ? DateTime.utc(2027, 1 + rnd.nextInt(24), 15)
                  : null,
            ),
            const [],
            hoy: hoy,
          ),
      ];
      final p = PlanPago.elegir(
        deudas: rs,
        elegida: null,
        extraMensual: 0,
        hoy: hoy,
      ).plan;
      for (final (s, limites) in [
        (p.paraTerminar, false),
        (p.paraLimites, true),
      ]) {
        if (s == null) continue;
        revisados++;
        final con = PlanPago.elegir(
          deudas: rs,
          elegida: null,
          extraMensual: s.extra,
          hoy: hoy,
          conSugerencias: false,
        ).plan;
        expect(con.alcanza, isTrue, reason: 'caso $c');
        if (limites) expect(con.fechasIncumplidas, 0, reason: 'caso $c');
        expect(con.fechaLibre, s.fechaLibre, reason: 'caso $c');
      }
    }
    expect(revisados, greaterThan(20));
  });
}
