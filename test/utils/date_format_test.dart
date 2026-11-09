import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/utils/date_format.dart';

void main() {
  group('formatFecha', () {
    test('formatea con ceros a la izquierda en día y mes', () {
      expect(formatFecha(DateTime(2026, 3, 5)), '05/03/2026');
    });

    test('día y mes de dos dígitos', () {
      expect(formatFecha(DateTime(2026, 12, 25)), '25/12/2026');
    });
  });

  group('formatFechaLegible', () {
    test('lunes 1 de enero de 2024', () {
      // 2024-01-01 fue un lunes.
      expect(formatFechaLegible(DateTime(2024, 1, 1)), 'lun 1 ene 2024');
    });

    test('domingo 7 de enero de 2024', () {
      expect(formatFechaLegible(DateTime(2024, 1, 7)), 'dom 7 ene 2024');
    });

    test('miércoles en diciembre', () {
      // 2024-12-25 fue un miércoles.
      expect(formatFechaLegible(DateTime(2024, 12, 25)), 'mié 25 dic 2024');
    });
  });

  group('fechaRelativa', () {
    test('hoy → "Hoy"', () {
      final ahora = DateTime.now();
      expect(fechaRelativa(ahora), 'Hoy');
    });

    test('ayer → "Ayer"', () {
      final ayer = DateTime.now().subtract(const Duration(days: 1));
      expect(fechaRelativa(ayer), 'Ayer');
    });

    test('hace varios días → "Hace N días"', () {
      final hace3 = DateTime.now().subtract(const Duration(days: 3));
      expect(fechaRelativa(hace3), 'Hace 3 días');
    });

    test('hace 1 día en singular no aplica (usa Ayer)', () {
      final hace1 = DateTime.now().subtract(const Duration(days: 1));
      expect(fechaRelativa(hace1), 'Ayer');
    });

    test('en 1 día → singular "En 1 día"', () {
      final manana = DateTime.now().add(const Duration(days: 1));
      expect(fechaRelativa(manana), 'En 1 día');
    });

    test('en varios días → plural "En N días"', () {
      final en5 = DateTime.now().add(const Duration(days: 5));
      expect(fechaRelativa(en5), 'En 5 días');
    });
  });
}
