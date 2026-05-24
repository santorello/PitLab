import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';

/// Tono semantico per un Pill.
///
/// Determina automaticamente colori background e foreground
/// basati su una scala predefinita.
enum PillTone {
  /// Neutro: background cool, foreground muted
  neutral,

  /// Segnale: background orange50, foreground arancione
  signal,

  /// Successo: background verde soft, foreground verde
  success,

  /// Avviso: background ambra soft, foreground ambra
  warning,

  /// Pericolo: background rosso soft, foreground rosso
  danger,

  /// Informativo: background blu soft, foreground blu
  info,
}

/// Componente Pill per segnali, badge, e chip di categoria.
///
/// Usato per visualizzare etichette compatte con icona opzionale.
/// Supporta toni semantici automatici o colori personalizzati.
///
/// Esempio:
/// ```dart
/// Pill(
///   label: 'Buggy',
///   icon: Icons.category,
///   tone: PillTone.neutral,
/// )
/// ```
class Pill extends StatelessWidget {
  const Pill({
    required this.label,
    this.icon,
    this.background,
    this.foreground,
    this.tone = PillTone.neutral,
    super.key,
  });

  /// Testo da visualizzare.
  final String label;

  /// Icona opzionale a sinistra del label.
  final IconData? icon;

  /// Colore background personalizzato.
  /// Se presente, ignora [tone].
  final Color? background;

  /// Colore foreground (testo + icona) personalizzato.
  /// Se presente, ignora [tone].
  final Color? foreground;

  /// Tono semantico. Usato se [background] o [foreground] sono null.
  final PillTone tone;

  /// Risolve il colore background dal tono.
  Color _resolveBackground() {
    if (background != null) return background!;

    return switch (tone) {
      PillTone.neutral => AppColors.surfaceCool,
      PillTone.signal => AppColors.orange50,
      PillTone.success => Color.alphaBlend(
          AppColors.statusOpen.withAlpha(40),
          AppColors.panel,
        ),
      PillTone.warning => Color.alphaBlend(
          AppColors.statusWarning.withAlpha(40),
          AppColors.panel,
        ),
      PillTone.danger => Color.alphaBlend(
          AppColors.statusClosed.withAlpha(40),
          AppColors.panel,
        ),
      PillTone.info => Color.alphaBlend(
          AppColors.statusInfo.withAlpha(40),
          AppColors.panel,
        ),
    };
  }

  /// Risolve il colore foreground dal tono.
  Color _resolveForeground() {
    if (foreground != null) return foreground!;

    return switch (tone) {
      PillTone.neutral => AppColors.onSurfaceMuted,
      PillTone.signal => AppColors.orangeText,
      PillTone.success => AppColors.statusOpen,
      PillTone.warning => AppColors.statusWarning,
      PillTone.danger => AppColors.statusClosed,
      PillTone.info => AppColors.statusInfo,
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolvedBg = _resolveBackground();
    final resolvedFg = _resolveForeground();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: resolvedFg,
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: resolvedFg,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
