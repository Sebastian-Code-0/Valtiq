import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract class CryptoService {
  static enc.Encrypter? _encrypter;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final keyFile = File(p.join(dir.path, 'valtiq_key.bin'));

    Uint8List keyBytes;
    if (await keyFile.exists()) {
      keyBytes = await keyFile.readAsBytes();
      if (keyBytes.length != 32) {
        keyBytes = _generateKey();
        await keyFile.writeAsBytes(keyBytes, flush: true);
      }
    } else {
      keyBytes = _generateKey();
      await keyFile.writeAsBytes(keyBytes, flush: true);
    }

    _encrypter = enc.Encrypter(enc.AES(enc.Key(keyBytes)));
  }

  static Uint8List _generateKey() {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
  }

  static String encrypt(String plaintext) {
    assert(_encrypter != null, 'CryptoService.init() must be called before encrypt()');
    if (plaintext.isEmpty) return '';
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = _encrypter!.encrypt(plaintext, iv: iv);
    return '${base64.encode(iv.bytes)}:${encrypted.base64}';
  }

  static String decrypt(String ciphertext) {
    if (_encrypter == null || ciphertext.isEmpty) return '';
    try {
      final parts = ciphertext.split(':');
      if (parts.length != 2) return '';
      final iv = enc.IV(base64.decode(parts[0]));
      return _encrypter!.decrypt64(parts[1], iv: iv);
    } catch (_) {
      return '';
    }
  }
}
