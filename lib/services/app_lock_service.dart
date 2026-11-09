import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bloqueo de acceso a la app: PIN propio (hash+salt, nunca en texto plano)
/// como fallback universal en las 3 plataformas, más biometría/PIN del
/// sistema vía `local_auth` donde el SO lo soporte (Android/iOS/Windows —
/// sin soporte oficial en Linux).
///
/// Es un gate de UI: NO cifra ni desbloquea la clave AES real que protege la
/// contraseña SMTP (ver `CryptoService`) — se evaluó atarlo a esa clave y se
/// decidió diferirlo a propósito, para no arriesgar dejar esa configuración
/// inaccesible por un bug de esta primera versión del bloqueo.
abstract class AppLockService {
  static const _kEnabled = 'valtiq_lock_enabled';
  static const _kPinHash = 'valtiq_lock_pin_hash';
  static const _kPinSalt = 'valtiq_lock_pin_salt';
  static const _kUseBiometric = 'valtiq_lock_use_biometric';
  static const _kTimeoutSeconds = 'valtiq_lock_timeout_seconds';

  static const timeoutPorDefecto = Duration(seconds: 30);

  static final LocalAuthentication _localAuth = LocalAuthentication();

  static Future<bool> bloqueoActivo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? false;
  }

  static Future<bool> usaBiometria() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUseBiometric) ?? true;
  }

  static Future<void> setUsaBiometria(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUseBiometric, valor);
  }

  static Future<Duration> timeoutReloqueo() async {
    final prefs = await SharedPreferences.getInstance();
    final segundos =
        prefs.getInt(_kTimeoutSeconds) ?? timeoutPorDefecto.inSeconds;
    return Duration(seconds: segundos);
  }

  static Future<void> setTimeoutReloqueo(Duration d) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTimeoutSeconds, d.inSeconds);
  }

  /// Verdadero solo si el SO soporta biometría/PIN de sistema Y hay al menos
  /// un método enrolado. `local_auth` no tiene implementación en Linux —
  /// cualquier llamada al plugin ahí lanzaría `MissingPluginException`, así
  /// que se descarta la plataforma antes de tocarlo (mismo patrón que
  /// `NotificationService._soportado`).
  static Future<bool> biometriaDisponible() async {
    if (!kIsWeb && Platform.isLinux) return false;
    try {
      final soportado = await _localAuth.isDeviceSupported();
      final puedeChequear = await _localAuth.canCheckBiometrics;
      return soportado && puedeChequear;
    } catch (_) {
      return false;
    }
  }

  /// `biometricOnly: false` deja que el usuario caiga al PIN/patrón del
  /// SISTEMA operativo si falla la huella/rostro — es una segunda capa
  /// además del PIN propio de Valtiq, no un reemplazo.
  static Future<bool> autenticarConBiometria() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Confirma tu identidad para abrir Valtiq',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Activa el bloqueo con un PIN nuevo. Deja `usaBiometria`/timeout en sus
  /// valores por defecto si todavía no existían (primera activación).
  static Future<void> activarConPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _generarSalt();
    final hash = await _hashPin(pin, salt);
    await prefs.setString(_kPinSalt, salt);
    await prefs.setString(_kPinHash, hash);
    await prefs.setBool(_kEnabled, true);
    if (!prefs.containsKey(_kTimeoutSeconds)) {
      await prefs.setInt(_kTimeoutSeconds, timeoutPorDefecto.inSeconds);
    }
    if (!prefs.containsKey(_kUseBiometric)) {
      await prefs.setBool(_kUseBiometric, true);
    }
  }

  static Future<void> desactivar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPinHash);
    await prefs.remove(_kPinSalt);
    await prefs.setBool(_kEnabled, false);
  }

  static Future<bool> verificarPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hashGuardado = prefs.getString(_kPinHash);
    final salt = prefs.getString(_kPinSalt);
    if (hashGuardado == null || salt == null) return false;
    return await _hashPin(pin, salt) == hashGuardado;
  }

  static Future<void> cambiarPin(String pinNuevo) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _generarSalt();
    final hash = await _hashPin(pinNuevo, salt);
    await prefs.setString(_kPinSalt, salt);
    await prefs.setString(_kPinHash, hash);
  }

  static String _generarSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  static Future<String> _hashPin(String pin, String saltBase64) {
    // `compute` corre el hash en un isolate aparte: 10.000 rondas de SHA-256
    // puro-Dart pueden tardar unos cientos de ms, suficiente para notarse
    // como traba de UI si corriera en el isolate principal de la pantalla
    // de bloqueo.
    return compute(_hashPinSync, (pin: pin, saltBase64: saltBase64));
  }
}

// Hash iterado (10.000 rondas de SHA-256 con salt aleatorio de 16 bytes) en
// vez de una librería PBKDF2 dedicada: alcanza para el modelo de amenaza
// real acá (alguien con acceso físico al dispositivo probando PINes a mano,
// no un ataque de fuerza bruta remoto/masivo contra un servicio), sin sumar
// una dependencia nueva solo para esto — `crypto` (sha256) ya es transitiva
// del proyecto. Top-level (no método de instancia/estático con closure)
// porque `compute()` exige una función aislable sin estado capturado.
String _hashPinSync(({String pin, String saltBase64}) args) {
  final salt = base64Decode(args.saltBase64);
  var bytes = [...utf8.encode(args.pin), ...salt];
  for (var i = 0; i < 10000; i++) {
    bytes = sha256.convert(bytes).bytes;
  }
  return base64Encode(bytes);
}
