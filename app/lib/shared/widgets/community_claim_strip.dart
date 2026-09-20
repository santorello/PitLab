import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

/// Fascia "Segnalata dalla community" con l'invito a rivendicare la scheda.
/// Usata su piste e negozi: [onDark] per l'hero scuro della pista.
class CommunityClaimStrip extends StatelessWidget {
  const CommunityClaimStrip({
    required this.onClaim,
    this.label = 'Segnalata dalla community · dati non confermati dal gestore',
    this.action = 'Sei il gestore?',
    this.onDark = false,
    super.key,
  });

  final VoidCallback onClaim;
  final String label;
  final String action;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : AppColors.graphite;
    final soft = onDark ? Colors.white70 : AppColors.steel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: onDark ? Colors.white10 : AppColors.surfaceCool,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: onDark ? Colors.white24 : AppColors.concrete),
      ),
      child: Row(
        children: [
          Icon(Icons.groups_outlined, size: 18, color: soft),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: fg, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onClaim,
            child: Text(
              action,
              style: TextStyle(color: fg, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
