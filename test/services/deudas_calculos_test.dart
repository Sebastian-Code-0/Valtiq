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
      // 1.700.000 a 100.000 → 17 meses; 1.100.000 a 300.000 → 4 meses.
      expect(cumplido.liquidacionEstimada(hoy).meses, 17);
      expect(generoso.liquidacionEstimada(hoy).meses, 4);
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
      expect(r.liquidacionEstimada(hoy).meses, 37); // 1.850.000 / 50.000
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
      expect(r.liquidacionEstimada(hoy).meses, 6);
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
      // Se paga el presupuesto completo todos los meses menos el último.
      final pagadoMaximo = p.presupuestoMensual * p.meses!;
      final pagadoMinimo = p.presupuestoMensual * (p.meses! - 1);
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
  });
}
