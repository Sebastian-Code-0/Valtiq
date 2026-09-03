import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

IngresosCompanion _ingreso({
  required int monto,
  required DateTime fecha,
  String frecuencia = 'mensual',
  String concepto = 'Test',
  bool activo = true,
}) => IngresosCompanion(
  concepto: Value(concepto),
  monto: Value(monto),
  frecuencia: Value(frecuencia),
  fecha: Value(fecha),
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

  group('IngresosDao.watchTotalIngresosMes', () {
    test('BD vacía → emite 0', () async {
      final total = await db.ingresosDao.watchTotalIngresosMes(2026, 6).first;

      expect(total, 0);
    });

    test(
      'ingreso recurrente (mensual) fechado en un mes pasado sigue '
      'contando en el mes consultado — es una fuente continua, no un '
      'evento puntual',
      () async {
        await db.ingresosDao.insertIngreso(
          _ingreso(monto: 3000000, fecha: DateTime(2025, 1, 10)),
        );

        final total = await db.ingresosDao
            .watchTotalIngresosMes(2026, 6)
            .first;

        expect(total, 3000000);
      },
    );

    test(
      'ingreso "unico" cuenta en el mes de su propia fecha',
      () async {
        await db.ingresosDao.insertIngreso(
          _ingreso(
            monto: 500000,
            fecha: DateTime(2026, 6, 15),
            frecuencia: 'unico',
          ),
        );

        final total = await db.ingresosDao
            .watchTotalIngresosMes(2026, 6)
            .first;

        expect(total, 500000);
      },
    );

    test(
      'ingreso "unico" de un mes distinto NO cuenta (el hueco real que '
      'se estaba corrigiendo: antes se sumaba para siempre)',
      () async {
        await db.ingresosDao.insertIngreso(
          _ingreso(
            monto: 500000,
            fecha: DateTime(2026, 3, 15),
            frecuencia: 'unico',
          ),
        );

        final totalJunio = await db.ingresosDao
            .watchTotalIngresosMes(2026, 6)
            .first;

        expect(totalJunio, 0);
      },
    );

    test('ingreso "unico" de un mes futuro tampoco cuenta todavía', () async {
      await db.ingresosDao.insertIngreso(
        _ingreso(
          monto: 500000,
          fecha: DateTime(2026, 12, 1),
          frecuencia: 'unico',
        ),
      );

      final totalJunio = await db.ingresosDao.watchTotalIngresosMes(2026, 6).first;

      expect(totalJunio, 0);
    });

    test(
      'ingreso inactivo no cuenta, ni siendo recurrente ni en su mes '
      'exacto de ser "unico"',
      () async {
        await db.ingresosDao.insertIngreso(
          _ingreso(monto: 1000000, fecha: DateTime(2020, 1, 1), activo: false),
        );
        await db.ingresosDao.insertIngreso(
          _ingreso(
            monto: 500000,
            fecha: DateTime(2026, 6, 15),
            frecuencia: 'unico',
            activo: false,
          ),
        );

        final total = await db.ingresosDao
            .watchTotalIngresosMes(2026, 6)
            .first;

        expect(total, 0);
      },
    );

    test(
      'mezcla real: salario recurrente + trabajo secundario del mes + '
      'trabajo secundario de un mes pasado (ignorado) = solo los dos '
      'primeros se suman',
      () async {
        await db.ingresosDao.insertIngreso(
          _ingreso(
            monto: 3000000,
            fecha: DateTime(2025, 1, 1),
            frecuencia: 'mensual',
            concepto: 'Salario',
          ),
        );
        await db.ingresosDao.insertIngreso(
          _ingreso(
            monto: 800000,
            fecha: DateTime(2026, 6, 20),
            frecuencia: 'unico',
            concepto: 'Freelance junio',
          ),
        );
        await db.ingresosDao.insertIngreso(
          _ingreso(
            monto: 1200000,
            fecha: DateTime(2026, 4, 5),
            frecuencia: 'unico',
            concepto: 'Freelance abril (viejo)',
          ),
        );

        final total = await db.ingresosDao
            .watchTotalIngresosMes(2026, 6)
            .first;

        expect(total, 3800000); // 3.000.000 + 800.000, sin el de abril
      },
    );

    test('frecuencia "quincenal"/"semanal" se tratan igual que recurrente', () async {
      await db.ingresosDao.insertIngreso(
        _ingreso(
          monto: 700000,
          fecha: DateTime(2024, 1, 1),
          frecuencia: 'quincenal',
        ),
      );
      await db.ingresosDao.insertIngreso(
        _ingreso(
          monto: 300000,
          fecha: DateTime(2024, 1, 1),
          frecuencia: 'semanal',
        ),
      );

      final total = await db.ingresosDao.watchTotalIngresosMes(2026, 6).first;

      expect(total, 1000000);
    });
  });
}
