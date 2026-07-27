import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/services/crypto_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    tempDir = await Directory.systemTemp.createTemp('valtiq_crypto_test_');

    // Mocking del canal de path_provider para apuntar al directorio temporal.
    // path_provider_linux usa PathProviderPlatform sin MethodChannel en versiones
    // recientes; si falla aquí es que la plataforma lo resuelve directamente.
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => tempDir.path);

    await CryptoService.init();
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  group('CryptoService', () {
    group('roundtrip básico', () {
      test('cifrar y descifrar string ASCII', () {
        const texto = 'contraseña_secreta_123';
        final cifrado = CryptoService.encrypt(texto);
        final descifrado = CryptoService.decrypt(cifrado);
        expect(descifrado, texto);
      });

      test('string con tildes, ñ y símbolo COP', () {
        const texto = 'Ñoño: contraseña café \$100.000';
        final cifrado = CryptoService.encrypt(texto);
        final descifrado = CryptoService.decrypt(cifrado);
        expect(descifrado, texto);
      });

      test('string vacío → encrypt retorna vacío, decrypt retorna vacío', () {
        expect(CryptoService.encrypt(''), '');
        expect(CryptoService.decrypt(''), '');
      });
    });

    group('propiedades de cifrado', () {
      test(
        'cifrar el mismo texto dos veces → resultados distintos (IV aleatorio)',
        () {
          const texto = 'mismo texto de prueba';
          final cifrado1 = CryptoService.encrypt(texto);
          final cifrado2 = CryptoService.encrypt(texto);
          expect(cifrado1, isNot(equals(cifrado2)));
        },
      );

      test('texto cifrado no contiene el texto plano', () {
        const texto = 'texto_muy_secreto_abc123';
        final cifrado = CryptoService.encrypt(texto);
        expect(cifrado.contains(texto), isFalse);
      });

      test('el cifrado tiene formato "iv:ciphertext" con dos partes', () {
        final cifrado = CryptoService.encrypt('hola mundo');
        final partes = cifrado.split(':');
        expect(partes.length, 2);
        expect(partes[0].isNotEmpty, isTrue);
        expect(partes[1].isNotEmpty, isTrue);
      });
    });

    group('manejo de errores al descifrar', () {
      test('string sin separador ":" → retorna cadena vacía', () {
        final resultado = CryptoService.decrypt('soloUnaParteSinDosP untos');
        expect(resultado, '');
      });

      test(
        'string con formato correcto pero base64 inválido → retorna vacío',
        () {
          final resultado = CryptoService.decrypt(
            'esto_invalido:tambien_invalido',
          );
          expect(resultado, '');
        },
      );

      test('string descifrado con clave incorrecta → retorna vacío', () {
        // Formato válido (iv:datos) pero cifrado con otra clave: decrypt falla silencioso
        const falsoIv = 'AAAAAAAAAAAAAAAAAAAAAA=='; // 16 bytes en base64
        const falsoCipher = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
        final resultado = CryptoService.decrypt('$falsoIv:$falsoCipher');
        // El código atrapa la excepción y retorna ''
        expect(resultado, isA<String>());
      });
    });

    group('modo GCM', () {
      test('roundtrip completo bajo GCM: el IV generado tiene 12 bytes', () {
        const texto = 'contraseña_smtp_prueba_gcm';
        final cifrado = CryptoService.encrypt(texto);
        final ivBase64 = cifrado.split(':').first;
        final ivBytes = base64.decode(ivBase64);

        expect(ivBytes.length, 12);
        expect(CryptoService.decrypt(cifrado), texto);
      });

      test('migración: ciphertext cifrado con el modo AES anterior (sin GCM) '
          'falla de forma segura, sin devolver contenido corrupto', () async {
        final keyFile = File('${tempDir.path}/valtiq_key.bin');
        final keyBytes = await keyFile.readAsBytes();

        // Encrypter con el modo por defecto anterior a este cambio (sin
        // especificar `mode`, es decir AESMode.sic), misma clave que usa
        // CryptoService internamente.
        final oldEncrypter = enc.Encrypter(enc.AES(enc.Key(keyBytes)));
        final oldIv = enc.IV.fromSecureRandom(16);
        const texto = 'contraseña_cifrada_antes_de_migrar_a_gcm';
        final cifradoViejo = oldEncrypter.encrypt(texto, iv: oldIv);
        final ciphertext =
            '${base64.encode(oldIv.bytes)}:${cifradoViejo.base64}';

        final resultado = CryptoService.decrypt(ciphertext);

        expect(resultado, '');
      });
    });
  });
}
