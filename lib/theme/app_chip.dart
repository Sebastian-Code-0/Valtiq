import 'package:flutter/material.dart';

import 'app_spacing.dart';

class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AtenuableCard extends StatelessWidget {
  const AtenuableCard({super.key, required this.atenuada, required this.child});

  final bool atenuada;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return atenuada ? Opacity(opacity: 0.6, child: child) : child;
  }
}
