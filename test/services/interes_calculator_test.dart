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
  });
}
