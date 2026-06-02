import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db/database.dart';
import 'screens/splash_screen.dart';
import 'services/background_worker.dart';
import 'services/crypto_service.dart';
import 'services/notification_service.dart';
import 'theme/theme.dart';

final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.system);

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

  await CryptoService.init();
  await NotificationService.init();
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
    // Escritorio: sin background real, se revisa al abrir (igual que antes).
    unawaited(NotificationService.revisarRecordatorios(db));
  } else if (!kIsWeb && Platform.isAndroid) {
    // Android: la revisión la hace WorkManager en segundo plano cada hora.
    unawaited(registrarWorkerRecordatorios());
  }
  runApp(ValtiqApp(db: db));
}

class ValtiqApp extends StatelessWidget {
  const ValtiqApp({super.key, required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Valtiq',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          locale: const Locale('es', 'CO'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es', 'CO')],
          home: SplashScreen(db: db),
        );
      },
    );
  }
}
