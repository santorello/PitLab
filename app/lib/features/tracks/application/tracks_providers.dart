import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/bootstrap/app_config.dart';
import '../../../app/l10n/locale_controller.dart';
import '../../../features/auth/application/auth_providers.dart';
import '../../../shared/models/submitted_track.dart';
import '../../../shared/models/track_arrival_summary.dart';
import '../../../shared/models/track_detail.dart';
import '../../../shared/models/track_list_item.dart';
import '../../../shared/models/track_map_pin.dart';
import '../../../shared/models/managed_track_update.dart';
import '../../../shared/models/track_weather_day.dart';
import '../../../shared/models/today_arrival_status.dart';
import '../../../shared/repositories/track_weather_repository.dart';
import '../../../shared/repositories/tracks_repository.dart';
import '../infrastructure/open_meteo_weather_repository.dart';
import '../infrastructure/supabase_tracks_repository.dart';
import 'track_taxonomy_option.dart';

// Guard difensivo: i provider degli arrivi richiedono un UUID valido come trackId.
// Local drafts creati prima dell'assegnazione UUID usano il slug come ID;
// passarli a Supabase genera "invalid input syntax for type uuid".
final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);
bool _isValidUuid(String id) => _uuidPattern.hasMatch(id);

/// Esposto ai widget che devono fare write verso Supabase con un trackId.
bool isPublishedTrackId(String id) => _isValidUuid(id);

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!AppConfig.hasSupabaseConfig) {
    return null;
  }

  return Supabase.instance.client;
});

final tracksRepositoryProvider = Provider<TracksRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return null;
  }

  return SupabaseTracksRepository(client);
});

final trackWeatherRepositoryProvider = Provider<TrackWeatherRepository>((ref) {
  return OpenMeteoWeatherRepository();
});

const _defaultTrackCategoryOptions = <TrackTaxonomyOption>[
  TrackTaxonomyOption(key: 'buggy', label: 'Buggy'),
  TrackTaxonomyOption(key: 'mini_z', label: 'Mini-Z'),
  TrackTaxonomyOption(key: 'touring', label: 'Touring'),
  TrackTaxonomyOption(key: 'indoor', label: 'Indoor'),
  TrackTaxonomyOption(key: 'outdoor', label: 'Outdoor'),
];

const _defaultTrackServiceOptions = <TrackTaxonomyOption>[
  TrackTaxonomyOption(key: 'power_220v', label: '220V'),
  TrackTaxonomyOption(key: 'compressed_air', label: 'Aria compressa'),
  TrackTaxonomyOption(key: 'tables', label: 'Tavoli box'),
  TrackTaxonomyOption(key: 'toilets', label: 'Bagni'),
  TrackTaxonomyOption(key: 'food', label: 'Ristoro'),
];

String _localizedLabel({
  required Map<String, dynamic> row,
  required String languageCode,
  required String fallbackKey,
}) {
  final preferred = languageCode == 'en'
      ? row['label_en'] as String?
      : row['label_it'] as String?;
  final alternate = languageCode == 'en'
      ? row['label_it'] as String?
      : row['label_en'] as String?;
  return (preferred?.trim().isNotEmpty == true
          ? preferred!
          : alternate?.trim().isNotEmpty == true
          ? alternate!
          : fallbackKey)
      .trim();
}

IconData _iconForCategoryKey(String key) {
  return switch (key) {
    'buggy' => Icons.terrain,
    'mini_z' => Icons.directions_car_outlined,
    'touring' => Icons.time_to_leave_outlined,
    'indoor' => Icons.sensor_door_outlined,
    'outdoor' => Icons.park_outlined,
    _ => Icons.category_outlined,
  };
}

