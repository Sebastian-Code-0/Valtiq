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

  runApp(ValtiqApp(db: db, bloqueoInicial: bloqueoInicial));
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
