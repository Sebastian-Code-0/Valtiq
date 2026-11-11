import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/utils/date_format.dart';

void main() {
  test('saludoSegunHora cambia con la hora del día', () {
    expect(saludoSegunHora(DateTime(2026, 11, 11, 5)), 'Buenos días');
    expect(saludoSegunHora(DateTime(2026, 11, 11, 11, 59)), 'Buenos días');
    expect(saludoSegunHora(DateTime(2026, 11, 11, 12)), 'Buenas tardes');
    expect(saludoSegunHora(DateTime(2026, 11, 11, 18, 59)), 'Buenas tardes');
    expect(saludoSegunHora(DateTime(2026, 11, 11, 19)), 'Buenas noches');
    expect(saludoSegunHora(DateTime(2026, 11, 11, 4, 59)), 'Buenas noches');
  });

  test('proximoCambioDeSaludo apunta al siguiente corte', () {
    expect(
      proximoCambioDeSaludo(DateTime(2026, 11, 11, 3)),
      DateTime(2026, 11, 11, 5),
    );
    expect(
      proximoCambioDeSaludo(DateTime(2026, 11, 11, 13, 30)),
      DateTime(2026, 11, 11, 19),
    );
    expect(
      proximoCambioDeSaludo(DateTime(2026, 11, 30, 22)),
      DateTime(2026, 12, 1),
    );
  });

  test('fechas recortadas', () {
    expect(formatDiaMesCorto(DateTime(2026, 11, 12)), '12 nov');
    expect(formatMesAnioCorto(DateTime(2027, 5, 3)), 'may 2027');
  });
}
