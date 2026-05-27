import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db/database.dart';
import 'screens/splash_screen.dart';
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

  await NotificationService.init();
  unawaited(NotificationService.revisarRecordatorios(db));
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
          home: SplashScreen(db: db),
        );
      },
    );
  }
}
