import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'recordatorios_dao.g.dart';

@DriftAccessor(tables: [Recordatorios])
class RecordatoriosDao extends DatabaseAccessor<AppDatabase>
    with _$RecordatoriosDaoMixin {
  RecordatoriosDao(super.db);

  Future<List<Recordatorio>> getAllRecordatorios() {
    return (select(recordatorios)
          ..orderBy([(t) => OrderingTerm.asc(t.fechaAlerta)]))
        .get();
  }

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

  Future<List<Recordatorio>> getRecordatoriosProximos(int dias) {
    final ahora = DateTime.now();
    final limite = ahora.add(Duration(days: dias));
    return (select(recordatorios)
          ..where(
            (t) =>
                t.activo.equals(true) &
                t.fechaAlerta.isBetweenValues(ahora, limite),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.fechaAlerta)]))
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
}
