import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Pannello placeholder generico per sezioni in costruzione o non disponibili.
///
/// Per stati vuoti con icona usa [EmptyStatePanel] in shared/widgets.
class PlaceholderPanel extends StatelessWidget {
  const PlaceholderPanel({
    required this.title,
    required this.body,
    this.icon,
    super.key,
  });

  final String title;
  final String body;

  /// Icona opzionale tenue sopra il titolo.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 32, color: AppColors.concrete),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.steel,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
