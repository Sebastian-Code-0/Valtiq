import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';

class DeudasScreen extends StatelessWidget {
  const DeudasScreen({super.key, required this.db});

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
                    'Deudas',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  FloatingActionButton.small(
                    heroTag: 'fab_deudas',
                    onPressed: () {},
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'No tienes deudas registradas',
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
