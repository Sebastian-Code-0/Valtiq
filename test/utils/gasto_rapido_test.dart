import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/utils/currency_input.dart';
import 'package:valtiq/utils/gasto_rapido.dart';

void main() {
  void espera(String linea, String nombre, int monto) {
    final g = leerGastoRapido(linea);
    expect(g, isNotNull, reason: '"$linea" no se entendió');
    expect(g!.descripcion, nombre, reason: 'nombre de "$linea"');
    expect(g.monto, monto, reason: 'monto de "$linea"');
  }

  group('leerGastoRapido: formas de escribir el monto', () {
    test('las tres del pedido: 5000, 5.000 y 5mil', () {
      espera('cafe 5000', 'Cafe', 5000);
      espera('cafe 5.000', 'Cafe', 5000);
      espera('Cafe 5mil', 'Cafe', 5000);
    });

    test('miles con punto, coma, espacio de más y signo de pesos', () {
      espera('café 5,000', 'Café', 5000);
      espera(r'café $5.000', 'Café', 5000);
      espera(r'café $ 5000', 'Café', 5000);
      espera(r'café 5000$', 'Café', 5000);
      espera('café   5000  ', 'Café', 5000);
      espera('arriendo 1.200.000', 'Arriendo', 1200000);
      espera('arriendo 1,200,000', 'Arriendo', 1200000);
      espera('mercado 85.500,50', 'Mercado', 85501);
    });

    test('"mil" en todas sus variantes', () {
      for (final texto in [
        'café 5 mil',
        'café 5mil',
        'café 5MIL',
        'café 5 Mil',
        'café 5k',
        'café 5 k',
        'café 5K',
        'café 5 lucas',
        'café 5 barras',
        'café 5 mil pesos',
        'café 5.000 pesos',
        'café 5000 cop',
      ]) {
        espera(texto, 'Café', 5000);
      }
      espera('bus 2,5 mil', 'Bus', 2500);
      espera('bus 2.5 mil', 'Bus', 2500);
      espera('almuerzo 15 mil 500', 'Almuerzo', 15500);
      espera('propina mil', 'Propina', 1000);
      espera('propina una luca', 'Propina', 1000);
    });

    test('millones', () {
      espera('arriendo 1 millón', 'Arriendo', 1000000);
      espera('arriendo 1 millon', 'Arriendo', 1000000);
      espera('arriendo un millón', 'Arriendo', 1000000);
      espera('moto 2 millones', 'Moto', 2000000);
      espera('moto 2millones', 'Moto', 2000000);
      espera('moto 1.5 millones', 'Moto', 1500000);
      espera('moto 1,5 millones', 'Moto', 1500000);
      espera('moto 2 palos', 'Moto', 2000000);
      espera('moto 2 millones 500 mil', 'Moto', 2500000);
    });

    test('el monto puede ir al principio, al final o en medio', () {
      espera('5000 café', 'Café', 5000);
      espera('5mil café con pan', 'Café con pan', 5000);
      espera('café 5000 en la esquina', 'Café en la esquina', 5000);
      espera('5000', '', 5000);
      espera(r'$ 12.000', '', 12000);
    });

    test('se quitan los conectores que sobran alrededor del monto', () {
      espera('café por 5000', 'Café', 5000);
      espera('café: 5000', 'Café', 5000);
      espera('café - 5.000', 'Café', 5000);
      espera('café = 5mil', 'Café', 5000);
      espera('café costó 5000', 'Café', 5000);
      espera('5000 de café', 'Café', 5000);
      espera('café 5000.', 'Café', 5000);
    });

    test('con varios números gana el marcado como plata; si no, el mayor', () {
      espera('2 cafés 8000', '2 cafés', 8000);
      espera('8000 2 cafés', '2 cafés', 8000);
      espera('bus 2 pasajes 6 mil', 'Bus 2 pasajes', 6000);
      espera('arriendo apto 301 1200000', 'Arriendo apto 301', 1200000);
      espera(r'rifa 5000 boleta $2000', 'Rifa 5000 boleta', 2000);
      espera('gaseosa 1.5 litros 4500', 'Gaseosa 1.5 litros', 4500);
      // "mil" suelto no le gana a un número de verdad.
      espera('mil hojas 3500', 'Mil hojas', 3500);
    });

    test('las palabras que solo se parecen a una unidad no cuentan', () {
      espera('milhojas 3500', 'Milhojas', 3500);
      espera('kilo de arroz 4000', 'Kilo de arroz', 4000);
      espera('palomitas 9000', 'Palomitas', 9000);
    });

    test('sin monto válido devuelve null', () {
      expect(leerGastoRapido(''), isNull);
      expect(leerGastoRapido('café'), isNull);
      expect(leerGastoRapido('café 0'), isNull);
      expect(leerGastoRapido(r'café $'), isNull);
      // Por encima del tope de la app.
      expect(leerGastoRapido('casa ${maxMonto}0'), isNull);
      expect(leerGastoRapido('casa 9999999 millones'), isNull);
    });
  });

  group('leerGastoRapido: números escritos en letras', () {
    test('el caso del pedido: "comida cincuenta mil pesos"', () {
      espera('comida cincuenta mil pesos', 'Comida', 50000);
      espera('comida cincuenta mil', 'Comida', 50000);
      espera('Comida Cincuenta Mil Pesos', 'Comida', 50000);
    });

    test('miles, centenas y el "y" de las decenas', () {
      espera('mercado treinta y cinco mil', 'Mercado', 35000);
      espera('taxi doce mil quinientos', 'Taxi', 12500);
      espera('almuerzo veintidós mil', 'Almuerzo', 22000);
      espera('regalo ciento veinte mil', 'Regalo', 120000);
      espera('zapatos doscientos cincuenta mil pesos', 'Zapatos', 250000);
      espera('pan mil quinientos', 'Pan', 1500);
      espera('mil quinientos pan', 'Pan', 1500);
      espera('arepa dos mil', 'Arepa', 2000);
      espera('chicle quinientos pesos', 'Chicle', 500);
      espera('dulce cien pesos', 'Dulce', 100);
    });

    test('millones y apodos (lucas, palos)', () {
      espera('moto un millón', 'Moto', 1000000);
      espera('moto dos millones quinientos mil', 'Moto', 2500000);
      espera('moto tres palos', 'Moto', 3000000);
      espera('cena cincuenta lucas', 'Cena', 50000);
    });

    test('se puede mezclar con un número en cifras en el nombre', () {
      espera('2 empanadas cinco mil', '2 empanadas', 5000);
      espera('una empanada tres mil', 'Una empanada', 3000);
    });

    test('un número en letras que no es plata no cuenta', () {
      // Sin "mil" ni "pesos", "dos" o "cinco" son cantidades, no el monto.
      espera('dos empanadas 3000', 'Dos empanadas', 3000);
      espera('cinco cafés 10000', 'Cinco cafés', 10000);
      expect(leerGastoRapido('dos empanadas'), isNull);
      expect(leerGastoRapido('pan y leche'), isNull);
    });
  });

  group('leerListaGastos', () {
    test('un gasto por renglón, y avisa de los que no traen monto', () {
      final r = leerListaGastos(
        'rosas 50mil\ncomida en la calle 10.000\n5000\n\nllamar a Pedro',
      );
      expect(r.gastos.map((g) => (g.descripcion, g.monto)), [
        ('Rosas', 50000),
        ('Comida en la calle', 10000),
        ('', 5000),
      ]);
      expect(r.sinMonto, ['llamar a Pedro']);
    });

    test('todo en un renglón separado por comas o punto y coma', () {
      final r = leerListaGastos(
        'rosas 50mil, comida 10.000, 5000; bus 2,5 mil',
      );
      expect(r.gastos.map((g) => (g.descripcion, g.monto)), [
        ('Rosas', 50000),
        ('Comida', 10000),
        ('', 5000),
        ('Bus', 2500),
      ]);
      expect(r.sinMonto, isEmpty);
    });

    test('la coma de los miles no parte el gasto', () {
      final r = leerListaGastos('arriendo 1,200,000');
      expect(r.gastos.single.monto, 1200000);
    });
  });

  group('categoriaAprendida', () {
    const historial = [
      ('Café', 'Restaurantes'),
      ('Bus', 'Transporte'),
      ('café', 'Alimentación'), // más viejo: no gana
      ('Mercado D1', 'Alimentación'),
    ];

    test(
      'mismo nombre (sin importar tildes ni mayúsculas): la más reciente',
      () {
        expect(categoriaAprendida('cafe', historial), 'Restaurantes');
        expect(categoriaAprendida('  CAFÉ ', historial), 'Restaurantes');
        expect(categoriaAprendida('bus', historial), 'Transporte');
      },
    );

    test('si no hay nombre igual, uno que comparta una palabra', () {
      expect(categoriaAprendida('café con leche', historial), 'Restaurantes');
      expect(categoriaAprendida('mercado', historial), 'Alimentación');
    });

    test('nada parecido o nombre vacío: null', () {
      expect(categoriaAprendida('gasolina', historial), isNull);
      expect(categoriaAprendida('', historial), isNull);
      // "bus" tiene 3 letras: solo vale si es el nombre exacto.
      expect(categoriaAprendida('bus intermunicipal', historial), isNull);
    });
  });
}
