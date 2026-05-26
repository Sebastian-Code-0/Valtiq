import 'package:drift/drift.dart';

import 'connection.dart' as conn;
import 'daos/config_smtp_dao.dart';
import 'daos/deudas_dao.dart';
import 'daos/gastos_fijos_dao.dart';
import 'daos/ingresos_dao.dart';
import 'daos/prestamos_dao.dart';
import 'daos/recordatorios_dao.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Deudas,
    Prestamos,
    PagosRecibidos,
    Ingresos,
    GastosFijos,
    Recordatorios,
    ConfigSmtps,
  ],
  daos: [
    DeudasDao,
    PrestamosDao,
    IngresosDao,
    GastosFijosDao,
    RecordatoriosDao,
    ConfigSmtpDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static QueryExecutor openConnection() => conn.openValtiqConnection();

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(configSmtps).insert(
        const ConfigSmtpsCompanion(id: Value(1)),
        mode: InsertMode.insertOrIgnore,
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(configSmtps);
        await into(configSmtps).insert(
          const ConfigSmtpsCompanion(id: Value(1)),
          mode: InsertMode.insertOrIgnore,
        );
      }
    },
  );
}
