import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/services/app_lock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppLockService', () {
    test('sin configurar → bloqueoActivo es false', () async {
      expect(await AppLockService.bloqueoActivo(), false);
    });

    test('activarConPin deja el bloqueo activo y el PIN verificable', () async {
      await AppLockService.activarConPin('1234');

      expect(await AppLockService.bloqueoActivo(), true);
      expect(await AppLockService.verificarPin('1234'), true);
    });

    test('verificarPin con un PIN incorrecto → false', () async {
      await AppLockService.activarConPin('1234');

      expect(await AppLockService.verificarPin('9999'), false);
    });

    test('verificarPin sin haber activado nunca el bloqueo → false, no lanza', () async {
      expect(await AppLockService.verificarPin('1234'), false);
    });

    test(
      'desactivar borra el hash/salt: bloqueoActivo pasa a false y ningún '
      'PIN anterior vuelve a verificar',
      () async {
        await AppLockService.activarConPin('1234');
        await AppLockService.desactivar();

        expect(await AppLockService.bloqueoActivo(), false);
        expect(await AppLockService.verificarPin('1234'), false);
      },
    );

    test('cambiarPin: el PIN viejo deja de servir, el nuevo sí', () async {
      await AppLockService.activarConPin('1234');
      await AppLockService.cambiarPin('5678');

      expect(await AppLockService.verificarPin('1234'), false);
      expect(await AppLockService.verificarPin('5678'), true);
    });

    test(
      'dos activaciones con el MISMO pin usan salts distintos (el hash '
      'guardado no es determinístico solo por el PIN)',
      () async {
        await AppLockService.activarConPin('1234');
        final prefs1 = await SharedPreferences.getInstance();
        final hash1 = prefs1.getString('valtiq_lock_pin_hash');
        final salt1 = prefs1.getString('valtiq_lock_pin_salt');

        await AppLockService.activarConPin('1234');
        final prefs2 = await SharedPreferences.getInstance();
        final hash2 = prefs2.getString('valtiq_lock_pin_hash');
        final salt2 = prefs2.getString('valtiq_lock_pin_salt');

        expect(salt1, isNot(salt2));
        expect(hash1, isNot(hash2));
        // Pero ambos siguen verificando el mismo PIN real.
        expect(await AppLockService.verificarPin('1234'), true);
      },
    );

    test('timeoutReloqueo por defecto es 30 segundos', () async {
      expect(
        await AppLockService.timeoutReloqueo(),
        const Duration(seconds: 30),
      );
    });

    test('setTimeoutReloqueo persiste el valor elegido', () async {
      await AppLockService.setTimeoutReloqueo(const Duration(minutes: 5));

      expect(
        await AppLockService.timeoutReloqueo(),
        const Duration(minutes: 5),
      );
    });

    test('usaBiometria por defecto es true', () async {
      expect(await AppLockService.usaBiometria(), true);
    });

    test('setUsaBiometria persiste el valor elegido', () async {
      await AppLockService.setUsaBiometria(false);

      expect(await AppLockService.usaBiometria(), false);
    });

    test(
      'biometriaDisponible en Linux siempre es false (local_auth no tiene '
      'implementación ahí) — el test corre sobre Linux, así que esto '
      'verifica la rama de plataforma sin necesitar mockear local_auth',
      () async {
        expect(await AppLockService.biometriaDisponible(), false);
      },
    );
  });
}
