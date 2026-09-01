import 'dart:math' as math;

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
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 2, 1),
        );
        expect(interes, closeTo(20000.0, 0.01));
      });

      test('tasa 0% → retorna 0 independientemente del período', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 500000,
          tasaInteres: 0,
          tipoInteres: 'mensual',
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 6, 1),
        );
        expect(interes, 0.0);
      });

      test('tipoInteres "ninguno" → retorna 0', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 500000,
          tasaInteres: 5,
          tipoInteres: 'ninguno',
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 6, 1),
        );
        expect(interes, 0.0);
      });

      test('fecha fin igual a fecha inicio → 0 días, sin interés', () {
        final fecha = DateTime.utc(2026, 3, 15);
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
          fechaInicio: DateTime.utc(2026, 3, 1),
          fechaFin: DateTime.utc(2026, 1, 1),
        );
        expect(interes, 0.0);
      });

      test('cruce de año nov→feb = 3 meses → 60.000', () {
        // nov 2025 + 1 = dic, + 2 = ene 2026, + 3 = feb 2026 (fecha exacta) → 3 meses
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime.utc(2025, 11, 1),
          fechaFin: DateTime.utc(2026, 2, 1),
        );
        expect(interes, closeTo(60000.0, 0.01));
      });

      test('tasa anual 24% equivale a tasa mensual 2%', () {
        final interesAnual = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 24,
          tipoInteres: 'anual',
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 2, 1),
        );
        final interesMensual = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 2, 1),
        );
        expect(interesAnual, closeTo(interesMensual, 0.01));
      });

      test('2 meses exactos → 40.000', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 3, 1),
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
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 2, 16),
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
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 3, 30),
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
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 2, 1),
        );
        final compuesto = InteresCalculator.calcularInteresCompuesto(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 2, 1),
        );
        expect(compuesto, closeTo(simple, 0.01));
      });

      test('2 meses: compuesto > simple (efecto capitalización)', () {
        final simple = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 3, 1),
        );
        final compuesto = InteresCalculator.calcularInteresCompuesto(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 3, 1),
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
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 3, 1),
        );
        expect(interes, 0.0);
      });

      test('tipoInteres "ninguno" → 0', () {
        final interes = InteresCalculator.calcularInteresCompuesto(
          monto: 1000000,
          tasaInteres: 10,
          tipoInteres: 'ninguno',
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 3, 1),
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
          fechaPrestamo: DateTime.utc(2026, 1, 1),
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
          fechaPrestamo: DateTime.utc(2026, 1, 1),
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
          fechaPrestamo: DateTime.utc(2026, 1, 1),
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
          fechaPrestamo: DateTime.utc(2026, 1, 1),
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
          fechaInicio: DateTime.utc(2026, 1, 31),
          fechaFin: DateTime.utc(2026, 2, 28),
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
          fechaInicio: DateTime.utc(2026, 1, 31),
          fechaFin: DateTime.utc(2026, 3, 3),
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
          fechaInicio: DateTime.utc(2026, 1, 31),
          fechaFin: DateTime.utc(2026, 4, 30),
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
          fechaInicio: DateTime.utc(2026, 1, 29),
          fechaFin: DateTime.utc(2026, 2, 28),
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
          fechaInicio: DateTime.utc(2026, 1, 30),
          fechaFin: DateTime.utc(2026, 2, 28),
        );
        // _aniversario(2026, 2, 30): ultimoDia=28 → Feb 28. diasDif=0.
        expect(interes, closeTo(20000.0, 0.01));
      });

      test('cruce de año: 31 oct → 28 feb = 4 meses exactos', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime.utc(2025, 10, 31),
          fechaFin: DateTime.utc(2026, 2, 28),
        );
        // Aniversarios: nov→30nov, dic→31dic, ene→31ene, _aniversario(2025,14,31)
        // = feb2026 con ultimoDia=28 → Feb 28. Feb 28 isAfter(Feb 28)? No → m=4.
        // ultimoCumplimiento=Feb 28, diasDif=0 → 4.0 meses.
        expect(interes, closeTo(80000.0, 0.01));
      });

      test('29 feb (año bisiesto) → 29 mar = 1 mes exacto, sin clip', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime.utc(2028, 2, 29),
          fechaFin: DateTime.utc(2028, 3, 29),
        );
        // 2028 es bisiesto. _aniversario(2028,3,29): marzo tiene 31 días,
        // día 29 existe → Mar 29 sin recorte. diasDif=0 → 1.0 mes exacto.
        expect(interes, closeTo(20000.0, 0.01));
      });

      test(
        '29 feb (bisiesto) → 28 feb del año siguiente (no bisiesto) = '
        '12 meses exactos (el aniversario de feb se recorta a 28)',
        () {
          final interes = InteresCalculator.calcularInteresSimple(
            monto: 1000000,
            tasaInteres: 2,
            tipoInteres: 'mensual',
            fechaInicio: DateTime.utc(2028, 2, 29),
            fechaFin: DateTime.utc(2029, 2, 28),
          );
          // 2029 no es bisiesto, así que el 12º aniversario (_aniversario con
          // día 29 y mes de destino = feb 2029) se recorta a Feb 28 —
          // exactamente la fecha de fin, sin días parciales. El punto de
          // esta prueba es fijar que un préstamo que arranca un 29 de
          // febrero también cae en meses exactos limpios (no arrastra un
          // día "fantasma" cada año al cruzar a un año no bisiesto).
          expect(interes, closeTo(240000.0, 0.01));
        },
      );

      test('31 ene → 1 mar = 1 mes + 1 día (justo tras el aniversario recortado)', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime.utc(2026, 1, 31),
          fechaFin: DateTime.utc(2026, 3, 1),
        );
        // Aniversario feb = Feb 28 (recorte). diasDif = Mar1 − Feb28 = 1 día
        // → 1 + 1/30 meses. 1M × 2% × 1.0333... = 20.666,67 → redondea a 20.667.
        expect(interes, 20667);
      });
    });

    group('fracciones de día mínimas', () {
      test('exactamente 1 día → fracción 1/30 de mes, sin redondear a 0', () {
        final interes = InteresCalculator.calcularInteresSimple(
          monto: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          fechaInicio: DateTime.utc(2026, 3, 15),
          fechaFin: DateTime.utc(2026, 3, 16),
        );
        // 1M × 2% × (1/30) = 666,67 → redondea a 667.
        expect(interes, 667);
      });
    });

    group('saldo_insoluto (amortización bancaria real)', () {
      test(
        'sin abonos → da exactamente lo mismo que saldo_original (mismo '
        'monto, misma fecha, mismo período)',
        () {
          final base = InteresCalculator.resumenPrestamo(
            montoPrestado: 1000000,
            tasaInteres: 2,
            tipoInteres: 'mensual',
            modalidadCalculo: 'simple',
            fechaPrestamo: DateTime.utc(2026, 1, 1),
            totalAbonado: 0,
            fechaFin: DateTime.utc(2026, 7, 1),
          );
          final insoluto = InteresCalculator.resumenPrestamo(
            montoPrestado: 1000000,
            tasaInteres: 2,
            tipoInteres: 'mensual',
            modalidadCalculo: 'simple',
            fechaPrestamo: DateTime.utc(2026, 1, 1),
            totalAbonado: 0,
            tipoAmortizacion: 'saldo_insoluto',
            fechaFin: DateTime.utc(2026, 7, 1),
          );
          expect(insoluto, base);
        },
      );

      test(
        '1M al 2% mensual, abono de 500.000 a los 2 meses exactos: el '
        'interés de los meses 3-4 se calcula sobre el saldo YA reducido '
        '(540.000), no sobre el millón original',
        () {
          final r = InteresCalculator.resumenPrestamo(
            montoPrestado: 1000000,
            tasaInteres: 2,
            tipoInteres: 'mensual',
            modalidadCalculo: 'simple',
            fechaPrestamo: DateTime.utc(2026, 1, 1),
            totalAbonado: 500000,
            tipoAmortizacion: 'saldo_insoluto',
            abonos: [
              AbonoInteres(fecha: DateTime.utc(2026, 3, 1), monto: 500000),
            ],
            fechaFin: DateTime.utc(2026, 5, 1),
          );
          // Meses 1-2: interés = 1.000.000 × 2% × 2 = 40.000. El abono de
          // 500.000 cubre esos 40.000 de interés y el resto (460.000) baja
          // el capital: 1.000.000 − 460.000 = 540.000.
          // Meses 3-4: interés = 540.000 × 2% × 2 = 21.600.
          expect(r['interesAcumulado'], 61600);
          expect(r['saldoPendiente'], 561600); // 540.000 + 21.600
          expect(r['totalConInteres'], 1061600);
          expect(r['totalAbonado'], 500000);
        },
      );

      test(
        'el mismo escenario en saldo_original da MÁS interés (sigue '
        'cobrando sobre el millón completo) — confirma que saldo_insoluto '
        'es siempre <= saldo_original con abonos de por medio',
        () {
          final original = InteresCalculator.resumenPrestamo(
            montoPrestado: 1000000,
            tasaInteres: 2,
            tipoInteres: 'mensual',
            modalidadCalculo: 'simple',
            fechaPrestamo: DateTime.utc(2026, 1, 1),
            totalAbonado: 500000,
            fechaFin: DateTime.utc(2026, 5, 1),
          );
          final insoluto = InteresCalculator.resumenPrestamo(
            montoPrestado: 1000000,
            tasaInteres: 2,
            tipoInteres: 'mensual',
            modalidadCalculo: 'simple',
            fechaPrestamo: DateTime.utc(2026, 1, 1),
            totalAbonado: 500000,
            tipoAmortizacion: 'saldo_insoluto',
            abonos: [
              AbonoInteres(fecha: DateTime.utc(2026, 3, 1), monto: 500000),
            ],
            fechaFin: DateTime.utc(2026, 5, 1),
          );
          expect(original['saldoPendiente'], 580000);
          expect(insoluto['saldoPendiente'], 561600);
          expect(
            insoluto['saldoPendiente']!,
            lessThan(original['saldoPendiente']!),
          );
        },
      );

      test('un abono que cubre todo el capital sin interés → saldo 0 exacto', () {
        final r = InteresCalculator.resumenPrestamo(
          montoPrestado: 1000000,
          tasaInteres: 0,
          tipoInteres: 'ninguno',
          modalidadCalculo: 'simple',
          fechaPrestamo: DateTime.utc(2026, 1, 1),
          totalAbonado: 1000000,
          tipoAmortizacion: 'saldo_insoluto',
          abonos: [AbonoInteres(fecha: DateTime.utc(2026, 2, 1), monto: 1000000)],
          fechaFin: DateTime.utc(2026, 3, 1),
        );
        expect(r['saldoPendiente'], 0);
        expect(r['interesAcumulado'], 0);
      });

      test(
        'dos abonos parciales con interés compuesto: cada abono reduce el '
        'capital ANTES del siguiente período de interés',
        () {
          final r = InteresCalculator.resumenPrestamo(
            montoPrestado: 5000000,
            tasaInteres: 3,
            tipoInteres: 'mensual',
            modalidadCalculo: 'compuesto',
            fechaPrestamo: DateTime.utc(2026, 1, 1),
            totalAbonado: 0,
            tipoAmortizacion: 'saldo_insoluto',
            abonos: [
              AbonoInteres(fecha: DateTime.utc(2026, 2, 1), monto: 1000000),
              AbonoInteres(fecha: DateTime.utc(2026, 3, 1), monto: 1000000),
            ],
            fechaFin: DateTime.utc(2026, 4, 1),
          );
          // mes1: interés=5.000.000×3%=150.000; abono 1.000.000 cubre el
          //   interés y baja capital en 850.000 → saldo 4.150.000.
          // mes2: interés=4.150.000×3%=124.500; abono 1.000.000 cubre el
          //   interés y baja capital en 875.500 → saldo 3.274.500.
          // mes3: interés=3.274.500×3%=98.235.
          expect(r['interesAcumulado'], 372735); // 150000+124500+98235
          expect(r['saldoPendiente'], 3372735); // 3.274.500+98.235
        },
      );

      test(
        'abonos fuera de orden cronológico en la lista de entrada se '
        'procesan igual (se reordenan internamente)',
        () {
          final enOrden = InteresCalculator.resumenPrestamo(
            montoPrestado: 5000000,
            tasaInteres: 3,
            tipoInteres: 'mensual',
            modalidadCalculo: 'compuesto',
            fechaPrestamo: DateTime.utc(2026, 1, 1),
            totalAbonado: 0,
            tipoAmortizacion: 'saldo_insoluto',
            abonos: [
              AbonoInteres(fecha: DateTime.utc(2026, 2, 1), monto: 1000000),
              AbonoInteres(fecha: DateTime.utc(2026, 3, 1), monto: 1000000),
            ],
            fechaFin: DateTime.utc(2026, 4, 1),
          );
          final desordenado = InteresCalculator.resumenPrestamo(
            montoPrestado: 5000000,
            tasaInteres: 3,
            tipoInteres: 'mensual',
            modalidadCalculo: 'compuesto',
            fechaPrestamo: DateTime.utc(2026, 1, 1),
            totalAbonado: 0,
            tipoAmortizacion: 'saldo_insoluto',
            abonos: [
              AbonoInteres(fecha: DateTime.utc(2026, 3, 1), monto: 1000000),
              AbonoInteres(fecha: DateTime.utc(2026, 2, 1), monto: 1000000),
            ],
            fechaFin: DateTime.utc(2026, 4, 1),
          );
          expect(desordenado, enOrden);
        },
      );

      test(
        'abono con fecha posterior a fechaFin (fecha de corte) se ignora '
        'del todo, incluido totalAbonado — no solo del interés/capital',
        () {
          final r = InteresCalculator.resumenPrestamo(
            montoPrestado: 1000000,
            tasaInteres: 2,
            tipoInteres: 'mensual',
            modalidadCalculo: 'simple',
            fechaPrestamo: DateTime.utc(2026, 1, 1),
            totalAbonado: 0,
            tipoAmortizacion: 'saldo_insoluto',
            abonos: [
              // Fechado DESPUÉS del corte que se está consultando (mayo,
              // pero fechaFin es marzo): desde la perspectiva de ese corte
              // todavía no pudo haber ocurrido.
              AbonoInteres(fecha: DateTime.utc(2026, 5, 1), monto: 500000),
            ],
            fechaFin: DateTime.utc(2026, 3, 1),
          );
          // Interés de 2 meses completos sobre el millón sin tocar (el
          // abono futuro no reduce capital): 1.000.000 × 2% × 2 = 40.000.
          expect(r['interesAcumulado'], 40000);
          expect(r['montoPrestado'], 1000000);
          // Si el abono futuro se contara aquí, totalAbonado sería 500.000
          // pero saldoPendiente NO lo reflejaría (el capital sigue en
          // 1.000.000) — totalConInteres - totalAbonado dejaría de cuadrar
          // con saldoPendiente. Debe quedar en 0: no se aplicó nada todavía.
          expect(r['totalAbonado'], 0);
          expect(r['saldoPendiente'], 1040000);
          expect(
            r['totalConInteres']! - r['totalAbonado']!,
            r['saldoPendiente'],
          );
        },
      );

      test('calcularDeudaTotal en saldo_insoluto delega a resumenPrestamo', () {
        final total = InteresCalculator.calcularDeudaTotal(
          montoPrestado: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          modalidadCalculo: 'simple',
          fechaPrestamo: DateTime.utc(2026, 1, 1),
          totalAbonado: 500000,
          tipoAmortizacion: 'saldo_insoluto',
          abonos: [
            AbonoInteres(fecha: DateTime.utc(2026, 3, 1), monto: 500000),
          ],
          fechaFin: DateTime.utc(2026, 5, 1),
        );
        expect(total, 561600);
      });
    });

    group('calcularCuotaFija / calcularCuotaFijaDesdeTasa (sistema francés)', () {
      test('tasa 0 → cuotas iguales de capital/n exacto', () {
        final cuota = InteresCalculator.calcularCuotaFija(
          capital: 1000000,
          tasaPeriodica: 0,
          numeroCuotas: 10,
        );
        expect(cuota, 100000);
      });

      test('numeroCuotas <= 0 → 0 sin lanzar', () {
        expect(
          InteresCalculator.calcularCuotaFija(
            capital: 1000000,
            tasaPeriodica: 0.02,
            numeroCuotas: 0,
          ),
          0,
        );
      });

      test(
        '10.000.000 al 1.5% mensual a 12 meses → cuota fija verificable '
        'contra la fórmula de amortización francesa estándar',
        () {
          final cuota = InteresCalculator.calcularCuotaFija(
            capital: 10000000,
            tasaPeriodica: 0.015,
            numeroCuotas: 12,
          );
          // Cuota = 10.000.000 × [0.015×(1.015)^12] / [(1.015)^12 − 1]
          final factor = math.pow(1.015, 12);
          final esperada =
              (10000000 * (0.015 * factor) / (factor - 1)).round();
          expect(cuota, esperada);
        },
      );

      test(
        'a mayor tasa, mayor cuota fija para el mismo capital y plazo',
        () {
          final cuotaBaja = InteresCalculator.calcularCuotaFija(
            capital: 1000000,
            tasaPeriodica: 0.01,
            numeroCuotas: 12,
          );
          final cuotaAlta = InteresCalculator.calcularCuotaFija(
            capital: 1000000,
            tasaPeriodica: 0.03,
            numeroCuotas: 12,
          );
          expect(cuotaAlta, greaterThan(cuotaBaja));
        },
      );

      test('calcularCuotaFijaDesdeTasa con tasa anual equivale a la mensual '
          'correspondiente', () {
        final desdeAnual = InteresCalculator.calcularCuotaFijaDesdeTasa(
          capital: 1000000,
          tasaInteres: 24,
          tipoInteres: 'anual',
          numeroCuotas: 12,
        );
        final desdeMensual = InteresCalculator.calcularCuotaFijaDesdeTasa(
          capital: 1000000,
          tasaInteres: 2,
          tipoInteres: 'mensual',
          numeroCuotas: 12,
        );
        expect(desdeAnual, desdeMensual);
      });
    });
  });
}
