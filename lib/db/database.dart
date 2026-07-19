import 'package:drift/drift.dart';

import 'connection.dart' as conn;
import 'daos/config_smtp_dao.dart';
import 'daos/deudas_dao.dart';
import 'daos/gastos_fijos_dao.dart';
import 'daos/ingresos_dao.dart';
import 'daos/pagos_deuda_dao.dart';
import 'daos/prestamos_dao.dart';
import 'daos/gastos_variables_dao.dart';
import 'daos/recordatorios_dao.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Deudas,
    PagosDeuda,
    Prestamos,
    PagosRecibidos,
    Ingresos,
    GastosFijos,
    Recordatorios,
    ConfigSmtps,
    GastosVariables,
  ],
  daos: [
    DeudasDao,
    PagosDeudaDao,
    PrestamosDao,
    IngresosDao,
    GastosFijosDao,
    RecordatoriosDao,
    ConfigSmtpDao,
    GastosVariablesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static QueryExecutor openConnection() => conn.openValtiqConnection();

  @override
  int get schemaVersion => 8;

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
      if (from < 3) {
        await m.alterTable(
          TableMigration(
            configSmtps,
            columnTransformer: {
              configSmtps.tieneContrasena: const CustomExpression(
                "CASE WHEN contrasena != '' THEN 1 ELSE 0 END",
              ),
            },
          ),
        );
        await m.createTable(pagosDeuda);
      }
      if (from < 4) {
        await m.addColumn(configSmtps, configSmtps.contrasenaEncriptada);
      }
      if (from < 5) {
        await m.addColumn(recordatorios, recordatorios.frecuenciaAviso);
        await m.addColumn(recordatorios, recordatorios.ultimaNotificacion);
        await m.addColumn(recordatorios, recordatorios.ultimoEnvioCorreo);
      }
      if (from < 6) {
        await m.addColumn(recordatorios, recordatorios.horaAviso);
        await m.addColumn(recordatorios, recordatorios.minutoAviso);
      }
      if (from < 7) {
        await m.createTable(gastosVariables);
      }
      if (from < 8) {
        await m.addColumn(deudas, deudas.modalidadCalculo);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
