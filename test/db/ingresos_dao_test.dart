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

    test('ingreso recurrente (mensual) fechado en un mes pasado sigue '
        'contando en el mes consultado — es una fuente continua, no un '
        'evento puntual', () async {
      await db.ingresosDao.insertIngreso(
        _ingreso(monto: 3000000, fecha: DateTime(2025, 1, 10)),
      );

      final total = await db.ingresosDao.watchTotalIngresosMes(2026, 6).first;

      expect(total, 3000000);
    });

    test('ingreso "unico" cuenta en el mes de su propia fecha', () async {
      await db.ingresosDao.insertIngreso(
        _ingreso(
          monto: 500000,
          fecha: DateTime(2026, 6, 15),
          frecuencia: 'unico',
        ),
      );

      final total = await db.ingresosDao.watchTotalIngresosMes(2026, 6).first;

      expect(total, 500000);
    });

    test('ingreso "unico" de un mes distinto NO cuenta (el hueco real que '
        'se estaba corrigiendo: antes se sumaba para siempre)', () async {
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
    });

    test('ingreso "unico" de un mes futuro tampoco cuenta todavía', () async {
      await db.ingresosDao.insertIngreso(
        _ingreso(
          monto: 500000,
          fecha: DateTime(2026, 12, 1),
          frecuencia: 'unico',
        ),
      );

      final totalJunio = await db.ingresosDao
          .watchTotalIngresosMes(2026, 6)
          .first;

      expect(totalJunio, 0);
    });

    test('ingreso inactivo no cuenta, ni siendo recurrente ni en su mes '
        'exacto de ser "unico"', () async {
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

      final total = await db.ingresosDao.watchTotalIngresosMes(2026, 6).first;

      expect(total, 0);
    });

    test('mezcla real: salario recurrente + trabajo secundario del mes + '
        'trabajo secundario de un mes pasado (ignorado) = solo los dos '
        'primeros se suman', () async {
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

      final total = await db.ingresosDao.watchTotalIngresosMes(2026, 6).first;

      expect(total, 3800000); // 3.000.000 + 800.000, sin el de abril
    });

    test('frecuencia "quincenal"/"semanal" cuentan siempre (sin filtro de '
        'fecha), igual que mensual — la diferencia real es el prorrateo, no '
        'si cuentan', () async {
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

      // 700.000×2 (quincenal) + 300.000×52/12 (semanal, redondeado)
      expect(total, 1400000 + 1300000);
    });

    group('prorrateo por frecuencia (monto es POR PERÍODO, no ya mensual)', () {
      test('quincenal: monto ×2 exacto', () async {
        await db.ingresosDao.insertIngreso(
          _ingreso(
            monto: 500000,
            fecha: DateTime(2024, 1, 1),
            frecuencia: 'quincenal',
          ),
        );

        final total = await db.ingresosDao.watchTotalIngresosMes(2026, 6).first;

        expect(total, 1000000);
      });

      test('semanal: monto ×52/12, redondeado una sola vez', () async {
        await db.ingresosDao.insertIngreso(
          _ingreso(
            monto: 100000,
            fecha: DateTime(2024, 1, 1),
            frecuencia: 'semanal',
          ),
        );

        final total = await db.ingresosDao.watchTotalIngresosMes(2026, 6).first;

        // 100.000 × 52/12 = 433.333,33... → redondea a 433.333
        expect(total, 433333);
      });

      test('mensual: sin cambio (factor 1)', () async {
        await db.ingresosDao.insertIngreso(
          _ingreso(
            monto: 2000000,
            fecha: DateTime(2024, 1, 1),
            frecuencia: 'mensual',
          ),
        );

        final total = await db.ingresosDao.watchTotalIngresosMes(2026, 6).first;

        expect(total, 2000000);
      });

      test('unico NUNCA se prorratea, aunque el factor de otra frecuencia '
          'sería distinto de 1 — cuenta tal cual, solo en su mes', () async {
        await db.ingresosDao.insertIngreso(
          _ingreso(
            monto: 500000,
            fecha: DateTime(2026, 6, 15),
            frecuencia: 'unico',
          ),
        );

        final total = await db.ingresosDao.watchTotalIngresosMes(2026, 6).first;

        expect(total, 500000);
      });

      test(
        'mezcla real: salario mensual + trabajo quincenal + freelance '
        'único del mes — los tres se suman con su propio tratamiento',
        () async {
          await db.ingresosDao.insertIngreso(
            _ingreso(
              monto: 2000000,
              fecha: DateTime(2024, 1, 1),
              frecuencia: 'mensual',
              concepto: 'Salario',
            ),
          );
          await db.ingresosDao.insertIngreso(
            _ingreso(
              monto: 400000,
              fecha: DateTime(2024, 1, 1),
              frecuencia: 'quincenal',
              concepto: 'Trabajo quincenal',
            ),
          );
          await db.ingresosDao.insertIngreso(
            _ingreso(
              monto: 300000,
              fecha: DateTime(2026, 6, 10),
              frecuencia: 'unico',
              concepto: 'Freelance junio',
            ),
          );

          final total = await db.ingresosDao
              .watchTotalIngresosMes(2026, 6)
              .first;

          // 2.000.000 + (400.000×2) + 300.000 = 3.100.000
          expect(total, 3100000);
        },
      );
    });
  });

  group('IngresosDao.getUnicosVencidos / desactivarVarios', () {
    test('unico de un mes pasado y activo → aparece como vencido', () async {
      await db.ingresosDao.insertIngreso(
        _ingreso(
          monto: 300000,
          fecha: DateTime(2026, 3, 15),
          frecuencia: 'unico',
        ),
      );

      final vencidos = await db.ingresosDao.getUnicosVencidos(
        DateTime.utc(2026, 6, 1),
      );

      expect(vencidos.length, 1);
      expect(vencidos.first.monto, 300000);
    });

    test('unico del mes actual → NO aparece (todavía no venció)', () async {
      await db.ingresosDao.insertIngreso(
        _ingreso(
          monto: 300000,
          fecha: DateTime(2026, 6, 15),
          frecuencia: 'unico',
        ),
      );

      final vencidos = await db.ingresosDao.getUnicosVencidos(
        DateTime.utc(2026, 6, 1),
      );

      expect(vencidos, isEmpty);
    });

    test('unico de un mes futuro → NO aparece', () async {
      await db.ingresosDao.insertIngreso(
        _ingreso(
          monto: 300000,
          fecha: DateTime(2026, 12, 1),
          frecuencia: 'unico',
        ),
      );

      final vencidos = await db.ingresosDao.getUnicosVencidos(
        DateTime.utc(2026, 6, 1),
      );

      expect(vencidos, isEmpty);
    });

    test(
      'unico de un mes pasado pero ya inactivo → NO aparece de nuevo',
      () async {
        await db.ingresosDao.insertIngreso(
          _ingreso(
            monto: 300000,
            fecha: DateTime(2026, 3, 15),
            frecuencia: 'unico',
            activo: false,
          ),
        );

        final vencidos = await db.ingresosDao.getUnicosVencidos(
          DateTime.utc(2026, 6, 1),
        );

        expect(vencidos, isEmpty);
      },
    );

    test('recurrente (mensual) de un mes pasado → nunca "vence"', () async {
      await db.ingresosDao.insertIngreso(
        _ingreso(
          monto: 2000000,
          fecha: DateTime(2020, 1, 1),
          frecuencia: 'mensual',
        ),
      );

      final vencidos = await db.ingresosDao.getUnicosVencidos(
        DateTime.utc(2026, 6, 1),
      );

      expect(vencidos, isEmpty);
    });

    test('desactivarVarios apaga los ids dados, sin tocar los demás', () async {
      final id1 = await db.ingresosDao.insertIngreso(
        _ingreso(
          monto: 100000,
          fecha: DateTime(2026, 3, 15),
          frecuencia: 'unico',
        ),
      );
      final id2 = await db.ingresosDao.insertIngreso(
        _ingreso(
          monto: 200000,
          fecha: DateTime(2026, 1, 1),
          frecuencia: 'mensual',
        ),
      );

      await db.ingresosDao.desactivarVarios([id1]);

      final ing1 = await db.ingresosDao.getIngresoById(id1);
      final ing2 = await db.ingresosDao.getIngresoById(id2);
      expect(ing1!.activo, false);
      expect(ing2!.activo, true);
    });

    test('desactivarVarios con lista vacía no lanza excepción', () async {
      await db.ingresosDao.desactivarVarios([]);
    });
  });
}
