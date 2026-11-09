import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/utils/format.dart';

void main() {
  group('formatCOP', () {
    test('cero → \$0', () {
      expect(formatCOP(0), r'$0');
    });

    test('monto positivo sin miles → sin separador', () {
      expect(formatCOP(500), r'$500');
    });

    test('monto positivo con miles → separador de punto', () {
      expect(formatCOP(1000), r'$1.000');
    });

    test('monto grande con varios grupos de miles', () {
      expect(formatCOP(1234567), r'$1.234.567');
    });

    test('monto negativo → prefijo -\$', () {
      expect(formatCOP(-500), r'-$500');
    });

    test('monto negativo grande', () {
      expect(formatCOP(-1234567), r'-$1.234.567');
    });

    test('decimales se redondean a entero', () {
      expect(formatCOP(999.4), r'$999');
      expect(formatCOP(999.6), r'$1.000');
    });

    group('rangos intermedios sin palabra propia en español (dígitos agrupados)', () {
      test('mil pesos', () {
        expect(formatCOP(1000), r'$1.000');
      });

      test('diez mil pesos', () {
        expect(formatCOP(10000), r'$10.000');
      });

      test('cien mil pesos', () {
        expect(formatCOP(100000), r'$100.000');
      });

      test('un millón de pesos', () {
        expect(formatCOP(1000000), r'$1.000.000');
      });

      test('diez millones de pesos', () {
        expect(formatCOP(10000000), r'$10.000.000');
      });

      test('cien millones de pesos', () {
        expect(formatCOP(100000000), r'$100.000.000');
      });

      test('mil millones de pesos (no tiene palabra corta en español)', () {
        expect(formatCOP(1000000000), r'$1.000.000.000');
      });

      test('diez mil millones de pesos', () {
        expect(formatCOP(10000000000), r'$10.000.000.000');
      });

      test('cien mil millones de pesos (justo debajo del umbral de billón)', () {
        expect(formatCOP(100000000000), r'$100.000.000.000');
      });
    });

    group('escala larga es_CO: billones (1e12) y trillones (1e18)', () {
      test('exactamente 1e12 → singular "billón", no "billones"', () {
        expect(formatCOP(1e12), r'$1 billón');
      });

      test('2e12 → plural "billones"', () {
        expect(formatCOP(2e12), r'$2 billones');
      });

      test('5,5e12 → coeficiente con decimales, plural', () {
        expect(formatCOP(5.5e12), r'$5,50 billones');
      });

      test('1e15 (mil billones) → sigue en escala de billones, plural', () {
        expect(formatCOP(1e15), r'$1000 billones');
      });

      test('exactamente 1e18 → singular "trillón", no "trillones"', () {
        expect(formatCOP(1e18), r'$1 trillón');
      });

      test('3e18 → plural "trillones"', () {
        expect(formatCOP(3e18), r'$3 trillones');
      });

      test('monto que excede maxCoeficiente → topado con "+", siempre plural', () {
        final excedido = formatCOP(1e40);
        expect(excedido, endsWith('+ trillones'));
        expect(excedido, isNot(contains('trillón ')));
      });
    });
  });

  group('formatTasaInicial', () {
    test('tasa entera → sin decimales', () {
      expect(formatTasaInicial(2), '2');
    });

    test('tasa cero → sin decimales', () {
      expect(formatTasaInicial(0), '0');
    });

    test('tasa con decimales → dos decimales', () {
      expect(formatTasaInicial(2.5), '2.50');
    });

    test('tasa con decimales exactos de más → se conservan dos', () {
      expect(formatTasaInicial(1.23), '1.23');
    });
  });
}
