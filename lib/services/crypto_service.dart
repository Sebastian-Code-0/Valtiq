import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract class CryptoService {
  static enc.Encrypter? _encrypter;

  /// True si en este arranque se detectó una clave corrupta y se generó una
  /// nueva (por lo tanto, cualquier dato cifrado con la clave anterior ya no
  /// es legible).
  static bool claveFueRegenerada = false;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final keyFile = File(p.join(dir.path, 'valtiq_key.bin'));

    Uint8List keyBytes;
    if (await keyFile.exists()) {
      keyBytes = await keyFile.readAsBytes();
      if (keyBytes.length != 32) {
        debugPrint(
          'CryptoService.init: clave corrupta detectada (tamaño inválido), '
          'se generó una nueva. Los datos cifrados con la clave anterior ya '
          'no serán legibles.',
        );
        claveFueRegenerada = true;
        keyBytes = _generateKey();
        await keyFile.writeAsBytes(keyBytes, flush: true);
      }
    } else {
      keyBytes = _generateKey();
      await keyFile.writeAsBytes(keyBytes, flush: true);
    }

    _encrypter = enc.Encrypter(
      enc.AES(enc.Key(keyBytes), mode: enc.AESMode.gcm),
    );
  }

  static Uint8List _generateKey() {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
  }

  static String encrypt(String plaintext) {
    assert(_encrypter != null, 'CryptoService.init() must be called before encrypt()');
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
