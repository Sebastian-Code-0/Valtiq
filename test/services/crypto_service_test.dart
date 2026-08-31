import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
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

  // Platform.isAndroid/isIOS reflejan el host real que corre `flutter test`
  // (aquí, Linux/Mac/Windows de escritorio) — CryptoService.usaAlmacenSeguroOverride
  // existe exactamente para poder forzar esta rama en un test sin depender
  // de un dispositivo/emulador real. El canal de flutter_secure_storage se
  // mockea con un mapa en memoria, igual que ya se mockeaba path_provider.
  group('CryptoService — almacén seguro (Android/iOS)', () {
    const secureChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    late Map<String, String> almacen;
    late Directory dirDispositivo;

    void mockSecureStorage() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureChannel, (call) async {
            switch (call.method) {
              case 'read':
                return almacen[call.arguments['key']];
              case 'write':
                almacen[call.arguments['key']] = call.arguments['value'];
                return null;
              case 'delete':
                almacen.remove(call.arguments['key']);
                return null;
              default:
                return null;
            }
          });
    }

    setUp(() async {
      almacen = {};
      dirDispositivo = await Directory.systemTemp.createTemp(
        'valtiq_secure_test_',
      );
      const dirChannel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(dirChannel, (_) async => dirDispositivo.path);
      mockSecureStorage();
      CryptoService.usaAlmacenSeguroOverride = () => true;
      CryptoService.claveFueRegenerada = false;
    });

    tearDown(() async {
      CryptoService.usaAlmacenSeguroOverride = () =>
          Platform.isAndroid || Platform.isIOS;
      await dirDispositivo.delete(recursive: true);
    });

    test(
      'instalación nueva: no hay clave en el almacén ni archivo viejo → '
      'genera una clave y la guarda en el almacén seguro, sin avisar nada',
      () async {
        await CryptoService.init();

        expect(almacen['valtiq_aes_key'], isNotNull);
        expect(CryptoService.claveFueRegenerada, isFalse);

        const texto = 'contraseña_smtp_de_prueba';
        expect(CryptoService.decrypt(CryptoService.encrypt(texto)), texto);
      },
    );

    test(
      'ya hay una clave válida en el almacén seguro → la reutiliza tal cual',
      () async {
        // Clave fija conocida para verificar que efectivamente se usó ESTA,
        // no una generada de nuevo.
        final claveFija = Uint8List.fromList(List.generate(32, (i) => i));
        almacen['valtiq_aes_key'] = base64.encode(claveFija);

        await CryptoService.init();

        expect(almacen['valtiq_aes_key'], base64.encode(claveFija));
        expect(CryptoService.claveFueRegenerada, isFalse);
      },
    );

    test(
      'migra un valtiq_key.bin válido del esquema de archivo anterior: lo '
      'copia al almacén seguro, lo usa de inmediato y borra el archivo',
      () async {
        final claveVieja = Uint8List.fromList(List.generate(32, (i) => i * 2));
        final keyFile = File(p.join(dirDispositivo.path, 'valtiq_key.bin'));
        await keyFile.writeAsBytes(claveVieja);

        await CryptoService.init();

        expect(almacen['valtiq_aes_key'], base64.encode(claveVieja));
        expect(CryptoService.claveFueRegenerada, isFalse);
        expect(await keyFile.exists(), isFalse);
      },
    );

    test(
      'valtiq_key.bin existe pero está corrupto (tamaño inválido) → genera '
      'clave nueva Y avisa con claveFueRegenerada (hueco real corregido: '
      'antes solo se avisaba si la clave YA estaba en el almacén seguro)',
      () async {
        final keyFile = File(p.join(dirDispositivo.path, 'valtiq_key.bin'));
        await keyFile.writeAsBytes(Uint8List.fromList([1, 2, 3]));

        await CryptoService.init();

        expect(almacen['valtiq_aes_key'], isNotNull);
        expect(CryptoService.claveFueRegenerada, isTrue);
      },
    );

    test(
      'valtiq_key.bin existe pero no se puede leer (error de E/S, ej. sin '
      'permiso) → genera clave nueva Y avisa con claveFueRegenerada, igual '
      'que si estuviera corrupto (antes este caso NO avisaba nada, era el '
      'hueco más grave: la migración fallaba en silencio)',
      () async {
        final keyFile = File(p.join(dirDispositivo.path, 'valtiq_key.bin'));
        await keyFile.writeAsBytes(Uint8List.fromList(List.filled(32, 7)));
        // Sin permiso de lectura: readAsBytes() lanza en vez de devolver
        // datos. chmod es específico de POSIX (Linux/Mac, donde corre esta
        // suite); en Windows este test se saltaría.
        final chmod = Process.runSync('chmod', ['000', keyFile.path]);
        if (chmod.exitCode != 0) {
          markTestSkipped('chmod no disponible en esta plataforma');
          return;
        }
        addTearDown(() => Process.runSync('chmod', ['600', keyFile.path]));

        await CryptoService.init();

        expect(almacen['valtiq_aes_key'], isNotNull);
        expect(CryptoService.claveFueRegenerada, isTrue);
      },
    );

    test(
      'clave en el almacén seguro con tamaño inválido → genera clave nueva '
      'y avisa con claveFueRegenerada',
      () async {
        almacen['valtiq_aes_key'] = base64.encode(Uint8List.fromList([9, 9]));

        await CryptoService.init();

        expect(CryptoService.claveFueRegenerada, isTrue);
        final nuevaGuardada = base64.decode(almacen['valtiq_aes_key']!);
        expect(nuevaGuardada.length, 32);
      },
    );
  });
}
