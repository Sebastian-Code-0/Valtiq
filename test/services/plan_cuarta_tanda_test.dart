import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/deudas_calculos.dart';
import 'package:valtiq/services/interes_calculator.dart';

Deuda _deuda(
  int id,
  int monto,
  double tasa,
  DateTime inicio, {
  int? dia,
  int? cuota,
  String modalidad = 'compuesto',
  String amortizacion = 'saldo_original',
  DateTime? limite,
}) => Deuda(
  id: id,
  acreedorNombre: 'd$id',
  descripcion: '',
  tipo: 'otro',
  diaPago: dia,
  montoOriginal: monto,
  tasaInteres: tasa,
  tipoInteres: tasa > 0 ? 'mensual' : 'ninguno',
  modalidadCalculo: modalidad,
  tipoAmortizacion: amortizacion,
  fechaPrestamo: inicio,
  fechaLimite: limite,
  cuotaMensual: cuota,
  notas: '',
  estado: 'activa',
  fechaPagoReal: null,
  creadoEn: DateTime.utc(2020),
  actualizadoEn: DateTime.utc(2020),
);

/// Una deuda vencida o con fecha muy cerca terminó antes en [p] que en [a]:
/// esa prioridad puede costar algo de interés o alargar el plan, a propósito.
bool _urgenteAntes(PlanPago p, PlanPago a) {
  for (final x in p.orden) {
    final l = x.mesLimite;
    if (l == null || l > 3) continue;
    final y = a.orden.firstWhere(
      (o) => o.resumen.deuda.id == x.resumen.deuda.id,
    );
    if (x.meses != null && (y.meses == null || x.meses! < y.meses!)) {
      return true;
    }
  }
  return false;
}

