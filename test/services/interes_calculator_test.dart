import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/services/interes_calculator.dart';

void main() {
  group('InteresCalculator', () {
    group('calcularInteresSimple', () {
      test('1.000.000 al 2% mensual, 1 mes exacto → 20.000', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 1, 1),
          fechaFin: DateTime(2026, 2, 1),
        );
        expect(interes, closeTo(20000.0, 0.01));
      });

      test('tasa 0% → retorna 0 independientemente del período', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 500000,
          tasaInteres: 0,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 1, 1),
          fechaFin: DateTime(2026, 6, 1),
        );
        expect(interes, 0.0);
      });

      test('tipoInteres "ninguno" → retorna 0', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 500000,
          tasaInteres: 5,
          tipoInteres: 'ninguno',
          fechaInicio: DateTime(2026, 1, 1),
          fechaFin: DateTime(2026, 6, 1),
        );
        expect(interes, 0.0);
      });

      test('fecha fin igual a fecha inicio → 0 días, sin interés', () {
        final fecha = DateTime(2026, 3, 15);
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: fecha,
          fechaFin: fecha,
        );
        expect(interes, 0.0);
      });

      test('fecha fin anterior a fecha inicio → retorna 0 sin crash', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 3, 1),
          fechaFin: DateTime(2026, 1, 1),
        );
        expect(interes, 0.0);
      });

      test('cruce de año nov→feb = 3 meses → 60.000', () {
        // nov 2025 + 1 = dic, + 2 = ene 2026, + 3 = feb 2026 (fecha exacta) → 3 meses
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2025, 11, 1),
          fechaFin: DateTime(2026, 2, 1),
        );
        expect(interes, closeTo(60000.0, 0.01));
      });

      test('tasa anual 24% equivale a tasa mensual 2%', () {
        final interesAnual = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 24,
          tipoInteres: 'anual',
          fechaInicio: DateTime(2026, 1, 1),
          fechaFin: DateTime(2026, 2, 1),
        );
        final interesMensual = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 1, 1),
          fechaFin: DateTime(2026, 2, 1),
        );
        expect(interesAnual, closeTo(interesMensual, 0.01));
      });

      test('2 meses exactos → 40.000', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 1, 1),
          fechaFin: DateTime(2026, 3, 1),
        );
        expect(interes, closeTo(40000.0, 0.01));
      });

      test('1 mes + 15 días → 14 días parciales exactos (no 15)', () {
        // Jan 1 → Feb 16: 1 mes completo + (Feb16−Feb1) = 15 días ELAPSED.
        // diasDiferencia = 15, sin +1 → 15/30 = 0.5 meses parciales.
        // Interés = 1M × 0.02 × 1.5 = 30.000 exacto.
        // Con el bug anterior daba 1 + 16/30 = 1.5333 meses → $30.667.
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 1, 1),
          fechaFin: DateTime(2026, 2, 16),
        );
        expect(interes, closeTo(30000.0, 0.01));
      });

      test('2 meses + 29 días no se redondea a 3 meses', () {
        // Jan 1 → Mar 30: 2 meses completos + 29 días (Mar30−Mar1).
        // 29/30 = 0.967, no llega a 1 mes más.
        // Con el bug anterior: 29+1=30 días → se convertía en 3 meses exactos.
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 1, 1),
          fechaFin: DateTime(2026, 3, 30),
        );
        // 2 + 29/30 meses × 2% × 1M = (2.9667) × 20000 = 59.333
        expect(interes, closeTo(59333.33, 1.0));
        expect(interes, lessThan(60000.0)); // debe ser MENOR que 3 meses
      });
    });

    group('calcularInteresCompuesto', () {
      test('1 mes → mismo resultado que interés simple', () {
        final simple = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 1, 1),
          fechaFin: DateTime(2026, 2, 1),
        );
        final compuesto = InteresCalculator.calcularInteresCompuesto(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 1, 1),
          fechaFin: DateTime(2026, 2, 1),
        );
        expect(compuesto, closeTo(simple, 0.01));
      });

      test('2 meses: compuesto > simple (efecto capitalización)', () {
        final simple = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 1, 1),
          fechaFin: DateTime(2026, 3, 1),
        );
        final compuesto = InteresCalculator.calcularInteresCompuesto(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 1, 1),
          fechaFin: DateTime(2026, 3, 1),
        );
        // simple: 1M * 0.02 * 2 = 40.000
        // compuesto: 1M * (1.02^2 - 1) = 1M * 0.0404 = 40.400
        expect(simple, closeTo(40000.0, 0.01));
        expect(compuesto, closeTo(40400.0, 1.0));
        expect(compuesto, greaterThan(simple));
      });

      test('tasa 0 → 0', () {
        final interes = InteresCalculator.calcularInteresCompuesto(
          monto: 1000000,
          tasaInteres: 0,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 1, 1),
          fechaFin: DateTime(2026, 3, 1),
        );
        expect(interes, 0.0);
      });

      test('tipoInteres "ninguno" → 0', () {
        final interes = InteresCalculator.calcularInteresCompuesto(
          monto: 1000000,
          tasaInteres: 10,
          tipoInteres: 'ninguno',
          fechaInicio: DateTime(2026, 1, 1),
          fechaFin: DateTime(2026, 3, 1),
        );
        expect(interes, 0.0);
      });
    });

    group('calcularDeudaTotal', () {
      test('sin interés y sin abonos → deuda igual al monto original', () {
        final total = InteresCalculator.calcularDeudaTotal(
          montoPrestado: 1000000,
          tasaInteres: 0,
          tipoInteres: 'ninguno',
          modalidadCalculo: 'simple',
          fechaPrestamo: DateTime(2026, 1, 1),
          totalAbonado: 0,
        );
        expect(total, 1000000.0);
      });

      test('abonado excede la deuda total → retorna 0 (no negativo)', () {
        final total = InteresCalculator.calcularDeudaTotal(
          montoPrestado: 1000000,
          tasaInteres: 0,
          tipoInteres: 'ninguno',
          modalidadCalculo: 'simple',
          fechaPrestamo: DateTime(2026, 1, 1),
          totalAbonado: 9999999,
        );
        expect(total, 0.0);
      });
    });

    group('resumenPrestamo', () {
      test('sin interés → todas las claves presentes y valores coherentes', () {
        final r = InteresCalculator.resumenPrestamo(
          montoPrestado: 1000000,
          tasaInteres: 0,
          tipoInteres: 'ninguno',
          modalidadCalculo: 'simple',
          fechaPrestamo: DateTime(2026, 1, 1),
          totalAbonado: 200000,
        );
        expect(r['montoPrestado'], 1000000.0);
        expect(r['interesAcumulado'], 0.0);
        expect(r['totalConInteres'], 1000000.0);
        expect(r['totalAbonado'], 200000.0);
        expect(r['saldoPendiente'], 800000.0);
        expect(r['gananciaInteres'], 0.0);
      });

      test('saldo no puede ser negativo', () {
        final r = InteresCalculator.resumenPrestamo(
          montoPrestado: 1000000,
          tasaInteres: 0,
          tipoInteres: 'ninguno',
          modalidadCalculo: 'simple',
          fechaPrestamo: DateTime(2026, 1, 1),
          totalAbonado: 9999999,
        );
        expect(r['saldoPendiente'], 0.0);
      });
    });

    group('convención bancaria días 29-31', () {
      test('31 ene → 28 feb = 1 mes exacto (último día de feb)', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 1, 31),
          fechaFin: DateTime(2026, 2, 28),
        );
        // _aniversario(2026, 2, 31) → Feb 28 (ultimoDia=28).
        // Feb 28 isAfter(Feb 28)? No → mesesCompletos=1.
        // ultimoCumplimiento=Feb 28, diasDif=0 → 1.0 meses.
        expect(interes, closeTo(20000.0, 0.01));
      });

      test('31 ene → 3 mar = 1 mes + 3 días parciales (no 2 meses)', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 1, 31),
          fechaFin: DateTime(2026, 3, 3),
        );
        // Aniversario feb = Feb 28. ultimoCumplimiento = Feb 28.
        // diasDif = Mar 3 − Feb 28 = 3 días → 1 + 3/30 = 1.1 meses.
        // 1M × 2% × 1.1 = 22.000
        expect(interes, closeTo(22000.0, 0.01));
      });

      test('31 ene → 30 abr = 3 meses exactos (aniversario abr = 30 abr)', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 1, 31),
          fechaFin: DateTime(2026, 4, 30),
        );
        // Aniversarios: feb→28feb, mar→31mar, _aniversario(2026,4,31)→Apr 30
        // (ultimoDia de abril=30). Apr 30 isAfter(Apr 30)? No → mesesCompletos=3.
        // diasDif=0 → 3.0 meses exactos.
        expect(interes, closeTo(60000.0, 0.01));
      });

      test('29 ene → 28 feb (año no bisiesto) = 1 mes exacto', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 1, 29),
          fechaFin: DateTime(2026, 2, 28),
        );
        // _aniversario(2026, 2, 29): ultimoDia=28 → Feb 28.
        // Feb 28 isAfter(Feb 28)? No → mesesCompletos=1. diasDif=0.
        expect(interes, closeTo(20000.0, 0.01));
      });

      test('30 ene → 28 feb (año no bisiesto) = 1 mes exacto', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2026, 1, 30),
          fechaFin: DateTime(2026, 2, 28),
        );
        // _aniversario(2026, 2, 30): ultimoDia=28 → Feb 28. diasDif=0.
        expect(interes, closeTo(20000.0, 0.01));
      });

      test('cruce de año: 31 oct → 28 feb = 4 meses exactos', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime(2025, 10, 31),
          fechaFin: DateTime(2026, 2, 28),
        );
        // Aniversarios: nov→30nov, dic→31dic, ene→31ene, _aniversario(2025,14,31)
        // = feb2026 con ultimoDia=28 → Feb 28. Feb 28 isAfter(Feb 28)? No → m=4.
        // ultimoCumplimiento=Feb 28, diasDif=0 → 4.0 meses.
        expect(interes, closeTo(80000.0, 0.01));
      });
    });
  });
}
