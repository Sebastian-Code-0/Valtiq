import 'package:flutter/material.dart';

import 'db/database.dart';
import 'screens/shell.dart';
import 'services/notification_service.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase(AppDatabase.openConnection());
  await NotificationService.init();
  unawaited(NotificationService.revisarRecordatorios(db));
  runApp(ValtiqApp(db: db));
}

void unawaited(Future<void> future) {
  future.catchError((_) {});
}

class ValtiqApp extends StatelessWidget {
  const ValtiqApp({super.key, required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Valtiq',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: ShellScreen(db: db),
    );
  }
}
