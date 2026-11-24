import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/deudas_calculos.dart';
import 'package:valtiq/services/interes_calculator.dart';

Deuda _deuda({
  int id = 1,
  String nombre = 'Deuda',
  required int monto,
  double tasa = 0,
  String tipoInteres = 'ninguno',
  String modalidad = 'simple',
  String amortizacion = 'saldo_original',
  required DateTime inicio,
  DateTime? limite,
  int? cuota,
  int? diaPago,
  String estado = 'activa',
  DateTime? fechaPagoReal,
}) => Deuda(
  id: id,
  acreedorNombre: nombre,
  descripcion: '',
  tipo: 'otro',
  diaPago: diaPago,
  montoOriginal: monto,
  tasaInteres: tasa,
  tipoInteres: tipoInteres,
  modalidadCalculo: modalidad,
  tipoAmortizacion: amortizacion,
  fechaPrestamo: inicio,
  fechaLimite: limite,
  cuotaMensual: cuota,
  notas: '',
  estado: estado,
  fechaPagoReal: fechaPagoReal,
  creadoEn: DateTime(2026),
  actualizadoEn: DateTime(2026),
);

AbonoInteres _abono(int anio, int mes, int dia, int monto) =>
    AbonoInteres(fecha: DateTime.utc(anio, mes, dia), monto: monto);

/// Fuerza bruta: ¿existe ALGÚN reparto (de a $1.000) de lo que sobra cada mes
/// con el que todas las deudas lleguen a su fecha límite pagando [extra]?
bool _algunRepartoCumple(List<ResumenDeuda> rs, int extra, DateTime hoy) {
  final n = rs.length;
  final limites = [for (final r in rs) r.mesLimite(hoy)];
  final ultimo = limites
      .whereType<int>()
      .where((l) => l >= 0)
      .fold<int>(0, math.max);
  final primeros = [for (final r in rs) r.primerMesDePago(hoy)];
  final memo = <String, bool>{};

  bool mes(int k, List<double> saldos) {
    for (var i = 0; i < n; i++) {
      final l = limites[i];
      if (l != null && l >= 0 && l < k && saldos[i] >= 0.5) return false;
    }
    if (k > ultimo) return true;
    final clave = '$k:${saldos.map((v) => v.round()).join(',')}';
    final visto = memo[clave];
    if (visto != null) return visto;
    final t = List.of(saldos);
    if (k > 0) {
      for (var i = 0; i < n; i++) {
        if (t[i] >= 0.5) t[i] += rs[i].interesDelMes(k, t[i]);
      }
    }
    var disponible = extra.toDouble();
    for (var i = 0; i < n; i++) {
      if (k < primeros[i]) continue;
      final cuota = (rs[i].deuda.cuotaMensual ?? 0).toDouble();
      disponible += cuota;
      final pago = math.min(cuota, t[i]);
      t[i] -= pago;
      disponible -= pago;
    }

    bool repartir(int i, double queda, List<double> u) {
      if (i == n - 1) {
        final v = List.of(u);
        v[i] = math.max(0, v[i] - queda);
        for (var j = 0; j < n; j++) {
          if (v[j] < 0.5) v[j] = 0;
        }
        return mes(k + 1, v);
      }
      for (var a = 0.0; ; a += 1000) {
        final real = math.min(a, queda);
        final v = List.of(u);
        v[i] = math.max(0, v[i] - real);
        if (repartir(i + 1, queda - real, v)) return true;
        if (a >= queda || a >= u[i]) break;
      }
      return false;
    }

    return memo[clave] = repartir(0, math.max(0, disponible), t);
  }

  return mes(0, [for (final r in rs) r.saldo.toDouble()]);
}