void main() {
  final hoy = DateTime(2026, 11, 22, 15);
  List<ResumenDeuda> resumenes(List<Deuda> ds) => [
    for (final d in ds)
      ResumenDeuda.calcular(d, const <AbonoInteres>[], hoy: hoy),
  ];

  test('con 5 deudas encuentra un orden que termina', () {
    final rs = resumenes([
      _deuda(0, 1500000, 8, DateTime.utc(2026, 10, 12), dia: 21, cuota: 60000),
      _deuda(1, 800000, 3, DateTime.utc(2026, 10, 22), dia: 30, cuota: 120000),
      _deuda(2, 800000, 2.4, DateTime.utc(2026, 10, 16), dia: 5, cuota: 80000),
      _deuda(3, 300000, 1.5, DateTime.utc(2026, 10, 14), dia: 1, cuota: 21000),
      _deuda(4, 1500000, .9, DateTime.utc(2026, 6, 20), cuota: 60000),
    ]);
    final plan = PlanPago.simular(
      deudas: rs,
      estrategia: EstrategiaPago.avalancha,
      extraMensual: 200000,
      hoy: hoy,
    );
    expect(plan.meses, isNotNull);
    expect(plan.meses, lessThanOrEqualTo(15));
  });

  test('con 5 a 7 deudas: el extra sugerido cumple, con 1.000 menos no, y '
      'más extra solo atrasa o encarece por una fecha o una urgente', () {
    final azar = math.Random(44);
    for (var caso = 0; caso < 40; caso++) {
      final n = 5 + caso % 3;
      final rs = resumenes([
        for (var i = 0; i < n; i++)
          _deuda(
            i,
            (azar.nextInt(30) + 2) * 100000,
            [0.9, 1.5, 3.0, 5.0, 8.0][azar.nextInt(5)],
            DateTime.utc(2026, 11 - azar.nextInt(8), 1 + azar.nextInt(27)),
            dia: azar.nextBool() ? 1 + azar.nextInt(30) : null,
            cuota: (azar.nextInt(9) + 2) * 10000,
            modalidad: azar.nextBool() ? 'simple' : 'compuesto',
            amortizacion: azar.nextBool() ? 'saldo_original' : 'saldo_insoluto',
            limite: azar.nextInt(3) == 0
                ? DateTime.utc(2027 + azar.nextInt(3), 1 + azar.nextInt(12), 15)
                : null,
          ),
      ]);
      PlanPago con(int x) => PlanPago.simular(
        deudas: rs,
        estrategia: EstrategiaPago.avalancha,
        extraMensual: x,
        hoy: hoy,
      );
      final base = con(0);
      final t = base.paraTerminar;
      if (t != null) {
        expect(con(t.extra).alcanza, isTrue, reason: 'caso $caso');
        if (t.extra > 1000) {
          expect(con(t.extra - 1000).alcanza, isFalse, reason: 'caso $caso');
        }
      }
      final l = base.paraLimites;
      if (l != null) {
        final p = con(l.extra);
        expect(p.alcanza && p.tarde.isEmpty, isTrue, reason: 'caso $caso');
        if (l.extra > 1000) {
          final menos = con(l.extra - 1000);
          expect(menos.alcanza && menos.tarde.isEmpty, isFalse);
        }
      }
      PlanPago? previo;
      for (final x in [0, 50000, 100000, 200000, 400000, 800000]) {
        final p = con(x);
        // Cumplir una fecha más puede alargar el plan: eso es a propósito.
        if (previo != null &&
            previo.alcanza &&
            p.tarde.length >= previo.tarde.length &&
            !_urgenteAntes(p, previo)) {
          expect(p.alcanza, isTrue, reason: 'caso $caso x=$x');
          expect(p.meses!, lessThanOrEqualTo(previo.meses!));
          expect(
            p.interesesTotales,
            lessThanOrEqualTo(previo.interesesTotales + 1),
            reason: 'caso $caso x=$x',
          );
        }
        previo = p;
      }
    }
  });

  test('cuota sugerida con abono este mes llega a la fecha límite', () {
    final h = DateTime(2028, 2, 29, 15);
    final r = ResumenDeuda.calcular(
      _deuda(
        1,
        200000,
        1.5,
        DateTime.utc(2028, 1, 2),
        dia: 21,
        modalidad: 'simple',
        limite: DateTime.utc(2028, 7, 8),
      ),
      [AbonoInteres(fecha: DateTime.utc(2028, 2, 29), monto: 50000)],
      hoy: h,
    );
    final s = r.sugerirCuotas(h)!;
    expect(s.minimo.cuota, 42000);
    expect(s.minimo.meses, lessThanOrEqualTo(r.mesLimite(h)!));
  });

  test('un orden que termina con menos extra no se pierde', () {
    final rs = resumenes([
      _deuda(0, 1500000, 8, DateTime.utc(2026, 9, 14), dia: 15, cuota: 105000),
      _deuda(1, 300000, 1.9, DateTime.utc(2026, 11, 19), dia: 5, cuota: 30000),
      _deuda(
        2,
        5000000,
        1.5,
        DateTime.utc(2026, 11, 16),
        dia: 5,
        cuota: 350000,
        modalidad: 'simple',
      ),
      _deuda(3, 300000, 0, DateTime.utc(2026, 12, 21), dia: 1, cuota: 21000),
      _deuda(
        4,
        800000,
        0,
        DateTime.utc(2026, 10, 15),
        dia: 31,
        cuota: 200000,
        modalidad: 'simple',
      ),
    ]);
    PlanPago con(int x) => PlanPago.simular(
      deudas: rs,
      estrategia: EstrategiaPago.avalancha,
      extraMensual: x,
      hoy: hoy,
    );
    expect(con(50000).meses, 20);
    final sugerido = con(0).paraTerminar!.extra;
    expect(sugerido, 41000);
    expect(con(sugerido).alcanza, isTrue);
    expect(con(sugerido - 1000).alcanza, isFalse);
  });

  test('los meses entre dos días no cambian al calcularlos sin fechas', () {
    final azar = math.Random(5);
    double porFechas(DateTime a, DateTime b) {
      DateTime aniv(int n) {
        final ultimo = DateTime.utc(a.year, a.month + n + 1, 0).day;
        return DateTime.utc(a.year, a.month + n, math.min(a.day, ultimo));
      }

      if (!b.isAfter(a)) return 0;
      var m = math.max(0, (b.year - a.year) * 12 + b.month - a.month - 1);
      while (!aniv(m + 1).isAfter(b)) {
        m++;
      }
      var d = b.difference(aniv(m)).inDays;
      if (d >= 30) {
        m++;
        d -= 30;
      }
      return m + d / 30;
    }

    for (var i = 0; i < 4000; i++) {
      final a = DateTime.utc(
        1999 + azar.nextInt(90),
        1 + azar.nextInt(12),
        1 + azar.nextInt(31),
      );
      final b = a.add(Duration(days: azar.nextInt(4000) - 200));
      expect(
        InteresCalculator.desglosarPeriodo(a, b).mesesTotal,
        porFechas(a, b),
        reason: '$a $b',
      );
    }
  });

  test('el extra que solo sirve pagando este mes lo dice', () {
    final rs = resumenes([
      _deuda(
        1,
        1000000,
        5,
        DateTime.utc(2026, 11, 22),
        cuota: 10000,
        modalidad: 'simple',
        amortizacion: 'saldo_insoluto',
      ),
    ]);
    final s = PlanPago.simular(
      deudas: rs,
      estrategia: EstrategiaPago.avalancha,
      extraMensual: 0,
      hoy: hoy,
    ).paraTerminar!;
    expect(s.extra, 39000);
    expect(s.soloDesdeEsteMes, isTrue);
    final desdeElOtro = PlanPago.simular(
      deudas: rs,
      estrategia: EstrategiaPago.avalancha,
      extraMensual: s.extra,
      extraDiferido: s.extra,
      hoy: hoy,
    );
    expect(desdeElOtro.alcanza, isFalse);
  });
}
