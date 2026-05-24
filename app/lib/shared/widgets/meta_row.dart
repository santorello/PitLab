import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Riga di metadati: icona + testo, con trailing text opzionale allineato a destra.
///
/// Usato per visualizzare informazioni strutturate come location, distanza, etc.
///
/// Esempio:
/// ```dart
/// MetaRow(
///   icon: Icons.location_on,
///   text: 'Parma, Italia',
///   trailingText: '1,4 km',
/// )
/// ```
class MetaRow extends StatelessWidget {
  const MetaRow({
    required this.icon,
    required this.text,
    this.trailingText,
    super.key,
  });

  /// Icona a sinistra (size 16).
  final IconData icon;

  /// Testo principale.
  final String text;

  /// Testo opzionale allineato a destra (es. distanza).
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.onSurfaceMuted,
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
          ),
        ),
        if (trailingText != null) ...[
          SizedBox(width: AppSpacing.sm),
          Text(
            trailingText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
          ),
        ],
      ],
    );
  }
}
