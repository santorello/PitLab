import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../data/models/pitcoin_badge.dart';
import '../providers/pitcoin_providers.dart';

/// Vetrina badge. Due modalita':
///
/// - **owner**: griglia col catalogo completo. Ottenute = colorate.
///   Non ancora ottenute = grigie. Per via dello stato corrente la progress
///   numerica resta best-effort e va sviluppata in una iterazione successiva.
/// - **pubblica** (`forSlug` valorizzato): mostra solo le ottenute come
///   distintivi compatti.
class PitcoinBadgesSection extends ConsumerWidget {
  const PitcoinBadgesSection({
    this.forSlug,
    super.key,
  });

  /// Se valorizzato, modalita' pubblica: legge le sole badge ottenute
  /// dell'utente identificato dal public_slug.
  final String? forSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    if (forSlug != null) {
      final badgesAsync = ref.watch(userBadgesBySlugProvider(forSlug!));
      return badgesAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (badges) {
          if (badges.isEmpty) return const SizedBox.shrink();
          return _BadgeStrip(badges: badges, languageCode: languageCode);
        },
      );
    }

    final mergedAsync = ref.watch(effectiveUserMergedBadgesProvider);
    return mergedAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => Text(l10n.pitcoinBadgesEmpty),
      data: (badges) {
        if (badges.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.pitcoinBadgesEmpty),
          );
        }
        return _BadgeGrid(badges: badges, languageCode: languageCode);
      },
    );
  }
}

class _BadgeStrip extends StatelessWidget {
  const _BadgeStrip({required this.badges, required this.languageCode});

  final List<PitcoinBadge> badges;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: badges
          .map((b) => _BadgeChip(badge: b, languageCode: languageCode))
          .toList(),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge, required this.languageCode});

  final PitcoinBadge badge;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final tierColor = _tierColor(badge.tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tierColor.withAlpha(38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor.withAlpha(140)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForCategory(badge.category), size: 14, color: tierColor),
          const SizedBox(width: 6),
          Text(
            badge.localizedName(languageCode),
            style: TextStyle(
              color: tierColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges, required this.languageCode});

  final List<PitcoinBadge> badges;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final crossAxis = mediaWidth >= 900 ? 5 : (mediaWidth >= 600 ? 4 : 3);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: badges.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxis,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        return _BadgeTile(
          badge: badges[index],
          languageCode: languageCode,
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.languageCode});

  final PitcoinBadge badge;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unlocked = badge.isUnlocked;
    final tierColor = _tierColor(badge.tier);
    final tone = unlocked ? tierColor : AppColors.concrete;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showBadgeSheet(context, badge, languageCode),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: unlocked
              ? tierColor.withAlpha(28)
              : Colors.black.withAlpha(8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tone.withAlpha(unlocked ? 140 : 60),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tone.withAlpha(unlocked ? 60 : 25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconForCategory(badge.category),
                color: tone,
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.localizedName(languageCode),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tone,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              unlocked
                  ? _tierLabel(badge.tier, l10n)
                  : l10n.pitcoinBadgeLocked,
              style: TextStyle(
                color: tone.withAlpha(180),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeSheet(
    BuildContext context,
    PitcoinBadge badge,
    String languageCode,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final tierColor = _tierColor(badge.tier);
    final unlocked = badge.isUnlocked;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: tierColor.withAlpha(unlocked ? 80 : 28),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconForCategory(badge.category),
                    color: unlocked ? tierColor : AppColors.concrete,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badge.localizedName(languageCode),
                        style: Theme.of(sheetCtx).textTheme.titleLarge,
                      ),
                      Text(
                        unlocked
                            ? _tierLabel(badge.tier, l10n)
                            : l10n.pitcoinBadgeLocked,
                        style: TextStyle(
                          color: tierColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              badge.localizedDescription(languageCode) ?? '',
              style: Theme.of(sheetCtx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (unlocked && badge.awardedAt != null)
              Text(
                l10n.pitcoinBadgeUnlockedOn(_formatDate(badge.awardedAt!, languageCode)),
                style: TextStyle(
                  color: AppColors.concrete,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date, String languageCode) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    if (languageCode == 'en') return '$year-$month-$day';
    return '$day/$month/$year';
  }
}

Color _tierColor(String tier) {
  switch (tier) {
    case 'gold':
      return const Color(0xFFFFB300);
    case 'silver':
      return const Color(0xFFB0BEC5);
    case 'bronze':
      return const Color(0xFFB87333);
    case 'special':
      return AppColors.signalOrange;
    default:
      return AppColors.concrete;
  }
}

String _tierLabel(String tier, AppLocalizations l10n) {
  switch (tier) {
    case 'gold':
      return l10n.pitcoinTierGold;
    case 'silver':
      return l10n.pitcoinTierSilver;
    case 'bronze':
      return l10n.pitcoinTierBronze;
    case 'special':
      return l10n.pitcoinTierSpecial;
    default:
      return '';
  }
}

IconData _iconForCategory(String category) {
  switch (category) {
    case 'identity':
      return Icons.badge_outlined;
    case 'garage':
      return Icons.directions_car_outlined;
    case 'catalog':
      return Icons.public_outlined;
    case 'operations':
      return Icons.tune_outlined;
    case 'events':
      return Icons.event_outlined;
    case 'engagement':
      return Icons.directions_run_outlined;
    case 'moderation':
      return Icons.shield_outlined;
    case 'milestone':
      return Icons.workspace_premium_outlined;
    default:
      return Icons.emoji_events_outlined;
  }
}
