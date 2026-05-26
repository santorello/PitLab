import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../location/application/user_location_context_provider.dart';
import '../../tracks/application/tracks_providers.dart';

class HomeTrackWeather {
  const HomeTrackWeather({
    required this.trackName,
    required this.city,
    required this.temperatureC,
    required this.precipitationProbability,
    required this.weatherCode,
  });

  final String trackName;
  final String city;
  final int? temperatureC;
  final int? precipitationProbability;
  final int weatherCode;
}

class HomeBuildOfWeek {
  const HomeBuildOfWeek({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.meta,
    required this.imageUrls,
    required this.authorName,
    required this.authorSlug,
    required this.weeklyVotes,
    required this.commentCount,
    required this.awardedPoints,
  });

  final String id;
  final String ownerId;
  final String title;
  final String meta;
  final List<String> imageUrls;
  final String authorName;
  final String authorSlug;
  final int weeklyVotes;
  final int commentCount;
  final int awardedPoints;

  String get primaryImageUrl => imageUrls.isEmpty ? '' : imageUrls.first;

  factory HomeBuildOfWeek.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'];
    final profileMap = profile is Map<String, dynamic> ? profile : null;
    final fallbackSlug = map['author_public_slug'] as String? ??
        profileMap?['public_slug'] as String? ??
        '';
    final displayName = map['author_display_name'] as String? ??
        profileMap?['display_name'] as String? ??
        fallbackSlug;

    return HomeBuildOfWeek(
      id: map['id'] as String? ?? '',
      ownerId: map['owner_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      meta: map['meta'] as String? ?? '',
      imageUrls: _parseImageUrls(map['image_urls']),
      authorName: displayName.trim().isEmpty ? 'Pilota PitLap' : displayName.trim(),
      authorSlug: fallbackSlug,
      weeklyVotes: (map['weekly_votes'] as num?)?.toInt() ?? 0,
      commentCount: (map['comment_count'] as num?)?.toInt() ?? 0,
      awardedPoints: (map['awarded_points'] as num?)?.toInt() ?? 0,
    );
  }
}

class HomeOverviewStats {
  const HomeOverviewStats({
    required this.openTracks,
    required this.eventsNext30Days,
    required this.newSpots30Days,
    required this.publicShops,
    required this.geocodedShops,
    required this.publicBuilds,
  });

  final int openTracks;
  final int eventsNext30Days;
  final int newSpots30Days;
  final int publicShops;
  final int geocodedShops;
  final int publicBuilds;

  static const empty = HomeOverviewStats(
    openTracks: 0,
    eventsNext30Days: 0,
    newSpots30Days: 0,
    publicShops: 0,
    geocodedShops: 0,
    publicBuilds: 0,
  );

  factory HomeOverviewStats.fromMap(Map<String, dynamic> map) {
    return HomeOverviewStats(
      openTracks: (map['open_tracks'] as num?)?.toInt() ?? 0,
      eventsNext30Days: (map['events_next_30_days'] as num?)?.toInt() ?? 0,
      newSpots30Days: (map['new_spots_30_days'] as num?)?.toInt() ?? 0,
      publicShops: (map['public_shops'] as num?)?.toInt() ?? 0,
      geocodedShops: (map['geocoded_shops'] as num?)?.toInt() ?? 0,
      publicBuilds: (map['public_builds'] as num?)?.toInt() ?? 0,
    );
  }
}

class HomeTrendingTrack {
  const HomeTrendingTrack({
    required this.id,
    required this.slug,
    required this.name,
    required this.city,
    required this.shortDescription,
    required this.status,
    required this.arrivalsToday,
    required this.events30d,
    required this.followersCount,
    required this.updates14d,
    required this.trendScore,
  });

  final String id;
  final String slug;
  final String name;
  final String city;
  final String shortDescription;
  final String status;
  final int arrivalsToday;
  final int events30d;
  final int followersCount;
  final int updates14d;
  final int trendScore;

  factory HomeTrendingTrack.fromMap(Map<String, dynamic> map) {
    return HomeTrendingTrack(
      id: map['id'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      name: map['name'] as String? ?? '',
      city: map['city'] as String? ?? '',
      shortDescription: map['short_description'] as String? ?? '',
      status: map['status'] as String? ?? 'unknown',
      arrivalsToday: (map['arrivals_today'] as num?)?.toInt() ?? 0,
      events30d: (map['events_30d'] as num?)?.toInt() ?? 0,
      followersCount: (map['followers_count'] as num?)?.toInt() ?? 0,
      updates14d: (map['updates_14d'] as num?)?.toInt() ?? 0,
      trendScore: (map['trend_score'] as num?)?.toInt() ?? 0,
    );
  }
}

class PitcoinLeaderboardEntry {
  const PitcoinLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.publicSlug,
    required this.displayName,
    required this.avatarUrl,
    required this.totalPoints,
  });

  final int rank;
  final String userId;
  final String publicSlug;
  final String displayName;
  final String? avatarUrl;
  final int totalPoints;

  factory PitcoinLeaderboardEntry.fromMap(Map<String, dynamic> map) {
    final fallbackSlug = map['public_slug'] as String? ?? '';
    return PitcoinLeaderboardEntry(
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      userId: map['user_id'] as String? ?? '',
      publicSlug: fallbackSlug,
      displayName: (map['display_name'] as String?)?.trim().isNotEmpty == true
          ? (map['display_name'] as String).trim()
          : fallbackSlug,
      avatarUrl: map['avatar_url'] as String?,
      totalPoints: (map['total_points'] as num?)?.toInt() ?? 0,
    );
  }
}

