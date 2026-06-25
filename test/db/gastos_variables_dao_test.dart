import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

GastosVariablesCompanion _gasto({
  required double monto,
  required DateTime fecha,
  String descripcion = 'Test',
  String categoria = 'General',
}) =>
    GastosVariablesCompanion(
      descripcion: Value(descripcion),
      monto: Value(monto),
      categoria: Value(categoria),
      fecha: Value(fecha),
    );

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createInMemoryDb();
  });

  tearDown(() async {
    await db.close();
  });

  group('GastosVariablesDao', () {
    group('watchGastosVariables', () {
      test('insertar un gasto → aparece en el stream', () async {
        await db.gastosVariablesDao.insertGastoVariable(
          _gasto(monto: 50000, fecha: DateTime(2026, 6, 15)),
        );

        final gastos =
            await db.gastosVariablesDao.watchGastosVariables().first;

        expect(gastos.length, 1);
        expect(gastos.first.monto, 50000.0);
        expect(gastos.first.descripcion, 'Test');
      });

      test('insertar dos gastos → ambos aparecen ordenados por fecha desc',
          () async {
        await db.gastosVariablesDao.insertGastoVariable(
          _gasto(monto: 10000, fecha: DateTime(2026, 6, 10), descripcion: 'A'),
        );
        await db.gastosVariablesDao.insertGastoVariable(
          _gasto(monto: 20000, fecha: DateTime(2026, 6, 15), descripcion: 'B'),
        );

        final gastos =
            await db.gastosVariablesDao.watchGastosVariables().first;

        expect(gastos.length, 2);
        expect(gastos[0].monto, 20000.0); // fecha más reciente primero
        expect(gastos[1].monto, 10000.0);
      });
    });

    group('watchGastosPorMes', () {
      test('gasto del mes correcto aparece, gasto de otro mes no', () async {
        await db.gastosVariablesDao.insertGastoVariable(
          _gasto(monto: 50000, fecha: DateTime(2026, 6, 15)),
        );
        await db.gastosVariablesDao.insertGastoVariable(
          _gasto(monto: 80000, fecha: DateTime(2026, 5, 15)),
        );

        final junio =
            await db.gastosVariablesDao.watchGastosPorMes(2026, 6).first;

        expect(junio.length, 1);
        expect(junio.first.monto, 50000.0);
      });

      test('dos gastos del mismo mes → ambos aparecen', () async {
        await db.gastosVariablesDao.insertGastoVariable(
          _gasto(monto: 30000, fecha: DateTime(2026, 6, 5)),
        );
        await db.gastosVariablesDao.insertGastoVariable(
          _gasto(monto: 70000, fecha: DateTime(2026, 6, 25)),
        );

        final junio =
            await db.gastosVariablesDao.watchGastosPorMes(2026, 6).first;

        expect(junio.length, 2);
      });

      test('mes sin gastos → lista vacía', () async {
        final julio =
            await db.gastosVariablesDao.watchGastosPorMes(2026, 7).first;

        expect(julio, isEmpty);
      });
    });

    group('watchTotalMes', () {
      test('BD vacía → emite 0.0 (fix del bug crítico)', () async {
        final total =
            await db.gastosVariablesDao.watchTotalMes(2026, 6).first;

        expect(total, 0.0);
      });

      test('dos gastos del mismo mes → total es la suma correcta', () async {
        await db.gastosVariablesDao.insertGastoVariable(
          _gasto(monto: 50000, fecha: DateTime(2026, 6, 10)),
        );
        await db.gastosVariablesDao.insertGastoVariable(
          _gasto(monto: 30000, fecha: DateTime(2026, 6, 20)),
        );

        final total =
            await db.gastosVariablesDao.watchTotalMes(2026, 6).first;

        expect(total, closeTo(80000.0, 0.01));
      });

      test('gastos de otro mes no se suman', () async {
        await db.gastosVariablesDao.insertGastoVariable(
          _gasto(monto: 100000, fecha: DateTime(2026, 5, 15)), // mayo
        );

        final totalJunio =
            await db.gastosVariablesDao.watchTotalMes(2026, 6).first;

        expect(totalJunio, 0.0);
      });
    });

    group('deleteGastoVariable', () {
      test('insertar y eliminar → ya no aparece en el stream', () async {
        final id = await db.gastosVariablesDao.insertGastoVariable(
          _gasto(monto: 50000, fecha: DateTime(2026, 6, 15)),
        );
        await db.gastosVariablesDao.deleteGastoVariable(id);

        final gastos =
            await db.gastosVariablesDao.watchGastosVariables().first;

        expect(gastos, isEmpty);
      });

      test('eliminar uno de dos → queda solo el otro', () async {
        final id1 = await db.gastosVariablesDao.insertGastoVariable(
          _gasto(monto: 10000, fecha: DateTime(2026, 6, 10)),
        );
        await db.gastosVariablesDao.insertGastoVariable(
          _gasto(monto: 20000, fecha: DateTime(2026, 6, 15)),
        );
        await db.gastosVariablesDao.deleteGastoVariable(id1);

        final gastos =
            await db.gastosVariablesDao.watchGastosVariables().first;

        expect(gastos.length, 1);
        expect(gastos.first.monto, 20000.0);
      });
    });
  });
}
