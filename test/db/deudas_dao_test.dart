import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

DeudasCompanion _deuda({
  String acreedorNombre = 'Banco Test',
  int montoOriginal = 100000,
  DateTime? fechaPrestamo,
}) => DeudasCompanion.insert(
  acreedorNombre: acreedorNombre,
  montoOriginal: montoOriginal,
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

  group('DeudasDao', () {
    test('insertDeuda → aparece con getDeudaById', () async {
      final id = await db.deudasDao.insertDeuda(_deuda());

      final deuda = await db.deudasDao.getDeudaById(id);

      expect(deuda, isNotNull);
      expect(deuda!.acreedorNombre, 'Banco Test');
      expect(deuda.montoOriginal, 100000.0);
      expect(deuda.estado, 'activa');
    });

    test('updateDeuda → los cambios se reflejan', () async {
      final id = await db.deudasDao.insertDeuda(_deuda());
      final original = (await db.deudasDao.getDeudaById(id))!;

      final actualizada = original.copyWith(
        acreedorNombre: 'Banco Nuevo',
        montoOriginal: 250000,
      );
      final ok = await db.deudasDao.updateDeuda(actualizada);

      final leida = await db.deudasDao.getDeudaById(id);
      expect(ok, isTrue);
      expect(leida!.acreedorNombre, 'Banco Nuevo');
      expect(leida.montoOriginal, 250000.0);
    });

    test('marcarComoPagada desactiva recordatorios vinculados', () async {
      final id = await db.deudasDao.insertDeuda(_deuda());
      await db.recordatoriosDao.insertRecordatorio(
        RecordatoriosCompanion.insert(
          titulo: 'Pagar deuda',
          fechaAlerta: DateTime(2026, 2, 1),
          referenciaTabla: const Value('deuda'),
          referenciaId: Value(id),
        ),
      );

      await db.deudasDao.marcarComoPagada(id, DateTime(2026, 1, 15));

      final recordatorios = await db.recordatoriosDao
          .getRecordatoriosPorReferencia('deuda', id);
      expect(recordatorios.single.activo, isFalse);
    });

    group('deleteDeudaConPagos', () {
      test('borra la deuda y sus pagos en cascada', () async {
        final id = await db.deudasDao.insertDeuda(_deuda());
        await db.pagosDeudaDao.insertPago(
          PagosDeudaCompanion.insert(
            deudaId: id,
            montoAbonado: 20000,
            fechaPago: DateTime(2026, 1, 10),
          ),
        );

        await db.deudasDao.deleteDeudaConPagos(id);

        final deuda = await db.deudasDao.getDeudaById(id);
        final pagos = await db.pagosDeudaDao.watchPagosDeDeuda(id).first;
        expect(deuda, isNull);
        expect(pagos, isEmpty);
      });

      test('desactiva (no borra) los recordatorios vinculados', () async {
        final id = await db.deudasDao.insertDeuda(_deuda());
        await db.recordatoriosDao.insertRecordatorio(
          RecordatoriosCompanion.insert(
            titulo: 'Pagar deuda',
            fechaAlerta: DateTime(2026, 2, 1),
            referenciaTabla: const Value('deuda'),
            referenciaId: Value(id),
          ),
        );

        await db.deudasDao.deleteDeudaConPagos(id);

        final recordatorios = await db.recordatoriosDao
            .getRecordatoriosPorReferencia('deuda', id);
        expect(recordatorios, hasLength(1));
        expect(recordatorios.single.activo, isFalse);
      });
    });

    group('PagosDeudaDao.getTotalAbonado', () {
      test('sin pagos → 0.0', () async {
        final id = await db.deudasDao.insertDeuda(_deuda());

        final total = await db.pagosDeudaDao.getTotalAbonado(id);

        expect(total, 0.0);
      });

      test('suma varios pagos de la misma deuda', () async {
        final id = await db.deudasDao.insertDeuda(_deuda());
        await db.pagosDeudaDao.insertPago(
          PagosDeudaCompanion.insert(
            deudaId: id,
            montoAbonado: 15000,
            fechaPago: DateTime(2026, 1, 5),
          ),
        );
        await db.pagosDeudaDao.insertPago(
          PagosDeudaCompanion.insert(
            deudaId: id,
            montoAbonado: 25000,
            fechaPago: DateTime(2026, 1, 20),
          ),
        );

        final total = await db.pagosDeudaDao.getTotalAbonado(id);

        expect(total, closeTo(40000.0, 0.01));
      });

      test('no mezcla pagos de otra deuda', () async {
        final id1 = await db.deudasDao.insertDeuda(_deuda());
        final id2 = await db.deudasDao.insertDeuda(
          _deuda(acreedorNombre: 'Otro banco'),
        );
        await db.pagosDeudaDao.insertPago(
          PagosDeudaCompanion.insert(
            deudaId: id1,
            montoAbonado: 10000,
            fechaPago: DateTime(2026, 1, 5),
          ),
        );
        await db.pagosDeudaDao.insertPago(
          PagosDeudaCompanion.insert(
            deudaId: id2,
            montoAbonado: 99999,
            fechaPago: DateTime(2026, 1, 5),
          ),
        );

        final total = await db.pagosDeudaDao.getTotalAbonado(id1);

        expect(total, closeTo(10000.0, 0.01));
      });
    });
  });
}
