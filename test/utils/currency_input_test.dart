import 'package:flutter/widgets.dart';
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

    test('valor con coma decimal (formato europeo) → se redondea al peso', () {
      // La función reemplaza ',' por '.' → '1000,50' se interpreta como
      // 1000.5 y se redondea al peso más cercano (money = int, sin
      // centavos) → 1001.
      expect(parseCOP('1000,50'), 1000);
    });

    test(r'$100.000.000 (cien millones) → 100000000', () {
      expect(parseCOP(r'$100.000.000'), 100000000);
    });
  });

  group('tope de montos (12 dígitos)', () {
    test('el máximo se acepta; uno más ya no', () {
      expect(parseCOP('999.999.999.999'), maxMonto);
      expect(parseCOP('1.000.000.000.000'), isNull);
    });

    test('un 1 seguido de 19 ceros no cabe en un entero: se rechaza en vez '
        'de aplastarse a 9.223.372.036.854.775.807', () {
      expect(parseCOP('10000000000000000000'), isNull);
      expect(parseCOP('1${'0' * 40}'), isNull);
    });

    test('el campo no deja escribir más de 12 dígitos', () {
      final f = CopInputFormatter();
      const doce = TextEditingValue(text: '999.999.999.999');
      final trece = f.formatEditUpdate(
        doce,
        const TextEditingValue(text: '999.999.999.9991'),
      );
      expect(trece.text, '999.999.999.999');
      // Pegar de golpe un número enorme: se rechaza, no se recorta.
      final pegado = f.formatEditUpdate(
        const TextEditingValue(
          text: '5.000',
          selection: TextSelection.collapsed(offset: 5),
        ),
        const TextEditingValue(
          text: '10000000000000000000',
          selection: TextSelection.collapsed(offset: 20),
        ),
      );
      expect(pegado.text, '5.000');
    });
  });

  group('campo de monto', () {
    TextEditingValue v(String t, int c, [int? b]) => TextEditingValue(
      text: t,
      selection: TextSelection(baseOffset: b ?? c, extentOffset: c),
    );
    final f = CopInputFormatter();

    TextEditingValue insertar(TextEditingValue a, String x) {
      final i = a.selection.start;
      final j = a.selection.end;
      return f.formatEditUpdate(
        a,
        v(a.text.replaceRange(i, j, x), i + x.length),
      );
    }

    TextEditingValue retroceso(TextEditingValue a) {
      final i = a.selection.start;
      return f.formatEditUpdate(a, v(a.text.replaceRange(i - 1, i, ''), i - 1));
    }

    TextEditingValue teclear(String teclas, [TextEditingValue? desde]) {
      var a = desde ?? v('', 0);
      for (final ch in teclas.split('')) {
        a = insertar(a, ch);
      }
      return a;
    }

    test('una sola lectura: miles válidos o decimales sin redondear', () {
      const casos = {
        '1,500,000': 1500000,
        '1.500.000': 1500000,
        '1500,50': 1500,
        '1500,000': 1500,
        '1000,500': 1000,
        '0,500': 0,
        '1.500,000': 1500,
        '1,5': 1,
        '0.999': 0,
        '000.000': 0,
        '050000': 50000,
        '1,500.50': 1500,
      };
      casos.forEach((t, esperado) => expect(parseCOP(t), esperado, reason: t));
    });

    test('lo ambiguo no se lee y al pegarlo no cambia el valor', () {
      const malos = [
        '1.500.000.50',
        '1,500,000,50',
        '1.234.56',
        '1,234,56',
        '1,50,000',
        '1.5.2',
        '5000 3000',
      ];
      for (final t in malos) {
        expect(parseCOP(t), isNull, reason: t);
        expect(insertar(v('12', 2, 0), t).text, '12', reason: t);
      }
      expect(insertar(v('', 0), '0.999').text, '0');
      expect(insertar(v('', 0), '1,500,000').text, '1.500.000');
    });

    test('solo números: coma y punto tecleados no hacen nada', () {
      for (final (teclas, texto, valor) in const [
        ('1,500,000', '1.500.000', 1500000),
        ('1.500.000', '1.500.000', 1500000),
        ('1,500000', '1.500.000', 1500000),
        ('1500,50', '150.050', 150050),
        ('1,5', '15', 15),
      ]) {
        final a = teclear(teclas);
        expect(a.text, texto);
        expect(parseCOP(a.text), valor);
      }
    });

    test('una coma al final no cambia el campo ni el cursor', () {
      final a = teclear(',', v('1.000', 5));
      expect(a.text, '1.000');
      expect(a.selection.end, 5);
    });

    test('el punto tecleado sigue igual: 1500000.50 es 150.000.050', () {
      expect(teclear('1500000.50').text, '150.000.050');
    });

    test('más de 12 dígitos: rechaza sin perder lo escrito', () {
      expect(insertar(v('123.456.789.012', 0), '9').text, '123.456.789.012');
      final a = teclear('1,000,000,000,000');
      expect(a.text, '100.000.000.000');
      expect(parseCOP(a.text), 100000000000);
      expect(teclear('999,999,999,999').text, '999.999.999.999');
      expect(parseCOP('999,999,999,999'), maxMonto);
    });

    test('borrar un dígito en medio no destruye el número', () {
      for (final (texto, final2) in const [
        ('1.000.000', '2.000.000'),
        ('1.050.000', '2.050.000'),
      ]) {
        final borrado = retroceso(v(texto, 1));
        expect(
          borrado.text.replaceAll('.', ''),
          texto.substring(2).replaceAll('.', '').padLeft(6, '0'),
        );
        expect(
          parseCOP(borrado.text),
          int.parse(texto.replaceAll('.', '').substring(1)),
        );
        expect(insertar(borrado, '2').text, final2);
      }
    });

    test('Supr y reemplazo junto a un punto de miles', () {
      expect(f.formatEditUpdate(v('1.000', 1), v('1000', 1)).text, '100');
      expect(f.formatEditUpdate(v('4.659', 2, 0), v('4659', 1)).text, '4.659');
    });

    test('sin ceros a la izquierda al escribir', () {
      expect(insertar(v('5.000', 0), '0').text, '5.000');
      expect(insertar(v('', 0), '007').text, '7');
      expect(teclear('000').text, '0');
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
