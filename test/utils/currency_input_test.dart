import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/utils/currency_input.dart';

void main() {
  group('parseCOP', () {
    test(r'$1.000 → 1000', () {
      expect(parseCOP(r'$1.000'), 1000);
    });

    test(r'$1.500.000 → 1500000', () {
      expect(parseCOP(r'$1.500.000'), 1500000);
    });

    test('sin símbolo: "1000" → 1000', () {
      expect(parseCOP('1000'), 1000);
    });

    test(r'$0 → 0', () {
      expect(parseCOP(r'$0'), 0);
    });

    test('cadena vacía → null', () {
      expect(parseCOP(''), isNull);
    });

    test('texto no numérico → null', () {
      expect(parseCOP('abc'), isNull);
    });

    test('espacios extra alrededor se ignoran', () {
      expect(parseCOP(r'  $1.000  '), 1000);
    });

    test(
      'valor con coma decimal (formato europeo) → se redondea al peso',
      () {
        // La función reemplaza ',' por '.' → '1000,50' se interpreta como
        // 1000.5 y se redondea al peso más cercano (money = int, sin
        // centavos) → 1001.
        expect(parseCOP('1000,50'), 1001);
      },
    );

    test(r'$100.000.000 (cien millones) → 100000000', () {
      expect(parseCOP(r'$100.000.000'), 100000000);
    });
  });

  group('formatCOPInput', () {
    test('1000.0 → "1.000"', () {
      expect(formatCOPInput(1000.0), '1.000');
    });

    test('1500000.0 → "1.500.000"', () {
      expect(formatCOPInput(1500000.0), '1.500.000');
    });

    test('0.0 → "0"', () {
      expect(formatCOPInput(0.0), '0');
    });

    test('valores negativos llevan prefijo "-"', () {
      expect(formatCOPInput(-1000.0), '-1.000');
    });

    test('100.0 → "100" (sin puntos)', () {
      expect(formatCOPInput(100.0), '100');
    });

    test('1000000.0 → "1.000.000"', () {
      expect(formatCOPInput(1000000.0), '1.000.000');
    });

    test('parte decimal se trunca (solo parte entera)', () {
      // La función usa .round() → 999.7 → 1000
      expect(formatCOPInput(999.7), '1.000');
    });

    test('roundtrip: parseCOP(formatCOPInput(v)) == v para enteros', () {
      const valores = [0.0, 1000.0, 50000.0, 1500000.0, 100000000.0];
      for (final v in valores) {
        final formateado = formatCOPInput(v);
        final parseado = parseCOP(formateado);
        expect(parseado, v, reason: 'Falló para $v → "$formateado"');
      }
    });
  });
}
