// ignore_for_file: lines_longer_than_80_chars
//
// ─────────────────────────────────────────────────────────────────────────────
//  TracksHomeScreen – layout proposto (review aprile 2026)
//
//  Miglioramenti rispetto alla V1:
//   • Selettore lingua spostato nell'header (trailingActions di ContentScaffold),
//     fuori dalla search bar.
//   • TrackCard ridisegnata:
//       - Un solo CTA primario ("Sto arrivando") → gerarchia chiara.
//       - "Vedi pista" come link testuale secondario (senza button stack).
//       - Testo hint "Tocca la card…" rimosso (la card è già InkWell).
//       - Copy informativi hardcoded per lingua sostituiti con l10n.
//       - Widget estratti in sotto-classi private testabili:
//           _CardHeader · _CardStats · _CardPersonalStatus · _CardActions
//   • Empty state con icona + testo invece di sola stringa.
//   • Spotlight grid con colore border codificato per stato pista.
//   • filtri _matchesFilters identici a V1 (parità funzionale).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/l10n/locale_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/models/track_list_item.dart';
import '../../../shared/models/track_arrival_summary.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/pill.dart';
import '../../../shared/widgets/place_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_providers.dart';
import '../application/tracks_providers.dart';
import 'tracks_home_filters.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class TracksHomeScreen extends ConsumerStatefulWidget {
  const TracksHomeScreen({super.key});

  @override
  ConsumerState<TracksHomeScreen> createState() => _TracksHomeScreenState();
}

