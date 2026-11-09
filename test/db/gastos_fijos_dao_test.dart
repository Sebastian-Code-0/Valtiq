import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

GastosFijosCompanion _gasto({
  required int monto,
  String frecuencia = 'mensual',
  String concepto = 'Test',
  bool activo = true,
}) => GastosFijosCompanion(
  concepto: Value(concepto),
  monto: Value(monto),
  frecuencia: Value(frecuencia),
  activo: Value(activo),
);

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createInMemoryDb();
  });

  tearDown(() async {
    await db.close();
  });

  group('GastosFijosDao.watchTotalMensualizado', () {
    test('BD vacía → emite 0', () async {
      final total = await db.gastosFijosDao.watchTotalMensualizado().first;

      expect(total, 0);
    });

    test('mensual: sin cambio (factor 1)', () async {
      await db.gastosFijosDao.insertGastoFijo(
        _gasto(monto: 800000, frecuencia: 'mensual'),
      );

      final total = await db.gastosFijosDao.watchTotalMensualizado().first;

      expect(total, 800000);
    });

    test('quincenal: monto ×2 exacto', () async {
      await db.gastosFijosDao.insertGastoFijo(
        _gasto(monto: 250000, frecuencia: 'quincenal'),
      );

      final total = await db.gastosFijosDao.watchTotalMensualizado().first;

      expect(total, 500000);
    });

    test('semanal: monto ×52/12, redondeado una sola vez', () async {
      await db.gastosFijosDao.insertGastoFijo(
        _gasto(monto: 50000, frecuencia: 'semanal'),
      );

      final total = await db.gastosFijosDao.watchTotalMensualizado().first;

      // 50.000 × 52/12 = 216.666,66... → redondea a 216.667
      expect(total, 216667);
    });

    test('gasto inactivo no cuenta', () async {
      await db.gastosFijosDao.insertGastoFijo(
        _gasto(monto: 1000000, frecuencia: 'mensual', activo: false),
      );

      final total = await db.gastosFijosDao.watchTotalMensualizado().first;

      expect(total, 0);
    });

    test(
      'mezcla real: arriendo mensual + gimnasio quincenal + suscripción semanal',
      () async {
        await db.gastosFijosDao.insertGastoFijo(
          _gasto(monto: 1500000, frecuencia: 'mensual', concepto: 'Arriendo'),
        );
        await db.gastosFijosDao.insertGastoFijo(
          _gasto(monto: 60000, frecuencia: 'quincenal', concepto: 'Gimnasio'),
        );
        await db.gastosFijosDao.insertGastoFijo(
          _gasto(monto: 20000, frecuencia: 'semanal', concepto: 'Streaming'),
        );

        final total = await db.gastosFijosDao.watchTotalMensualizado().first;

        // 1.500.000 + (60.000×2) + round(20.000×52/12=86.666,66) = 1.706.667
        expect(total, 1706667);
      },
    );
  });
}
