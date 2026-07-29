import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/models/track_arrival_summary.dart';
import '../../../shared/models/track_weather_day.dart';
import '../../../shared/models/today_arrival_status.dart';
import '../../../shared/utils/share_entity.dart';
import '../../auth/application/auth_providers.dart';
import '../../comments/presentation/comments_section.dart';
import '../application/tracks_providers.dart';

class TrackDetailScreen extends ConsumerStatefulWidget {
  const TrackDetailScreen({
    required this.slug,
    this.openArrivalOnLoad = false,
    super.key,
  });

  final String slug;
  final bool openArrivalOnLoad;

  @override
  ConsumerState<TrackDetailScreen> createState() => _TrackDetailScreenState();
}

class _TrackDetailScreenState extends ConsumerState<TrackDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _todayKey = GlobalKey();
  bool _arrivalIntentHandled = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackAsync = ref.watch(publicTrackDetailProvider(widget.slug));
    final currentUser = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;

    return ContentScaffold(
      title: l10n.tracksTitle,
      description: l10n.trackDetailTitle,
      child: trackAsync.when(
        data: (track) {
          if (track == null) {
            return Center(
              child: Text(l10n.trackNotFound),
            );
          }

          final statusColor = _statusColor(track.status);
          final statusLabel = _statusLabel(context, track.status);
          final heroDescription = track.description.isNotEmpty
              ? track.description
              : track.shortDescription;
          final locationText = [
            if (track.city.isNotEmpty) track.city,
            if (track.country.isNotEmpty) track.country,
          ].join(', ');
          final weatherRequest =
              track.latitude != null && track.longitude != null
              ? TrackWeatherRequest(
                  trackId: track.id,
                  latitude: track.latitude!,
                  longitude: track.longitude!,
                )
              : null;
          final weatherForecastAsync = weatherRequest == null
              ? const AsyncValue<List<TrackWeatherDay>>.data(<TrackWeatherDay>[])
              : ref.watch(trackWeatherProvider(weatherRequest));
          final weatherDays = weatherForecastAsync.maybeWhen(
            data: (forecast) => forecast.isEmpty
                ? _mockWeatherForTrack(context, track.slug)
                : _mapWeatherDays(context, forecast),
            orElse: () => _mockWeatherForTrack(context, track.slug),
          );
          final todayArrivalAsync = ref.watch(todayArrivalStatusProvider(track.id));
          final todayArrivalSummaryAsync = ref.watch(
            trackTodayArrivalSummaryProvider(track.id),
          );
          final todayArrivalSummary = todayArrivalSummaryAsync.maybeWhen(
            data: (summary) => summary,
            orElse: TrackArrivalSummary.empty,
          );
          final isFollowed = ref.watch(isTrackFollowedProvider(track.id));
          final followerCountAsync = ref.watch(trackFollowerCountProvider(track.id));
          final followerCount = followerCountAsync.maybeWhen(
            data: (value) => value,
            orElse: () => 0,
          );
          final arrivalActionLabel = todayArrivalAsync.maybeWhen(
            data: (arrival) => arrival?.status == 'coming' ? l10n.comingButton : l10n.signupButton,
            orElse: () => l10n.signupButton,
          );
          final favoriteActionLabel = isFollowed
              ? l10n.favoritedTrackButton
              : l10n.favoriteTrackButton;

          if (widget.openArrivalOnLoad &&
              !_arrivalIntentHandled &&
              currentUser != null &&
              track.id.isNotEmpty) {
            _arrivalIntentHandled = true;
            debugPrint(
              '[ArrivalFlow] Auto-confirm trigger slug=${track.slug} trackId=${track.id} user=${currentUser.id}',
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              _confirmArrival(
                trackId: track.id,
                trackSlug: track.slug,
                trackName: track.name,
                currentUserId: ref.read(effectiveUserIdProvider) ?? currentUser.id,
              );
            });
          }

          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              Card(
                color: AppColors.graphite,
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.darkSurface.withAlpha(220),
                                AppColors.graphite,
                                AppColors.darkScaffold,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -36,
                        right: -12,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(10),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -48,
                        left: -24,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.signalOrange.withAlpha(20),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.trackBreadcrumb(track.name),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.white60,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              track.name.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              locationText,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.concrete,
                              ),
                            ),
                            if (track.address.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.place_outlined,
                                    size: 18,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      track.address,
                                      style: Theme.of(context).textTheme.bodyMedium
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            _HeroStatusStrip(
                              statusLabel: statusLabel,
                              statusColor: statusColor,
                              statusMessage: track.statusMessage.isNotEmpty
                                  ? track.statusMessage
                                  : l10n.trackStatusUpdated,
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _HeroQuickFact(
                                  icon: Icons.group_outlined,
                                  label: _heroPresenceLabel(context),
                                  value: _heroPresenceValue(context, todayArrivalSummary),
                                  color: AppColors.signalOrange,
                                ),
                                _HeroQuickFact(
                                  icon: Icons.cloud_outlined,
                                  label: l10n.weatherLabel,
                                  value: l10n.weatherTodayVerdict(weatherDays.first.verdict),
                                  color: weatherDays.first.color,
                                ),
                                _HeroQuickFact(
                                  icon: Icons.handyman_outlined,
                                  label: l10n.servicesLabel,
                                  value: l10n.servicesConfirmedCount(
                                    track.availableServices.length,
                                  ),
                                  color: Colors.white,
                                ),
                                _HeroQuickFact(
                                  icon: Icons.favorite_border,
                                  label: l10n.profileFavoritesTitle,
                                  value: l10n.entitySavedCount(followerCount),
                                  color: AppColors.signalOrange,
                                ),
                              ],
                            ),
                            if (track.categoryKeys.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: track.categoryKeys
                                    .map(
                                      (key) => _CategoryTag(categoryKey: key),
                                    )
                                    .toList(),
                              ),
                            ],
                            if (track.availableServices.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: track.availableServices
                                    .map((service) => _ServiceTag(label: service))
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Text(
                              heroDescription,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _handleArrivalAction(
                                    trackId: track.id,
                                    trackSlug: track.slug,
                                    trackName: track.name,
                                    // Usa effectiveUserIdProvider così save e fetch
                                    // usano sempre la stessa identità (anche in impersonazione).
                                    currentUserId: ref.read(effectiveUserIdProvider),
                                  ),
                                  child: Text(arrivalActionLabel),
                                ),
                                _HeroIconAction(
                                  tooltip: favoriteActionLabel,
                                  onPressed: () => _toggleFollowTrack(
                                    trackId: track.id,
                                    trackName: track.name,
                                  ),
                                  icon: isFollowed
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  active: isFollowed,
                                ),
                                _HeroIconAction(
                                  tooltip: l10n.openMapButton,
                                  onPressed: track.externalMapUrl.isEmpty
                                      ? null
                                      : () => _openMap(track.externalMapUrl),
                                  icon: Icons.map_outlined,
                                ),
                                _HeroIconAction(
                                  tooltip: l10n.shareAction,
                                  onPressed: () => shareEntity(
                                    context: context,
                                    entityType: 'track',
                                    entityId: track.slug,
                                  ),
                                  icon: Icons.ios_share_outlined,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _WeatherVerdictCard(
                days: weatherDays,
                isLive: weatherForecastAsync.hasValue &&
                    weatherForecastAsync.maybeWhen(
                      data: (forecast) => forecast.isNotEmpty,
                      orElse: () => false,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _TodayAtTrackCard(
                key: _todayKey,
                arrivalStatusAsync: todayArrivalAsync,
                arrivalSummaryAsync: todayArrivalSummaryAsync,
                isAuthenticated: currentUser != null,
              ),
              // Commenti: solo per piste già pubblicate su Supabase (UUID).
              if (isPublishedTrackId(track.id)) ...[
                const SizedBox(height: AppSpacing.lg),
                CommentsSection(
                  entityType: 'track',
                  entityId: track.id,
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(l10n.trackLoadError(error.toString())),
        ),
      ),
    );
  }

  static String _statusLabel(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'open':
        return l10n.statusOpen;
      case 'wet':
        return l10n.statusWet;
      case 'closed':
        return l10n.statusClosed;
      default:
        return l10n.statusUnknown;
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.openGreen;
      case 'wet':
        return AppColors.wetBlue;
      case 'closed':
        return AppColors.closedRed;
      default:
        return AppColors.warningAmber;
    }
  }

  static Future<void> _openMap(String mapUrl) async {
    final uri = Uri.tryParse(mapUrl);
    if (uri == null) {
      return;
    }

    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  static List<_WeatherDay> _mockWeatherForTrack(BuildContext context, String slug) {
    final l10n = AppLocalizations.of(context)!;
    if (slug == 'offroad-parma') {
      return [
        _WeatherDay(
          label: l10n.todayLabel,
          shortDate: '2 Apr',
          verdict: l10n.weatherOk,
          note: l10n.weatherOutdoorOkNote,
          color: AppColors.openGreen,
        ),
        _WeatherDay(
          label: l10n.weatherDaySun,
          shortDate: '3 Apr',
          verdict: l10n.weatherWarning,
          note: l10n.weatherOutdoorWarningNote,
          color: AppColors.warningAmber,
        ),
        _WeatherDay(
          label: l10n.weatherDayMon,
          shortDate: '4 Apr',
          verdict: l10n.weatherNo,
          note: l10n.weatherOutdoorNoNote,
          color: AppColors.closedRed,
        ),
      ];
    }

    return [
      _WeatherDay(
        label: l10n.todayLabel,
        shortDate: '2 Apr',
        verdict: l10n.weatherOk,
        note: l10n.weatherIndoorOkNote,
        color: AppColors.openGreen,
      ),
      _WeatherDay(
        label: l10n.weatherDaySun,
        shortDate: '3 Apr',
        verdict: l10n.weatherOk,
        note: l10n.weatherIndoorRegularNote,
        color: AppColors.openGreen,
      ),
      _WeatherDay(
        label: l10n.weatherDayMon,
        shortDate: '4 Apr',
        verdict: l10n.weatherWarning,
        note: l10n.weatherIndoorWarningNote,
        color: AppColors.warningAmber,
      ),
    ];
  }

  static List<_WeatherDay> _mapWeatherDays(
    BuildContext context,
    List<TrackWeatherDay> forecast,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return forecast.take(3).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value;
      return _WeatherDay(
        label: index == 0
            ? l10n.todayLabel
            : DateFormat.E(localeName).format(day.date),
        shortDate: DateFormat('d MMM', localeName).format(day.date),
        verdict: _forecastVerdict(l10n, day),
        note: _forecastNote(l10n, day),
        color: _forecastColor(day),
      );
    }).toList();
  }

  static String _forecastVerdict(AppLocalizations l10n, TrackWeatherDay day) {
    if (day.weatherCode >= 60 || (day.precipitationProbabilityMax ?? 0) >= 70) {
      return l10n.weatherNo;
    }
    if (day.weatherCode >= 3 || (day.precipitationProbabilityMax ?? 0) >= 35) {
      return l10n.weatherWarning;
    }
    return l10n.weatherOk;
  }

  static String _forecastNote(AppLocalizations l10n, TrackWeatherDay day) {
    if (day.weatherCode >= 60 || (day.precipitationProbabilityMax ?? 0) >= 70) {
      return l10n.weatherApiRainExpected(day.precipitationProbabilityMax ?? 0);
    }
    if (day.weatherCode >= 3 || (day.precipitationProbabilityMax ?? 0) >= 35) {
      return l10n.weatherApiMixedConditions(
        day.precipitationProbabilityMax ?? 0,
      );
    }
    return l10n.weatherApiStableDay(day.temperatureMaxC?.round() ?? 0);
  }

  static Color _forecastColor(TrackWeatherDay day) {
    if (day.weatherCode >= 60 || (day.precipitationProbabilityMax ?? 0) >= 70) {
      return AppColors.closedRed;
    }
    if (day.weatherCode >= 3 || (day.precipitationProbabilityMax ?? 0) >= 35) {
      return AppColors.warningAmber;
    }
    return AppColors.openGreen;
  }

  static String _heroPresenceLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it'
        ? 'Presenze'
        : 'Attendance';
  }

  static String _heroPresenceValue(
    BuildContext context,
    TrackArrivalSummary summary,
  ) {
    final isItalian = Localizations.localeOf(context).languageCode == 'it';
    if (summary.activeCount <= 0) {
      return isItalian ? 'Nessun segnale oggi' : 'No signals today';
    }

    return isItalian
        ? '${summary.activeCount} oggi'
        : '${summary.activeCount} today';
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) {
      return;
    }

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Future<void> _handleArrivalAction({
    required String trackId,
    required String trackSlug,
    required String trackName,
    required String? currentUserId,
  }) async {
    debugPrint(
      '[ArrivalFlow] Manual arrival action trackId=$trackId slug=$trackSlug user=$currentUserId',
    );
    if (currentUserId == null) {
      if (!mounted) {
        return;
      }
      debugPrint(
        '[ArrivalFlow] User not authenticated, redirecting to login for slug=$trackSlug',
      );
      context.go(
        '/login?redirect=${Uri.encodeComponent('/track/$trackSlug?intent=arrival')}',
      );
      return;
    }

    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.panel,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🚗 ${l10n.arrivalSheetTitle}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.arrivalSheetBody(trackName),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.steel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ArrivalOptionTile(
                    icon: Icons.directions_car_filled_outlined,
                    title: l10n.arrivalConfirmTitle,
                    subtitle: l10n.arrivalConfirmSubtitle,
                    onTap: () => Navigator.of(context).pop(l10n.arrivalConfirmTitle),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ArrivalOptionTile(
                    icon: Icons.help_outline,
                    title: l10n.arrivalMaybeTitle,
                    subtitle: l10n.arrivalMaybeSubtitle,
                    onTap: () => Navigator.of(context).pop(l10n.arrivalMaybeTitle),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ArrivalOptionTile(
                    icon: Icons.close_outlined,
                    title: l10n.arrivalCancelTitle,
                    subtitle: l10n.arrivalCancelSubtitle,
                    onTap: () => Navigator.of(context).pop(l10n.arrivalCancelTitle),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || selection == null) {
      debugPrint('[ArrivalFlow] Bottom sheet closed without selection.');
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final status = switch (selection) {
      _ when selection == l10n.arrivalConfirmTitle => 'coming',
      _ when selection == l10n.arrivalMaybeTitle => 'maybe',
      _ => 'cancelled',
    };
    debugPrint(
      '[ArrivalFlow] Manual selection="$selection" resolvedStatus=$status trackId=$trackId',
    );

    await _saveArrivalStatus(
      trackId: trackId,
      currentUserId: currentUserId,
      status: status,
    );

    await _scrollToSection(_todayKey);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.arrivalSavedMessage(selection, trackName)),
      ),
    );
  }

  Future<void> _confirmArrival({
    required String trackId,
    required String trackSlug,
    required String trackName,
    required String? currentUserId,
  }) async {
    debugPrint(
      '[ArrivalFlow] Auto-confirm start trackId=$trackId slug=$trackSlug user=$currentUserId',
    );
    if (currentUserId == null) {
      if (!mounted) {
        return;
      }
      debugPrint(
        '[ArrivalFlow] Auto-confirm found no user, redirecting again to login for slug=$trackSlug',
      );
      context.go(
        '/login?redirect=${Uri.encodeComponent('/track/$trackSlug?intent=arrival')}',
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    await _saveArrivalStatus(
      trackId: trackId,
      currentUserId: currentUserId,
      status: 'coming',
    );

    await _scrollToSection(_todayKey);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.arrivalSavedMessage(l10n.arrivalConfirmTitle, trackName)),
      ),
    );
  }

  Future<void> _saveArrivalStatus({
    required String trackId,
    required String currentUserId,
    required String status,
  }) async {
    // Guard: local drafts approvati usano il slug come ID; Supabase richiede UUID.
    if (!isPublishedTrackId(trackId)) {
      debugPrint(
        '[ArrivalFlow] Skip: trackId=$trackId is not a UUID (draft not yet published to Supabase).',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Questa pista non è ancora disponibile online: registrazione presenze non attiva.'),
          ),
        );
      }
      return;
    }

    final repository = ref.read(tracksRepositoryProvider);
    if (repository == null) {
      debugPrint('[ArrivalFlow] No tracks repository available.');
      return;
    }

    debugPrint(
      '[ArrivalFlow] Saving status=$status for trackId=$trackId user=$currentUserId',
    );
    await repository.upsertTodayArrivalStatus(
      trackId: trackId,
      userId: currentUserId,
      status: status,
    );

    debugPrint('[ArrivalFlow] Save completed. Invalidating todayArrivalStatusProvider($trackId)');
    ref.invalidate(todayArrivalStatusProvider(trackId));
    ref.invalidate(trackTodayArrivalSummaryProvider(trackId));
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) {
        return;
      }
      ref.invalidate(trackTodayArrivalSummaryProvider(trackId));
    });
  }

  void _toggleFollowTrack({
    required String trackId,
    required String trackName,
  }) {
    final nowFollowed = ref.read(followedTrackIdsProvider.notifier).toggle(trackId);
    ref.invalidate(trackFollowerCountProvider(trackId));
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) {
        return;
      }
      ref.invalidate(trackFollowerCountProvider(trackId));
    });
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowFollowed
              ? l10n.followTrackSaved(trackName)
              : l10n.followTrackRemoved(trackName),
        ),
      ),
    );
  }
}

