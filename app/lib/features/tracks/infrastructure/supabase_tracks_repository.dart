import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/models/submitted_track.dart';
import '../../../shared/models/track_arrival_summary.dart';
import '../../../shared/models/track_detail.dart';
import '../../../shared/models/track_list_item.dart';
import '../../../shared/models/track_map_pin.dart';
import '../../../shared/models/managed_track_update.dart';
import '../../../shared/models/today_arrival_status.dart';
import '../../../shared/repositories/tracks_repository.dart';

class SupabaseTracksRepository implements TracksRepository {
  const SupabaseTracksRepository(this._client);

  final SupabaseClient _client;
  static const _defaultRetryAttempts = 3;

  @override
  Future<List<TrackListItem>> fetchPublicTracks() async {
    final response = await _withRetry(
      operation: 'fetchPublicTracks',
      action: () => _client
          .from('tracks')
          .select('''
            id,
            slug,
            name,
            city,
            short_description,
            track_status_current(status, message),
            track_services(is_available, service_types(label_it, label_en)),
            track_category_links(track_categories(key))
          ''')
          .eq('is_public', true)
          .eq('approval_status', 'approved')
          .order('name'),
    );

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(TrackListItem.fromMap)
        .toList();
  }

  @override
  Future<List<TrackMapPin>> fetchPublicTrackPins() async {
    final response = await _withRetry(
      operation: 'fetchPublicTrackPins',
      action: () => _client
          .from('tracks')
          .select('slug, name, city, latitude, longitude, track_status_current(status)')
          .eq('is_public', true)
          .eq('approval_status', 'approved')
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .order('name'),
    );

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(TrackMapPin.fromMap)
        .toList();
  }

  @override
  Future<List<TrackListItem>> fetchManagedTracks({
    required String userId,
  }) async {
    final response = await _withRetry(
      operation: 'fetchManagedTracks',
      action: () => _client
          .from('track_managers')
          .select('''
            track_id,
            tracks(
              id,
              slug,
              name,
              city,
              short_description,
              track_status_current(status, message),
              track_services(is_available, service_types(label_it, label_en))
            )
          ''')
          .eq('user_id', userId)
          .order('created_at'),
    );

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((row) => row['tracks'])
        .whereType<Map<String, dynamic>>()
        .map(TrackListItem.fromMap)
        .toList();
  }

  @override
  Future<TrackDetail?> fetchPublicTrackBySlug(
    String slug, {
    String preferredLanguageCode = 'it',
  }) async {
    final response = await _withRetry(
      operation: 'fetchPublicTrackBySlug',
      action: () => _client
          .from('tracks')
          .select('''
            id,
            slug,
            name,
            city,
            country,
            short_description,
            description,
            address,
            latitude,
            longitude,
            external_map_url,
            track_status_current(status, message),
            track_services(
              is_available,
              service_types(label_it, label_en)
            ),
            track_category_links(track_categories(key))
          ''')
          .eq('is_public', true)
          .eq('slug', slug)
          .maybeSingle(),
    );

    if (response == null) {
      return null;
    }

    return TrackDetail.fromMap(
      response,
      preferredLanguageCode: preferredLanguageCode,
    );
  }

  @override
  Future<TrackDetail?> fetchAnyTrackBySlug(
    String slug, {
    String preferredLanguageCode = 'it',
  }) async {
    // Identico a fetchPublicTrackBySlug ma senza il filtro is_public:
    // l'admin può accedere anche a piste rifiutate/nascoste.
    final response = await _withRetry(
      operation: 'fetchAnyTrackBySlug',
      action: () => _client
          .from('tracks')
          .select('''
            id,
            slug,
            name,
            city,
            country,
            short_description,
            description,
            address,
            latitude,
            longitude,
            external_map_url,
            track_status_current(status, message),
            track_services(
              is_available,
              service_types(label_it, label_en)
            ),
            track_category_links(track_categories(key))
          ''')
          .eq('slug', slug)
          .maybeSingle(),
    );

    if (response == null) return null;
    return TrackDetail.fromMap(
      response,
      preferredLanguageCode: preferredLanguageCode,
    );
  }

