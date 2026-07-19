import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'deudas_dao.g.dart';

@DriftAccessor(tables: [Deudas])
class DeudasDao extends DatabaseAccessor<AppDatabase> with _$DeudasDaoMixin {
  DeudasDao(super.db);

  Future<List<Deuda>> getAllDeudas() {
    return (select(deudas)
          ..orderBy([(t) => OrderingTerm.desc(t.fechaPrestamo)]))
        .get();
  }

  Future<List<Deuda>> getDeudasActivas() {
    return (select(deudas)..where((t) => t.estado.equals('activa'))).get();
  }

  Future<List<Deuda>> getDeudasPagadas() {
    return (select(deudas)..where((t) => t.estado.equals('pagada'))).get();
  }

  Future<Deuda?> getDeudaById(int id) {
    return (select(deudas)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertDeuda(DeudasCompanion deuda) {
    return into(deudas).insert(deuda);
  }

  Future<bool> updateDeuda(Deuda deuda) {
    return update(deudas).replace(deuda);
  }

  Future<bool> marcarComoPagada(int id, DateTime fechaPago) async {
    final count = await (update(deudas)..where((t) => t.id.equals(id))).write(
      DeudasCompanion(
        estado: const Value('pagada'),
        fechaPagoReal: Value(fechaPago),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
    return count > 0;
  }

  Future<bool> marcarComoActiva(int id) async {
    final count = await (update(deudas)..where((t) => t.id.equals(id))).write(
      DeudasCompanion(
        estado: const Value('activa'),
        fechaPagoReal: const Value(null),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
    return count > 0;
  }

  Future<int> deleteDeuda(int id) {
    return (delete(deudas)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteDeudaConPagos(int id) {
    return transaction(() async {
      await (delete(attachedDatabase.pagosDeuda)
            ..where((t) => t.deudaId.equals(id)))
          .go();
      await (delete(deudas)..where((t) => t.id.equals(id))).go();
    });
  }
}
