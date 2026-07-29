import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';

/// Pattern visivo unificato per gli stati vuoti nelle schermate principali.
///
/// Mostra icona tenue + titolo + sottotitolo con superficie panel coerente.
/// Sostituisce il testo nudo nei casi empty delle sezioni.
///
/// Esempio:
/// ```dart
/// EmptyStatePanel(
///   icon: Icons.notifications_none_outlined,
///   title: 'Nessuna notifica',
///   subtitle: 'Le novità dalla community appariranno qui.',
/// )
/// ```
class EmptyStatePanel extends StatelessWidget {
  const EmptyStatePanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
    super.key,
  });

  /// Icona decorativa (dimensione ridotta, colore tenue).
  final IconData icon;

  /// Titolo breve, in stile titleMedium.
  final String title;

  /// Sottotitolo descrittivo, in stile bodyMedium.
  final String subtitle;

  /// Se `true`, riduce il padding per contesti compatti (sezioni, card interne).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padding = compact
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          )
        : const EdgeInsets.all(AppSpacing.xxl);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 32 : 48,
            color: AppColors.concrete,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.steel,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
