import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/utils/categoria_gasto.dart';
import 'package:valtiq/utils/gasto_rapido.dart';
import 'package:valtiq/utils/nombres_conocidos.dart';
import 'package:valtiq/utils/tipo_deuda.dart';

void main() {
  test('la lista es grande y no repite nombres', () {
    expect(totalNombresConocidos, greaterThan(450));
    final vistos = <String>{};
    for (final g in gruposNombres) {
      for (final n in g.nombres) {
        expect(
          vistos.add(normalizarNombre(n.nombre)),
          isTrue,
          reason: 'repetido: ${n.nombre}',
        );
      }
    }
  });

  test('toda categoría de la lista es una categoría de fábrica', () {
    final fabrica = CategoriaGasto.nombres.toSet();
    for (final g in gruposNombres) {
      if (g.categoria != null) {
        expect(fabrica, contains(g.categoria), reason: g.tipo);
      }
      for (final n in g.nombres) {
        if (n.categoria != null) {
          expect(fabrica, contains(n.categoria), reason: n.nombre);
        }
      }
    }
    for (final e in palabrasCategoria.entries) {
      expect(fabrica, contains(e.value), reason: e.key);
      expect(e.key, normalizarNombre(e.key), reason: 'sin tildes: ${e.key}');
    }
  });

  group('sugerirNombres', () {
    List<String> nombres(String t) =>
        sugerirNombres(t).map((s) => s.nombre).toList();

    test('por el comienzo, sin importar tildes ni mayúsculas', () {
      expect(nombres('bancol'), contains('Bancolombia'));
      expect(nombres('DAVI'), containsAll(['Davivienda', 'Daviplata']));
      expect(nombres('exi'), contains('Éxito'));
      expect(nombres('olimp'), contains('Olímpica'));
    });

    test('por alias y por una palabra de en medio', () {
      expect(nombres('nubank'), ['Nu']);
      expect(nombres('rebaja'), contains('La Rebaja'));
      expect(nombres('valdez'), contains('Juan Valdez'));
    });

    test('una sola letra no sugiere nada; respeta el límite', () {
      expect(sugerirNombres('b'), isEmpty);
      expect(sugerirNombres('ba', limite: 3), hasLength(3));
    });
  });

  group('categoriaPorNombre', () {
    test('marcas', () {
      expect(categoriaPorNombre('D1'), 'Alimentación');
      expect(categoriaPorNombre('mercado en el d1'), 'Alimentación');
      expect(categoriaPorNombre('Uber'), 'Transporte');
      expect(categoriaPorNombre('netflix'), 'Suscripciones');
      expect(categoriaPorNombre('Juan Valdez'), 'Restaurantes');
      expect(categoriaPorNombre('tanqueo terpel'), 'Carro');
      expect(categoriaPorNombre('recibo epm'), 'Servicios públicos');
      expect(categoriaPorNombre('Cruz Verde'), 'Salud');
    });

    test('palabras comunes', () {
      expect(categoriaPorNombre('café'), 'Restaurantes');
      expect(categoriaPorNombre('Almuerzo'), 'Restaurantes');
      expect(categoriaPorNombre('bus'), 'Transporte');
      expect(categoriaPorNombre('pan y leche'), 'Alimentación');
      expect(categoriaPorNombre('corte de pelo'), 'Cuidado personal');
      expect(categoriaPorNombre('arriendo'), 'Hogar');
    });

    test('"metro" es el pasaje, no el supermercado', () {
      expect(categoriaPorNombre('metro'), 'Transporte');
    });

    test('nada conocido: null', () {
      expect(categoriaPorNombre('rosas'), isNull);
      expect(categoriaPorNombre(''), isNull);
    });
  });

  test('tipoDeudaPorNombre', () {
    expect(tipoDeudaPorNombre('Bancolombia'), TipoDeuda.banco);
    expect(tipoDeudaPorNombre('tarjeta exito'), TipoDeuda.tarjeta);
    expect(tipoDeudaPorNombre('Addi'), TipoDeuda.banco);
    expect(tipoDeudaPorNombre('Alkosto'), TipoDeuda.tienda);
    expect(tipoDeudaPorNombre('Juan'), isNull);
  });
}
