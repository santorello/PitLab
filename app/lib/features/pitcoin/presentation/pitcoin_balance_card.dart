import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../providers/pitcoin_providers.dart';

/// Card riusabile che mostra il balance PitCoin dell'utente effettivo
/// (loggato o impersonato) e una CTA verso lo storico attivita'.
///
/// Visibile solo se l'utente e' autenticato.
///
/// La card si inserisce additivamente in `ProfileScreen` senza richiedere
/// alcuna modifica al codice esistente al di la' dell'import e dell'inserimento
/// nel ListView.
class PitcoinBalanceCard extends ConsumerWidget {
  const PitcoinBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final balanceAsync = ref.watch(effectiveUserPitcoinBalanceProvider);
    final deltaAsync = ref.watch(effectiveUserPitcoinRecentDeltaProvider);

    return Card(
      color: AppColors.graphite,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _CoinIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🪙 ${l10n.pitcoinBalanceTitle}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  balanceAsync.when(
                    loading: () => const _LoadingTotal(),
                    error: (_, __) => Text(
                      '—',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    data: (balance) {
                      final total = balance?.totalPoints ?? 0;
                      return Text(
                        l10n.pitcoinPointsLabel(total),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.pitcoinBalanceSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.concrete,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      deltaAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (delta) {
                          if (delta <= 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _DeltaChip(
                              label: l10n.pitcoinBalanceDeltaWeek(delta),
                            ),
                          );
                        },
                      ),
                      TextButton.icon(
                        onPressed: () => context.go('/profile/activity'),
                        icon: const Icon(
                          Icons.history,
                          color: AppColors.signalOrange,
                          size: 18,
                        ),
                        label: Text(
                          l10n.pitcoinHistoryAction,
                          style: const TextStyle(
                            color: AppColors.signalOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Versione compatta usata sui profili pubblici (`/u/:slug`).
class PitcoinBalanceCompact extends ConsumerWidget {
  const PitcoinBalanceCompact({required this.publicSlug, super.key});

  final String publicSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final balanceAsync = ref.watch(pitcoinBalanceBySlugProvider(publicSlug));

    return balanceAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (balance) {
        if (balance == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.signalOrange.withAlpha(28),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.signalOrange.withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.savings_outlined,
                  size: 16, color: AppColors.signalOrange),
              const SizedBox(width: 6),
              Text(
                l10n.pitcoinPointsLabel(balance.totalPoints),
                style: const TextStyle(
                  color: AppColors.signalOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CoinIcon extends StatelessWidget {
  const _CoinIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.signalOrange.withAlpha(220),
            AppColors.signalOrange.withAlpha(140),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.savings_outlined,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}

class _LoadingTotal extends StatelessWidget {
  const _LoadingTotal();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      width: 80,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withAlpha(120)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.greenAccent,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
