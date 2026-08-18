import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'presupuestos_categorias_dao.g.dart';

@DriftAccessor(tables: [PresupuestosCategorias])
class PresupuestosCategoriasDao extends DatabaseAccessor<AppDatabase>
    with _$PresupuestosCategoriasDaoMixin {
  PresupuestosCategoriasDao(super.db);

  Stream<List<PresupuestosCategoria>> watchPresupuestos() =>
      select(presupuestosCategorias).watch();

  Future<PresupuestosCategoria?> getPresupuestoPorCategoria(String categoria) {
    return (select(
      presupuestosCategorias,
    )..where((t) => t.categoria.equals(categoria))).getSingleOrNull();
  }

  Future<int> upsertPresupuesto(PresupuestosCategoriasCompanion presupuesto) {
    return into(presupuestosCategorias).insertOnConflictUpdate(presupuesto);
  }

  Future<int> eliminarPresupuesto(int id) {
    return (delete(
      presupuestosCategorias,
    )..where((t) => t.id.equals(id))).go();
  }
}
