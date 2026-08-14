import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'pagos_deuda_dao.g.dart';

@DriftAccessor(tables: [PagosDeuda])
class PagosDeudaDao extends DatabaseAccessor<AppDatabase>
    with _$PagosDeudaDaoMixin {
  PagosDeudaDao(super.db);

  Future<List<PagosDeudaData>> getAllPagos() {
    return (select(
      pagosDeuda,
    )..orderBy([(t) => OrderingTerm.desc(t.fechaPago)])).get();
  }

  Stream<List<PagosDeudaData>> watchPagosDeDeuda(int deudaId) {
    return (select(pagosDeuda)
          ..where((t) => t.deudaId.equals(deudaId))
          ..orderBy([(t) => OrderingTerm.desc(t.fechaPago)]))
        .watch();
  }

  Future<int> insertPago(PagosDeudaCompanion pago) {
    return into(pagosDeuda).insert(pago);
  }

  Future<int> deletePago(int id) {
    return (delete(pagosDeuda)..where((t) => t.id.equals(id))).go();
  }

  Future<double> getTotalAbonado(int deudaId) async {
    final sum = pagosDeuda.montoAbonado.sum();
    final query = selectOnly(pagosDeuda)
      ..addColumns([sum])
      ..where(pagosDeuda.deudaId.equals(deudaId));
    final row = await query.getSingle();
    return row.read(sum) ?? 0.0;
  }
}
