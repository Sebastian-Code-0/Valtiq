import 'package:drift/drift.dart';

import '../../utils/frecuencia.dart';
import '../database.dart';
import '../tables.dart';

part 'gastos_fijos_dao.g.dart';

@DriftAccessor(tables: [GastosFijos])
class GastosFijosDao extends DatabaseAccessor<AppDatabase>
    with _$GastosFijosDaoMixin {
  GastosFijosDao(super.db);

  Future<List<GastosFijo>> getAllGastosFijos() {
    return (select(
      gastosFijos,
    )..orderBy([(t) => OrderingTerm.asc(t.concepto)])).get();
  }

  Future<List<GastosFijo>> getGastosFijosActivos() {
    return (select(gastosFijos)..where((t) => t.activo.equals(true))).get();
  }

  Future<GastosFijo?> getGastoFijoById(int id) {
    return (select(
      gastosFijos,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<GastosFijo>> getGastosFijosByIds(List<int> ids) {
    if (ids.isEmpty) return Future.value([]);
    return (select(gastosFijos)..where((t) => t.id.isIn(ids))).get();
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

  Future<void> deleteGastoFijoConRecordatorios(int id) {
    return transaction(() async {
      await (delete(gastosFijos)..where((t) => t.id.equals(id))).go();
      await attachedDatabase.recordatoriosDao
          .desactivarRecordatoriosPorReferencia('gasto', id);
    });
  }

  /// Total mensual de gastos fijos activos: el `monto` guardado es POR
  /// PERÍODO (lo que se paga cada quincena/semana/mes), así que se
  /// multiplica por `factorMensual` antes de sumar — mismo mecanismo que
  /// `IngresosDao.watchTotalIngresosMes`. `GastosFijos` no tiene 'unico' ni
  /// columna `fecha`: siempre es recurrente, así que no hace falta filtrar
  /// por mes acá, solo prorratear.
  Stream<int> watchTotalMensualizado() {
    return (select(
      gastosFijos,
    )..where((t) => t.activo.equals(true))).watch().map(
      (lista) => lista.fold<int>(
        0,
        (s, g) => s + (g.monto * factorMensual(g.frecuencia)).round(),
      ),
    );
  }

  Future<void> setActivo(int id, {required bool activo}) {
    return transaction(() async {
      await (update(gastosFijos)..where((t) => t.id.equals(id))).write(
        GastosFijosCompanion(
          activo: Value(activo),
          actualizadoEn: Value(DateTime.now()),
        ),
      );
      if (activo) {
        await attachedDatabase.recordatoriosDao
            .reactivarRecordatoriosPorReferencia('gasto', id);
      } else {
        await attachedDatabase.recordatoriosDao
            .desactivarRecordatoriosPorReferencia('gasto', id);
      }
    });
  }
}
