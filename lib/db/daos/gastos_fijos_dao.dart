import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'gastos_fijos_dao.g.dart';

@DriftAccessor(tables: [GastosFijos])
class GastosFijosDao extends DatabaseAccessor<AppDatabase>
    with _$GastosFijosDaoMixin {
  GastosFijosDao(super.db);

  Future<List<GastosFijo>> getAllGastosFijos() {
    return select(gastosFijos).get();
  }

  Future<List<GastosFijo>> getGastosFijosActivos() {
    return (select(gastosFijos)..where((t) => t.activo.equals(true))).get();
  }

  Future<GastosFijo> getGastoFijoById(int id) {
    return (select(gastosFijos)..where((t) => t.id.equals(id))).getSingle();
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

  Future<double> getTotalGastosFijosActivos() async {
    final sum = gastosFijos.monto.sum();
    final query = selectOnly(gastosFijos)
      ..addColumns([sum])
      ..where(gastosFijos.activo.equals(true));
    final row = await query.getSingle();
    return row.read(sum) ?? 0.0;
  }
}
