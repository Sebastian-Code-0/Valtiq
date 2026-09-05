import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/dashboard_service.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

DeudasCompanion _deuda({int montoOriginal = 100000}) => DeudasCompanion.insert(
  acreedorNombre: 'Banco Test',
  montoOriginal: montoOriginal,
  fechaPrestamo: DateTime(2026, 1, 1),
);

PrestamosCompanion _prestamo({int montoPrestado = 100000}) =>
    PrestamosCompanion.insert(
      deudorNombre: 'Juan',
      montoPrestado: montoPrestado,
      fechaPrestamo: DateTime(2026, 1, 1),
    );

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createInMemoryDb();
  });

  tearDown(() async {
    await db.close();
  });

  group('DashboardService.watchTotalDeudasActivas', () {
    test('BD vacía → emite 0', () async {
      final total = await DashboardService.watchTotalDeudasActivas(db).first;
      expect(total, 0);
    });

    test('suma varias deudas activas (sin interés, sin abonos)', () async {
      await db.deudasDao.insertDeuda(_deuda(montoOriginal: 100000));
      await db.deudasDao.insertDeuda(_deuda(montoOriginal: 200000));

      final total = await DashboardService.watchTotalDeudasActivas(db).first;

      expect(total, 300000);
    });

    test('una deuda pagada no cuenta en el total', () async {
      final id1 = await db.deudasDao.insertDeuda(_deuda(montoOriginal: 100000));
      await db.deudasDao.insertDeuda(_deuda(montoOriginal: 200000));
      await db.deudasDao.marcarComoPagada(id1, DateTime(2026, 2, 1));

      final total = await DashboardService.watchTotalDeudasActivas(db).first;

      expect(total, 200000);
    });
  });

  group('DashboardService.watchTotalPrestamosActivos', () {
    test('BD vacía → emite 0', () async {
      final total = await DashboardService.watchTotalPrestamosActivos(db)
          .first;
      expect(total, 0);
    });

    test('suma varios préstamos activos (sin interés, sin abonos)', () async {
      await db.prestamosDao.insertPrestamo(_prestamo(montoPrestado: 50000));
      await db.prestamosDao.insertPrestamo(_prestamo(montoPrestado: 75000));

      final total = await DashboardService.watchTotalPrestamosActivos(
        db,
      ).first;

      expect(total, 125000);
    });

    test('un préstamo pagado no cuenta en el total', () async {
      final id1 = await db.prestamosDao.insertPrestamo(
        _prestamo(montoPrestado: 50000),
      );
      await db.prestamosDao.insertPrestamo(_prestamo(montoPrestado: 75000));
      await db.prestamosDao.marcarComoPagado(id1);

      final total = await DashboardService.watchTotalPrestamosActivos(
        db,
      ).first;

      expect(total, 75000);
    });
  });

  group('DashboardService.watchBalanceMensual', () {
    test(
      'combina ingresos/gastos fijos/gastos variables del mes actual',
      () async {
        final ahora = DateTime.now();

        await db.ingresosDao.insertIngreso(
          IngresosCompanion.insert(
            concepto: 'Salario',
            monto: 1000000,
            fecha: ahora,
          ),
        );
        await db.gastosFijosDao.insertGastoFijo(
          GastosFijosCompanion.insert(concepto: 'Arriendo', monto: 400000),
        );
        await db.gastosVariablesDao.insertGastoVariable(
          GastosVariablesCompanion.insert(
            descripcion: 'Mercado',
            monto: 50000,
            categoria: 'alimentacion',
            fecha: ahora,
          ),
        );

        final balance = await DashboardService.watchBalanceMensual(db).firstWhere(
          (b) => b.ingresos > 0 && b.gastos > 0 && b.variables > 0,
        );

        expect(balance.ingresos, 1000000);
        expect(balance.gastos, 400000);
        expect(balance.variables, 50000);
      },
    );

    test('reacciona a cambios: un ingreso nuevo emite un balance actualizado', () async {
      final ahora = DateTime.now();
      final stream = DashboardService.watchBalanceMensual(db);

      final emisiones = <({double ingresos, double gastos, double variables})>[];
      final sub = stream.listen(emisiones.add);
      addTearDown(sub.cancel);

      // Da tiempo a que el listener se conecte antes de insertar.
      await Future<void>.delayed(Duration.zero);

      await db.ingresosDao.insertIngreso(
        IngresosCompanion.insert(
          concepto: 'Salario',
          monto: 1000000,
          fecha: ahora,
        ),
      );

      await pumpEventQueue();

      expect(emisiones.any((b) => b.ingresos == 1000000), isTrue);
    });
  });
}