  @override
  Future<TrackDetail?> fetchManagedTrackBySlug({
    required String userId,
    required String slug,
    String preferredLanguageCode = 'it',
  }) async {
    // Step 1: resolve the track_id values managed by this user.
    // Filtering on embedded resources with .eq('relation.column') is
    // unreliable in PostgREST and triggers 406 errors; a two-step query
    // that filters the parent table via .inFilter() is always safe.
    final managerRows = await _withRetry(
      operation: 'fetchManagedTrackBySlug_ids',
      action: () => _client
          .from('track_managers')
          .select('track_id')
          .eq('user_id', userId),
    );

    final managedIds = (managerRows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((row) => row['track_id'] as String?)
        .whereType<String>()
        .toList();

    if (managedIds.isEmpty) return null;

    // Step 2: fetch the track by slug, restricted to managed IDs.
    final response = await _withRetry(
      operation: 'fetchManagedTrackBySlug_detail',
      action: () => _client
          .from('tracks')
          .select('''
            id,
            slug,
            name,
            city,
            country,
            short_description,
            description,
            address,
            latitude,
            longitude,
            external_map_url,
            track_status_current(status, message),
            track_services(
              is_available,
              service_types(key, label_it, label_en)
            ),
            track_category_links(track_categories(key))
          ''')
          .eq('slug', slug)
          .inFilter('id', managedIds)
          .maybeSingle(),
    );

    if (response == null) return null;

    return TrackDetail.fromMap(
      response,
      preferredLanguageCode: preferredLanguageCode,
    );
  }

  @override
  Future<TodayArrivalStatus?> fetchTodayArrivalStatus({
    required String trackId,
    required String userId,
  }) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    debugPrint(
      '[ArrivalFlow] Fetch today status trackId=$trackId user=$userId date=$today',
    );
    final response = await _withRetry(
      operation: 'fetchTodayArrivalStatus',
      action: () => _client
          .from('arrivals')
          .select('status, updated_at')
          .eq('track_id', trackId)
          .eq('user_id', userId)
          .eq('arrival_date', today)
          .maybeSingle(),
    );

    if (response == null) {
      debugPrint('[ArrivalFlow] No arrival record found for trackId=$trackId user=$userId');
      return null;
    }

    final status = response['status'] as String?;
    final updatedAt = response['updated_at'] == null
        ? null
        : DateTime.tryParse(response['updated_at'] as String);
    debugPrint(
      '[ArrivalFlow] Fetched arrival status=$status for trackId=$trackId user=$userId',
    );
    if (status == null || status.isEmpty) {
      return null;
    }

    return TodayArrivalStatus(
      status: status,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<TrackArrivalSummary> fetchTodayArrivalSummary({
    required String trackId,
  }) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    try {
      final response = await _withRetry(
        operation: 'fetchTodayArrivalSummaryRpc',
        action: () => _client.rpc(
          'get_public_track_arrival_summary',
          params: {
            'track_uuid': trackId,
            'target_date': today,
          },
        ),
      );

      if (response is List<dynamic> && response.isNotEmpty) {
        final row = response.first;
        if (row is Map<String, dynamic>) {
          return TrackArrivalSummary.fromMap(row);
        }
      }

      if (response is Map<String, dynamic>) {
        return TrackArrivalSummary.fromMap(response);
      }
    } catch (error) {
      debugPrint(
        '[ArrivalFlow] RPC get_public_track_arrival_summary unavailable for trackId=$trackId: $error',
      );
      return TrackArrivalSummary.empty();
    }

    return TrackArrivalSummary.empty();
  }

  @override
  Future<void> upsertTodayArrivalStatus({
    required String trackId,
    required String userId,
    required String status,
  }) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    debugPrint(
      '[ArrivalFlow] Upsert arrival status=$status trackId=$trackId user=$userId date=$today',
    );
    await _withRetry(
      operation: 'upsertTodayArrivalStatus',
      action: () => _client.from('arrivals').upsert({
        'track_id': trackId,
        'user_id': userId,
        'arrival_date': today,
        'status': status,
      }, onConflict: 'track_id,user_id,arrival_date'),
    );
    await _withRetry(
      operation: 'cleanupOldArrivalStatus',
      action: () => _client
          .from('arrivals')
          .delete()
          .eq('user_id', userId)
          .lt('arrival_date', today),
    );
    debugPrint(
      '[ArrivalFlow] Upsert completed trackId=$trackId user=$userId date=$today',
    );
  }

  @override
  Future<Set<String>> fetchFollowedTrackIds({
    required String userId,
  }) async {
    final response = await _withRetry(
      operation: 'fetchFollowedTrackIds',
      action: () => _client
          .from('track_follows')
          .select('track_id')
          .eq('user_id', userId),
    );

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((row) => row['track_id'] as String?)
        .whereType<String>()
        .toSet();
  }

