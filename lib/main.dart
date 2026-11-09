import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db/database.dart';
import 'screens/lock/app_lock_overlay.dart';
import 'screens/splash_screen.dart';
import 'services/app_lock_service.dart';
import 'services/crypto_service.dart';
import 'services/notification_service.dart';
import 'theme/theme.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.system,
);

final ValueNotifier<Color> acentoNotifier = ValueNotifier(AppColors.acento);

/// Falso mientras la app está bloqueada esperando PIN/biometría. `main()`
/// lo pone en `false` antes de `runApp` si arranca bloqueada;
/// `AppLockOverlay` lo pone en `true` al desbloquear. `ShellScreen` lo usa
/// para no mostrar avisos (diálogos/SnackBars con info real, ej. "se perdió
/// la config SMTP" o "se desactivaron N ingresos") hasta que la app esté
/// realmente desbloqueada — `ShellScreen` monta igual aunque el bloqueo
/// esté activo (el bloqueo es solo un overlay visual encima, no pausa la
/// navegación de `SplashScreen`), así que sin este chequeo esos avisos se
/// dispararían mientras la pantalla de bloqueo todavía está tapando todo:
/// un hueco de seguridad real, no solo cosmético — información real
/// quedaría lista/mostrándose antes de que alguien probara el PIN.
final ValueNotifier<bool> appDesbloqueadaNotifier = ValueNotifier(true);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase(AppDatabase.openConnection());

  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('valtiq_theme');
  if (saved == 'light') {
    themeModeNotifier.value = ThemeMode.light;
  } else if (saved == 'dark') {
    themeModeNotifier.value = ThemeMode.dark;
  }

  final savedAcento = prefs.getString('valtiq_acento');
  if (savedAcento != null) {
    final value = int.tryParse(savedAcento, radix: 16);
    if (value != null) acentoNotifier.value = Color(value);
  }

  await CryptoService.init();
  await NotificationService.init();
  unawaited(NotificationService.revisarRecordatorios(db));
  unawaited(NotificationService.revisarIngresosUnicosVencidos(db));

  // Cargado ANTES de runApp (misma convención que theme/acento arriba) para
  // que el primer frame ya sepa si debe arrancar bloqueada — evita mostrar
  // contenido real sin proteger mientras se resuelve un Future async. Barato
  // acá: SharedPreferences.getInstance() ya está en caché por el `prefs` de
  // arriba, así que este await no agrega I/O real.
  final bloqueoInicial = await AppLockService.bloqueoActivo();
  if (bloqueoInicial) appDesbloqueadaNotifier.value = false;

  runApp(ValtiqApp(db: db, bloqueoInicial: bloqueoInicial));

  // Después de runApp: en Android 13+ esto espera la respuesta real del
  // diálogo nativo de permisos. Si corriera antes de runApp (como hacía
  // NotificationService.init() antes), el primer frame de la app quedaría
  // bloqueado hasta que el usuario decida — así la app ya se ve mientras
  // el diálogo aparece encima.
  unawaited(NotificationService.solicitarPermisoNotificaciones());
}

class ValtiqApp extends StatelessWidget {
  const ValtiqApp({super.key, required this.db, required this.bloqueoInicial});

  final AppDatabase db;
  final bool bloqueoInicial;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return ValueListenableBuilder<Color>(
          valueListenable: acentoNotifier,
          builder: (context, acento, _) {
            return MaterialApp(
              title: 'Valtiq',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(acento),
              darkTheme: AppTheme.dark(acento),
              themeMode: mode,
              locale: const Locale('es', 'CO'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('es', 'CO')],
              home: SplashScreen(db: db),
              builder: (context, child) => AppLockOverlay(
                initiallyLocked: bloqueoInicial,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }
}