class _TodayAtTrackCard extends StatelessWidget {
  const _TodayAtTrackCard({
    required this.arrivalStatusAsync,
    required this.arrivalSummaryAsync,
    required this.isAuthenticated,
    super.key,
  });

  final AsyncValue<TodayArrivalStatus?> arrivalStatusAsync;
  final AsyncValue<TrackArrivalSummary> arrivalSummaryAsync;
  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏁 ${l10n.todayAtTrackTitle}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildArrivalSummary(context),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              Localizations.localeOf(context).languageCode == 'it'
                  ? 'Il tuo stato personale'
                  : 'Your personal status',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.steel,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            arrivalStatusAsync.when(
              data: (arrival) {
                if (!isAuthenticated) {
                  return Text(
                    Localizations.localeOf(context).languageCode == 'it'
                        ? 'Accedi per segnalare la tua presenza personale di oggi. Le informazioni pubbliche qui sopra restano aggregate.'
                        : 'Sign in to report your personal attendance for today. Public information above remains aggregated.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  );
                }

                if (arrival == null) {
                  return Text(
                    l10n.noArrivalForToday,
                    style: Theme.of(context).textTheme.bodyLarge,
                  );
                }

                final label = switch (arrival.status) {
                  'coming' => l10n.arrivalConfirmed,
                  'maybe' => l10n.arrivalMaybe,
                  'cancelled' => l10n.arrivalCancelled,
                  _ => l10n.arrivalStatusUpdated,
                };
                final registeredAt = arrival.updatedAt == null
                    ? null
                    : TimeOfDay.fromDateTime(arrival.updatedAt!.toLocal()).format(context);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoLine(
                      label: l10n.todayAtTrackStateLabel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _statusColor(arrival.status).withAlpha(18),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: _statusColor(arrival.status),
                          ),
                        ),
                      ),
                    ),
                    if (registeredAt != null) ...[
                      const SizedBox(height: 12),
                      _InfoLine(
                        label: l10n.todayAtTrackUpdatedLabel,
                        child: Text(
                          l10n.arrivalRegisteredAt(registeredAt),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.steel,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      l10n.arrivalValidForToday,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                );
              },
              loading: () => Text(
                l10n.loadingTodayArrival,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              error: (error, stackTrace) => Text(
                l10n.arrivalReadError(error.toString()),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'coming':
        return AppColors.openGreen;
      case 'maybe':
        return AppColors.warningAmber;
      case 'cancelled':
        return AppColors.closedRed;
      default:
        return AppColors.steel;
    }
  }

  Widget _buildArrivalSummary(BuildContext context) {
    return arrivalSummaryAsync.when(
      data: (summary) {
        final isItalian = Localizations.localeOf(context).languageCode == 'it';
        final chips = <Widget>[
          _SummaryChip(
            color: AppColors.openGreen,
            label: isItalian
                ? '${summary.comingCount} confermati'
                : '${summary.comingCount} confirmed',
          ),
          _SummaryChip(
            color: AppColors.warningAmber,
            label: isItalian
                ? '${summary.maybeCount} in forse'
                : '${summary.maybeCount} maybe',
          ),
        ];

        if (summary.cancelledCount > 0) {
          chips.add(
            _SummaryChip(
              color: AppColors.closedRed,
              label: isItalian
                  ? '${summary.cancelledCount} cancellati'
                  : '${summary.cancelledCount} cancelled',
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isItalian
                  ? 'Presenza aggregata di oggi'
                  : 'Aggregated attendance today',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.steel,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: chips,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isItalian
                  ? 'Questa sezione mostra solo conteggi aggregati (nessun nominativo pubblico).'
                  : 'This section shows aggregated counts only (no public names).',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.steel,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              summary.activeCount > 0
                  ? (isItalian
                        ? '${summary.activeCount} persone hanno gia\' segnalato una presenza possibile per oggi.'
                        : '${summary.activeCount} people have already signaled they may be at the track today.')
                  : (isItalian
                        ? 'Nessuna presenza segnalata per oggi al momento.'
                        : 'No attendance has been reported for today yet.'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.steel,
              ),
            ),
          ],
        );
      },
      loading: () => Text(
        Localizations.localeOf(context).languageCode == 'it'
            ? 'Caricamento presenze aggregate'
            : 'Loading aggregate attendance',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.steel,
        ),
      ),
      error: (error, stackTrace) => Text(
        Localizations.localeOf(context).languageCode == 'it'
            ? 'Le presenze aggregate non sono disponibili in questo momento.'
            : 'Aggregate attendance is unavailable right now.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.steel,
        ),
      ),
    );
  }
}

