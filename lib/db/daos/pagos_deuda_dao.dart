import 'package:drift/drift.dart';

import '../../services/interes_calculator.dart';
import '../../utils/fecha_civil.dart';
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

  Future<List<PagosDeudaData>> getPagosDeDeuda(int deudaId) {
    return (select(pagosDeuda)
          ..where((t) => t.deudaId.equals(deudaId))
          ..orderBy([(t) => OrderingTerm.desc(t.fechaPago)]))
        .get();
  }

  Future<int> insertPago(PagosDeudaCompanion pago) {
    return into(pagosDeuda).insert(pago);
  }

  Future<int> deletePago(int id) {
    return (delete(pagosDeuda)..where((t) => t.id.equals(id))).go();
  }

  /// Elimina un pago. Si la deuda estaba liquidada con sus pagos y sin este
  /// vuelve a deber, la reabre y devuelve lo que se debe; si no, `null`. Una
  /// deuda que el usuario marcó como pagada debiendo no se reabre: esa fue
  /// su decisión.
  Future<int?> eliminarPago(int id) {
    return transaction(() async {
      final pago = await (select(
        pagosDeuda,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (pago == null) return null;
      final deuda = await attachedDatabase.deudasDao.getDeudaById(pago.deudaId);
      final antes = await getPagosDeDeuda(pago.deudaId);
      await deletePago(id);
      if (deuda == null ||
          deuda.estado != 'pagada' ||
          deuda.fechaPagoReal == null) {
        return null;
      }
      final corte = fechaCivilGuardada(deuda.fechaPagoReal!);
      int saldo(List<PagosDeudaData> pagos, DateTime fin) =>
          InteresCalculator.resumenPrestamo(
            montoPrestado: deuda.montoOriginal,
            tasaInteres: deuda.tasaInteres,
            tipoInteres: deuda.tipoInteres,
            modalidadCalculo: deuda.modalidadCalculo,
            fechaPrestamo: deuda.fechaPrestamo,
            totalAbonado: pagos.fold<int>(0, (s, p) => s + p.montoAbonado),
            tipoAmortizacion: deuda.tipoAmortizacion,
            abonos: [
              for (final p in pagos)
                AbonoInteres(fecha: p.fechaPago, monto: p.montoAbonado),
            ],
            fechaFin: fin,
          )['saldoPendiente']!;
      if (saldo(antes, corte) > 1) return null;
      final quedan = [
        for (final p in antes)
          if (p.id != id) p,
      ];
      if (saldo(quedan, corte) <= 0) return null;
      await attachedDatabase.deudasDao.marcarComoActiva(deuda.id);
      // Ya activa, corre hasta hoy: es la cifra que muestra la tarjeta.
      return saldo(quedan, normalizarFechaCivil(DateTime.now()));
    });
  }

  Future<int> getTotalAbonado(int deudaId) async {
    final sum = pagosDeuda.montoAbonado.sum();
    final query = selectOnly(pagosDeuda)
      ..addColumns([sum])
      ..where(pagosDeuda.deudaId.equals(deudaId));
    final row = await query.getSingle();
    return row.read(sum) ?? 0;
  }
}
