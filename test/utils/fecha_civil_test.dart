import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/utils/fecha_civil.dart';

void main() {
  group('sumarMesesCivil', () {
    test('día normal: conserva el día del mes', () {
      expect(
        sumarMesesCivil(DateTime.utc(2026, 1, 15), 1),
        DateTime.utc(2026, 2, 15),
      );
    });

    test('31 de enero + 1 mes = último día de febrero (no 3 de marzo)', () {
      expect(
        sumarMesesCivil(DateTime.utc(2026, 1, 31), 1),
        DateTime.utc(2026, 2, 28),
      );
      expect(
        sumarMesesCivil(DateTime.utc(2028, 1, 31), 1),
        DateTime.utc(2028, 2, 29),
      );
    });

    test('31 de enero + 2 meses vuelve a caer en 31 (no se queda en 28)', () {
      expect(
        sumarMesesCivil(DateTime.utc(2026, 1, 31), 2),
        DateTime.utc(2026, 3, 31),
      );
    });

    test('31 + 1 mes hacia un mes de 30 días = día 30', () {
      expect(
        sumarMesesCivil(DateTime.utc(2026, 3, 31), 1),
        DateTime.utc(2026, 4, 30),
      );
    });

    test('cruza de año', () {
      expect(
        sumarMesesCivil(DateTime.utc(2026, 12, 31), 2),
        DateTime.utc(2027, 2, 28),
      );
    });
  });
}
