import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/local_storage_providers.dart';
import '../../../shared/utils/local_image_data_url.dart';
import '../../auth/application/auth_providers.dart';

class CreatedEventRecord {
  CreatedEventRecord({
    required this.id,
    required this.date,
    required this.title,
    required this.location,
    required this.note,
    required this.badge,
    required this.creatorLabel,
    required this.creatorRole,
    this.authorUserId,
    this.venue,
    List<String> imageUrls = const [],
    String? imageSource,
    this.startsAtIso,
    this.endsAtIso,
  }) : imageUrls = imageUrls.isNotEmpty
           ? imageUrls
           : [
               if (imageSource != null && imageSource.trim().isNotEmpty)
                 imageSource.trim(),
             ];

  final String id;
  final String date;
  final String title;
  final String location;
  final String note;
  final String badge;
  final String creatorLabel;
  final String creatorRole;
  final String? authorUserId;
  final String? venue;
  final List<String> imageUrls;
  final String? startsAtIso;
  final String? endsAtIso;

  String? get imageSource => imageUrls.isEmpty ? null : imageUrls.first;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'location': location,
      'note': note,
      'badge': badge,
      'creator_label': creatorLabel,
      'creator_role': creatorRole,
      'author_user_id': authorUserId,
      'venue': venue,
      'image_source': imageSource,
      'image_urls': imageUrls,
      'starts_at_iso': startsAtIso,
      'ends_at_iso': endsAtIso,
    };
  }

  Map<String, dynamic> toLocalCacheMap() {
    final cacheableImageUrls = imageUrls
        .where((url) => !url.startsWith('data:image'))
        .toList();
    final cacheImageSource = cacheableImageUrls.isEmpty
        ? null
        : cacheableImageUrls.first;

    return {
      'id': id,
      'date': date,
      'title': title,
      'location': location,
      'note': note,
      'badge': badge,
      'creator_label': creatorLabel,
      'creator_role': creatorRole,
      'author_user_id': authorUserId,
      'venue': venue,
      'image_source': cacheImageSource,
      'image_urls': cacheableImageUrls,
      'starts_at_iso': startsAtIso,
      'ends_at_iso': endsAtIso,
    };
  }

  factory CreatedEventRecord.fromMap(Map<String, dynamic> map) {
    return CreatedEventRecord(
      id: map['id'] as String? ?? '',
      date: map['date'] as String? ?? '',
      title: map['title'] as String? ?? '',
      location: map['location'] as String? ?? '',
      note: map['note'] as String? ?? '',
      badge: map['badge'] as String? ?? '',
      creatorLabel: map['creator_label'] as String? ?? '',
      creatorRole: map['creator_role'] as String? ?? 'user',
      authorUserId: map['author_user_id'] as String?,
      venue: map['venue'] as String?,
      imageUrls: _safeImageSources(
        (map['image_urls'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .map(_safeImageSource)
            .whereType<String>()
            .toList(),
        fallback: _safeImageSource(map['image_source'] as String?),
      ),
      startsAtIso: map['starts_at_iso'] as String?,
      endsAtIso: map['ends_at_iso'] as String?,
    );
  }

  /// Factory per riga Supabase dalla tabella community_events.
  factory CreatedEventRecord.fromRow(Map<String, dynamic> row) {
    final startsAtIso = row['starts_at'] as String?;
    return CreatedEventRecord(
      id: row['id'] as String? ?? '',
      date: _formatDate(startsAtIso),
      title: row['title'] as String? ?? '',
      location: row['location'] as String? ?? '',
      note: row['note'] as String? ?? '',
      badge: row['badge'] as String? ?? '',
      creatorLabel: row['creator_label'] as String? ?? '',
      creatorRole: row['creator_role'] as String? ?? 'user',
      authorUserId: row['author_id'] as String?,
      venue: row['venue'] as String?,
      imageUrls: _safeImageSources(
        (row['image_urls'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .map(_safeImageSource)
            .whereType<String>()
            .toList(),
      ),
      startsAtIso: startsAtIso,
      endsAtIso: row['ends_at'] as String?,
    );
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

  static List<String> _safeImageSources(
    List<String> imageUrls, {
    String? fallback,
  }) {
    if (imageUrls.isNotEmpty) {
      return imageUrls.take(maxEventImages).toList();
    }
    if (fallback != null && fallback.isNotEmpty) {
      return [fallback];
    }
    return const [];
  }

  static String? _safeImageSource(String? value) {
    final resolved = value?.trim();
    if (resolved == null || resolved.isEmpty) {
      return null;
    }
    if (isLocalImageDataUrlTooLarge(resolved)) {
      return null;
    }
    return resolved;
  }

  DateTime? get startsAt {
    final value = startsAtIso;
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  DateTime? get endsAt {
    final value = endsAtIso;
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}

// ── Repository Supabase ───────────────────────────────────────────────────────

class CommunityEventsRepository {
  const CommunityEventsRepository(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id, author_id, title, location, venue, note, badge, '
      'creator_label, creator_role, image_urls, starts_at, ends_at';

  Future<List<CreatedEventRecord>> fetchForUser(String userId) async {
    final data = await _client
        .from('community_events')
        .select(_columns)
        .eq('author_id', userId)
        .order('starts_at', ascending: false);
    return (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(CreatedEventRecord.fromRow)
        .toList();
  }

  Future<CreatedEventRecord> insert({
    required String userId,
    required CreatedEventRecord event,
  }) async {
    final startsAt = event.startsAt;
    final endsAt = event.endsAt;
    final payload = {
      'author_id': userId,
      'title': event.title,
      'location': event.location,
      'venue': event.venue ?? '',
      'note': event.note,
      'badge': event.badge,
      'creator_label': event.creatorLabel,
      'creator_role': event.creatorRole,
      'image_urls': event.imageUrls,
      if (startsAt != null) 'starts_at': startsAt.toUtc().toIso8601String(),
      if (endsAt != null) 'ends_at': endsAt.toUtc().toIso8601String(),
    };
    final data = await _client
        .from('community_events')
        .insert(payload)
        .select(_columns)
        .single();
    return CreatedEventRecord.fromRow(data);
  }

  Future<CreatedEventRecord> update({
    required String eventId,
    required CreatedEventRecord event,
  }) async {
    final startsAt = event.startsAt;
    final endsAt = event.endsAt;
    final payload = <String, dynamic>{
      'title': event.title,
      'location': event.location,
      'venue': event.venue ?? '',
      'note': event.note,
      'badge': event.badge,
      'creator_label': event.creatorLabel,
      'creator_role': event.creatorRole,
      'image_urls': event.imageUrls,
      if (startsAt != null) 'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt?.toUtc().toIso8601String(), // null = rimuovi data fine
    };
    final data = await _client
        .from('community_events')
        .update(payload)
        .eq('id', eventId)
        .select(_columns)
        .single();
    return CreatedEventRecord.fromRow(data);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

// Nota: savedShopIdsProvider rimosso — i negozi seguiti sono gestiti da
// followedShopIdsProvider in shop_follows_providers.dart (Supabase-backed).

const _createdEventsLegacyKey = 'profile_created_events_v1';
const _createdEventsPublicKey = 'profile_created_events_public_v1';

final communityEventsRepositoryProvider =
    Provider<CommunityEventsRepository?>((ref) {
      final client = ref.watch(authClientProvider);
      if (client == null) return null;
      return CommunityEventsRepository(client);
    });

final createdEventsProvider =
    NotifierProvider<CreatedEventsController, List<CreatedEventRecord>>(
      CreatedEventsController.new,
    );

class CreatedEventsController extends Notifier<List<CreatedEventRecord>> {
  bool _loaded = false;
  List<CreatedEventRecord> _cached = const [];

  @override
  List<CreatedEventRecord> build() {
    // Avvia il caricamento asincrono (da Supabase o SharedPreferences).
    // Usa effectiveUserIdProvider: durante impersonazione carica gli eventi
    // dell'utente osservato, non dell'admin reale.
    final effectiveUserId = ref.watch(effectiveUserIdProvider);
    final repository = ref.watch(communityEventsRepositoryProvider);
    if (!_loaded) {
      _loaded = true;
      if (repository != null && effectiveUserId != null) {
        Future.microtask(() => _fetchFromSupabase(repository, effectiveUserId));
      } else {
        Future.microtask(_restoreFromLocal);
      }
    }
    return _cached;
  }

  // ── Supabase ──────────────────────────────────────────────────────────────

  Future<void> _fetchFromSupabase(
    CommunityEventsRepository repository,
    String userId,
  ) async {
    try {
      final events = await repository.fetchForUser(userId);
      _cached = events;
      state = _cached;
      // Sincronizza su SharedPreferences come cache locale
      _persistLocal();
    } catch (e) {
      debugPrint('[CommunityEvents] fetchForUser error: $e');
      // Fallback: carica da SharedPreferences
      await _restoreFromLocal();
    }
  }

  // ── SharedPreferences (fallback / cache locale) ───────────────────────────

  Future<void> _restoreFromLocal() async {
    if (_cached.isNotEmpty) return;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final stored = prefs.getString(_createdEventsPublicKey);
    final restored = <CreatedEventRecord>[
      if (stored != null && stored.isNotEmpty) ..._decodeEvents(stored),
    ];

    final seenIds = restored.map((event) => event.id).toSet();
    for (final key in prefs.getKeys()) {
      if (!key.startsWith('$_createdEventsLegacyKey:')) {
        continue;
      }
      final legacyStored = prefs.getString(key);
      if (legacyStored == null || legacyStored.isEmpty) {
        continue;
      }
      for (final event in _decodeEvents(legacyStored)) {
        if (seenIds.add(event.id)) {
          restored.add(event);
        }
      }
    }

    _cached = restored;
    state = _cached;
  }

  static List<CreatedEventRecord> _decodeEvents(String stored) {
    final decoded = jsonDecode(stored) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CreatedEventRecord.fromMap)
        .toList();
  }

  Future<void> _persistLocal() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final encoded = jsonEncode(
        state.map((event) => event.toLocalCacheMap()).toList(),
      );
      await prefs.setString(_createdEventsPublicKey, encoded);
    } catch (e) {
      debugPrint('[CommunityEvents] _persistLocal error: $e');
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> add(CreatedEventRecord event) async {
    // Ottimistico: mostra subito il record con ID temporaneo
    _cached = [event, ...state.where((e) => e.id != event.id)];
    state = _cached;

    final repository = ref.read(communityEventsRepositoryProvider);
    // Usa effectiveUserIdProvider: l'evento viene salvato per l'utente
    // corrente (o per quello osservato in impersonazione).
    final effectiveUserId = ref.read(effectiveUserIdProvider);

    if (repository != null && effectiveUserId != null) {
      try {
        final saved = await repository.insert(userId: effectiveUserId, event: event);
        // Sostituisci il record temporaneo con l'UUID reale del server
        _cached = [
          saved,
          ...state.where((e) => e.id != event.id && e.id != saved.id),
        ];
        state = _cached;
      } catch (e) {
        debugPrint('[CommunityEvents] insert error: $e');
      }
    }

    _persistLocal();
  }

  Future<void> update(CreatedEventRecord updated) async {
    // Ottimistico: aggiorna subito la lista locale
    _cached = state.map((e) => e.id == updated.id ? updated : e).toList();
    state = _cached;

    final repository = ref.read(communityEventsRepositoryProvider);

    if (repository != null) {
      try {
        final saved = await repository.update(eventId: updated.id, event: updated);
        _cached = state.map((e) => e.id == saved.id ? saved : e).toList();
        state = _cached;
      } catch (e) {
        debugPrint('[CommunityEvents] update error: $e');
      }
    }

    _persistLocal();
  }
}

// ── Derived providers ─────────────────────────────────────────────────────────

final activeCreatedEventsProvider = Provider<List<CreatedEventRecord>>((ref) {
  final now = DateTime.now();
  final events = ref.watch(createdEventsProvider);
  return events.where((event) {
    final startsAt = event.startsAt;
    if (startsAt == null) {
      return true;
    }
    final local = startsAt.toLocal();
    return !local.isBefore(DateTime(now.year, now.month, now.day));
  }).toList();
});

final myActiveCreatedEventsProvider = Provider<List<CreatedEventRecord>>((ref) {
  // Usa effectiveUserIdProvider per mostrare gli eventi dell'utente osservato
  // in impersonazione, o del proprio utente se non c'è impersonazione.
  final userId = ref.watch(effectiveUserIdProvider);
  if (userId == null) {
    return const [];
  }
  final events = ref.watch(activeCreatedEventsProvider);
  return events.where((event) => event.authorUserId == userId).toList();
});

final archivedCreatedEventsProvider = Provider<List<CreatedEventRecord>>((ref) {
  final now = DateTime.now();
  final events = ref.watch(createdEventsProvider);
  return events.where((event) {
    final startsAt = event.startsAt;
    if (startsAt == null) {
      return false;
    }
    final local = startsAt.toLocal();
    return local.isBefore(DateTime(now.year, now.month, now.day));
  }).toList();
});

final myArchivedCreatedEventsProvider =
    Provider<List<CreatedEventRecord>>((ref) {
      final userId = ref.watch(currentUserProvider)?.id;
      if (userId == null) {
        return const [];
      }
      final events = ref.watch(archivedCreatedEventsProvider);
      return events.where((event) => event.authorUserId == userId).toList();
    });

final effectiveCreatedEventsProvider =
    FutureProvider<List<CreatedEventRecord>>((ref) async {
      final impersonation = ref.watch(impersonationProvider);
      if (impersonation == null) {
        return ref.watch(createdEventsProvider);
      }

      final repository = ref.watch(communityEventsRepositoryProvider);
      final userId = ref.watch(effectiveUserIdProvider);
      if (repository == null || userId == null) {
        return const [];
      }

      try {
        return repository.fetchForUser(userId);
      } catch (e) {
        debugPrint('[CommunityEvents] effectiveCreatedEvents error: $e');
        return const [];
      }
    });
