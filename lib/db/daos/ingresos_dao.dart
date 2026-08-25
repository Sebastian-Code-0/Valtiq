import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'ingresos_dao.g.dart';

@DriftAccessor(tables: [Ingresos])
class IngresosDao extends DatabaseAccessor<AppDatabase>
    with _$IngresosDaoMixin {
  IngresosDao(super.db);

  Future<List<Ingreso>> getAllIngresos() {
    return (select(
      ingresos,
    )..orderBy([(t) => OrderingTerm.desc(t.fecha)])).get();
  }

  Future<List<Ingreso>> getIngresosActivos() {
    return (select(ingresos)..where((t) => t.activo.equals(true))).get();
  }

  Future<Ingreso?> getIngresoById(int id) {
    return (select(ingresos)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertIngreso(IngresosCompanion ingreso) {
    return into(ingresos).insert(ingreso);
  }

  Future<bool> updateIngreso(Ingreso ingreso) {
    return update(ingresos).replace(ingreso);
  }

  Future<int> deleteIngreso(int id) {
    return (delete(ingresos)..where((t) => t.id.equals(id))).go();
  }

  Future<void> setActivo(int id, {required bool activo}) async {
    await (update(ingresos)..where((t) => t.id.equals(id))).write(
      IngresosCompanion(
        activo: Value(activo),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  Future<int> getTotalIngresosActivos() async {
    final sum = ingresos.monto.sum();
    final query = selectOnly(ingresos)
      ..addColumns([sum])
      ..where(ingresos.activo.equals(true));
    final row = await query.getSingle();
    return row.read(sum) ?? 0;
  }
}