final trackCategoryOptionsProvider =
    FutureProvider<List<TrackTaxonomyOption>>((ref) async {
      final client = ref.watch(supabaseClientProvider);
      final locale = ref.watch(localeProvider);
      if (client == null) return _defaultTrackCategoryOptions;

      try {
        final response = await client
            .from('track_categories')
            .select('key, label_it, label_en, sort_order')
            .order('sort_order')
            .order('label_it');

        final languageCode = locale?.languageCode ?? 'it';
        final options = (response as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map((row) {
              final key = row['key'] as String? ?? '';
              return TrackTaxonomyOption(
                key: key,
                label: _localizedLabel(
                  row: row,
                  languageCode: languageCode,
                  fallbackKey: key,
                ),
                icon: _iconForCategoryKey(key),
              );
            })
            .where((option) => option.key.isNotEmpty)
            .toList();
        return options.isEmpty ? _defaultTrackCategoryOptions : options;
      } catch (_) {
        return _defaultTrackCategoryOptions;
      }
    });

final trackServiceOptionsProvider =
    FutureProvider<List<TrackTaxonomyOption>>((ref) async {
      final client = ref.watch(supabaseClientProvider);
      final locale = ref.watch(localeProvider);
      if (client == null) return _defaultTrackServiceOptions;

      try {
        final response = await client
            .from('service_types')
            .select('key, label_it, label_en')
            .order('label_it');

        final languageCode = locale?.languageCode ?? 'it';
        final options = (response as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map((row) {
              final key = row['key'] as String? ?? '';
              return TrackTaxonomyOption(
                key: key,
                label: _localizedLabel(
                  row: row,
                  languageCode: languageCode,
                  fallbackKey: key,
                ),
              );
            })
            .where((option) => option.key.isNotEmpty)
            .toList();
        return options.isEmpty ? _defaultTrackServiceOptions : options;
      } catch (_) {
        return _defaultTrackServiceOptions;
      }
    });

final publicTracksProvider = FutureProvider<List<TrackListItem>>((ref) async {
  final repository = ref.watch(tracksRepositoryProvider);
  if (repository == null) return const [];
  final tracks = await repository.fetchPublicTracks();
  return tracks..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
});

/// Piste pubbliche con coordinate per la mappa unificata.
/// Query leggera — non usare per altri scopi.
final publicTrackPinsProvider = FutureProvider<List<TrackMapPin>>((ref) async {
  final repository = ref.watch(tracksRepositoryProvider);
  if (repository == null) return const [];
  return repository.fetchPublicTrackPins();
});

final managedTracksProvider = FutureProvider<List<TrackListItem>>((ref) async {
  final repository = ref.watch(tracksRepositoryProvider);
  // effectiveUserIdProvider: in impersonazione mostra le piste
  // dell'utente osservato, non dell'admin reale.
  final userId = ref.watch(effectiveUserIdProvider);
  if (repository == null || userId == null) {
    return const [];
  }

  return repository.fetchManagedTracks(userId: userId);
});

final publicTrackDetailProvider =
    FutureProvider.family<TrackDetail?, String>((ref, slug) async {
      final repository = ref.watch(tracksRepositoryProvider);
      final locale = ref.watch(localeProvider);
      if (repository == null) return null;
      return repository.fetchPublicTrackBySlug(
        slug,
        preferredLanguageCode: locale?.languageCode ?? 'it',
      );
    });

final managedTrackDetailProvider =
    FutureProvider.family<TrackDetail?, String>((ref, slug) async {
      final repository = ref.watch(tracksRepositoryProvider);
      // effectiveUserIdProvider + effectiveUserRoleProvider: in impersonazione
      // mostra/consente la pista dell'utente osservato, non dell'admin reale.
      final userId = ref.watch(effectiveUserIdProvider);
      final role = ref.watch(effectiveUserRoleProvider);
      final locale = ref.watch(localeProvider);
      if (repository == null || userId == null) return null;

      final lang = locale?.languageCode ?? 'it';

      // L'admin può editare qualsiasi pista, anche non assegnata a sé
      // e anche se non pubblica (es. rifiutata). Proviamo prima la via
      // normale (track_managers) e, se non trovata, usiamo il fallback
      // senza filtro ownership/is_public per chi ha ruolo admin.
      final managed = await repository.fetchManagedTrackBySlug(
        userId: userId,
        slug: slug,
        preferredLanguageCode: lang,
      );
      if (managed != null) return managed;

      if (role == 'admin') {
        return repository.fetchAnyTrackBySlug(slug, preferredLanguageCode: lang);
      }

      return null;
    });

/// Track inviate dall'organizzatore (draft | pending | rejected).
/// Lette da Supabase via la policy "organizer reads own".
final submittedTracksProvider =
    FutureProvider<List<SubmittedTrack>>((ref) async {
      final repository = ref.watch(tracksRepositoryProvider);
      // effectiveUserIdProvider: in impersonazione mostra le submission
      // dell'utente osservato, non dell'admin reale.
      final userId = ref.watch(effectiveUserIdProvider);
      if (repository == null || userId == null) return const [];
      return repository.fetchSubmittedTracks(userId: userId);
    });

final managedTrackRecentUpdatesProvider =
    FutureProvider.family<List<ManagedTrackUpdate>, String>((ref, trackId) async {
      final repository = ref.watch(tracksRepositoryProvider);
      // effectiveUserIdProvider: in impersonazione verifica ownership per
      // l'utente osservato, non per l'admin reale.
      final userId = ref.watch(effectiveUserIdProvider);
      if (repository == null || userId == null || trackId.isEmpty) {
        return const [];
      }

      return repository.fetchManagedTrackRecentUpdates(
        trackId: trackId,
        userId: userId,
      );
    });

final todayArrivalStatusProvider =
    FutureProvider.family<TodayArrivalStatus?, String>((ref, trackId) async {
      // Slug usati come ID da local drafts non ancora pubblicati → skip silenzioso.
      if (trackId.isEmpty || !_isValidUuid(trackId)) return null;
      final repository = ref.watch(tracksRepositoryProvider);
      // effectiveUserIdProvider: in impersonazione legge lo stato arrivi
      // dell'utente osservato, non dell'admin reale.
      final userId = ref.watch(effectiveUserIdProvider);
      if (repository == null || userId == null) return null;

      return repository.fetchTodayArrivalStatus(
        trackId: trackId,
        userId: userId,
      );
    });

final trackTodayArrivalSummaryProvider =
    FutureProvider.family<TrackArrivalSummary, String>((ref, trackId) async {
      // Slug usati come ID da local drafts non ancora pubblicati → skip silenzioso.
      if (trackId.isEmpty || !_isValidUuid(trackId)) return TrackArrivalSummary.empty();
      final repository = ref.watch(tracksRepositoryProvider);
      if (repository == null) return TrackArrivalSummary.empty();

      return repository.fetchTodayArrivalSummary(trackId: trackId);
    });

final trackWeatherProvider =
    FutureProvider.family<List<TrackWeatherDay>, TrackWeatherRequest>((
      ref,
      request,
    ) async {
      final repository = ref.watch(trackWeatherRepositoryProvider);
      return repository.fetchForecast(
        latitude: request.latitude,
        longitude: request.longitude,
      );
    });

final followedTrackIdsProvider =
    NotifierProvider<FollowedTrackIdsController, Set<String>>(
      FollowedTrackIdsController.new,
    );

final isTrackFollowedProvider = Provider.family<bool, String>((ref, trackId) {
  final followedIds = ref.watch(followedTrackIdsProvider);
  return followedIds.contains(trackId);
});

final effectiveFollowedTrackIdsProvider = FutureProvider<Set<String>>((ref) async {
  final impersonation = ref.watch(impersonationProvider);
  if (impersonation == null) {
    return ref.watch(followedTrackIdsProvider);
  }

  final repository = ref.watch(tracksRepositoryProvider);
  final userId = ref.watch(effectiveUserIdProvider);
  if (repository == null || userId == null) {
    return const <String>{};
  }

  try {
    return repository.fetchFollowedTrackIds(userId: userId);
  } catch (_) {
    return const <String>{};
  }
});

final trackFollowerCountProvider = FutureProvider.family<int, String>((ref, trackId) async {
  if (trackId.isEmpty || !_isValidUuid(trackId)) return 0;
  final repository = ref.watch(tracksRepositoryProvider);
  if (repository == null) {
    final followedIds = ref.watch(followedTrackIdsProvider);
    return followedIds.contains(trackId) ? 1 : 0;
  }

  try {
    return repository.fetchTrackFollowerCount(trackId: trackId);
  } catch (_) {
    final followedIds = ref.watch(followedTrackIdsProvider);
    return followedIds.contains(trackId) ? 1 : 0;
  }
});

class FollowedTrackIdsController extends Notifier<Set<String>> {
  String? _loadedForKey;
  Set<String> _cached = <String>{};

  @override
  Set<String> build() {
    final repository = ref.watch(tracksRepositoryProvider);
    final user = ref.watch(currentUserProvider);
    final nextKey = repository != null && user != null ? 'remote:${user.id}' : 'guest';

    if (_loadedForKey != nextKey) {
      _loadedForKey = nextKey;
      if (repository != null && user != null) {
        unawaited(_restoreRemote(repository: repository, userId: user.id));
      } else {
        _cached = <String>{};
        state = _cached;
      }
    }

    return _cached;
  }

  Future<void> _restoreRemote({
    required TracksRepository repository,
    required String userId,
  }) async {
    try {
      final followedIds = await repository.fetchFollowedTrackIds(userId: userId);
      _cached = followedIds;
      state = followedIds;
    } catch (_) {
      _cached = <String>{};
      state = _cached;
    }
  }

  bool toggle(String trackId) {
    final repository = ref.read(tracksRepositoryProvider);
    final user = ref.read(currentUserProvider);
    final next = <String>{...state};
    final nowFollowed = !next.contains(trackId);
    if (nowFollowed) {
      next.add(trackId);
    } else {
      next.remove(trackId);
    }
    _cached = next;
    state = next;
    // Sync remota solo per UUID validi; local-draft senza UUID pubblicato → skip.
    if (repository != null && user != null && _isValidUuid(trackId)) {
      unawaited(
        repository.setTrackFollowed(
          trackId: trackId,
          userId: user.id,
          followed: nowFollowed,
        ),
      );
    }
    return nowFollowed;
  }
}
