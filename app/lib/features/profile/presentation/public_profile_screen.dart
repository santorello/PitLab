import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../auth/application/auth_providers.dart';
import '../../pitcoin/presentation/pitcoin_badges_section.dart';
import '../../pitcoin/presentation/pitcoin_balance_card.dart';
import '../../social/application/profile_follows_providers.dart';
import '../application/public_profile_provider.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({required this.publicSlug, super.key});

  final String publicSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(publicSlug));

    return ContentScaffold(
      title: 'Profilo pilota',
      description: 'Profilo pubblico PitLap',
      child: profileAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => _ErrorState(slug: publicSlug),
        data: (profile) {
          if (profile == null) {
            return _NotFoundState(slug: publicSlug);
          }
          return _ProfileContent(profile: profile);
        },
      ),
    );
  }
}

// ── Contenuto principale ──────────────────────────────────────────────────────

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile});

  final PublicProfileRecord profile;

  String get _roleLabel => switch (profile.role) {
    'track_organizer' => 'Organizzatore pista',
    'shop_manager' => 'Gestore negozio',
    'admin' => 'Admin PitLap',
    _ => 'Pilota',
  };

  IconData get _roleIcon => switch (profile.role) {
    'track_organizer' => Icons.flag_outlined,
    'shop_manager' => Icons.storefront_outlined,
    'admin' => Icons.shield_outlined,
    _ => Icons.directions_car_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile = currentUser?.id == profile.id;
    final isFollowing =
        ref.watch(isProfileFollowedProvider(profile.id));
    final followerCount = ref
        .watch(profileFollowerCountProvider(profile.id))
        .maybeWhen(data: (v) => v, orElse: () => 0);

    return ListView(
      children: [
        // ── Hero profilo ──────────────────────────────────────────────────
        Card(
          color: AppColors.graphite,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _Avatar(avatarUrl: profile.avatarUrl, displayName: profile.displayName),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(_roleIcon, size: 16, color: AppColors.concrete),
                              const SizedBox(width: 6),
                              Text(
                                _roleLabel,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.concrete,
                                ),
                              ),
                              const SizedBox(width: 12),
                              PitcoinBalanceCompact(publicSlug: profile.publicSlug),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // ── Follow row (hidden on own profile) ─────────────────
                if (!isOwnProfile) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Follower count chip
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              size: 15, color: AppColors.concrete),
                          const SizedBox(width: 5),
                          Text(
                            '$followerCount ${followerCount == 1 ? l10n.profileFollowerSingular : l10n.profileFollowerPlural}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.concrete),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Follow / Unfollow button
                      _FollowButton(
                        profile: profile,
                        currentUser: currentUser,
                        isFollowing: isFollowing,
                        l10n: l10n,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // ── Trofei pubblici ────────────────────────────────────────────────
        Builder(
          builder: (innerCtx) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: PitcoinBadgesSection(forSlug: profile.publicSlug),
            );
          },
        ),

        // ── Garage pubblico ───────────────────────────────────────────────
        if (profile.builds.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '🔧 Garage',
              style: theme.textTheme.titleLarge,
            ),
          ),
          ...profile.builds.map((build) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BuildCard(entry: build),
          )),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.garage_outlined, size: 40, color: AppColors.steel),
                  const SizedBox(height: 10),
                  Text(
                    'Nessuna build pubblica',
                    style: theme.textTheme.titleMedium?.copyWith(color: AppColors.steel),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.displayName} non ha ancora condiviso modelli nel garage.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Follow button ─────────────────────────────────────────────────────────────

class _FollowButton extends ConsumerWidget {
  const _FollowButton({
    required this.profile,
    required this.currentUser,
    required this.isFollowing,
    required this.l10n,
  });

  final PublicProfileRecord profile;
  final dynamic currentUser;
  final bool isFollowing;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (currentUser == null) {
      // Guest: show CTA that redirects to login.
      return OutlinedButton.icon(
        onPressed: () {
          context.go(
            '/login?redirect=${Uri.encodeComponent('/u/${profile.publicSlug}')}',
          );
        },
        icon: const Icon(Icons.person_add_outlined, size: 16, color: Colors.white70),
        label: Text(
          l10n.profileFollowAction,
          style: const TextStyle(color: Colors.white70),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white30),
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    if (isFollowing) {
      return OutlinedButton.icon(
        onPressed: () {
          ref.read(followedProfileIdsProvider.notifier).toggle(profile.id);
        },
        icon: const Icon(Icons.check, size: 16, color: Colors.white70),
        label: Text(
          l10n.profileFollowingAction,
          style: const TextStyle(color: Colors.white70),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.signalOrange.withAlpha(160)),
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    return FilledButton.icon(
      onPressed: () {
        ref.read(followedProfileIdsProvider.notifier).toggle(profile.id);
      },
      icon: const Icon(Icons.person_add_outlined, size: 16),
      label: Text(l10n.profileFollowAction),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.signalOrange,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl, required this.displayName});

  final String? avatarUrl;
  final String displayName;

  String get _initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    return CircleAvatar(
      radius: 36,
      backgroundColor: AppColors.signalOrange,
      child: url != null && url.isNotEmpty
          ? ClipOval(
              child: AdaptiveImage(
                source: url,
                fit: BoxFit.cover,
                fallback: _Initials(initials: _initials),
              ),
            )
          : _Initials(initials: _initials),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Text(
      initials,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 22,
      ),
    );
  }
}

// ── Build card ────────────────────────────────────────────────────────────────

class _BuildCard extends StatelessWidget {
  const _BuildCard({required this.entry});

  final PublicBuildRecord entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = entry.imageUrls.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: AdaptiveImage(
                    source: entry.imageUrls.first,
                    fit: BoxFit.cover,
                    fallback: const ColoredBox(color: Color(0xFFEDEFF3)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title, style: theme.textTheme.titleMedium),
                  if (entry.meta.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.meta,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                  if (entry.specs.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.specs,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.steel,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stati di errore ───────────────────────────────────────────────────────────

class _NotFoundState extends StatelessWidget {
  const _NotFoundState({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 56, color: AppColors.steel),
            const SizedBox(height: 16),
            Text(
              'Profilo non trovato',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Il profilo "$slug" non esiste o non è pubblico.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.steel,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.steel),
            const SizedBox(height: 16),
            Text(
              'Errore nel caricamento',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Impossibile caricare il profilo. Riprova più tardi.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.steel,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