class _HeroStatusStrip extends StatelessWidget {
  const _HeroStatusStrip({
    required this.statusLabel,
    required this.statusColor,
    required this.statusMessage,
  });

  final String statusLabel;
  final Color statusColor;
  final String statusMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(24),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              statusLabel,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: statusColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}


class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.steel,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}

class _ArrivalOptionTile extends StatelessWidget {
  const _ArrivalOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.concrete),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceCool,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: AppColors.graphite),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.steel,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.steel),
          ],
        ),
      ),
    );
  }
}

class _WeatherVerdictCard extends StatelessWidget {
  const _WeatherVerdictCard({
    required this.days,
    required this.isLive,
  });

  final List<_WeatherDay> days;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCool,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.cloud_outlined,
                    color: AppColors.graphite,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🌤️ ${l10n.weatherTrackTitle}', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        l10n.weatherQuickVerdict,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.steel,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: days.first.color.withAlpha(22),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    l10n.weatherTodayVerdict(days.first.verdict),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: days.first.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isLive
                        ? AppColors.openGreen.withAlpha(18)
                        : AppColors.warningAmber.withAlpha(16),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    isLive ? l10n.weatherLiveBadge : l10n.weatherMockBadge,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isLive ? AppColors.openGreen : AppColors.warningAmber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: days
                  .map((day) => _WeatherDayTile(day: day))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.weatherDataSourceAttribution,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.steel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherDayTile extends StatelessWidget {
  const _WeatherDayTile({required this.day});

  final _WeatherDay day;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 172,
      height: 190,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.concrete),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.steel,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(day.shortDate, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: day.color.withAlpha(24),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              day.verdict,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: day.color,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            day.note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.steel,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherDay {
  const _WeatherDay({
    required this.label,
    required this.shortDate,
    required this.verdict,
    required this.note,
    required this.color,
  });

  final String label;
  final String shortDate;
  final String verdict;
  final String note;
  final Color color;
}

class _ServiceTag extends StatelessWidget {
  const _ServiceTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.categoryKey});