final homeOverviewStatsProvider = FutureProvider<HomeOverviewStats>((ref) async {
  final client = ref.watch(authClientProvider);
  if (client == null) return HomeOverviewStats.empty;

  try {
    final row = await client
        .from('home_overview_stats')
        .select()
        .eq('id', 1)
        .maybeSingle();
    if (row == null) return HomeOverviewStats.empty;
    final stats = HomeOverviewStats.fromMap(row);
    if (!stats.isAllZero) return stats;

    final fallback = await _fetchHomeOverviewStatsFallback(client);
    return fallback.isAllZero ? stats : fallback;
  } catch (error) {
    debugPrint('[HomeDashboard] home_overview_stats unavailable: $error');
    return _fetchHomeOverviewStatsFallback(client);
  }
});

extension on HomeOverviewStats {
  bool get isAllZero =>
      openTracks == 0 &&
      eventsNext30Days == 0 &&
      newSpots30Days == 0 &&
      publicShops == 0 &&
      geocodedShops == 0 &&
      publicBuilds == 0;
}

Future<HomeOverviewStats> _fetchHomeOverviewStatsFallback(client) async {
  final now = DateTime.now();
  final next30 = now.add(const Duration(days: 30));
  final last30 = now.subtract(const Duration(days: 30));

  Future<int> safeLength(Future<dynamic> future) async {
    try {
      final rows = await future;
      return rows is List ? rows.length : 0;
    } catch (error) {
      debugPrint('[HomeDashboard] fallback stat unavailable: $error');
      return 0;
    }
  }

  final counts = await Future.wait<int>([
    safeLength(
      client.from('track_status_current').select('track_id').eq('status', 'open'),
    ),
    safeLength(
      client
          .from('events')
          .select('id')
          .gte('start_at', now.toIso8601String())
          .lte('start_at', next30.toIso8601String()),
    ),
    safeLength(
      client
          .from('spots')
          .select('id')
          .gte('created_at', last30.toIso8601String()),
    ),
    safeLength(
      client
          .from('shops')
          .select('id')
          .eq('is_public', true)
          .eq('approval_status', 'approved'),
    ),
    safeLength(
      client
          .from('shops')
          .select('id')
          .eq('is_public', true)
          .eq('approval_status', 'approved')
          .not('latitude', 'is', null)
          .not('longitude', 'is', null),
    ),
    safeLength(
      client
          .from('user_builds')
          .select('id')
          .eq('is_public', true),
    ),
  ]);

  return HomeOverviewStats(
    openTracks: counts[0],
    eventsNext30Days: counts[1],
    newSpots30Days: counts[2],
    publicShops: counts[3],
    geocodedShops: counts[4],
    publicBuilds: counts[5],
  );
}

final homeTrendingTracksProvider =
    FutureProvider<List<HomeTrendingTrack>>((ref) async {
  final client = ref.watch(authClientProvider);
  if (client == null) return const [];

  try {
    final response = await client
        .from('home_trending_tracks')
        .select()
        .order('trend_score', ascending: false)
        .order('name')
        .limit(8);

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(HomeTrendingTrack.fromMap)
        .where((track) => track.slug.isNotEmpty && track.name.isNotEmpty)
        .toList();
  } catch (error) {
    debugPrint('[HomeDashboard] home_trending_tracks unavailable: $error');
    return const [];
  }
});

final homeFeaturedTrackProvider = FutureProvider<HomeTrendingTrack?>((ref) async {
  final client = ref.watch(authClientProvider);
  if (client == null) return null;

  try {
    final row = await client
        .from('home_featured_track')
        .select()
        .maybeSingle();
    if (row == null) return null;
    return HomeTrendingTrack.fromMap(row);
  } catch (error) {
    debugPrint('[HomeDashboard] home_featured_track unavailable: $error');
    return null;
  }
});

