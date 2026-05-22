import 'package:drift/drift.dart';

import 'connection.dart' as conn;
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
  ],
  daos: [
    DeudasDao,
    PrestamosDao,
    IngresosDao,
    GastosFijosDao,
    RecordatoriosDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static QueryExecutor openConnection() => conn.openValtiqConnection();

  @override
  int get schemaVersion => 1;
}
