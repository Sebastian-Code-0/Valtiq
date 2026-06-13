import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'recordatorios_dao.g.dart';

@DriftAccessor(tables: [Recordatorios])
class RecordatoriosDao extends DatabaseAccessor<AppDatabase>
    with _$RecordatoriosDaoMixin {
  RecordatoriosDao(super.db);

  Future<List<Recordatorio>> getRecordatoriosActivos() {
    return (select(recordatorios)..where((t) => t.activo.equals(true))).get();
  }

  Future<Recordatorio> getRecordatorioById(int id) {
    return (select(recordatorios)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<List<Recordatorio>> getRecordatoriosPorReferencia(
    String tabla,
    int refId,
  ) {
    return (select(recordatorios)
          ..where(
            (t) =>
                t.referenciaTabla.equals(tabla) & t.referenciaId.equals(refId),
          ))
        .get();
  }

  Future<int> insertRecordatorio(RecordatoriosCompanion rec) {
    return into(recordatorios).insert(rec);
  }

  Future<bool> updateRecordatorio(Recordatorio rec) {
    return update(recordatorios).replace(rec);
  }

  Future<int> deleteRecordatorio(int id) {
    return (delete(recordatorios)..where((t) => t.id.equals(id))).go();
  }

  Future<bool> desactivarRecordatorio(int id) async {
    final count =
        await (update(recordatorios)..where((t) => t.id.equals(id))).write(
      const RecordatoriosCompanion(activo: Value(false)),
    );
    return count > 0;
  }

  Future<bool> activarRecordatorio(int id) async {
    final count =
        await (update(recordatorios)..where((t) => t.id.equals(id))).write(
      const RecordatoriosCompanion(activo: Value(true)),
    );
    return count > 0;
  }

  Future<int> marcarNotificado(int id, DateTime cuando) =>
      (update(recordatorios)..where((t) => t.id.equals(id)))
          .write(RecordatoriosCompanion(ultimaNotificacion: Value(cuando)));

  Future<int> marcarEnvioCorreo(int id, DateTime cuando) =>
      (update(recordatorios)..where((t) => t.id.equals(id)))
          .write(RecordatoriosCompanion(ultimoEnvioCorreo: Value(cuando)));

  Future<int> resetearDeduplicacion(int id) =>
      (update(recordatorios)..where((t) => t.id.equals(id)))
          .write(const RecordatoriosCompanion(
            ultimaNotificacion: Value(null),
            ultimoEnvioCorreo: Value(null),
          ));

  Future<int> reprogramarMensual(int id, DateTime nuevaFecha) =>
      (update(recordatorios)..where((t) => t.id.equals(id)))
          .write(RecordatoriosCompanion(
            fechaAlerta: Value(nuevaFecha),
            ultimaNotificacion: const Value(null),
            ultimoEnvioCorreo: const Value(null),
          ));
}
