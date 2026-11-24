import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'plan_seguir_comun.dart';

/// "Seguir el plan": cada mes se abre la app el día 1, se paga lo que dice
/// "Este mes paga" en el día de pago de cada deuda, con el calculador real,
/// y al terminar una deuda se acepta "Seguir pagándolos". El plan del primer
/// día tiene que acertar el mes en que se termina, no cambiar su fecha de un
/// mes a otro, nunca pedir menos del mínimo ni más de lo que se debe, y su
/// último pago tiene que dejar cada deuda en cero.
void main() {
  final fechas = [
    DateTime(2026, 11, 24),
    DateTime(2026, 11, 1),
    DateTime(2026, 12, 31),
    DateTime(2027, 1, 30),
    DateTime(2028, 2, 29),
  ];

  void revisar(Informe inf) {
    expect(
      inf.problemas.keys.where(
        (k) => k != 'intereses distintos a lo prometido',
      ),
      isEmpty,
      reason: inf.resumen(),
    );
    expect(inf.difMeses.every((d) => d == 0), isTrue, reason: inf.resumen());
    expect(inf.seguidasHastaElFinal, greaterThan(inf.carteras * 0.8));
  }

  test('una deuda de cada tipo (amigos, tarjetas, almacén, libre inversión, '
      'carro, ICETEX, gota a gota, hipoteca a 15-30 y a 50 años)', () {
    final inf = Informe();
    var semilla = 0;
    for (final tipo in [
      'amigo',
      'tarjeta',
      'almacen',
      'libre',
      'carro',
      'icetex',
      'gota',
      'casa',
      'casa50',
    ]) {
      for (var i = 0; i < 10; i++) {
        semillaActual = semilla;
        seguir(
          cartera(tipo, math.Random(semilla++), fechas[i % fechas.length]),
          inf,
        );
      }
    }
    revisar(inf);
  }, timeout: const Timeout(Duration(minutes: 5)));

  test(
    'carteras mezcladas, de familia y con hipoteca',
    () {
      final inf = Informe();
      for (var i = 0; i < 90; i++) {
        semillaActual = 10000 + i;
        final esquema = ['mixta', 'familia', 'conCasa'][i % 3];
        seguir(
          cartera(
            esquema,
            math.Random(semillaActual),
            fechas[i % fechas.length],
          ),
          inf,
        );
      }
      revisar(inf);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
