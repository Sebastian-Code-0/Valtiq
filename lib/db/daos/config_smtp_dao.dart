import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../database.dart';
import '../tables.dart';

part 'config_smtp_dao.g.dart';

@DriftAccessor(tables: [ConfigSmtps])
class ConfigSmtpDao extends DatabaseAccessor<AppDatabase>
    with _$ConfigSmtpDaoMixin {
  ConfigSmtpDao(super.db);

  static const int _configId = 1;
  static const String _storageKey = 'valtiq_smtp_password';
  static const _storage = FlutterSecureStorage();

  Future<ConfigSmtp> getConfig() async {
    final existing = await (select(configSmtps)
          ..where((t) => t.id.equals(_configId)))
        .getSingleOrNull();
    if (existing != null) return existing;

    await into(configSmtps).insert(
      const ConfigSmtpsCompanion(id: Value(_configId)),
      mode: InsertMode.insertOrIgnore,
    );
    return (select(configSmtps)..where((t) => t.id.equals(_configId)))
        .getSingle();
  }

  Stream<ConfigSmtp> watchConfig() {
    return (select(configSmtps)..where((t) => t.id.equals(_configId)))
        .watchSingle();
  }

  Future<String?> getPassword() => _storage.read(key: _storageKey);

  Future<void> savePassword(String? password) async {
    if (password == null || password.isEmpty) {
      await _storage.delete(key: _storageKey);
    } else {
      await _storage.write(key: _storageKey, value: password);
    }
  }

  Future<void> guardarConfig({
    required String servidor,
    required int puerto,
    required String usuario,
    String? contrasena,
    required String correoDestino,
    required String nombreRemitente,
    required bool ssl,
    required bool habilitado,
  }) async {
    await getConfig();
    if (contrasena != null) {
      await savePassword(contrasena);
    }
    final tienePass = (await getPassword())?.isNotEmpty ?? false;
    await (update(configSmtps)..where((t) => t.id.equals(_configId))).write(
      ConfigSmtpsCompanion(
        servidor: Value(servidor),
        puerto: Value(puerto),
        usuario: Value(usuario),
        tieneContrasena: Value(tienePass),
        correoDestino: Value(correoDestino),
        nombreRemitente: Value(nombreRemitente),
        ssl: Value(ssl),
        habilitado: Value(habilitado),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }
}
