import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/notification_planner.dart';

Recordatorio _rec({
  int id = 1,
  required DateTime fechaAlerta,
  int diasAnticipacion = 3,
  String tipo = 'sistema',
  String frecuencia = 'unica',
  bool repetir = false,
  bool activo = true,
  DateTime? ultimaNotificacion,
  int hora = 12,
  int minuto = 0,
}) => Recordatorio(
  id: id,
  titulo: 'Arriendo',
  fechaAlerta: fechaAlerta,
  diasAnticipacion: diasAnticipacion,
  tipoNotificacion: tipo,
  repetir: repetir,
  activo: activo,
  creadoEn: DateTime(2026),
  frecuenciaAviso: frecuencia,
  ultimaNotificacion: ultimaNotificacion,
  horaAviso: hora,
  minutoAviso: minuto,
);

List<AvisoPlaneado> _planear(List<Recordatorio> rs, DateTime ahora) =>
    NotificationPlanner.planear(
      recordatorios: rs,
      ahora: ahora,
      cuerpo: (r, dias) => 'faltan $dias',
    );

void main() {
  // "Ahora" fijo: 10 de noviembre de 2026, 9:00 a. m. (hora local).
  final ahora = DateTime(2026, 11, 10, 9);

  test('aviso único: un solo aviso, el primer día de la ventana, a la hora '
      'elegida', () {
    final plan = _planear([
      _rec(fechaAlerta: DateTime.utc(2026, 11, 20), hora: 7, minuto: 30),
    ], ahora);

    expect(plan, hasLength(1));
    // Ventana: del 17 (3 días antes) al 27. Primer día = 17.
    expect(plan.single.cuando, DateTime(2026, 11, 17, 7, 30));
    expect(plan.single.cuerpo, 'faltan 3');
  });

  test('aviso diario: uno por cada día desde 3 días antes hasta 7 días '
      'después', () {
    final plan = _planear([
      _rec(fechaAlerta: DateTime.utc(2026, 11, 20), frecuencia: 'diaria'),
    ], ahora);

    expect(plan, hasLength(11)); // 17, 18, …, 27
    expect(plan.first.cuando, DateTime(2026, 11, 17, 12));
    expect(plan.last.cuando, DateTime(2026, 11, 27, 12));
    expect(plan[3].cuerpo, 'faltan 0'); // el propio día 20
    expect(plan.last.cuerpo, 'faltan -7');
  });

  test('ya en ventana y la hora de hoy no ha pasado: se programa para hoy', () {
    final plan = _planear([
      _rec(fechaAlerta: DateTime.utc(2026, 11, 11)),
    ], ahora);

    expect(plan.single.cuando, DateTime(2026, 11, 10, 12));
    expect(plan.single.cuerpo, 'faltan 1');
  });

  test('la hora de hoy ya pasó: no se programa en el pasado; pasa a mañana '
      '(lo de hoy lo atiende la revisión inmediata al abrir la app)', () {
    final plan = _planear([
      _rec(fechaAlerta: DateTime.utc(2026, 11, 11), hora: 8),
    ], ahora);

    expect(plan.single.cuando, DateTime(2026, 11, 11, 8));
  });

  test('aviso único ya avisado: no se vuelve a programar', () {
    final plan = _planear([
      _rec(
        fechaAlerta: DateTime.utc(2026, 11, 11),
        ultimaNotificacion: DateTime(2026, 11, 9, 12),
      ),
    ], ahora);

    expect(plan, isEmpty);
  });

  test('aviso diario ya avisado HOY: hoy no se repite, mañana sí', () {
    final plan = _planear([
      _rec(
        fechaAlerta: DateTime.utc(2026, 11, 11),
        frecuencia: 'diaria',
        ultimaNotificacion: DateTime(2026, 11, 10, 8),
      ),
    ], ahora);

    expect(plan.first.cuando, DateTime(2026, 11, 11, 12));
  });

  test('inactivos y de solo correo no generan aviso del sistema', () {
    final plan = _planear([
      _rec(id: 1, fechaAlerta: DateTime.utc(2026, 11, 12), activo: false),
      _rec(id: 2, fechaAlerta: DateTime.utc(2026, 11, 12), tipo: 'correo'),
      _rec(id: 3, fechaAlerta: DateTime.utc(2026, 11, 12), tipo: 'ambos'),
    ], ahora);

    expect(plan.map((a) => a.recordatorioId), [3]);
  });

  test('mensual: deja programados también los meses siguientes dentro del '
      'horizonte, aunque el de este mes ya se haya avisado', () {
    final plan = _planear([
      _rec(
        fechaAlerta: DateTime.utc(2026, 11, 12),
        repetir: true,
        ultimaNotificacion: DateTime(2026, 11, 9, 12),
      ),
    ], ahora);

    // El de noviembre ya se avisó; queda el de diciembre (ventana desde el 9).
    expect(plan.single.cuando, DateTime(2026, 12, 9, 12));
  });

  test('mensual de día 31: el mes siguiente cae en su último día', () {
    final plan = _planear([
      _rec(
        fechaAlerta: DateTime.utc(2026, 10, 31),
        repetir: true,
        diasAnticipacion: 0,
        ultimaNotificacion: DateTime(2026, 10, 31, 12),
      ),
    ], ahora);

    expect(plan.first.cuando, DateTime(2026, 11, 30, 12));
  });

  test('fuera del horizonte (más de 45 días): todavía no se programa', () {
    final plan = _planear([_rec(fechaAlerta: DateTime.utc(2027, 3, 1))], ahora);

    expect(plan, isEmpty);
  });

  test('nunca se pasa del tope, y conserva los avisos más cercanos', () {
    final plan = _planear([
      for (var i = 1; i <= 20; i++)
        _rec(
          id: i,
          fechaAlerta: DateTime.utc(2026, 11, 10 + i),
          frecuencia: 'diaria',
        ),
    ], ahora);

    expect(plan, hasLength(NotificationPlanner.maxAvisos));
    for (var i = 1; i < plan.length; i++) {
      expect(plan[i].cuando.isBefore(plan[i - 1].cuando), isFalse);
    }
  });
}
