import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'gastos_fijos_dao.g.dart';

@DriftAccessor(tables: [GastosFijos])
class GastosFijosDao extends DatabaseAccessor<AppDatabase>
    with _$GastosFijosDaoMixin {
  GastosFijosDao(super.db);

  Future<List<GastosFijo>> getGastosFijosActivos() {
    return (select(gastosFijos)..where((t) => t.activo.equals(true))).get();
  }

  Future<GastosFijo?> getGastoFijoById(int id) {
    return (select(gastosFijos)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertGastoFijo(GastosFijosCompanion gasto) {
    return into(gastosFijos).insert(gasto);
  }

  Future<bool> updateGastoFijo(GastosFijo gasto) {
    return update(gastosFijos).replace(gasto);
  }

  Future<int> deleteGastoFijo(int id) {
    return (delete(gastosFijos)..where((t) => t.id.equals(id))).go();
  }

  Future<void> setActivo(int id, {required bool activo}) async {
    await (update(gastosFijos)..where((t) => t.id.equals(id))).write(
      GastosFijosCompanion(
        activo: Value(activo),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

}
