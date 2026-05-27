import 'dart:convert';

import 'package:encrypt/encrypt.dart' as enc;

abstract class CryptoService {
  static final _key = enc.Key.fromUtf8('valtiq_2024_smtp_32_bytes_key!!!');
  static final _encrypter = enc.Encrypter(enc.AES(_key));

  static String encrypt(String plaintext) {
    if (plaintext.isEmpty) return '';
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plaintext, iv: iv);
    return '${base64.encode(iv.bytes)}:${encrypted.base64}';
  }

  static String decrypt(String ciphertext) {
    if (ciphertext.isEmpty) return '';
    try {
      final parts = ciphertext.split(':');
      if (parts.length != 2) return '';
      final iv = enc.IV(base64.decode(parts[0]));
      return _encrypter.decrypt64(parts[1], iv: iv);
    } catch (_) {
      return '';
    }
  }
}
