String formatFecha(DateTime fecha) {
  final d = fecha.day.toString().padLeft(2, '0');
  final m = fecha.month.toString().padLeft(2, '0');
  final y = fecha.year.toString();
  return '$d/$m/$y';
}

const _mesesCortos = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

const _diasCortos = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

const _mesesLargos = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// "marzo de 2026" — para mensajes que necesitan nombrar un mes específico
/// (ej. "superaste tu presupuesto de X en marzo de 2026"), distinto del mes
/// en curso.
String formatMesAnio(DateTime fecha) => '${_mesesLargos[fecha.month - 1]} de ${fecha.year}';

String formatFechaLegible(DateTime fecha) {
  final dia = _diasCortos[fecha.weekday - 1];
  final mes = _mesesCortos[fecha.month - 1];
  return '$dia ${fecha.day} $mes ${fecha.year}';
}

String fechaRelativa(DateTime fecha) {
  final ahora = DateTime.now();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final dia = DateTime(fecha.year, fecha.month, fecha.day);
  final diff = dia.difference(hoy).inDays;

  if (diff == 0) return 'Hoy';
  if (diff == -1) return 'Ayer';
  if (diff < 0) {
    final n = -diff;
    return 'Hace $n ${n == 1 ? 'día' : 'días'}';
  }
  return 'En $diff ${diff == 1 ? 'día' : 'días'}';
}

const _diasLargos = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

/// "MARTES 10 NOVIEMBRE" — la fecha de hoy en el encabezado de Inicio.
String formatFechaEncabezado(DateTime fecha) =>
    '${_diasLargos[fecha.weekday - 1]} ${fecha.day} '
            '${_mesesLargos[fecha.month - 1]}'
        .toUpperCase();

/// Saludo de Inicio según la hora: "Buenos días" (5:00–11:59), "Buenas
/// tardes" (12:00–18:59), "Buenas noches" (el resto).
String saludoSegunHora(DateTime ahora) {
  final h = ahora.hour;
  if (h >= 5 && h < 12) return 'Buenos días';
  if (h >= 12 && h < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

/// Próximo momento en que cambia el saludo o el día (5:00, 12:00, 19:00 o
/// medianoche), para refrescar el encabezado de Inicio justo entonces.
DateTime proximoCambioDeSaludo(DateTime ahora) {
  for (final h in const [5, 12, 19]) {
    if (ahora.hour < h) return DateTime(ahora.year, ahora.month, ahora.day, h);
  }
  return DateTime(ahora.year, ahora.month, ahora.day + 1);
}

/// "12 nov" — fecha recortada, sin año.
String formatDiaMesCorto(DateTime fecha) =>
    '${fecha.day} ${_mesesCortos[fecha.month - 1]}';

/// "may 2027" — mes recortado y año.
String formatMesAnioCorto(DateTime fecha) =>
    '${_mesesCortos[fecha.month - 1]} ${fecha.year}';
