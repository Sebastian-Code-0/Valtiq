import 'package:flutter/material.dart';

import 'db/database.dart';
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
      home: const _PantallaPlaceholder(),
    );
  }
}

class _PantallaPlaceholder extends StatelessWidget {
  const _PantallaPlaceholder();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorSecundario = isDark
        ? AppColors.textoSecundarioOscuro
        : AppColors.textoSecundarioClaro;

    return Scaffold(
      appBar: AppBar(title: const Text('Valtiq')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 96,
              color: AppColors.acento,
            ),
            const SizedBox(height: 16),
            Text('Valtiq', style: textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Tu control financiero personal',
              style: textTheme.bodyLarge?.copyWith(color: colorSecundario),
            ),
            const SizedBox(height: 32),
            Text(
              'Base de datos conectada ✓',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.positivo),
            ),
          ],
        ),
      ),
    );
  }
}
