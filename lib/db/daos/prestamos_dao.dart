import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'prestamos_dao.g.dart';

@DriftAccessor(tables: [Prestamos, PagosRecibidos])
class PrestamosDao extends DatabaseAccessor<AppDatabase>
    with _$PrestamosDaoMixin {
  PrestamosDao(super.db);

  Future<List<Prestamo>> getAllPrestamos() {
    return (select(prestamos)
          ..orderBy([(t) => OrderingTerm.desc(t.fechaPrestamo)]))
        .get();
  }

  Future<List<Prestamo>> getPrestamosActivos() {
    return (select(prestamos)..where((t) => t.estado.equals('activo'))).get();
  }

  Future<Prestamo?> getPrestamoById(int id) {
    return (select(prestamos)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertPrestamo(PrestamosCompanion prestamo) {
    return into(prestamos).insert(prestamo);
  }

  Future<bool> updatePrestamo(Prestamo prestamo) {
    return update(prestamos).replace(prestamo);
  }

  Future<int> deletePrestamo(int id) {
    return (delete(prestamos)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deletePrestamoConPagos(int id) {
    return transaction(() async {
      await (delete(pagosRecibidos)..where((t) => t.prestamoId.equals(id))).go();
      await (delete(prestamos)..where((t) => t.id.equals(id))).go();
      await attachedDatabase.recordatoriosDao
          .desactivarRecordatoriosPorReferencia('prestamo', id);
    });
  }

  Future<bool> marcarComoPagado(int id) {
    return transaction(() async {
      final count =
          await (update(prestamos)..where((t) => t.id.equals(id))).write(
        PrestamosCompanion(
          estado: const Value('pagado'),
          actualizadoEn: Value(DateTime.now()),
        ),
      );
      await attachedDatabase.recordatoriosDao
          .desactivarRecordatoriosPorReferencia('prestamo', id);
      return count > 0;
    });
  }

  Future<bool> marcarComoVencido(int id) async {
    final count =
        await (update(prestamos)..where((t) => t.id.equals(id))).write(
      PrestamosCompanion(
        estado: const Value('vencido'),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
    return count > 0;
  }

  Future<void> reactivarPrestamo(int id) {
    return transaction(() async {
      await (update(prestamos)..where((p) => p.id.equals(id))).write(
        PrestamosCompanion(
          estado: const Value('activo'),
          actualizadoEn: Value(DateTime.now()),
        ),
      );
      await attachedDatabase.recordatoriosDao
          .reactivarRecordatoriosPorReferencia('prestamo', id);
    });
  }

  Future<List<PagosRecibido>> getPagosDelPrestamo(int prestamoId) {
    return (select(pagosRecibidos)
          ..where((t) => t.prestamoId.equals(prestamoId))
          ..orderBy([(t) => OrderingTerm.desc(t.fechaPago)]))
        .get();
  }

  Future<int> insertPago(PagosRecibidosCompanion pago) {
    return into(pagosRecibidos).insert(pago);
  }

  Future<int> deletePago(int id) {
    return (delete(pagosRecibidos)..where((t) => t.id.equals(id))).go();
  }

  Future<double> getTotalAbonado(int prestamoId) async {
    final sum = pagosRecibidos.montoAbonado.sum();
    final query = selectOnly(pagosRecibidos)
      ..addColumns([sum])
      ..where(pagosRecibidos.prestamoId.equals(prestamoId));
    final row = await query.getSingle();
    return row.read(sum) ?? 0.0;
  }

  Future<double> getSaldoPendiente(int prestamoId) async {
    final prestamo = await getPrestamoById(prestamoId);
    if (prestamo == null) return 0.0;
    final abonado = await getTotalAbonado(prestamoId);
    return prestamo.montoPrestado - abonado;
  }

  Future<double> getTotalPrestadoActivo() async {
    final sum = prestamos.montoPrestado.sum();
    final query = selectOnly(prestamos)
      ..addColumns([sum])
      ..where(prestamos.estado.equals('activo'));
    final row = await query.getSingle();
    return row.read(sum) ?? 0.0;
  }
}
