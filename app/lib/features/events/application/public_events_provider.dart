import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/auth_providers.dart';
import '../../profile/application/profile_hub_providers.dart';

// ─── Repository ──────────────────────────────────────────────────────────────

class PublicEventsRepository {
  const PublicEventsRepository(this._client);

  final SupabaseClient _client;

  Future<List<CreatedEventRecord>> fetchUpcomingPublicEvents({
    int limit = 10,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final response = await _client
        .from('events')
        .select('''
          id,
          title,
          description,
          start_at,
          end_at,
          tracks(name, city)
        ''')
        .eq('visibility', 'public')
        .gte('start_at', now)
        .order('start_at')
        .limit(limit);

    final events = (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(mapPublicEventRow)
        .toList();
    events.sort(_compareEventsByStartDate);
    return events;
  }

  Future<List<CreatedEventRecord>> fetchPastPublicEvents({int limit = 50}) async {
    final now = DateTime.now().toUtc();
    final response = await _client
        .from('events')
        .select('''
          id,
          title,
          description,
          start_at,
          end_at,
          tracks(name, city)
        ''')
        .eq('visibility', 'public')
        .lt('start_at', now.toIso8601String())
        .order('start_at', ascending: false)
        .limit(limit);

    final events = (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(mapPublicEventRow)
        .where((event) {
          final effectiveEnd = event.endsAt ?? event.startsAt;
          if (effectiveEnd == null) return false;
          return effectiveEnd.toUtc().isBefore(now);
        })
        .toList();
    events.sort(_compareEventsByStartDateDesc);
    return events;
  }

  Future<CreatedEventRecord?> fetchPublicEventById(String eventId) async {
    final response = await _client
        .from('events')
        .select('''
          id,
          title,
          description,
          start_at,
          end_at,
          tracks(name, city)
        ''')
        .eq('id', eventId)
        .eq('visibility', 'public')
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return mapPublicEventRow(response);
  }

  static String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const days = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
      const months = [
        'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
        'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic',
      ];
      return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return '';
    }
  }
}

int _compareEventsByStartDate(CreatedEventRecord a, CreatedEventRecord b) {
  final aStart = a.startsAt;
  final bStart = b.startsAt;
  if (aStart == null && bStart == null) {
    return a.title.compareTo(b.title);
  }
  if (aStart == null) return 1;
  if (bStart == null) return -1;
  return aStart.compareTo(bStart);
}

int _compareEventsByStartDateDesc(CreatedEventRecord a, CreatedEventRecord b) {
  return _compareEventsByStartDate(b, a);
}

CreatedEventRecord mapPublicEventRow(Map<String, dynamic> row) {
  final track = row['tracks'] as Map<String, dynamic>?;
  final trackName = track?['name'] as String? ?? '';
  final city = track?['city'] as String? ?? '';
  final location = city.isNotEmpty ? city : trackName;

  final startsAtIso = row['start_at'] as String?;
  final endsAtIso = row['end_at'] as String?;
  final date = PublicEventsRepository._formatDate(startsAtIso);

  return CreatedEventRecord(
    id: row['id'] as String? ?? '',
    date: date,
    title: row['title'] as String? ?? '',
    location: location,
    note: row['description'] as String? ?? '',
    badge: 'Evento',
    creatorLabel: trackName,
    creatorRole: 'track',
    venue: trackName,
    startsAtIso: startsAtIso,
    endsAtIso: endsAtIso,
  );
}

// ─── Providers ───────────────────────────────────────────────────────────────

final publicEventsRepositoryProvider =
    Provider<PublicEventsRepository?>((ref) {
      final client = ref.watch(authClientProvider);
      if (client == null) return null;
      return PublicEventsRepository(client);
    });

final publicUpcomingEventsProvider =
    FutureProvider<List<CreatedEventRecord>>((ref) async {
      final repo = ref.watch(publicEventsRepositoryProvider);
      if (repo == null) return const [];
      return repo.fetchUpcomingPublicEvents();
    });

final publicPastEventsProvider =
    FutureProvider<List<CreatedEventRecord>>((ref) async {
      final repo = ref.watch(publicEventsRepositoryProvider);
      if (repo == null) return const [];
      return repo.fetchPastPublicEvents();
    });

final publicEventDetailProvider =
    FutureProvider.family<CreatedEventRecord?, String>((ref, eventId) async {
      final repo = ref.watch(publicEventsRepositoryProvider);
      if (repo == null) return null;
      return repo.fetchPublicEventById(eventId);
    });