final pitcoinPublicLeaderboardProvider =
    FutureProvider<List<PitcoinLeaderboardEntry>>((ref) async {
  final client = ref.watch(authClientProvider);
  if (client == null) return const [];

  try {
    final response = await client
        .from('pitcoin_public_leaderboard')
        .select()
        .order('total_points', ascending: false)
        .order('display_name')
        .limit(5);

    final entries = (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(PitcoinLeaderboardEntry.fromMap)
        .where((entry) => entry.publicSlug.isNotEmpty)
        .toList();
    entries.sort((a, b) {
      final pointsComparison = b.totalPoints.compareTo(a.totalPoints);
      if (pointsComparison != 0) return pointsComparison;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return entries;
  } catch (error) {
    debugPrint('[HomeDashboard] pitcoin_public_leaderboard unavailable: $error');
    return const [];
  }
});

List<String> _parseImageUrls(dynamic value) {
  if (value is List) {
    return value
        .whereType<String>()
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
  }

  if (value is! String || value.trim().isEmpty) {
    return const [];
  }

  final raw = value.trim();
  if (raw.startsWith('[')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList();
      }
    } catch (_) {
      return const [];
    }
  }

  if (!raw.startsWith('{') || !raw.endsWith('}')) {
    return [raw];
  }

  final content = raw.substring(1, raw.length - 1);
  final items = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;
  var escaped = false;

  for (final codeUnit in content.codeUnits) {
    final char = String.fromCharCode(codeUnit);
    if (escaped) {
      buffer.write(char);
      escaped = false;
      continue;
    }
    if (char == '\\') {
      escaped = true;
      continue;
    }
    if (char == '"') {
      inQuotes = !inQuotes;
      continue;
    }
    if (char == ',' && !inQuotes) {
      final item = buffer.toString().trim();
      if (item.isNotEmpty && item.toUpperCase() != 'NULL') items.add(item);
      buffer.clear();
      continue;
    }
    buffer.write(char);
  }

  final last = buffer.toString().trim();
  if (last.isNotEmpty && last.toUpperCase() != 'NULL') items.add(last);
  return items.where((url) => url.isNotEmpty).toList();
}

final homeBuildOfWeekProvider = FutureProvider<HomeBuildOfWeek?>((ref) async {
  final client = ref.watch(authClientProvider);
  if (client == null) return null;

  try {
    final row = await client
        .from('home_build_of_week')
        .select()
        .maybeSingle();
    if (row != null) return HomeBuildOfWeek.fromMap(row);
  } catch (error) {
    debugPrint('[HomeDashboard] home_build_of_week unavailable: $error');
  }

  try {
    final response = await client
        .from('user_builds')
        .select(
          'id, owner_id, title, meta, image_urls, created_at',
        )
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .limit(20);

    final builds = (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(HomeBuildOfWeek.fromMap)
        .where((build) => build.id.isNotEmpty && build.title.isNotEmpty)
        .toList();
    if (builds.isEmpty) return null;

    final index = DateTime.now().difference(DateTime(2026)).inDays % builds.length;
    return builds[index];
  } catch (error) {
    debugPrint('[HomeDashboard] public build fallback unavailable: $error');
    return null;
  }
});

final myPitcoinStreakProvider = FutureProvider<int>((ref) async {
  final client = ref.watch(authClientProvider);
  final user = ref.watch(currentUserProvider);
  if (client == null || user == null) return 0;

  try {
    final response = await client.rpc('get_my_pitcoin_streak');
    if (response is int) return response;
    if (response is num) return response.toInt();
    return 0;
  } catch (error) {
    debugPrint('[HomeDashboard] get_my_pitcoin_streak unavailable: $error');
    return 0;
  }
});

final homeTrackWeatherProvider =
    FutureProvider<List<HomeTrackWeather>>((ref) async {
  final pins = await ref.watch(publicTrackPinsProvider.future);
  if (pins.isEmpty) return const [];

  final repository = ref.watch(trackWeatherRepositoryProvider);
  final location = await ref.watch(userLocationContextProvider.future);
  final selected = [...pins]
    ..sort((a, b) {
      if (location.hasCoordinates) {
        final aDistance = distanceKmBetween(
          fromLatitude: location.latitude!,
          fromLongitude: location.longitude!,
          toLatitude: a.latitude,
          toLongitude: a.longitude,
        );
        final bDistance = distanceKmBetween(
          fromLatitude: location.latitude!,
          fromLongitude: location.longitude!,
          toLatitude: b.latitude,
          toLongitude: b.longitude,
        );
        return aDistance.compareTo(bDistance);
      }
      final statusScore = (b.status == 'open' ? 1 : 0) - (a.status == 'open' ? 1 : 0);
      if (statusScore != 0) return statusScore;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  final forecasts = await Future.wait(
    selected.take(4).map((pin) async {
      try {
        final forecast = await repository.fetchForecast(
          latitude: pin.latitude,
          longitude: pin.longitude,
          days: 1,
        );
        final today = forecast.isEmpty ? null : forecast.first;
        return HomeTrackWeather(
          trackName: pin.name,
          city: pin.city,
          temperatureC: today?.temperatureMaxC?.round(),
          precipitationProbability: today?.precipitationProbabilityMax,
          weatherCode: today?.weatherCode ?? -1,
        );
      } catch (error) {
        debugPrint('[HomeDashboard] Open-Meteo unavailable for ${pin.name}: $error');
        return null;
      }
    }),
  );

  return forecasts.whereType<HomeTrackWeather>().toList();
});
