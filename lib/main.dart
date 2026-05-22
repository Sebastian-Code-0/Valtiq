import 'package:flutter/material.dart';

import 'db/database.dart';
import 'screens/shell.dart';
import 'theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase(AppDatabase.openConnection());
  runApp(ValtiqApp(db: db));
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
