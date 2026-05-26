String formatFecha(DateTime fecha) {
  final d = fecha.day.toString().padLeft(2, '0');
  final m = fecha.month.toString().padLeft(2, '0');
  final y = fecha.year.toString();
  return '$d/$m/$y';
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
