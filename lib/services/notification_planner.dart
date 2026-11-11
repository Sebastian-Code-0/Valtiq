import '../db/database.dart';
import '../utils/fecha_civil.dart';

/// Un aviso que hay que dejarle programado al sistema operativo: sonará en
/// [cuando] aunque Valtiq esté cerrado.
class AvisoPlaneado {
  const AvisoPlaneado({
    required this.recordatorioId,
    required this.cuando,
    required this.titulo,
    required this.cuerpo,
  });

  final int recordatorioId;

  /// Fecha y hora LOCAL del dispositivo (la hora que el usuario eligió).
  final DateTime cuando;
  final String titulo;
  final String cuerpo;
}

/// Decide QUÉ avisos programar y PARA CUÁNDO, sin tocar el sistema operativo
/// ni la base de datos — por eso se puede probar con tests normales.
/// `NotificationService.replanificar` toma esta lista y se la entrega a
/// Android.
///
/// Sigue las mismas reglas que la revisión al abrir la app
/// (`NotificationService.revisarRecordatorios`):
/// - Un recordatorio avisa desde `diasAnticipacion` días antes de su fecha
///   hasta [diasGracia] días después.
/// - `frecuenciaAviso == 'unica'`: un solo aviso por fecha. `'diaria'`: uno
///   cada día de esa ventana.
/// - `repetir`: la fecha se repite cada mes (mismo día, o el último del mes
///   si no existe).
/// - Siempre a la hora elegida (`horaAviso:minutoAviso`).
abstract class NotificationPlanner {
  /// Días después de la fecha en los que todavía se avisa ("vencido hace…").
  static const diasGracia = 7;

  /// Hasta cuántos días hacia adelante se deja programado. Cada vez que se
  /// abre la app se vuelve a planear, así que solo hace falta cubrir el
  /// tiempo que alguien podría pasar SIN abrirla.
  static const horizonteDias = 45;

  /// Tope de avisos programados a la vez (Android limita las alarmas por
  /// app; se conservan los más cercanos).
  static const maxAvisos = 60;

  static List<AvisoPlaneado> planear({
    required List<Recordatorio> recordatorios,
    required DateTime ahora,
    required String Function(Recordatorio r, int diasFaltantes) cuerpo,
  }) {
    final hoy = normalizarFechaCivil(ahora);
    final limite = hoy.add(const Duration(days: horizonteDias));
    final avisos = <AvisoPlaneado>[];

    for (final r in recordatorios) {
      if (!r.activo) continue;
      // Los de solo correo no generan aviso del sistema.
      if (r.tipoNotificacion != 'sistema' && r.tipoNotificacion != 'ambos') {
        continue;
      }
      final fechaBase = fechaCivilGuardada(r.fechaAlerta);
      final ultimaNotificacion = r.ultimaNotificacion;

      // ciclo 0 = la fecha guardada; ciclo k = k meses después (solo si
      // el recordatorio se repite).
      for (var ciclo = 0; ciclo < 240; ciclo++) {
        if (ciclo > 0 && !r.repetir) break;
        final fecha = ciclo == 0
            ? fechaBase
            : sumarMesesCivil(fechaBase, ciclo);
        final inicioVentana = fecha.subtract(
          Duration(days: r.diasAnticipacion),
        );
        final finVentana = fecha.add(const Duration(days: diasGracia));
        if (inicioVentana.isAfter(limite)) break;
        if (finVentana.isBefore(hoy)) continue;

        // Un recordatorio de aviso único ya avisado no vuelve a sonar para
        // ESA fecha (las fechas de meses siguientes sí: al reprogramarse se
        // borra la marca de "ya avisado").
        final unica = r.frecuenciaAviso == 'unica';
        if (unica && ciclo == 0 && ultimaNotificacion != null) continue;

        var dia = inicioVentana.isBefore(hoy) ? hoy : inicioVentana;
        for (
          ;
          !dia.isAfter(finVentana) && !dia.isAfter(limite);
          dia = dia.add(const Duration(days: 1))
        ) {
          final cuando = DateTime(
            dia.year,
            dia.month,
            dia.day,
            r.horaAviso,
            r.minutoAviso,
          );
          // Solo momentos que todavía no han pasado: lo de hoy ya vencido
          // lo atiende la revisión inmediata al abrir la app.
          if (!cuando.isAfter(ahora)) continue;
          if (ciclo == 0 &&
              ultimaNotificacion != null &&
              _mismoDiaLocal(ultimaNotificacion, cuando)) {
            continue;
          }
          avisos.add(
            AvisoPlaneado(
              recordatorioId: r.id,
              cuando: cuando,
              titulo: r.titulo,
              cuerpo: cuerpo(r, fecha.difference(dia).inDays),
            ),
          );
          if (unica) break;
        }
      }
    }

    avisos.sort((a, b) => a.cuando.compareTo(b.cuando));
    return avisos.length > maxAvisos ? avisos.sublist(0, maxAvisos) : avisos;
  }

  static bool _mismoDiaLocal(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }
}
