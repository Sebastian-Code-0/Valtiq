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