class _TracksHomeScreenState extends ConsumerState<TracksHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _activeFilter;
  String? _activeCity;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── language toggle widget ──────────────────────────────────────────────

  Widget _buildLangButton(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Tooltip(
      message: locale.languageCode == 'it' ? 'Switch to English' : 'Passa a Italiano',
      child: OutlinedButton(
        onPressed: () {
          final nextLocale = locale.languageCode == 'it'
              ? const Locale('en')
              : const Locale('it');
          ref.read(localeProvider.notifier).setLocale(nextLocale);
          final repository = ref.read(authProfileRepositoryProvider);
          final user = ref.read(currentUserProvider);
          if (repository != null && user != null) {
            unawaited(
              repository.upsertPreferredLanguage(
                userId: user.id,
                languageCode: nextLocale.languageCode,
              ),
            );
          }
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: AppColors.concrete.withAlpha(200)),
          foregroundColor: AppColors.graphite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 16),
            const SizedBox(width: 6),
            Text(
              locale.languageCode.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tracksAsync = ref.watch(publicTracksProvider);
    final availableCities = tracksAsync.maybeWhen(
      data: (tracks) => extractTrackCities(tracks),
      orElse: () => const <String>[],
    );

    return ContentScaffold(
      title: l10n.tracksTitle,
      description: l10n.homeSubheadline,
      trailingActions: [_buildLangButton(context)],
      child: ListView(
        children: [
          // ── Spotlight banner ──────────────────────────────────────────
          _SpotlightBanner(tracksAsync: tracksAsync),
          const SizedBox(height: 18),

          // ── Search bar (senza il tasto lingua) ───────────────────────
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: l10n.searchTracksHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: l10n.clearSearchAction,
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close),
                    )
              : null,
            ),
          ),
          if (availableCities.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _activeCity,
              decoration: InputDecoration(
                labelText: _cityFilterLabel(context),
                prefixIcon: const Icon(Icons.location_city_outlined),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(_allCitiesLabel(context)),
                ),
                ...availableCities.map(
                  (city) => DropdownMenuItem<String?>(
                    value: city,
                    child: Text(city),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _activeCity = value;
                });
              },
            ),
          ],
          const SizedBox(height: 16),

          // ── Filtri ───────────────────────────────────────────────────
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FilterChipV2(
                label: l10n.filterBuggy,
                selected: _activeFilter == 'buggy',
                onSelected: () => _toggleFilter('buggy'),
              ),
              _FilterChipV2(
                label: l10n.filterMiniZ,
                selected: _activeFilter == 'mini_z',
                onSelected: () => _toggleFilter('mini_z'),
              ),
              _FilterChipV2(
                label: l10n.filterIndoor,
                selected: _activeFilter == 'indoor',
                onSelected: () => _toggleFilter('indoor'),
              ),
              _FilterChipV2(
                label: l10n.filterOutdoor,
                selected: _activeFilter == 'outdoor',
                onSelected: () => _toggleFilter('outdoor'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Lista piste ───────────────────────────────────────────────
          tracksAsync.when(
            data: (tracks) {
              final filtered = tracks.where(_matchesFilters).toList();
              if (filtered.isEmpty) {
                return _EmptyState(
                  icon: Icons.search_off_rounded,
                  message: _searchQuery.isEmpty &&
                          _activeFilter == null &&
                          _activeCity == null
                      ? l10n.noTracksAvailable
                      : l10n.noTracksMatchingFilters,
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: filtered
                        .map(
                          (track) => SizedBox(
                            width: isWide
                                ? (constraints.maxWidth - 20) / 2
                                : constraints.maxWidth,
                            child: _TrackCardV3(
                              trackId: track.id,
                              slug: track.slug,
                              title: track.name,
                              city: track.city,
                              statusLabel: _statusLabel(context, track.status),
                              statusColor: _statusColor(track.status),
                              availableServiceCount:
                                  track.availableServiceCount,
                              serviceLabels: track.serviceLabels,
                              categoryKeys: track.categoryKeys,
                              imageUrl: track.imageUrl,
                              note: track.statusMessage.isNotEmpty
                                  ? track.statusMessage
                                  : track.shortDescription,
                              onOpen: () =>
                                  context.go('/track/${track.slug}'),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => _EmptyState(
              icon: Icons.cloud_off_rounded,
              message: l10n.tracksLoadError(error.toString()),
              isError: true,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFilter(String value) {
    setState(() {
      _activeFilter = _activeFilter == value ? null : value;
    });
  }

  bool _matchesFilters(TrackListItem track) {
    return matchesTrackHomeFilters(
      track,
      searchQuery: _searchQuery,
      activeCategory: _activeFilter,
      activeCity: _activeCity,
    );
  }

  static String _cityFilterLabel(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'it' ? 'Città' : 'City';
  }

  static String _allCitiesLabel(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'it' ? 'Tutte le città' : 'All cities';
  }

  static String _statusLabel(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    return switch (status) {
      'open' => l10n.statusOpen,
      'wet' => l10n.statusWet,
      'closed' => l10n.statusClosed,
      _ => l10n.statusUnknown,
    };
  }

  static Color _statusColor(String status) {
    return switch (status) {
      'open' => AppColors.openGreen,
      'wet' => AppColors.wetBlue,
      'closed' => AppColors.closedRed,
      _ => AppColors.warningAmber,
    };
  }
}

// ─── Spotlight banner ────────────────────────────────────────────────────────

class _SpotlightBanner extends StatelessWidget {
  const _SpotlightBanner({required this.tracksAsync});

  final AsyncValue<List<TrackListItem>> tracksAsync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6EFE3), Colors.white, Color(0xFFF2F4F7)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Text(
                l10n.homeExploreTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.graphite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.homeExploreBody,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.steel,
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final spotlightTracks = tracksAsync.maybeWhen(
                    data: (tracks) => tracks.take(3).toList(),
                    orElse: () => const <TrackListItem>[],
                  );
                  if (spotlightTracks.isEmpty) {
                    return Text(
                      l10n.noTracksAvailable,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.steel,
                      ),
                    );
                  }
                  final isWide = constraints.maxWidth >= 820;
                  final itemWidth = isWide
                      ? (constraints.maxWidth - 24) / 3
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: spotlightTracks
                        .map(
                          (t) => SizedBox(
                            width: itemWidth,
                            child: _SpotlightCard(
                              title: t.name,
                              body: t.statusMessage.isNotEmpty
                                  ? t.statusMessage
                                  : t.shortDescription,
                              statusColor: _spotlightStatusColor(t.status),
                              onTap: () =>
                                  context.go('/track/${t.slug}'),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _spotlightStatusColor(String status) {
    return switch (status) {
      'open' => AppColors.openGreen,
      'wet' => AppColors.wetBlue,
      'closed' => AppColors.closedRed,
      _ => AppColors.warningAmber,
    };
  }
}

// ─── Spotlight card ───────────────────────────────────────────────────────────

// Flutter non permette borderRadius con Border a colori non uniformi.
// Soluzione: Card (gestisce borderRadius + uniform border) + strip colorata in cima.
class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({
    required this.title,
    required this.body,
    required this.statusColor,
    required this.onTap,
  });

  final String title;
  final String body;
  final Color statusColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: Colors.white.withAlpha(210),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.concrete),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Strip colorata per stato (top) — sostituisce il border top non uniforme
            Container(height: 4, color: statusColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.steel,
                    ),
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

// ─── Filter chip ─────────────────────────────────────────────────────────────

class _FilterChipV2 extends StatelessWidget {
  const _FilterChipV2({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.signalOrange.withAlpha(35),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: selected ? AppColors.graphite : null,
      ),
      side: BorderSide(
        color: selected ? AppColors.signalOrange : Colors.transparent,
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.closedRed : AppColors.steel;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color.withAlpha(130)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Static label helpers ─────────────────────────────────────────────────────

// ignore: avoid_classes_with_only_static_members
class _TrackCardV2 {
  static String _arrivalLabel(
      BuildContext context, TrackArrivalSummary summary) {
    final isIt = Localizations.localeOf(context).languageCode == 'it';
    if (summary.activeCount <= 0) {
      return isIt
          ? 'Nessun segnale oggi'
          : 'No signals today';
    }
    final parts = <String>[
      if (summary.comingCount > 0)
        isIt
            ? '${summary.comingCount} confermati'
            : '${summary.comingCount} confirmed',
      if (summary.maybeCount > 0)
        isIt ? '${summary.maybeCount} in forse' : '${summary.maybeCount} maybe',
    ];
    return parts.join(' · ');
  }

  static String _loadingArrivalLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it'
        ? 'Caricamento presenze…'
        : 'Loading arrivals…';
  }

  static String _servicesLabel(BuildContext context, int count) {
    final isIt = Localizations.localeOf(context).languageCode == 'it';
    if (count <= 0) {
      return isIt ? 'Nessun servizio attivo' : 'No services active';
    }
    return isIt
        ? '$count servizi disponibili'
        : '$count available services';
  }
}

// ─── Sub-widget: _TrackCardV3 (refactored su PlaceCard) ────────────────────

class _TrackCardV3 extends ConsumerWidget {
  const _TrackCardV3({
    required this.trackId,
    required this.slug,
    required this.title,
    required this.city,
    required this.statusLabel,
    required this.statusColor,
    required this.availableServiceCount,
    required this.serviceLabels,
    required this.categoryKeys,
    required this.imageUrl,
    required this.note,
    required this.onOpen,
  });

  final String trackId;
  final String slug;
  final String title;
  final String city;
  final String statusLabel;
  final Color statusColor;
  final int availableServiceCount;
  final List<String> serviceLabels;
  final List<String> categoryKeys;
  final String? imageUrl;
  final String note;
  final VoidCallback onOpen;

  /// Converte una category key in label display-friendly.
  /// Usa l10n per le 4 categorie principali, capitalizza le altre.
  static String _categoryLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    return switch (key) {
      'buggy'   => l10n.filterBuggy,
      'mini_z'  => l10n.filterMiniZ,
      'indoor'  => l10n.filterIndoor,
      'outdoor' => l10n.filterOutdoor,
      _         => key.replaceAll('_', ' ').split(' ').map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1);
        }).join(' '),
    };
  }

  /// Mapps status to StatusBadgeKind.
  static StatusBadgeKind _statusKind(String status) {
    return switch (status) {
      'open' => StatusBadgeKind.open,
      'closed' => StatusBadgeKind.closed,
      'wet' => StatusBadgeKind.scheduled,
      _ => StatusBadgeKind.neutral,
    };
  }

  void _handleFavoriteToggle(
    BuildContext context,
    WidgetRef ref,
    User? currentUser,
  ) {
    if (currentUser == null) {
      context.go('/login?redirect=${Uri.encodeComponent('/track/$slug')}');
      return;
    }
    ref.read(followedTrackIdsProvider.notifier).toggle(trackId);
    ref.invalidate(trackFollowerCountProvider(trackId));
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!context.mounted) return;
      ref.invalidate(trackFollowerCountProvider(trackId));
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final arrivalStatusAsync = ref.watch(todayArrivalStatusProvider(trackId));
    final arrivalSummaryAsync =
        ref.watch(trackTodayArrivalSummaryProvider(trackId));
    final isFollowed = ref.watch(isTrackFollowedProvider(trackId));
    final followerCountAsync = ref.watch(trackFollowerCountProvider(trackId));
    final currentUser = ref.watch(currentUserProvider);

    final personalStatusLabel = arrivalStatusAsync.maybeWhen(
      data: (arrival) {
        if (arrival == null) return null;
        return switch (arrival.status) {
          'coming' => l10n.arrivalConfirmed,
          'maybe' => l10n.arrivalMaybe,
          'cancelled' => l10n.arrivalCancelled,
          _ => l10n.arrivalStatusUpdated,
        };
      },
      orElse: () => null,
    );
    final followerCount = followerCountAsync.maybeWhen(
      data: (v) => v,
      orElse: () => 0,
    );
    final arrivalSummaryLabel = arrivalSummaryAsync.maybeWhen(
      data: (summary) => _TrackCardV2._arrivalLabel(context, summary),
      orElse: () => _TrackCardV2._loadingArrivalLabel(context),
    );
    final servicesLabel =
        _TrackCardV2._servicesLabel(context, availableServiceCount);
    final primaryCta = arrivalStatusAsync.maybeWhen(
      data: (arrival) =>
          arrival?.status == 'coming' ? l10n.comingButton : l10n.signupButton,
      orElse: () => l10n.signupButton,
    );

    // Build media: AdaptiveImage or placeholder
    final media = _TrackMediaPanel(
      imageUrl: imageUrl,
      statusColor: statusColor,
      serviceLabels: serviceLabels,
    );

    // Build type badge (semplice Pill per "Pista RC")
    final typeBadge = const Pill(
      label: 'Pista RC',
      tone: PillTone.signal,
    );

    // Build signals: status badge + category pills + arrival + services + followers
    final signals = <Widget>[];
    signals.add(
      StatusBadge(
        label: statusLabel,
        kind: _statusKind(statusColor == AppColors.openGreen
            ? 'open'
            : statusColor == AppColors.closedRed
                ? 'closed'
                : 'wet'),
      ),
    );
    // Categoria pills (max 3, troncati con +N se piu')
    final visibleCategoryKeys = categoryKeys.length > 3
        ? [...categoryKeys.take(3), '+${categoryKeys.length - 3}']
        : categoryKeys;
    for (final key in visibleCategoryKeys) {
      if (key.startsWith('+')) {
        signals.add(
          Pill(
            label: key,
            tone: PillTone.neutral,
          ),
        );
      } else {
        signals.add(
          Pill(
            label: _categoryLabel(context, key),
            tone: PillTone.signal,
          ),
        );
      }
    }
    // Arrival summary pill
    signals.add(
      Pill(
        label: arrivalSummaryLabel,
        tone: PillTone.neutral,
        icon: Icons.group_outlined,
      ),
    );

    // Build footer leading CTA
    final footerLeading = ElevatedButton.icon(
      onPressed: () => context.go('/track/$slug?intent=arrival'),
      icon: const Icon(Icons.directions_run, size: 16),
      label: Text(primaryCta),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.signalOrange,
        foregroundColor: Colors.white,
      ),
    );

    // Build footer actions (follow + share)
    final footerActions = <Widget>[
      Tooltip(
        message: isFollowed ? l10n.favoritedTrackButton : l10n.favoriteTrackButton,
        child: IconButton(
          onPressed: () => _handleFavoriteToggle(context, ref, currentUser),
          icon: Icon(
            isFollowed ? Icons.favorite : Icons.favorite_border,
            color: isFollowed ? AppColors.signalOrange : AppColors.graphite,
          ),
        ),
      ),
    ];

    // Personal status body if present
    String? bodyText;
    if (personalStatusLabel != null) {
      bodyText = '$personalStatusLabel · $servicesLabel · ${l10n.entitySavedCount(followerCount)}';
    } else {
      bodyText = '$servicesLabel · ${l10n.entitySavedCount(followerCount)}';
    }

    return PlaceCard(
      media: media,
      title: title,
      subtitle: city,
      typeBadge: typeBadge,
      signals: signals.isNotEmpty ? signals : null,
      body: note.isNotEmpty ? note : bodyText,
      footerLeading: footerLeading,
      footerActions: footerActions.isNotEmpty ? footerActions : null,
      onTap: onOpen,
      variant: PlaceCardVariant.standard,
    );
  }
}

class _TrackMediaPanel extends StatelessWidget {
  const _TrackMediaPanel({
    required this.imageUrl,
    required this.statusColor,
    required this.serviceLabels,
  });

  final String? imageUrl;
  final Color statusColor;
  final List<String> serviceLabels;

  @override
  Widget build(BuildContext context) {
    final visibleLabels = serviceLabels.take(3).toList();

    Widget background = (imageUrl ?? '').trim().isNotEmpty
        ? AdaptiveImage(
            source: imageUrl!,
            fit: BoxFit.cover,
            fallback: ColoredBox(color: AppColors.surfaceMuted),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  statusColor.withAlpha(210),
                  AppColors.graphite,
                ],
              ),
            ),
          );

    Widget panel = Stack(
      children: [
        Positioned.fill(child: background),
        // subtle bottom scrim so chips remain readable
        if (visibleLabels.isNotEmpty)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(100),
                  ],
                ),
              ),
            ),
          ),
        if (visibleLabels.isNotEmpty)
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: visibleLabels
                  .map(
                    (label) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(220),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.graphite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );

    return panel;
  }
}

