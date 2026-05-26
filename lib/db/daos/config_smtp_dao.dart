import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'config_smtp_dao.g.dart';

@DriftAccessor(tables: [ConfigSmtps])
class ConfigSmtpDao extends DatabaseAccessor<AppDatabase>
    with _$ConfigSmtpDaoMixin {
  ConfigSmtpDao(super.db);

  static const int _configId = 1;

  Future<ConfigSmtp> getConfig() async {
    final existing = await (select(
      configSmtps,
    )..where((t) => t.id.equals(_configId))).getSingleOrNull();
    if (existing != null) return existing;

    await into(configSmtps).insert(
      const ConfigSmtpsCompanion(id: Value(_configId)),
      mode: InsertMode.insertOrIgnore,
    );
    return (select(
      configSmtps,
    )..where((t) => t.id.equals(_configId))).getSingle();
  }

  Stream<ConfigSmtp> watchConfig() {
    return (select(
      configSmtps,
    )..where((t) => t.id.equals(_configId))).watchSingle();
  }

  Future<void> guardarConfig({
    required String servidor,
    required int puerto,
    required String usuario,
    required String contrasena,
    required String correoDestino,
    required String nombreRemitente,
    required bool ssl,
    required bool habilitado,
  }) async {
    await getConfig();
    await (update(configSmtps)..where((t) => t.id.equals(_configId))).write(
      ConfigSmtpsCompanion(
        servidor: Value(servidor),
        puerto: Value(puerto),
        usuario: Value(usuario),
        contrasena: Value(contrasena),
        correoDestino: Value(correoDestino),
        nombreRemitente: Value(nombreRemitente),
        ssl: Value(ssl),
        habilitado: Value(habilitado),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }
}