  @override
  Future<int> fetchTrackFollowerCount({
    required String trackId,
  }) async {
    try {
      final response = await _withRetry(
        operation: 'fetchTrackFollowerCount',
        action: () => _client.rpc(
          'get_track_follower_count',
          params: {'track_uuid': trackId},
        ),
      );
      if (response is int) return response;
      if (response is num) return response.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> setTrackFollowed({
    required String trackId,
    required String userId,
    required bool followed,
  }) async {
    if (followed) {
      await _withRetry(
        operation: 'setTrackFollowedUpsert',
        action: () => _client.from('track_follows').upsert({
          'track_id': trackId,
          'user_id': userId,
        }, onConflict: 'track_id,user_id'),
      );
      return;
    }

    await _withRetry(
      operation: 'setTrackFollowedDelete',
      action: () => _client
          .from('track_follows')
          .delete()
          .eq('track_id', trackId)
          .eq('user_id', userId),
    );
  }

  @override
  Future<void> saveManagedTrackSnapshot({
    required String trackId,
    required String userId,
    required String status,
    required String message,
    required bool compressedAirAvailable,
    required bool bathroomsAvailable,
  }) async {
    final normalizedMessage = message.trim();

    await _client.from('track_status_current').upsert({
      'track_id': trackId,
      'status': status,
      'message': normalizedMessage.isEmpty ? null : normalizedMessage,
      'updated_by': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'track_id');

    await _client.from('track_status_history').insert({
      'track_id': trackId,
      'status': status,
      'message': normalizedMessage.isEmpty ? null : normalizedMessage,
      'updated_by': userId,
    });

    final serviceTypes = await _client
        .from('service_types')
        .select('id, key')
        .inFilter('key', ['compressed_air', 'toilets']);

    final typeByKey = <String, String>{};
    for (final row in (serviceTypes as List<dynamic>).whereType<Map<String, dynamic>>()) {
      final key = row['key'] as String?;
      final id = row['id'] as String?;
      if (key != null && id != null) {
        typeByKey[key] = id;
      }
    }

    final updates = <Map<String, dynamic>>[];
    final compressedAirId = typeByKey['compressed_air'];
    if (compressedAirId != null) {
      updates.add({
        'track_id': trackId,
        'service_type_id': compressedAirId,
        'is_available': compressedAirAvailable,
      });
    }

    final bathroomsId = typeByKey['toilets'];
    if (bathroomsId != null) {
      updates.add({
        'track_id': trackId,
        'service_type_id': bathroomsId,
        'is_available': bathroomsAvailable,
      });
    }

    if (updates.isNotEmpty) {
      await _client.from('track_services').upsert(
        updates,
        onConflict: 'track_id,service_type_id',
      );
    }
  }

  @override
  Future<List<ManagedTrackUpdate>> fetchManagedTrackRecentUpdates({
    required String trackId,
    required String userId,
    int limit = 8,
  }) async {
    debugPrint(
      '[ManagerFlow] Fetch recent updates trackId=$trackId user=$userId limit=$limit',
    );
    final response = await _withRetry(
      operation: 'fetchManagedTrackRecentUpdates',
      action: () => _client
          .from('track_status_history')
          .select('status, message, updated_at, updated_by')
          .eq('track_id', trackId)
          .order('updated_at', ascending: false)
          .limit(limit),
    );

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ManagedTrackUpdate.fromMap)
        .toList();
  }

  @override
  Future<void> updateManagedTrackDetails({
    required String trackId,
    required String userId,
    required String slug,
    required String name,
    required String shortDescription,
    required String description,
    required String address,
    required String city,
    required String country,
    required String externalMapUrl,
    required List<String> availableServiceKeys,
    List<String> categoryKeys = const [],
  }) async {
    await _client
        .from('tracks')
        .update({
          'slug': slug,
          'name': name,
          'short_description': shortDescription.isEmpty ? null : shortDescription,
          'description': description.isEmpty ? null : description,
          'address': address.isEmpty ? null : address,
          'city': city,
          'country': country,
          'external_map_url': externalMapUrl.isEmpty ? null : externalMapUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', trackId);

    // ── Servizi ──────────────────────────────────────────────────────
    final serviceTypes = await _client
        .from('service_types')
        .select('id, key');

    final selectedKeys = availableServiceKeys.toSet();
    final serviceUpdates = <Map<String, dynamic>>[];

    for (final row in (serviceTypes as List<dynamic>).whereType<Map<String, dynamic>>()) {
      final serviceId = row['id'] as String?;
      final serviceKey = row['key'] as String?;
      if (serviceId == null || serviceKey == null) {
        continue;
      }
      serviceUpdates.add({
        'track_id': trackId,
        'service_type_id': serviceId,
        'is_available': selectedKeys.contains(serviceKey),
      });
    }

    if (serviceUpdates.isNotEmpty) {
      await _client.from('track_services').upsert(
        serviceUpdates,
        onConflict: 'track_id,service_type_id',
      );
    }

    // ── Categorie ────────────────────────────────────────────────────
    if (categoryKeys.isNotEmpty) {
      // Recupera gli ID delle categorie selezionate
      final categoryRows = await _client
          .from('track_categories')
          .select('id, key')
          .inFilter('key', categoryKeys);

      final selectedCategoryIds = (categoryRows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((row) => row['id'] as String?)
          .whereType<String>()
          .toList();

      // Elimina tutti i link esistenti e reinserisce quelli selezionati
      await _client
          .from('track_category_links')
          .delete()
          .eq('track_id', trackId);

      if (selectedCategoryIds.isNotEmpty) {
        await _client.from('track_category_links').insert(
          selectedCategoryIds
              .map((catId) => {'track_id': trackId, 'category_id': catId})
              .toList(),
        );
      }
    } else {
      // Nessuna categoria selezionata: rimuove tutti i link
      await _client
          .from('track_category_links')
          .delete()
          .eq('track_id', trackId);
    }

    // ── Status history ───────────────────────────────────────────────
    // Usa 'info' per indicare un aggiornamento della scheda (non un cambio
    // di stato operativo come open/closed/wet).
    await _client.from('track_status_history').insert({
      'track_id': trackId,
      'status': 'info',
      'message': 'Scheda pista aggiornata dal pannello gestione.',
      'updated_by': userId,
    });
  }

  Future<T> _withRetry<T>({
    required String operation,
    required Future<T> Function() action,
    int maxAttempts = _defaultRetryAttempts,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await action();
      } catch (error) {
        lastError = error;
        final shouldRetry =
            attempt < maxAttempts && _isRetryableError(error);
        if (!shouldRetry) {
          rethrow;
        }
        debugPrint(
          '[SupabaseRetry] operation=$operation attempt=$attempt failed, retrying: $error',
        );
        final delayMs = attempt * 250;
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }
    }
    throw StateError(
      'Unexpected retry exit for $operation: $lastError',
    );
  }

  // ── Track submission (organizer → Supabase) ────────────────────────────

  static const _submittedTrackColumns =
      'id, slug, name, city, short_description, description, address, country, '
      'image_url, contact_email, phone, external_map_url, organization_name, '
      'approval_status, review_notes, created_at';

  @override
  Future<SubmittedTrack> insertSubmittedTrack({
    required String submittedBy,
    required SubmittedTrack track,
  }) async {
    final data = await _client
        .from('tracks')
        .insert(track.toInsertMap(submittedBy: submittedBy))
        .select(_submittedTrackColumns)
        .single();
    return SubmittedTrack.fromMap(data);
  }

  @override
  Future<SubmittedTrack> updateSubmittedTrack({
    required SubmittedTrack track,
  }) async {
    final data = await _client
        .from('tracks')
        .update(track.toUpdateMap())
        .eq('id', track.id)
        .select(_submittedTrackColumns)
        .single();
    return SubmittedTrack.fromMap(data);
  }

  @override
  Future<List<SubmittedTrack>> fetchSubmittedTracks({
    required String userId,
  }) async {
    try {
      final data = await _client
          .from('tracks')
          .select(_submittedTrackColumns)
          .eq('submitted_by', userId)
          .inFilter('approval_status', ['draft', 'pending', 'rejected'])
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(SubmittedTrack.fromMap)
          .toList();
    } catch (e) {
      debugPrint('[TracksRepo] fetchSubmittedTracks error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────

  bool _isRetryableError(Object error) {
    if (error is PostgrestException) {
      final code = (error.code ?? '').toLowerCase();
      if (code.startsWith('08') || code == '53300' || code == '57014') {
        return true;
      }

      final message = error.message.toLowerCase();
      if (message.contains('timeout') ||
          message.contains('timed out') ||
          message.contains('connection') ||
          message.contains('temporarily unavailable')) {
        return true;
      }

      return false;
    }

    final raw = error.toString().toLowerCase();
    return raw.contains('timeout') ||
        raw.contains('timed out') ||
        raw.contains('socket') ||
        raw.contains('connection reset') ||
        raw.contains('network') ||
        raw.contains('temporarily unavailable');
  }
}
