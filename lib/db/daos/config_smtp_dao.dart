import 'package:drift/drift.dart';

import '../../services/crypto_service.dart';
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

  Future<String?> getPassword() async {
    final config = await getConfig();
    final enc = config.contrasenaEncriptada;
    if (enc == null || enc.isEmpty) return null;
    final decrypted = CryptoService.decrypt(enc);
    if (decrypted.isEmpty) {
      await (update(configSmtps)..where((t) => t.id.equals(_configId))).write(
        const ConfigSmtpsCompanion(
          contrasenaEncriptada: Value(null),
          tieneContrasena: Value(false),
        ),
      );
      return null;
    }
    return decrypted;
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
    await into(configSmtps).insert(
      const ConfigSmtpsCompanion(id: Value(_configId)),
      mode: InsertMode.insertOrIgnore,
    );

    Value<String?> encValue = const Value.absent();
    Value<bool> tienePassValue = const Value.absent();

    if (contrasena != null) {
      if (contrasena.isNotEmpty) {
        encValue = Value(CryptoService.encrypt(contrasena));
        tienePassValue = const Value(true);
      } else {
        encValue = const Value(null);
        tienePassValue = const Value(false);
      }
    }

    await (update(configSmtps)..where((t) => t.id.equals(_configId))).write(
      ConfigSmtpsCompanion(
        servidor: Value(servidor),
        puerto: Value(puerto),
        usuario: Value(usuario),
        contrasenaEncriptada: encValue,
        tieneContrasena: tienePassValue,
        correoDestino: Value(correoDestino),
        nombreRemitente: Value(nombreRemitente),
        ssl: Value(ssl),
        habilitado: Value(habilitado),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }
}
