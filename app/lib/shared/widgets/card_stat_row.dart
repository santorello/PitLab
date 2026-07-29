import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Una singola statistica della riga metadati di una card (stile "stat row").
/// Fornire [dotColor] per un pallino colorato (es. stato), oppure [icon] per
/// un'icona grigia. [textColor] evidenzia il testo (usato solo per lo stato).
class CardStat {
  const CardStat({
    required this.text,
    this.icon,
    this.dotColor,
    this.textColor,
  });

  final String text;
  final IconData? icon;
  final Color? dotColor;
  final Color? textColor;
}

/// Riga di statistiche quiete (icona/pallino + valore), separate da spazio.
/// Sostituisce la "zuppa di pill": colore riservato allo stato, resto grigio.
/// Va a capo con grazia su card strette (Wrap).
class CardStatRow extends StatelessWidget {
  const CardStatRow({required this.stats, super.key});

  final List<CardStat> stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: stats.map(_item).toList(),
    );
  }

  Widget _item(CardStat s) {
    Widget? leading;
    if (s.dotColor != null) {
      leading = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: s.dotColor, shape: BoxShape.circle),
      );
    } else if (s.icon != null) {
      leading = Icon(s.icon, size: 16, color: AppColors.onSurfaceMuted);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading, const SizedBox(width: 5)],
        Text(
          s.text,
          style: TextStyle(
            fontSize: 13.5,
            color: s.textColor ?? AppColors.onSurfaceMuted,
            fontWeight: s.textColor != null ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