  final String categoryKey;

  /// Mappa la chiave DB in una label leggibile e un colore di accento.
  (String, Color) _resolve() {
    return switch (categoryKey) {
      'buggy' => ('🏎 Buggy', const Color(0xFFFF6B35)),
      'mini_z' => ('🔵 Mini-Z', const Color(0xFF4A90D9)),
      'scaler' => ('🪨 Scaler', const Color(0xFF7E6B52)),
      'bashing' => ('💥 Bashing', const Color(0xFFE74C3C)),
      'indoor' => ('🏠 Indoor', const Color(0xFF27AE60)),
      'outdoor' => ('☀️ Outdoor', const Color(0xFFF39C12)),
      'droni' || 'drone' => ('🚁 Droni', const Color(0xFF8E44AD)),
      'treni' || 'train' => ('🚂 Treni', const Color(0xFF16A085)),
      _ => (categoryKey, const Color(0xFF95A5A6)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve();
    // Usiamo il colore pieno come testo su background semitrasparente
    // per garantire contrasto sufficiente su sfondi scuri della hero.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(48),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withAlpha(160)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroQuickFact extends StatelessWidget {
  const _HeroQuickFact({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIconAction extends StatelessWidget {
  const _HeroIconAction({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.active = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 50,
        height: 50,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: active
                ? AppColors.signalOrange.withAlpha(36)
                : Colors.white10,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: FilledButton.tonal(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: active ? AppColors.signalOrange : Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Icon(icon, size: 20, key: ValueKey(icon)),
            ),
          ),
        ),
      ),
    );
  }
}

