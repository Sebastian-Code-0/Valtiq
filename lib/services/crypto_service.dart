import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract class CryptoService {
  static enc.Encrypter? _encrypter;

  /// True si en este arranque se detectó una clave corrupta o no se pudo
  /// migrar la clave existente (por lo tanto, cualquier dato cifrado con la
  /// clave anterior ya no es legible). Se pone en `true` para CUALQUIER caso
  /// donde había evidencia de una clave previa real que se perdió — no solo
  /// cuando la clave encontrada tenía tamaño inválido — para que la UI (ver
  /// ShellScreen) pueda avisarle al usuario en vez de dejarlo enterarse por
  /// un envío de correo fallido en silencio.
  static bool claveFueRegenerada = false;

  static const _secureStorageKeyName = 'valtiq_aes_key';
  static const _secureStorage = FlutterSecureStorage();

  /// Sobreescribible en tests: `Platform.isAndroid`/`isIOS` reflejan el
  /// host real que corre `flutter test` (Linux/Mac/Windows), así que sin
  /// esto la rama de almacén seguro sería imposible de ejercitar en un test
  /// automatizado. En producción siempre usa el valor real de la plataforma.
  @visibleForTesting
  static bool Function() usaAlmacenSeguroOverride = () =>
      Platform.isAndroid || Platform.isIOS;

  /// Android/iOS respaldan la clave en Keystore/Keychain (con soporte
  /// hardware). En Linux/Windows no hay keystore de escritorio confiable
  /// (el backend de keyring puede no estar desbloqueado o instalado), así
  /// que ahí se mantiene el archivo plano junto a la DB como fallback.
  static bool get _usaAlmacenSeguro => usaAlmacenSeguroOverride();

  static Future<void> init() async {
    final keyBytes = _usaAlmacenSeguro
        ? await _initAlmacenSeguro()
        : await _initArchivo();

    _encrypter = enc.Encrypter(
      enc.AES(enc.Key(keyBytes), mode: enc.AESMode.gcm),
    );
  }

  static Future<Uint8List> _initArchivo() async {
    final dir = await getApplicationSupportDirectory();
    final keyFile = File(p.join(dir.path, 'valtiq_key.bin'));

    if (await keyFile.exists()) {
      final keyBytes = await keyFile.readAsBytes();
      if (keyBytes.length == 32) return keyBytes;
      debugPrint(
        'CryptoService.init: clave corrupta detectada (tamaño inválido), '
        'se generó una nueva. Los datos cifrados con la clave anterior ya '
        'no serán legibles.',
      );
      claveFueRegenerada = true;
    }
    final nuevaClave = _generateKey();
    await keyFile.writeAsBytes(nuevaClave, flush: true);
    return nuevaClave;
  }

  static Future<Uint8List> _initAlmacenSeguro() async {
    final existente = await _secureStorage.read(key: _secureStorageKeyName);
    if (existente != null) {
      final keyBytes = base64.decode(existente);
      if (keyBytes.length == 32) return keyBytes;
      debugPrint(
        'CryptoService.init: clave corrupta detectada en almacén seguro '
        '(tamaño inválido), se generó una nueva. Los datos cifrados con la '
        'clave anterior ya no serán legibles.',
      );
      claveFueRegenerada = true;
    } else {
      // Instalación previa a este cambio: la clave puede seguir en el
      // archivo plano que se usaba antes de adoptar Keystore/Keychain.
      final migracion = await _migrarClaveDesdeArchivo();
      final clave = migracion.clave;
      if (clave != null) {
        await _secureStorage.write(
          key: _secureStorageKeyName,
          value: base64.encode(clave),
        );
        return clave;
      }
      // habiaArchivoPrevio distingue "instalación nueva, nunca hubo archivo"
      // (no hace falta avisar) de "el archivo existía pero no se pudo leer o
      // estaba corrupto" (sí hace falta avisar: antes esto se perdía
      // silenciosamente porque solo se marcaba claveFueRegenerada cuando la
      // clave del almacén seguro YA existía y estaba corrupta, nunca cuando
      // fallaba la migración desde el archivo viejo).
      if (migracion.habiaArchivoPrevio) {
        debugPrint(
          'CryptoService.init: no se pudo migrar valtiq_key.bin al almacén '
          'seguro (corrupto o inaccesible), se generó una clave nueva. Los '
          'datos cifrados con la clave anterior ya no serán legibles.',
        );
        claveFueRegenerada = true;
      }
    }
    final nuevaClave = _generateKey();
    await _secureStorage.write(
      key: _secureStorageKeyName,
      value: base64.encode(nuevaClave),
    );
    return nuevaClave;
  }

  /// Lee la clave del esquema de archivo plano usado antes de este cambio
  /// (solo aplicable a Android, la única plataforma móvil que ya existía) y
  /// borra el archivo una vez migrada. Nunca lanza.
  static Future<({Uint8List? clave, bool habiaArchivoPrevio})>
  _migrarClaveDesdeArchivo() async {
    try {
      final dir = Platform.isAndroid
          ? await getApplicationDocumentsDirectory()
          : await getApplicationSupportDirectory();
      final keyFile = File(p.join(dir.path, 'valtiq_key.bin'));
      if (!await keyFile.exists()) {
        return (clave: null, habiaArchivoPrevio: false);
      }
      final keyBytes = await keyFile.readAsBytes();
      if (keyBytes.length != 32) {
        return (clave: null, habiaArchivoPrevio: true);
      }
      await keyFile.delete();
      return (clave: keyBytes, habiaArchivoPrevio: true);
    } catch (_) {
      // No se puede saber con certeza si el archivo existía (el error puede
      // venir de exists()/readAsBytes()/delete()), así que se asume que sí
      // para no ocultarle al usuario una posible pérdida de su clave real.
      return (clave: null, habiaArchivoPrevio: true);
    }
  }

  static Uint8List _generateKey() {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
  }

  static String encrypt(String plaintext) {
    assert(
      _encrypter != null,
      'CryptoService.init() must be called before encrypt()',
    );
    if (plaintext.isEmpty) return '';
    final iv = enc.IV.fromSecureRandom(12);
    final encrypted = _encrypter!.encrypt(plaintext, iv: iv);
    return '${base64.encode(iv.bytes)}:${encrypted.base64}';
  }

  static String decrypt(String ciphertext) {
    if (_encrypter == null) {
      debugPrint(
        'CryptoService.decrypt: CryptoService.init() no fue llamado antes '
        'de decrypt().',
      );
      return '';
    }
    if (ciphertext.isEmpty) return '';
    try {
      final parts = ciphertext.split(':');
      if (parts.length != 2) {
        debugPrint(
          'CryptoService.decrypt: descifrado fallido (ciphertext con '
          'formato inválido).',
        );
        return '';
      }
      final iv = enc.IV(base64.decode(parts[0]));
      return _encrypter!.decrypt64(parts[1], iv: iv);
    } catch (_) {
      debugPrint(
        'CryptoService.decrypt: descifrado fallido (ciphertext corrupto o '
        'cifrado con una clave/formato distinto).',
      );
      return '';
    }
  }
}
