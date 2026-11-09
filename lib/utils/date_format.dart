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
