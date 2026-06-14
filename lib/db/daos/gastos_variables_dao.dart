import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'gastos_variables_dao.g.dart';

@DriftAccessor(tables: [GastosVariables])
class GastosVariablesDao extends DatabaseAccessor<AppDatabase>
    with _$GastosVariablesDaoMixin {
  GastosVariablesDao(super.db);

  Stream<List<GastoVariable>> watchGastosVariables() =>
      (select(gastosVariables)
            ..orderBy([(g) => OrderingTerm.desc(g.fecha)]))
          .watch();

  Stream<List<GastoVariable>> watchGastosPorMes(int anio, int mes) {
    final inicio = DateTime(anio, mes, 1);
    final fin = DateTime(anio, mes + 1, 1);
    return (select(gastosVariables)
          ..where((g) => g.fecha.isBiggerOrEqualValue(inicio) &
              g.fecha.isSmallerThanValue(fin))
          ..orderBy([(g) => OrderingTerm.desc(g.fecha)]))
        .watch();
  }

  Stream<Map<String, double>> watchTotalPorCategoria(int anio, int mes) {
    final inicio = DateTime(anio, mes, 1);
    final fin = DateTime(anio, mes + 1, 1);
    final sumMonto = gastosVariables.monto.sum();
    return (selectOnly(gastosVariables)
          ..addColumns([gastosVariables.categoria, sumMonto])
          ..where(gastosVariables.fecha.isBiggerOrEqualValue(inicio) &
              gastosVariables.fecha.isSmallerThanValue(fin))
          ..groupBy([gastosVariables.categoria]))
        .watch()
        .map((rows) {
      final mapa = <String, double>{};
      for (final row in rows) {
        final cat = row.read(gastosVariables.categoria) ?? '';
        final total = row.read(sumMonto) ?? 0.0;
        mapa[cat] = total;
      }
      return mapa;
    });
  }

  Stream<double> watchTotalMes(int anio, int mes) {
    final inicio = DateTime(anio, mes, 1);
    final fin = DateTime(anio, mes + 1, 1);
    final sumMonto = gastosVariables.monto.sum();
    return (selectOnly(gastosVariables)
          ..addColumns([sumMonto])
          ..where(gastosVariables.fecha.isBiggerOrEqualValue(inicio) &
              gastosVariables.fecha.isSmallerThanValue(fin)))
        .watchSingle()
        .map((row) => row.read(sumMonto) ?? 0.0);
  }

  Future<int> insertGastoVariable(GastosVariablesCompanion gasto) =>
      into(gastosVariables).insert(gasto);

  Future<bool> updateGastoVariable(GastoVariable gasto) =>
      update(gastosVariables).replace(gasto);

  Future<int> deleteGastoVariable(int id) =>
      (delete(gastosVariables)..where((g) => g.id.equals(id))).go();
}
