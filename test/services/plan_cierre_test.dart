import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/deudas_calculos.dart';
import 'package:valtiq/services/interes_calculator.dart';
import 'package:valtiq/utils/currency_input.dart';

Deuda _deuda(
  int id,
  int monto,
  double tasa,
  DateTime inicio,
  String modalidad,
  String amortizacion,
  int cuota, {
  int? dia,
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

String _teclear(String texto) {
  final f = CopInputFormatter();
  var v = TextEditingValue.empty;
  for (final letra in texto.split('')) {
    final t = v.text + letra;
    v = f.formatEditUpdate(
      v,
      TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      ),
    );
  }
  return v.text;
}

void main() {
  test('Avalancha con 5 deudas no pierde una fecha límite cumplible', () {
    final hoy = DateTime(2026, 11, 22, 15);
    final ds = [
      _deuda(
        0,
        800000,
        1.9,
        DateTime.utc(2027, 1, 19),
        'simple',
        'saldo_insoluto',
        80000,
        limite: DateTime.utc(2027, 3, 27),
      ),
      _deuda(
        1,
        5000000,
        8,
        DateTime.utc(2026, 9, 13),
        'simple',
        'saldo_original',
        1250000,
      ),
      _deuda(
        2,
        800000,
        3,
        DateTime.utc(2025, 10, 5),
        'compuesto',
        'saldo_original',
        56000,
        dia: 21,
      ),
      _deuda(
        3,
        5000000,
        3,
        DateTime.utc(2026, 2, 11),
        'simple',
        'saldo_insoluto',
        750000,
        dia: 1,
      ),
      _deuda(
        4,
        300000,
        0,
        DateTime.utc(2026, 9, 24),
        'simple',
        'saldo_insoluto',
        21000,
        dia: 5,
      ),
    ];
    final plan = PlanPago.simular(
      deudas: [
        for (final d in ds)
          ResumenDeuda.calcular(d, const <AbonoInteres>[], hoy: hoy),
      ],
      estrategia: EstrategiaPago.avalancha,
      extraMensual: 200000,
      hoy: hoy,
    );
    final paso = plan.orden.firstWhere((p) => p.resumen.deuda.id == 0);
    expect(paso.tarde, isFalse);
  });

  test('miles mal puestos no se leen como un monto', () {
    for (final s in ['1,500000', '1,50000', '1500,5000', '1.234,5678']) {
      expect(parseCOP(s), isNull, reason: s);
    }
    expect(parseCOP('1500,50'), 1500);
    expect(parseCOP('1500,000'), 1500);
    expect(parseCOP('1,500,000'), 1500000);
  });

  test('al teclear solo cuentan los números', () {
    expect(_teclear('1,500000'), '1.500.000');
    expect(_teclear('1,50,000'), '150.000');
    expect(_teclear('1,500,000'), '1.500.000');
  });

  test('la deuda vencida va primero y las cuotas no cambian', () {
    final hoy = DateTime(2026, 11, 23, 15);
    final rs = [
      for (final d in [
        _deuda(
          1,
          2000000,
          5,
          DateTime.utc(2026, 10, 1),
          'simple',
          'saldo_insoluto',
          150000,
        ),
        _deuda(
          2,
          300000,
          0,
          DateTime.utc(2026, 10, 1),
          'simple',
          'saldo_original',
          20000,
          limite: DateTime.utc(2026, 11, 10),
        ),
        _deuda(
          3,
          300000,
          0,
          DateTime.utc(2026, 10, 1),
          'simple',
          'saldo_original',
          20000,
          limite: DateTime.utc(2027, 1, 20),
        ),
      ])
        ResumenDeuda.calcular(d, const <AbonoInteres>[], hoy: hoy),
    ];
    final plan = PlanPago.simular(
      deudas: rs,
      estrategia: EstrategiaPago.avalancha,
      extraMensual: 0,
      hoy: hoy,
    );
    expect([for (final p in plan.orden) p.resumen.deuda.id], [2, 3, 1]);
    expect(plan.presupuestoMensual, 190000);
    final vencida = plan.orden.first;
    expect(vencida.pagoEsteMes, 20000);
  });

  test('Automática prefiere la que cumple más fechas límite', () {
    final hoy = DateTime(2026, 11, 23, 15);
    final r = ResumenDeuda.calcular(
      _deuda(
        1,
        300000,
        0,
        DateTime.utc(2026, 10, 1),
        'simple',
        'saldo_original',
        20000,
      ),
      const <AbonoInteres>[],
      hoy: hoy,
    );
    PlanPago plan(EstrategiaPago e, int intereses, int fin) => PlanPago(
      estrategia: e,
      presupuestoMensual: 20000,
      meses: 10,
      fechaLibre: DateTime(2027, 9),
      interesesTotales: intereses,
      orden: [
        PasoPlan(
          resumen: r,
          meses: fin,
          fecha: DateTime(2027, 1 + fin),
          mesLimite: 5,
        ),
      ],
      soloMinimos: const SoloMinimos(meses: 10, interesesTotales: 0),
    );
    expect(
      PlanPago.recomendar(
        plan(EstrategiaPago.avalancha, 900000, 8),
        plan(EstrategiaPago.bolaDeNieve, 920000, 4),
      ),
      EstrategiaPago.bolaDeNieve,
    );
  });

  test('pegar con cero inicial en medio del monto conserva el cero', () {
    final v = CopInputFormatter().formatEditUpdate(
      const TextEditingValue(
        text: '1.000',
        selection: TextSelection.collapsed(offset: 1),
      ),
      const TextEditingValue(
        text: '105.000',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    expect(v.text, '105.000');
  });
}