void main() {
  final hoy = DateTime(2026, 11, 11);

  group('ResumenDeuda', () {
    test('sin interés: saldo, pagado y porcentaje', () {
      final r = ResumenDeuda.calcular(
        _deuda(monto: 1000000, inicio: DateTime.utc(2026, 8, 1), cuota: 200000),
        [_abono(2026, 9, 1, 250000), _abono(2026, 10, 1, 250000)],
        hoy: hoy,
      );
      expect(r.saldo, 500000);
      expect(r.abonado, 500000);
      expect(r.total, 1000000);
      expect(r.fraccionPagada, 0.5);
      expect(r.pagoMinimo, 200000);
    });

    test('el pago mínimo nunca supera el saldo y es null sin cuota', () {
      final casiPagada = ResumenDeuda.calcular(
        _deuda(monto: 300000, inicio: DateTime.utc(2026, 8, 1), cuota: 200000),
        [_abono(2026, 9, 1, 250000)],
        hoy: hoy,
      );
      expect(casiPagada.pagoMinimo, 50000);

      final sinCuota = ResumenDeuda.calcular(
        _deuda(monto: 300000, inicio: DateTime.utc(2026, 8, 1)),
        const [],
        hoy: hoy,
      );
      expect(sinCuota.pagoMinimo, isNull);
    });

    test('tasa anual se pasa a mensual dividiendo entre 12', () {
      final r = ResumenDeuda.calcular(
        _deuda(
          monto: 1000000,
          tasa: 24,
          tipoInteres: 'anual',
          inicio: DateTime.utc(2026, 11, 11),
        ),
        const [],
        hoy: hoy,
      );
      expect(r.tasaMensualPct, 2);
    });

    test('una deuda pagada congela el saldo en su fecha real de pago', () {
      final r = ResumenDeuda.calcular(
        _deuda(
          monto: 1000000,
          tasa: 2,
          tipoInteres: 'mensual',
          inicio: DateTime.utc(2026, 1, 1),
          estado: 'pagada',
          fechaPagoReal: DateTime.utc(2026, 2, 1),
        ),
        [_abono(2026, 2, 1, 1020000)],
        hoy: hoy,
      );
      // Un mes de interés (20.000), no los diez que han pasado hasta hoy.
      expect(r.total, 1020000);
      expect(r.saldo, 0);
      expect(r.fraccionPagada, 1);
    });
  });

  group('proximoPago / vencimiento', () {
    ResumenDeuda con({int? dia, DateTime? limite}) => ResumenDeuda.calcular(
      _deuda(
        monto: 500000,
        inicio: DateTime.utc(2026, 8, 1),
        diaPago: dia,
        limite: limite,
      ),
      const [],
      hoy: hoy,
    );

    test('día que todavía no llega este mes', () {
      expect(con(dia: 12).proximoPago(hoy), DateTime(2026, 11, 12));
    });

    test('el día de hoy cuenta como próximo pago', () {
      expect(con(dia: 11).proximoPago(hoy), DateTime(2026, 11, 11));
    });

    test('día que ya pasó: salta al mes siguiente', () {
      expect(con(dia: 5).proximoPago(hoy), DateTime(2026, 12, 5));
    });

    test('día 31 en un mes de 30 cae en el último día', () {
      expect(con(dia: 31).proximoPago(hoy), DateTime(2026, 11, 30));
      expect(
        con(dia: 31).proximoPago(DateTime(2027, 2, 1)),
        DateTime(2027, 2, 28),
      );
    });

    test('diciembre pasa a enero del año siguiente', () {
      expect(
        con(dia: 5).proximoPago(DateTime(2026, 12, 20)),
        DateTime(2027, 1, 5),
      );
    });

    test('sin día de pago usa la fecha límite y marca si ya venció', () {
      final vigente = con(limite: DateTime.utc(2026, 12, 1)).vencimiento(hoy)!;
      expect(vigente.fecha, DateTime(2026, 12, 1));
      expect(vigente.vencida, isFalse);

      final vencida = con(limite: DateTime.utc(2026, 11, 1)).vencimiento(hoy)!;
      expect(vencida.vencida, isTrue);

      expect(con().vencimiento(hoy), isNull);
    });
  });

  group('liquidacionEstimada', () {
    test('sin interés y pagando la cuota: saldo / cuota meses', () {
      final r = ResumenDeuda.calcular(
        _deuda(
          monto: 1000000,
          inicio: DateTime.utc(2026, 11, 1),
          cuota: 250000,
        ),
        const [],
        hoy: hoy,
      );
      final e = r.liquidacionEstimada(hoy);
      expect(e.meses, 4);
      expect(e.fecha, DateTime(2027, 3, 1));
      expect(e.noBaja, isFalse);
    });

    test('sin cuota y sin historial no se puede estimar', () {
      final r = ResumenDeuda.calcular(
        _deuda(monto: 1000000, inicio: DateTime.utc(2026, 11, 1)),
        const [],
        hoy: hoy,
      );
      final e = r.liquidacionEstimada(hoy);
      expect(e.fecha, isNull);
      expect(e.noBaja, isFalse);
    });

    test('quien paga MÁS que la cuota termina antes', () {
      final deuda = _deuda(
        monto: 2000000,
        inicio: DateTime.utc(2026, 7, 15),
        cuota: 100000,
      );
      final cumplido = ResumenDeuda.calcular(deuda, [
        _abono(2026, 8, 15, 100000),
        _abono(2026, 9, 15, 100000),
        _abono(2026, 10, 15, 100000),
      ], hoy: hoy);
      final generoso = ResumenDeuda.calcular(deuda, [
        _abono(2026, 8, 15, 300000),
        _abono(2026, 9, 15, 300000),
        _abono(2026, 10, 15, 300000),
      ], hoy: hoy);

      expect(cumplido.ritmoMensual(hoy), 100000);
      expect(generoso.ritmoMensual(hoy), 300000);
      // 1.700.000 a 100.000 → 17 pagos; 1.100.000 a 300.000 → 4 pagos. El
      // primero es el de este mes (noviembre aún no se paga), así que el
      // último cae 16 y 3 meses después.
      expect(cumplido.liquidacionEstimada(hoy).meses, 16);
      expect(generoso.liquidacionEstimada(hoy).meses, 3);
    });

    test('quien se salta un mes o paga menos termina después', () {
      final deuda = _deuda(
        monto: 2000000,
        inicio: DateTime.utc(2026, 7, 15),
        cuota: 100000,
      );
      final r = ResumenDeuda.calcular(deuda, [
        _abono(2026, 8, 15, 100000),
        // septiembre: no pagó
        _abono(2026, 10, 15, 50000),
      ], hoy: hoy);
      expect(r.ritmoMensual(hoy), 50000); // 150.000 / 3 meses
      // 1.850.000 / 50.000 = 37 pagos, el primero este mes.
      expect(r.liquidacionEstimada(hoy).meses, 36);
    });

    test('los pagos del mes en curso no cambian el ritmo (evita saltos)', () {
      final deuda = _deuda(
        monto: 2000000,
        inicio: DateTime.utc(2026, 7, 15),
        cuota: 100000,
      );
      final r = ResumenDeuda.calcular(deuda, [
        _abono(2026, 8, 15, 100000),
        _abono(2026, 9, 15, 100000),
        _abono(2026, 10, 15, 100000),
        _abono(2026, 11, 5, 900000),
      ], hoy: hoy);
      expect(r.ritmoMensual(hoy), 100000);
    });

    test('si no abonó nada en los meses mirados se asume la cuota', () {
      final r = ResumenDeuda.calcular(
        _deuda(monto: 600000, inicio: DateTime.utc(2026, 7, 15), cuota: 100000),
        const [],
        hoy: hoy,
      );
      expect(r.ritmoMensual(hoy), 100000);
      // 6 pagos, el primero este mes (todavía no se ha pagado noviembre).
      expect(r.liquidacionEstimada(hoy).meses, 5);
      expect(r.liquidacionEstimada(hoy).fecha, DateTime(2027, 4, 1));
    });

    test('con interés sobre saldo: coincide con la amortización a mano', () {
      // 1.000.000 al 2 % mensual pagando 100.000: n = 11 meses
      // (−ln(1 − 0,02·10) / ln 1,02 = 11,27 → el pago 12 es el último).
      final r = ResumenDeuda.calcular(
        _deuda(
          monto: 1000000,
          tasa: 2,
          tipoInteres: 'mensual',
          amortizacion: 'saldo_insoluto',
          inicio: DateTime.utc(2026, 11, 11),
          cuota: 100000,
        ),
        const [],
        hoy: hoy,
      );
      final e = r.liquidacionEstimada(hoy);
      expect(e.meses, 12);
      expect(e.fecha, DateTime(2027, 11, 1));
    });

    test('si el pago no cubre ni el interés, la deuda no baja', () {
      final r = ResumenDeuda.calcular(
        _deuda(
          monto: 1000000,
          tasa: 3,
          tipoInteres: 'mensual',
          amortizacion: 'saldo_insoluto',
          inicio: DateTime.utc(2026, 11, 11),
          cuota: 20000,
        ),
        const [],
        hoy: hoy,
      );
      final e = r.liquidacionEstimada(hoy);
      expect(e.noBaja, isTrue);
      expect(e.fecha, isNull);
    });
  });

  group('TotalesDeudas', () {
    test('suma saldos y mínimos, y saca el porcentaje pagado', () {
      final a = ResumenDeuda.calcular(
        _deuda(monto: 1000000, inicio: DateTime.utc(2026, 8, 1), cuota: 200000),
        [_abono(2026, 9, 1, 400000)],
        hoy: hoy,
      );
      final b = ResumenDeuda.calcular(
        _deuda(id: 2, monto: 1000000, inicio: DateTime.utc(2026, 8, 1)),
        [_abono(2026, 9, 1, 100000)],
        hoy: hoy,
      );
      final t = TotalesDeudas([a, b]);
      expect(t.cantidad, 2);
      expect(t.totalDeudas, 1500000);
      expect(t.pagosMinimosMes, 200000);
      expect(t.fraccionPagada, 0.25);
    });

    test('sin deudas: todo en cero, sin dividir entre cero', () {
      final t = TotalesDeudas(const []);
      expect(t.totalDeudas, 0);
      expect(t.fraccionPagada, 0);
    });
  });

  group('PlanPago', () {
    // Caro: 1.000.000 al 3 % mensual. Chico: 300.000 al 1 % mensual.
    List<ResumenDeuda> deudas() => [
      ResumenDeuda.calcular(
        _deuda(
          id: 1,
          nombre: 'Cara',
          monto: 1000000,
          tasa: 3,
          tipoInteres: 'mensual',
          amortizacion: 'saldo_insoluto',
          inicio: DateTime.utc(2026, 11, 11),
          cuota: 100000,
        ),
        const [],
        hoy: hoy,
      ),
      ResumenDeuda.calcular(
        _deuda(
          id: 2,
          nombre: 'Chica',
          monto: 300000,
          tasa: 1,
          tipoInteres: 'mensual',
          amortizacion: 'saldo_insoluto',
          inicio: DateTime.utc(2026, 11, 11),
          cuota: 50000,
        ),
        const [],
        hoy: hoy,
      ),
    ];

    PlanPago plan(EstrategiaPago e, {int extra = 100000}) => PlanPago.simular(
      deudas: deudas(),
      estrategia: e,
      extraMensual: extra,
      hoy: hoy,
    );

    test('avalancha ataca primero la tasa más alta', () {
      final p = plan(EstrategiaPago.avalancha);
      expect(p.orden.map((x) => x.resumen.deuda.acreedorNombre), [
        'Cara',
        'Chica',
      ]);
    });

    test('bola de nieve ataca primero el saldo más pequeño', () {
      final p = plan(EstrategiaPago.bolaDeNieve);
      expect(p.orden.map((x) => x.resumen.deuda.acreedorNombre), [
        'Chica',
        'Cara',
      ]);
      // La chica cae antes con bola de nieve que con avalancha.
      final chicaAvalancha = plan(
        EstrategiaPago.avalancha,
      ).orden.firstWhere((x) => x.resumen.deuda.id == 2);
      expect(p.orden.first.meses! < chicaAvalancha.meses!, isTrue);
    });

    test('avalancha nunca paga más intereses que bola de nieve', () {
      final a = plan(EstrategiaPago.avalancha);
      final b = plan(EstrategiaPago.bolaDeNieve);
      expect(a.interesesTotales <= b.interesesTotales, isTrue);
      expect(a.interesesTotales, greaterThan(0));
    });

    test('el presupuesto del mes es mínimos + extra', () {
      expect(plan(EstrategiaPago.avalancha).presupuestoMensual, 250000);
      expect(
        plan(EstrategiaPago.avalancha, extra: 0).presupuestoMensual,
        150000,
      );
    });

    test('más extra = libre de deudas antes y con menos intereses', () {
      final poco = plan(EstrategiaPago.avalancha, extra: 0);
      final mucho = plan(EstrategiaPago.avalancha, extra: 300000);
      expect(mucho.meses! < poco.meses!, isTrue);
      expect(mucho.interesesTotales < poco.interesesTotales, isTrue);
    });

    test('lo pagado en total = capital + intereses (no se pierde plata)', () {
      final p = plan(EstrategiaPago.avalancha);
      // Las dos empezaron este mes: este mes solo va el extra (100.000) y
      // después el presupuesto completo todos los meses menos el último.
      final pagadoMaximo = 100000 + p.presupuestoMensual * p.meses!;
      final pagadoMinimo = 100000 + p.presupuestoMensual * (p.meses! - 1);
      final debe = 1300000 + p.interesesTotales;
      expect(debe <= pagadoMaximo, isTrue);
      expect(debe > pagadoMinimo, isTrue);
    });

    test('sin intereses y sin extra: fecha = la deuda que más tarda', () {
      final p = PlanPago.simular(
        deudas: [
          ResumenDeuda.calcular(
            _deuda(
              id: 1,
              monto: 600000,
              inicio: DateTime.utc(2026, 11, 11),
              cuota: 100000,
            ),
            const [],
            hoy: hoy,
          ),
        ],
        estrategia: EstrategiaPago.avalancha,
        extraMensual: 0,
        hoy: hoy,
      );
      expect(p.meses, 6);
      expect(p.fechaLibre, DateTime(2027, 5, 1));
      expect(p.interesesTotales, 0);
    });

    test('sin mínimos ni extra el plan no alcanza', () {
      final p = PlanPago.simular(
        deudas: [
          ResumenDeuda.calcular(
            _deuda(monto: 600000, inicio: DateTime.utc(2026, 11, 11)),
            const [],
            hoy: hoy,
          ),
        ],
        estrategia: EstrategiaPago.avalancha,
        extraMensual: 0,
        hoy: hoy,
      );
      expect(p.alcanza, isFalse);
      expect(p.fechaLibre, isNull);
      expect(p.orden.single.fecha, isNull);
    });

    test('si los pagos no cubren el interés, el plan no alcanza', () {
      final p = PlanPago.simular(
        deudas: [
          ResumenDeuda.calcular(
            _deuda(
              monto: 1000000,
              tasa: 5,
              tipoInteres: 'mensual',
              amortizacion: 'saldo_insoluto',
              inicio: DateTime.utc(2026, 11, 11),
              cuota: 30000,
            ),
            const [],
            hoy: hoy,
          ),
        ],
        estrategia: EstrategiaPago.avalancha,
        extraMensual: 0,
        hoy: hoy,
      );
      expect(p.alcanza, isFalse);
    });

    test('sin deudas activas: plan vacío', () {
      final p = PlanPago.simular(
        deudas: const [],
        estrategia: EstrategiaPago.bolaDeNieve,
        extraMensual: 0,
        hoy: hoy,
      );
      expect(p.orden, isEmpty);
      expect(p.fechaLibre, isNull);
    });
    // Una deuda vieja (julio) sin interés: 600.000 con cuota de 100.000.
    Deuda vieja({DateTime? limite}) => _deuda(
      id: 7,
      nombre: 'Vieja',
      monto: 600000,
      inicio: DateTime.utc(2026, 7, 15),
      cuota: 100000,
      limite: limite,
    );

    PlanPago uno(ResumenDeuda r, {int extra = 0}) => PlanPago.simular(
      deudas: [r],
      estrategia: EstrategiaPago.avalancha,
      extraMensual: extra,
      hoy: hoy,
    );

    test('avalancha ordena por lo que cuesta cada deuda, no por la tasa '
        'escrita', () {
      // Prestaron 1.000.000 al 5 % sobre lo prestado y ya casi se paga: el
      // interés sigue siendo 50.000 al mes sobre un saldo pequeño.
      final casiPaga = ResumenDeuda.calcular(
        _deuda(
          id: 1,
          nombre: 'Casi paga',
          monto: 1000000,
          tasa: 5,
          tipoInteres: 'mensual',
          inicio: DateTime.utc(2026, 7, 11),
          cuota: 100000,
        ),
        [
          _abono(2026, 8, 11, 400000),
          _abono(2026, 9, 11, 400000),
          _abono(2026, 10, 11, 200000),
        ],
        hoy: hoy,
      );
      final banco = ResumenDeuda.calcular(
        _deuda(
          id: 2,
          nombre: 'Banco',
          monto: 1000000,
          tasa: 6,
          tipoInteres: 'mensual',
          amortizacion: 'saldo_insoluto',
          inicio: DateTime.utc(2026, 11, 11),
          cuota: 100000,
        ),
        const [],
        hoy: hoy,
      );
      expect(casiPaga.tasaMensualPct, 5);
      expect(casiPaga.costoMensualPct, greaterThan(6));
      expect(banco.costoMensualPct, closeTo(6, 1e-9));
      final p = PlanPago.simular(
        deudas: [banco, casiPaga],
        estrategia: EstrategiaPago.avalancha,
        extraMensual: 100000,
        hoy: hoy,
      );
      expect(p.orden.map((x) => x.resumen.deuda.acreedorNombre), [
        'Casi paga',
        'Banco',
      ]);
    });

    test('el pago de este mes cuenta si todavía no se hace', () {
      final r = ResumenDeuda.calcular(vieja(), const [], hoy: hoy);
      final p = uno(r);
      // 6 pagos: noviembre (este mes) a abril.
      expect(p.meses, 5);
      expect(p.fechaLibre, DateTime(2027, 4, 1));
      expect(p.orden.single.pagoEsteMes, 100000);
      expect(p.proximosPagos.esteMes, isTrue);
      // La tarjeta de la deuda da la misma fecha con el mismo pago.
      expect(r.liquidacionEstimada(hoy).fecha, p.fechaLibre);
    });

    test('registrar el pago de este mes no mueve la fecha ni lo cobra dos '
        'veces', () {
      final r = ResumenDeuda.calcular(vieja(), [
        _abono(2026, 11, 5, 100000),
      ], hoy: hoy);
      final p = uno(r);
      expect(p.fechaLibre, DateTime(2027, 4, 1));
      expect(p.orden.single.pagoEsteMes, 0);
      expect(p.orden.single.pagoMesSiguiente, 100000);
      // Lo de este mes ya está: lo próximo es diciembre.
      expect(p.proximosPagos.esteMes, isFalse);
      expect(p.proximosPagos.pagos.single.$2, 100000);
      expect(r.liquidacionEstimada(hoy).fecha, DateTime(2027, 4, 1));
    });

    test('el extra de este mes descuenta lo ya pagado de más', () {
      final sinPagar = ResumenDeuda.calcular(vieja(), const [], hoy: hoy);
      expect(uno(sinPagar, extra: 50000).orden.single.pagoEsteMes, 150000);
      // Pagó 130.000 este mes: la cuota y 30.000 del extra.
      final pagoDeMas = ResumenDeuda.calcular(vieja(), [
        _abono(2026, 11, 5, 130000),
      ], hoy: hoy);
      expect(uno(pagoDeMas, extra: 50000).orden.single.pagoEsteMes, 20000);
    });

    test('avisa si una deuda termina después de su fecha límite y dice el '
        'extra que hace falta', () {
      // Empieza hoy, sin interés: 600.000 a 100.000 → 6 meses (mayo), pero
      // la fecha límite es febrero (3 meses).
      final r = ResumenDeuda.calcular(
        _deuda(
          monto: 600000,
          inicio: DateTime.utc(2026, 11, 11),
          cuota: 100000,
          limite: DateTime.utc(2027, 2, 15),
        ),
        const [],
        hoy: hoy,
      );
      final p = uno(r);
      expect(p.orden.single.mesLimite, 3);
      expect(p.tarde, hasLength(1));
      // Este mes x + 3 meses de (100.000 + x) = 600.000 → x = 75.000.
      expect(p.paraLimites?.extra, 75000);
      expect(p.paraLimites?.fechaLibre, DateTime(2027, 2, 1));

      final conExtra = uno(r, extra: 75000);
      expect(conExtra.tarde, isEmpty);
      expect(conExtra.paraLimites, isNull);
    });

    test('el extra para llegar a tiempo también termina las que no bajan', () {
      final conLimite = ResumenDeuda.calcular(
        _deuda(
          id: 1,
          monto: 600000,
          inicio: DateTime.utc(2026, 11, 11),
          cuota: 100000,
          limite: DateTime.utc(2027, 2, 15),
        ),
        const [],
        hoy: hoy,
      );
      final crece = ResumenDeuda.calcular(
        _deuda(
          id: 2,
          monto: 10000000,
          tasa: 5,
          tipoInteres: 'mensual',
          amortizacion: 'saldo_insoluto',
          inicio: DateTime.utc(2026, 11, 11),
          cuota: 10000,
        ),
        const [],
        hoy: hoy,
      );
      final p = PlanPago.simular(
        deudas: [conLimite, crece],
        estrategia: EstrategiaPago.bolaDeNieve,
        extraMensual: 0,
        hoy: hoy,
      );
      expect(p.alcanza, isFalse);
      expect(p.tarde, isNotEmpty);
      final s = p.paraLimites!;
      final con = PlanPago.simular(
        deudas: [conLimite, crece],
        estrategia: EstrategiaPago.bolaDeNieve,
        extraMensual: s.extra,
        hoy: hoy,
      );
      expect(con.alcanza, isTrue);
      expect(con.tarde, isEmpty);
    });

    test('una fecha límite que ya pasó se marca aparte, sin sugerir extra', () {
      final r = ResumenDeuda.calcular(
        vieja(limite: DateTime.utc(2026, 10, 1)),
        const [],
        hoy: hoy,
      );
      final p = uno(r);
      expect(p.orden.single.limiteVencido, isTrue);
      expect(p.tarde, isEmpty);
      expect(p.paraLimites, isNull);
    });

    test('una deuda que no baja no esconde las fechas de las demás y se dice '
        'cuánto extra hace falta', () {
      final chica = ResumenDeuda.calcular(
        _deuda(
          id: 1,
          nombre: 'Chica',
          monto: 300000,
          inicio: DateTime.utc(2026, 11, 11),
          cuota: 10000,
        ),
        const [],
        hoy: hoy,
      );
      // 5 % sobre 1.000.000 = 50.000 de interés; las dos cuotas juntas son
      // 40.000: ni pasándole todo a esta termina.
      final crece = ResumenDeuda.calcular(
        _deuda(
          id: 2,
          nombre: 'Crece',
          monto: 1000000,
          tasa: 5,
          tipoInteres: 'mensual',
          amortizacion: 'saldo_insoluto',
          inicio: DateTime.utc(2026, 11, 11),
          cuota: 30000,
        ),
        const [],
        hoy: hoy,
      );
      PlanPago con(int extra) => PlanPago.simular(
        deudas: [chica, crece],
        estrategia: EstrategiaPago.avalancha,
        extraMensual: extra,
        hoy: hoy,
      );
      final p = con(0);
      expect(p.alcanza, isFalse);
      expect(p.sinTerminar.single.resumen.deuda.acreedorNombre, 'Crece');
      final paso = p.orden.firstWhere((x) => x.resumen.deuda.id == 1);
      expect(paso.meses, 30);
      expect(paso.fecha, DateTime(2029, 5, 1));

      final sugerido = p.paraTerminar!;
      expect(sugerido.extra % 1000, 0);
      expect(con(sugerido.extra).alcanza, isTrue);
      expect(con(sugerido.extra).fechaLibre, sugerido.fechaLibre);
      expect(con(sugerido.extra - 1000).alcanza, isFalse);
    });

    test('compara contra pagar solo los mínimos', () {
      final p = plan(EstrategiaPago.avalancha);
      expect(p.soloMinimos.termina, isTrue);
      expect(p.meses! < p.soloMinimos.meses!, isTrue);
      expect(p.interesesTotales < p.soloMinimos.interesesTotales, isTrue);
      // Sin extra igual se gana: lo que se libera pasa a la otra deuda.
      final sinExtra = plan(EstrategiaPago.avalancha, extra: 0);
      expect(sinExtra.meses! < sinExtra.soloMinimos.meses!, isTrue);
    });

    test('solo los mínimos no termina si alguna deuda no tiene cuota', () {
      final p = PlanPago.simular(
        deudas: [
          ResumenDeuda.calcular(
            _deuda(monto: 100000, inicio: DateTime.utc(2026, 11, 11)),
            const [],
            hoy: hoy,
          ),
        ],
        estrategia: EstrategiaPago.avalancha,
        extraMensual: 50000,
        hoy: hoy,
      );
      expect(p.alcanza, isTrue);
      expect(p.soloMinimos.termina, isFalse);
    });
  });

  group('cuotas sugeridas', () {
    // 36 millones: el tramo más alto de plazos (mínimo 36, rápido 12).
    ResumenDeuda sinInteres({DateTime? limite}) => ResumenDeuda.calcular(
      _deuda(
        monto: 36000000,
        inicio: DateTime.utc(2026, 11, 11),
        limite: limite,
      ),
      const [],
      hoy: hoy,
    );

    test('plazos según lo que se debe', () {
      expect(plazosSugeridos(100000), (minimo: 6, rapido: 3));
      expect(plazosSugeridos(500000), (minimo: 6, rapido: 3));
      expect(plazosSugeridos(500001), (minimo: 12, rapido: 6));
      expect(plazosSugeridos(2000000), (minimo: 12, rapido: 6));
      expect(plazosSugeridos(10000000), (minimo: 24, rapido: 12));
      expect(plazosSugeridos(10000001), (minimo: 36, rapido: 12));
    });

    test('una deuda pequeña no se estira años', () {
      // 100.000: 6 meses (17.000) o 3 meses (34.000), no 3.000 en 3 años.
      final s = ResumenDeuda.calcular(
        _deuda(monto: 100000, inicio: DateTime.utc(2026, 11, 11)),
        const [],
        hoy: hoy,
      ).sugerirCuotas(hoy)!;
      expect(s.minimo.cuota, 17000);
      expect(s.minimo.meses, 6);
      expect(s.rapido!.cuota, 34000);
      expect(s.rapido!.meses, 3);
    });

    test('sin fecha límite y deuda grande: mínimo a 3 años y rápido a 1', () {
      final s = sinInteres().sugerirCuotas(hoy)!;
      expect(s.porLimite, isFalse);
      expect(s.minimo.cuota, 1000000); // 36.000.000 / 36
      expect(s.minimo.meses, 36);
      expect(s.minimo.fecha, DateTime(2029, 11, 1));
      expect(s.rapido!.cuota, 3000000); // 36.000.000 / 12
      expect(s.rapido!.meses, 12);
    });

    test('con fecha límite antes del plazo, el mínimo llega a tiempo', () {
      // Límite en noviembre de 2028: 24 meses.
      final s = sinInteres(
        limite: DateTime.utc(2028, 11, 20),
      ).sugerirCuotas(hoy)!;
      expect(s.porLimite, isTrue);
      expect(s.minimo.cuota, 1500000); // 36.000.000 / 24
      expect(s.minimo.meses, lessThanOrEqualTo(24));
      expect(s.rapido!.cuota, 3000000);
    });

    test('con fecha límite cerca, el rápido es la mitad del plazo', () {
      // Límite en mayo: 6 meses → mínimo a 6, rápido a 3.
      final s = sinInteres(
        limite: DateTime.utc(2027, 5, 30),
      ).sugerirCuotas(hoy)!;
      expect(s.minimo.cuota, 6000000);
      expect(s.rapido!.cuota, 12000000);
    });

    test('una fecha límite que ya pasó no cuenta', () {
      final s = sinInteres(
        limite: DateTime.utc(2026, 9, 1),
      ).sugerirCuotas(hoy)!;
      expect(s.porLimite, isFalse);
      expect(s.minimo.cuota, 1000000);
    });

    group('día de pago', () {
      // Empezó el 12 de noviembre, límite 31 de enero, hoy 19 de noviembre.
      final hoy19 = DateTime(2026, 11, 19);
      ResumenDeuda cien({int? diaPago, DateTime? limite}) =>
          ResumenDeuda.calcular(
            _deuda(
              monto: 100000,
              inicio: DateTime.utc(2026, 11, 12),
              limite: limite ?? DateTime.utc(2027, 1, 31),
              diaPago: diaPago,
            ),
            const [],
            hoy: hoy19,
          );

      test('paga los 30: el 30 de noviembre ya cuenta como pago', () {
        final r = cien(diaPago: 30);
        expect(r.tienePagoEsteMes(hoy19), isTrue);
        expect(r.mesLimite(hoy19), 2);
        final s = r.sugerirCuotas(hoy19)!;
        // Tres pagos (30 nov, 30 dic, 30 ene).
        expect(s.minimo.cuota, 34000);
        expect(s.minimo.meses, 2);
        // Más rápido: dos pagos, termina en diciembre.
        expect(s.rapido!.cuota, 50000);
        expect(s.rapido!.meses, 1);
      });

      test('sin día de pago, el primer pago es el mes que viene', () {
        final r = cien();
        expect(r.tienePagoEsteMes(hoy19), isFalse);
        expect(r.sugerirCuotas(hoy19)!.minimo.cuota, 50000);
      });

      test('un día de pago anterior al inicio no cuenta este mes', () {
        expect(cien(diaPago: 5).tienePagoEsteMes(hoy19), isFalse);
        expect(cien(diaPago: 12).tienePagoEsteMes(hoy19), isFalse);
      });

      test('si paga después del día límite, ese mes ya no alcanza', () {
        // Límite el 15 de enero, paga los 30: el 30 de enero llega tarde,
        // así que quedan el 30 de noviembre y el 30 de diciembre.
        final r = cien(diaPago: 30, limite: DateTime.utc(2027, 1, 15));
        expect(r.mesLimite(hoy19), 1);
        expect(r.sugerirCuotas(hoy19)!.minimo.cuota, 50000);
        // Sin día de pago el mes del límite sí cuenta.
        expect(cien(limite: DateTime.utc(2027, 1, 15)).mesLimite(hoy19), 2);
      });

      test('un límite de este mes que ya pasó cuenta como vencido', () {
        // Hoy 19 de noviembre, límite el 10: ya pasó aunque sea este mes.
        final r = cien(diaPago: 30, limite: DateTime.utc(2026, 11, 10));
        expect(r.mesLimite(hoy19), -1);
        expect(r.sugerirCuotas(hoy19)!.porLimite, isFalse);
        // Hoy mismo todavía no ha pasado.
        expect(cien(limite: DateTime.utc(2026, 11, 19)).mesLimite(hoy19), 0);
        final p = PlanPago.simular(
          deudas: [
            ResumenDeuda.calcular(
              _deuda(
                monto: 100000,
                inicio: DateTime.utc(2026, 10, 1),
                limite: DateTime.utc(2026, 11, 10),
                cuota: 50000,
              ),
              const [],
              hoy: hoy19,
            ),
          ],
          estrategia: EstrategiaPago.avalancha,
          extraMensual: 0,
          hoy: hoy19,
        );
        expect(p.orden.single.limiteVencido, isTrue);
        expect(p.orden.single.tarde, isFalse);
        expect(p.paraLimites, isNull);
      });

      test('el 31 en un mes de 30 días cae en el último', () {
        final r = cien(diaPago: 31);
        expect(r.tienePagoEsteMes(hoy19), isTrue); // 30 de noviembre
        expect(r.fechaDePagoEn(DateTime(2027, 2, 1)), DateTime(2027, 2, 28));
      });
    });

    test('un pago menor que el interés nunca termina; el mínimo sugerido sí '
        'y es el más bajo que llega a 2 años', () {
      final r = ResumenDeuda.calcular(
        _deuda(
          monto: 5000000,
          tasa: 1,
          tipoInteres: 'mensual',
          amortizacion: 'saldo_insoluto',
          inicio: DateTime.utc(2026, 11, 11),
          cuota: 1000,
        ),
        const [],
        hoy: hoy,
      );
      expect(r.interesProximoMes, 50000);
      expect(r.liquidacionCon(1000, hoy).noBaja, isTrue);
      final minimo = r.sugerirCuotas(hoy)!.minimo.cuota;
      expect(minimo, greaterThan(50000));
      // 5.000.000: tramo de 24 meses.
      expect(r.liquidacionCon(minimo, hoy).meses!, lessThanOrEqualTo(24));
      final menos = r.liquidacionCon(minimo - 1000, hoy).meses;
      expect(menos == null || menos > 24, isTrue);
    });

    test('con interés sobre lo prestado la cuota cubre ese interés fijo', () {
      // 1.000.000 al 2 % sobre lo prestado: 20.000 de interés todos los
      // meses. En 36 meses: 36·c ≥ 1.000.000 + 36·20.000 → c = 48.000.
      // (La fórmula de cuota fija de los bancos daría 39.233, que no
      // alcanza.)
      final r = ResumenDeuda.calcular(
        _deuda(
          monto: 1000000,
          tasa: 2,
          tipoInteres: 'mensual',
          inicio: DateTime.utc(2026, 11, 11),
        ),
        const [],
        hoy: hoy,
      );
      expect(r.cuotaParaTerminarEn(36, hoy), 48000);
      expect(r.liquidacionCon(48000, hoy).meses, 36);
      expect(r.liquidacionCon(47000, hoy).meses, greaterThan(36));
    });

    test('la cuota usa lo que se debe hoy, no lo prestado', () {
      final r = ResumenDeuda.calcular(
        _deuda(monto: 600000, inicio: DateTime.utc(2026, 7, 15)),
        [_abono(2026, 8, 15, 240000)],
        hoy: hoy,
      );
      // Debe 360.000; este mes ya cuenta como el primer pago.
      expect(r.cuotaParaTerminarEn(35, hoy), 10000);
    });

    test('lo pagado este mes no se descuenta dos veces', () {
      // Debía 100.000, pagó 50.000 este mes: con una cuota de 100.000 le
      // faltan 50.000 este mes y termina este mismo mes.
      final r = ResumenDeuda.calcular(
        _deuda(monto: 100000, inicio: DateTime.utc(2026, 7, 15)),
        [_abono(2026, 11, 5, 50000)],
        hoy: hoy,
      );
      expect(r.pendienteEsteMes(hoy, 100000), 50000);
      expect(r.liquidacionCon(100000, hoy).meses, 0);
    });
  });

  group('correcciones del plan de pago (2026-11-21)', () {
    final hoy21 = DateTime(2026, 11, 21);

    ResumenDeuda res(Deuda d, [List<AbonoInteres> a = const []]) =>
        ResumenDeuda.calcular(d, a, hoy: hoy21);

    PlanPago plan(
      List<ResumenDeuda> rs, {
      EstrategiaPago e = EstrategiaPago.avalancha,
      int extra = 0,
      int diferido = 0,
      List<ResumenDeuda> terminadas = const [],
    }) => PlanPago.simular(
      deudas: rs,
      estrategia: e,
      extraMensual: extra,
      extraDiferido: diferido,
      terminadas: terminadas,
      hoy: hoy21,
    );

    group('1. cuota de una deuda terminada', () {
      final a = _deuda(
        id: 1,
        nombre: 'A',
        monto: 100000,
        inicio: DateTime.utc(2026, 9, 1),
        cuota: 100000,
      );
      final b = _deuda(
        id: 2,
        nombre: 'B',
        monto: 1000000,
        inicio: DateTime.utc(2026, 9, 1),
        cuota: 100000,
      );

      test('sin sumarla, la fecha es honesta; sumándola vuelve a abril sin '
          'contar dos veces la plata de este mes', () {
        expect(plan([res(a), res(b)]).fechaLibre, DateTime(2027, 4, 1));
        // A quedó pagada y B ya recibió su cuota de noviembre.
        final soloB = res(b, [_abono(2026, 11, 21, 100000)]);
        expect(plan([soloB]).fechaLibre, DateTime(2027, 8, 1));
        final seguir = plan([soloB], extra: 100000, diferido: 100000);
        expect(seguir.fechaLibre, DateTime(2027, 4, 1));
        expect(seguir.orden.single.pagoEsteMes, 0);
        expect(seguir.orden.single.pagoMesSiguiente, 200000);
      });
    });

    group('2. fechas límite', () {
      List<ResumenDeuda> cuatro() => [
        res(
          _deuda(
            id: 1,
            nombre: 'Amigo',
            monto: 100000,
            inicio: DateTime.utc(2026, 11, 12),
            limite: DateTime.utc(2027, 1, 31),
            diaPago: 30,
            cuota: 34000,
          ),
        ),
        res(
          _deuda(
            id: 2,
            nombre: 'Banco',
            monto: 5000000,
            tasa: 1,
            tipoInteres: 'mensual',
            amortizacion: 'saldo_insoluto',
            inicio: DateTime.utc(2026, 10, 21),
            diaPago: 15,
            cuota: 250000,
          ),
        ),
        res(
          _deuda(
            id: 3,
            nombre: 'Tarjeta',
            monto: 2000000,
            tasa: 2.5,
            tipoInteres: 'mensual',
            amortizacion: 'saldo_insoluto',
            inicio: DateTime.utc(2026, 10, 21),
            diaPago: 25,
            cuota: 120000,
          ),
        ),
        res(
          _deuda(
            id: 4,
            nombre: 'Límite',
            monto: 600000,
            inicio: DateTime.utc(2026, 11, 21),
            limite: DateTime.utc(2027, 2, 28),
            cuota: 20000,
          ),
        ),
      ];

      for (final e in EstrategiaPago.values) {
        test('${e.nombre}: el extra sugerido es el mínimo real', () {
          final rs = cuatro();
          final p = plan(rs, e: e);
          final x = p.paraLimites!.extra;
          // 4x + cuotas de Límite (60.000) + lo que libera Amigo (36.000)
          // = 600.000 → x = 126.000.
          expect(x, 126000);
          expect(plan(rs, e: e, extra: x).tarde, isEmpty);
          expect(plan(rs, e: e, extra: x - 1000).tarde, isNotEmpty);
        });
      }

      test('una fecha límite muy cerca va primero aunque no haya riesgo', () {
        final rs = cuatro();
        final holgado = plan(rs, extra: 1600000);
        expect(holgado.tarde, isEmpty);
        expect(holgado.orden.first.resumen.deuda.acreedorNombre, 'Amigo');
        expect(holgado.orden.first.priorizadaPorLimite, isTrue);
        // Lo que sobra después de esa fecha sigue yendo a la Tarjeta.
        final tarjeta = holgado.orden.firstWhere(
          (p) => p.resumen.deuda.acreedorNombre == 'Tarjeta',
        );
        expect(tarjeta.pagoEsteMes, greaterThan(120000));
      });

      test('fuerza bruta: ningún reparto logra las fechas con menos extra', () {
        final rnd = math.Random(11);
        var revisados = 0;
        for (var c = 0; c < 120; c++) {
          final n = 2 + rnd.nextInt(2);
          final rs = [
            for (var i = 0; i < n; i++)
              res(
                _deuda(
                  id: i + 1,
                  monto: (4 + rnd.nextInt(16)) * 1000,
                  tasa: c.isOdd ? [0.0, 2.0, 5.0, 10.0][rnd.nextInt(4)] : 0,
                  tipoInteres: c.isOdd ? 'mensual' : 'ninguno',
                  amortizacion: 'saldo_insoluto',
                  inicio: rnd.nextBool()
                      ? DateTime.utc(2026, 11, 21)
                      : DateTime.utc(2026, 9, 1),
                  limite: rnd.nextDouble() < .7
                      ? DateTime.utc(2026, 12 + rnd.nextInt(3), 28)
                      : null,
                  cuota: (2 + rnd.nextInt(3)) * 1000,
                ),
              ),
          ];
          for (final e in EstrategiaPago.values) {
            final p = plan(rs, e: e);
            final s = p.paraLimites;
            if (p.tarde.isEmpty || s == null) continue;
            revisados++;
            expect(plan(rs, e: e, extra: s.extra).tarde, isEmpty);
            if (s.extra >= 1000) {
              expect(
                _algunRepartoCumple(rs, s.extra - 1000, hoy21),
                isFalse,
                reason: 'caso $c (${e.name}): extra ${s.extra}',
              );
            }
          }
        }
        expect(revisados, greaterThan(50));
      });
    });

    group('3. "N meses" son N pagos', () {
      test('deuda de meses anteriores: 12 meses = 12 pagos', () {
        final r = res(_deuda(monto: 1200000, inicio: DateTime.utc(2026, 8, 1)));
        final c = r.cuotaParaPagos(12, hoy21)!;
        expect(c.cuota, 100000);
        expect(c.porLimite, isFalse);
        expect(r.liquidacionCon(c.cuota, hoy21).meses, 11);
      });

      test('deuda nueva: el primer pago es el mes que viene', () {
        final r = res(
          _deuda(monto: 1200000, inicio: DateTime.utc(2026, 11, 21)),
        );
        expect(r.cuotaParaPagos(12, hoy21)!.cuota, 100000);
      });

      test('si este mes ya pagó, cuenta desde el siguiente', () {
        final r = res(
          _deuda(monto: 1300000, inicio: DateTime.utc(2026, 8, 1)),
          [_abono(2026, 11, 5, 100000)],
        );
        expect(r.cuotaParaPagos(12, hoy21)!.cuota, 100000);
      });

      test('con fecha límite más cercana manda la fecha límite', () {
        final r = res(
          _deuda(
            monto: 1200000,
            inicio: DateTime.utc(2026, 8, 1),
            limite: DateTime.utc(2027, 2, 28),
          ),
        );
        final c = r.cuotaParaPagos(12, hoy21)!;
        expect(c.porLimite, isTrue);
        expect(c.cuota, 300000); // nov, dic, ene, feb
      });

      test('las sugerencias también son esa cantidad de pagos', () {
        final s = res(
          _deuda(monto: 1200000, inicio: DateTime.utc(2026, 8, 1)),
        ).sugerirCuotas(hoy21)!;
        expect(s.minimo.cuota, 100000); // 12 pagos
        expect(s.minimo.meses, 11);
        expect(s.rapido!.cuota, 200000); // 6 pagos
        expect(s.rapido!.meses, 5);
      });
    });

    group('4. último pago', () {
      test('abonó parte de la última cuota: el plan dice lo que falta', () {
        final r = res(
          _deuda(
            monto: 100000,
            inicio: DateTime.utc(2026, 8, 1),
            cuota: 100000,
          ),
          [_abono(2026, 11, 5, 50000)],
        );
        expect(r.saldo, 50000);
        expect(r.pendienteCuotaEsteMes(hoy21), 50000);
        final p = plan([r]);
        expect(p.orden.single.pagoEsteMes, 50000);
        expect(p.proximosPagos.esteMes, isTrue);
        expect(p.meses, 0);
        expect(r.liquidacionCon(100000, hoy21).meses, p.meses);
      });

      test('cuota mayor que el saldo con interés: plan y tarjeta iguales', () {
        final r = res(
          _deuda(
            monto: 100000,
            tasa: 5,
            tipoInteres: 'mensual',
            amortizacion: 'saldo_insoluto',
            inicio: DateTime.utc(2026, 11, 21),
            cuota: 200000,
          ),
        );
        expect(r.liquidacionCon(200000, hoy21).meses, 1);
        final p = plan([r]);
        expect(p.meses, 1);
        expect(p.presupuestoMensual, 105000);
      });
    });

    group('5. límite este mes antes del día de pago', () {
      final r = res(
        _deuda(
          monto: 300000,
          inicio: DateTime.utc(2026, 8, 1),
          limite: DateTime.utc(2026, 11, 25),
          diaPago: 30,
          cuota: 300000,
        ),
      );

      test('sigue a tiempo, pero avisa que hay que pagar antes', () {
        expect(r.mesLimite(hoy21), 0);
        expect(r.pagarAntesDe(hoy21), DateTime(2026, 11, 25));
        expect(r.vencimiento(hoy21)!.fecha, DateTime(2026, 11, 25));
        final p = plan([r]);
        expect(p.orden.single.limiteVencido, isFalse);
        expect(p.orden.single.tarde, isFalse);
      });

      test('si el día de pago llega a tiempo no hay aviso', () {
        final bien = res(
          _deuda(
            monto: 300000,
            inicio: DateTime.utc(2026, 8, 1),
            limite: DateTime.utc(2026, 11, 28),
            diaPago: 25,
          ),
        );
        expect(bien.pagarAntesDe(hoy21), isNull);
      });

      test('empezó este mes y el día de pago del mes siguiente cae después '
          'del límite: no cuenta un mes sin pago', () {
        final x = res(
          _deuda(
            monto: 100000,
            inicio: DateTime.utc(2026, 11, 15),
            limite: DateTime.utc(2026, 12, 5),
            diaPago: 10,
          ),
        );
        expect(x.primerMesDePago(hoy21), 1);
        expect(x.mesLimite(hoy21), 1);
        expect(x.pagarAntesDe(hoy21), DateTime(2026, 12, 5));
      });
    });

    test('6. creada hoy con límite este mes y sin día de pago: se puede '
        'pagar este mes', () {
      final r = res(
        _deuda(
          monto: 100000,
          inicio: DateTime.utc(2026, 11, 21),
          limite: DateTime.utc(2026, 11, 28),
        ),
      );
      expect(r.tienePagoEsteMes(hoy21), isTrue);
      final s = r.sugerirCuotas(hoy21)!;
      expect(s.porLimite, isTrue);
      expect(s.minimo.cuota, 100000);
      expect(s.minimo.meses, 0);
      expect(s.minimo.fecha, DateTime(2026, 11, 1));
    });

    group('7. deuda que empieza en el futuro', () {
      final r = res(
        _deuda(
          monto: 300000,
          tasa: 2,
          tipoInteres: 'mensual',
          amortizacion: 'saldo_insoluto',
          inicio: DateTime.utc(2027, 1, 15),
          cuota: 100000,
          diaPago: 20,
        ),
      );

      test('no cobra cuota ni interés antes de empezar', () {
        expect(r.primerMesDePago(hoy21), 2);
        expect(r.tienePagoEsteMes(hoy21), isFalse);
        expect(r.pendienteCuotaEsteMes(hoy21), 0);
        expect(r.interesDelMes(1, 300000), 0);
        // Enero: corre del 15 (inicio) al 20 (día de pago).
        expect(r.interesDelMes(2, 300000), closeTo(1000, 1e-6));
        expect(r.interesDelMes(3, 200000), closeTo(4000, 1e-6));
        expect(r.proximoPago(hoy21), DateTime(2027, 1, 20));
        final p = plan([r], extra: 50000);
        expect(p.orden.single.pagoEsteMes, 0);
        expect(p.orden.single.pagoMesSiguiente, 0);
      });

      test('plan y tarjeta coinciden', () {
        final tarjeta = r.liquidacionCon(100000, hoy21);
        final p = plan([r]);
        expect(p.meses, tarjeta.meses);
        expect(p.fechaLibre, tarjeta.fecha);
      });

      test('el extra no se le adelanta a otra deuda antes de tiempo ni se '
          'pierde', () {
        final vieja = res(
          _deuda(
            id: 9,
            monto: 1000000,
            inicio: DateTime.utc(2026, 8, 1),
            cuota: 100000,
          ),
        );
        final p = plan([r, vieja], extra: 50000);
        final pasoFutura = p.orden.firstWhere((x) => x.resumen.deuda.id == 1);
        final pasoVieja = p.orden.firstWhere((x) => x.resumen.deuda.id == 9);
        expect(pasoFutura.pagoEsteMes, 0);
        expect(pasoVieja.pagoEsteMes, 150000);
      });
    });

    test('invariante: pagar lo del plan este mes no mueve la fecha de fin', () {
      final rnd = math.Random(23);
      var revisados = 0;
      for (var c = 0; c < 300; c++) {
        final n = 1 + rnd.nextInt(4);
        final deudas = [
          for (var i = 0; i < n; i++)
            _deuda(
              id: i + 1,
              monto: (1 + rnd.nextInt(40)) * 50000,
              tasa: [0.0, 1.0, 2.5, 5.0][rnd.nextInt(4)],
              tipoInteres: 'mensual',
              amortizacion: rnd.nextBool()
                  ? 'saldo_insoluto'
                  : 'saldo_original',
              inicio: [
                DateTime.utc(2026, 8, 3),
                DateTime.utc(2026, 11, 12),
                DateTime.utc(2026, 11, 21),
                DateTime.utc(2027, 1, 15),
              ][rnd.nextInt(4)],
              limite: rnd.nextBool()
                  ? DateTime.utc(2026, 12 + rnd.nextInt(8), 20)
                  : null,
              diaPago: rnd.nextBool() ? 1 + rnd.nextInt(28) : null,
              cuota: (1 + rnd.nextInt(8)) * 50000,
            ),
        ];
        final extra = rnd.nextInt(5) * 50000;
        for (final e in EstrategiaPago.values) {
          final antes = plan(
            [for (final d in deudas) res(d)],
            e: e,
            extra: extra,
          );
          if (!antes.alcanza) continue;
          var extraDespues = extra;
          var diferido = 0;
          final despues = <ResumenDeuda>[];
          final terminadas = <ResumenDeuda>[];
          for (final p in antes.orden) {
            final d = p.resumen.deuda;
            final abonos = [
              if (p.pagoEsteMes > 0) _abono(2026, 11, 21, p.pagoEsteMes),
            ];
            final r = res(d, abonos);
            if (r.saldo <= 1) {
              // Caso 1: al terminarla, su cuota se suma con el aviso.
              extraDespues += d.cuotaMensual!;
              diferido += d.cuotaMensual!;
              terminadas.add(r);
            } else {
              despues.add(r);
            }
          }
          if (despues.isEmpty) continue;
          revisados++;
          final ahora = plan(
            despues,
            e: e,
            extra: extraDespues,
            diferido: diferido,
            terminadas: terminadas,
          );
          // Sin día de pago, exacta. Con día de pago el plan supone que se
          // paga ese día: pagar antes ahorra interés y solo puede adelantar.
          if (deudas.every((d) => d.diaPago == null)) {
            expect(
              ahora.fechaLibre,
              antes.fechaLibre,
              reason: 'caso $c (${e.name})',
            );
          } else {
            expect(
              ahora.fechaLibre!.isAfter(antes.fechaLibre!),
              isFalse,
              reason: 'caso $c (${e.name})',
            );
          }
        }
      }
      expect(revisados, greaterThan(100));
    });
  });

  group('estrategia recomendada', () {
    ResumenDeuda d(int id, int monto, double tasa, int cuota) =>
        ResumenDeuda.calcular(
          _deuda(
            id: id,
            nombre: 'D$id',
            monto: monto,
            tasa: tasa,
            tipoInteres: tasa > 0 ? 'mensual' : 'ninguno',
            amortizacion: 'saldo_insoluto',
            inicio: DateTime.utc(2026, 11, 11),
            cuota: cuota,
          ),
          const [],
          hoy: hoy,
        );

    test('si una cobra bastante menos intereses, esa', () {
      final e = PlanPago.elegir(
        deudas: [d(1, 2000000, 5, 120000), d(2, 100000, 0, 10000)],
        elegida: null,
        extraMensual: 50000,
        hoy: hoy,
      );
      expect(e.casiIgual, isFalse);
      expect(e.recomendada, EstrategiaPago.avalancha);
      expect(e.automatica, isTrue);
      expect(e.plan.estrategia, EstrategiaPago.avalancha);
      expect(e.plan.interesesTotales < e.otra.interesesTotales, isTrue);
    });

    test('si cuestan casi lo mismo, bola de nieve', () {
      final e = PlanPago.elegir(
        deudas: [d(1, 500000, 0, 50000), d(2, 100000, 0, 10000)],
        elegida: null,
        extraMensual: 0,
        hoy: hoy,
      );
      expect(e.casiIgual, isTrue);
      expect(e.recomendada, EstrategiaPago.bolaDeNieve);
    });

    test('lo que elige el usuario manda', () {
      final e = PlanPago.elegir(
        deudas: [d(1, 2000000, 5, 120000), d(2, 100000, 0, 10000)],
        elegida: EstrategiaPago.bolaDeNieve,
        extraMensual: 50000,
        hoy: hoy,
      );
      expect(e.automatica, isFalse);
      expect(e.plan.estrategia, EstrategiaPago.bolaDeNieve);
      expect(e.recomendada, EstrategiaPago.avalancha);
    });
  });
}
