/// Normaliza una fecha de NEGOCIO (fecha de una transacción — no un
/// timestamp de auditoría como `creadoEn`/`actualizadoEn`) a medianoche UTC
/// de su fecha civil, antes de guardarla.
///
/// `seleccionada` debe ser un valor que ya representa el día correcto tal
/// como lo ve el usuario (viene de `showDatePicker` o de `DateTime.now()`
/// local) — se toman su año/mes/día directamente (sin conversión de huso,
/// porque ya son los correctos) y se fijan como medianoche UTC. Guardar así
/// hace que la fecha de la transacción sea un valor civil fijo (como un
/// `DATE` de SQL), no un instante que se reinterprete si el usuario viaja o
/// cambia la zona horaria del dispositivo.
DateTime normalizarFechaCivil(DateTime seleccionada) =>
    DateTime.utc(seleccionada.year, seleccionada.month, seleccionada.day);

/// Extrae la fecha civil (año/mes/día) de un campo de fecha de negocio ya
/// guardado (leído de la base de datos).
///
/// Drift reconstruye el `DateTime` como "local" (`isUtc == false`) aunque el
/// instante guardado sea exactamente medianoche UTC, así que leer
/// `.year`/`.month`/`.day` directamente puede dar el día equivocado según el
/// huso horario ACTUAL del dispositivo que lee (no hace falta viajar: basta
/// con estar en un huso negativo como UTC-5 para que se corra un día). Por
/// eso esta función siempre pasa primero por `.toUtc()` antes de extraer los
/// componentes — es la única forma correcta de leer uno de estos campos para
/// comparar, agrupar o mostrar como fecha civil.
DateTime fechaCivilGuardada(DateTime guardada) {
  final u = guardada.toUtc();
  return DateTime.utc(u.year, u.month, u.day);
}
