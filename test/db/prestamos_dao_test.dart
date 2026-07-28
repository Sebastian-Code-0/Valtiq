import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

PrestamosCompanion _prestamo({
  String deudorNombre = 'Juan Test',
  double montoPrestado = 100000,
  DateTime? fechaPrestamo,
}) => PrestamosCompanion.insert(
  deudorNombre: deudorNombre,
  montoPrestado: montoPrestado,
  fechaPrestamo: fechaPrestamo ?? DateTime(2026, 1, 1),
);

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createInMemoryDb();
  });

  tearDown(() async {
    await db.close();
  });

  group('PrestamosDao', () {
    test('insertPrestamo → aparece con getPrestamoById', () async {
      final id = await db.prestamosDao.insertPrestamo(_prestamo());

      final prestamo = await db.prestamosDao.getPrestamoById(id);

      expect(prestamo, isNotNull);
      expect(prestamo!.deudorNombre, 'Juan Test');
      expect(prestamo.montoPrestado, 100000.0);
      expect(prestamo.estado, 'activo');
    });

    test('updatePrestamo → los cambios se reflejan', () async {
      final id = await db.prestamosDao.insertPrestamo(_prestamo());
      final original = (await db.prestamosDao.getPrestamoById(id))!;

      final actualizado = original.copyWith(
        deudorNombre: 'Pedro Nuevo',
        montoPrestado: 300000,
      );
      final ok = await db.prestamosDao.updatePrestamo(actualizado);

      final leido = await db.prestamosDao.getPrestamoById(id);
      expect(ok, isTrue);
      expect(leido!.deudorNombre, 'Pedro Nuevo');
      expect(leido.montoPrestado, 300000.0);
    });

    test('marcarComoPagado desactiva recordatorios vinculados', () async {
      final id = await db.prestamosDao.insertPrestamo(_prestamo());
      await db.recordatoriosDao.insertRecordatorio(
        RecordatoriosCompanion.insert(
          titulo: 'Cobrar préstamo',
          fechaAlerta: DateTime(2026, 2, 1),
          referenciaTabla: const Value('prestamo'),
          referenciaId: Value(id),
        ),
      );

      await db.prestamosDao.marcarComoPagado(id);

      final recordatorios = await db.recordatoriosDao
          .getRecordatoriosPorReferencia('prestamo', id);
      expect(recordatorios.single.activo, isFalse);
    });

    group('deletePrestamoConPagos', () {
      test('borra el préstamo y sus pagos en cascada', () async {
        final id = await db.prestamosDao.insertPrestamo(_prestamo());
        await db.prestamosDao.insertPago(
          PagosRecibidosCompanion.insert(
            prestamoId: id,
            montoAbonado: 20000,
            fechaPago: DateTime(2026, 1, 10),
          ),
        );

        await db.prestamosDao.deletePrestamoConPagos(id);

        final prestamo = await db.prestamosDao.getPrestamoById(id);
        final pagos = await db.prestamosDao.getPagosDelPrestamo(id);
        expect(prestamo, isNull);
        expect(pagos, isEmpty);
      });

      test('desactiva (no borra) los recordatorios vinculados', () async {
        final id = await db.prestamosDao.insertPrestamo(_prestamo());
        await db.recordatoriosDao.insertRecordatorio(
          RecordatoriosCompanion.insert(
            titulo: 'Cobrar préstamo',
            fechaAlerta: DateTime(2026, 2, 1),
            referenciaTabla: const Value('prestamo'),
            referenciaId: Value(id),
          ),
        );

        await db.prestamosDao.deletePrestamoConPagos(id);

        final recordatorios = await db.recordatoriosDao
            .getRecordatoriosPorReferencia('prestamo', id);
        expect(recordatorios, hasLength(1));
        expect(recordatorios.single.activo, isFalse);
      });
    });

    group('getTotalAbonado / getSaldoPendiente', () {
      test('sin pagos → total 0.0 y saldo igual al monto prestado', () async {
        final id = await db.prestamosDao.insertPrestamo(
          _prestamo(montoPrestado: 50000),
        );

        final total = await db.prestamosDao.getTotalAbonado(id);
        final saldo = await db.prestamosDao.getSaldoPendiente(id);

        expect(total, 0.0);
        expect(saldo, 50000.0);
      });

      test('suma varios pagos y descuenta del saldo', () async {
        final id = await db.prestamosDao.insertPrestamo(
          _prestamo(montoPrestado: 100000),
        );
        await db.prestamosDao.insertPago(
          PagosRecibidosCompanion.insert(
            prestamoId: id,
            montoAbonado: 15000,
            fechaPago: DateTime(2026, 1, 5),
          ),
        );
        await db.prestamosDao.insertPago(
          PagosRecibidosCompanion.insert(
            prestamoId: id,
            montoAbonado: 25000,
            fechaPago: DateTime(2026, 1, 20),
          ),
        );

        final total = await db.prestamosDao.getTotalAbonado(id);
        final saldo = await db.prestamosDao.getSaldoPendiente(id);

        expect(total, closeTo(40000.0, 0.01));
        expect(saldo, closeTo(60000.0, 0.01));
      });

      test('no mezcla pagos de otro préstamo', () async {
        final id1 = await db.prestamosDao.insertPrestamo(_prestamo());
        final id2 = await db.prestamosDao.insertPrestamo(
          _prestamo(deudorNombre: 'Otro'),
        );
        await db.prestamosDao.insertPago(
          PagosRecibidosCompanion.insert(
            prestamoId: id1,
            montoAbonado: 10000,
            fechaPago: DateTime(2026, 1, 5),
          ),
        );
        await db.prestamosDao.insertPago(
          PagosRecibidosCompanion.insert(
            prestamoId: id2,
            montoAbonado: 99999,
            fechaPago: DateTime(2026, 1, 5),
          ),
        );

        final total = await db.prestamosDao.getTotalAbonado(id1);

        expect(total, closeTo(10000.0, 0.01));
      });
    });
  });
}
