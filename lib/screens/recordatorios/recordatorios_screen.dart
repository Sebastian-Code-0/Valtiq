import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';

class RecordatoriosScreen extends StatelessWidget {
  const RecordatoriosScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorSec = isDark
        ? AppColors.textoSecundarioOscuro
        : AppColors.textoSecundarioClaro;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    'Recordatorios',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  FloatingActionButton.small(
                    heroTag: 'fab_recordatorios',
                    onPressed: () {},
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'No tienes recordatorios',
                  style: theme.textTheme.bodyLarge?.copyWith(color: colorSec),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
