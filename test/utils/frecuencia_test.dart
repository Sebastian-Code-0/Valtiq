import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/utils/frecuencia.dart';

void main() {
  group('factorMensual', () {
    test('mensual → 1 (sin cambio)', () {
      expect(factorMensual('mensual'), 1);
    });

    test('quincenal → 2 exacto', () {
      expect(factorMensual('quincenal'), 2);
    });

    test('semanal → 52/12, no 4 (un mes tiene más de 4 semanas exactas)', () {
      expect(factorMensual('semanal'), closeTo(4.3333, 0.001));
    });

    test('valor desconocido → 1 (tratado como mensual por defecto)', () {
      expect(factorMensual('unico'), 1);
      expect(factorMensual('algo_invalido'), 1);
    });
  });
}
