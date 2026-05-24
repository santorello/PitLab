import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/auth/application/auth_providers.dart';
import '../../../features/tracks/application/tracks_providers.dart';
import '../domain/spot_catalog.dart';

// ── Repository Supabase ───────────────────────────────────────────────────────

class SpotsRepository {
  const SpotsRepository(this._client);

  final SupabaseClient _client;

  static const _publicColumns =
      'id, slug, title, city, category, best_for, surface, note, '
      'image_accent, photo_count, address, latitude, longitude, '
      'image_urls, video_url, is_custom, is_owned_by_current_user';

  Future<List<SpotEntry>> fetchAll() async {
    final data = await _client
        .from('public_spots')
        .select(_publicColumns)
        .order('is_custom', ascending: false)
        .order('created_at');
    return (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(SpotEntry.fromMap)
        .toList();
  }

  Future<SpotEntry> insertCustomSpot({
    required String userId,
    required SpotEntry spot,
  }) async {
    final payload = {
      'slug': spot.slug,
      'title': spot.title,
      'city': spot.city,
      'category': spot.category,
      'best_for': spot.bestFor,
      'surface': spot.surface,
      'note': spot.note,
      'image_accent': colorToSignedArgb32(spot.imageAccent),
      'photo_count': spot.photoCount,
      'address': spot.address,
      'latitude': spot.latitude,
      'longitude': spot.longitude,
      'image_urls': spot.imageUrls,
      'video_url': spot.videoUrl,
      'is_custom': true,
      'owner_id': userId,
    };
    final data = await _client
        .from('spots')
        .insert(payload)
        .select(
          'id, slug, title, city, category, best_for, surface, note, '
          'image_accent, photo_count, address, latitude, longitude, '
          'image_urls, video_url, is_custom',
        )
        .single();
    return SpotEntry.fromMap({
      ...data,
      'is_owned_by_current_user': true,
    });
  }

  Future<SpotEntry> updateCustomSpot({required SpotEntry spot}) async {
    final payload = {
      'title': spot.title,
      'city': spot.city,
      'category': spot.category,
      'best_for': spot.bestFor,
      'surface': spot.surface,
      'note': spot.note,
      'image_accent': colorToSignedArgb32(spot.imageAccent),
      'photo_count': spot.photoCount,
      'address': spot.address,
      'latitude': spot.latitude,
      'longitude': spot.longitude,
      'image_urls': spot.imageUrls,
      'video_url': spot.videoUrl,
    };
    final data = await _client
        .from('spots')
        .update(payload)
        .eq('slug', spot.slug)
        .select(
          'id, slug, title, city, category, best_for, surface, note, '
          'image_accent, photo_count, address, latitude, longitude, '
          'image_urls, video_url, is_custom',
        )
        .single();
    return SpotEntry.fromMap({
      ...data,
      'is_owned_by_current_user': true,
    });
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final spotsRepositoryProvider = Provider<SpotsRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SpotsRepository(client);
});

final spotEntriesProvider =
    NotifierProvider<SpotEntriesController, List<SpotEntry>>(
      SpotEntriesController.new,
    );

class SpotEntriesController extends Notifier<List<SpotEntry>> {
  bool _loaded = false;

  @override
  List<SpotEntry> build() {
    final repository = ref.watch(spotsRepositoryProvider);
    if (repository != null && !_loaded) {
      _loaded = true;
      Future.microtask(_fetchFromSupabase);
    }
    return SpotCatalog.defaultSpots;
  }

  Future<void> _fetchFromSupabase() async {
    final repository = ref.read(spotsRepositoryProvider);
    if (repository == null) return;
    try {
      final spots = await repository.fetchAll();
      if (spots.isNotEmpty) {
        state = spots;
      }
    } catch (e) {
      debugPrint('[Spots] fetchAll error: $e');
    }
  }

  Future<bool> addCustomSpot(SpotEntry spot) async {
    final repository = ref.read(spotsRepositoryProvider);
    // effectiveUserIdProvider: in impersonazione crea lo spot per l'utente
    // osservato. Il JWT admin soddisfa "admins manage all" sulla tabella spots.
    final userId = ref.read(effectiveUserIdProvider);

    if (repository != null && userId != null) {
      final saved = await repository.insertCustomSpot(
        userId: userId,
        spot: spot,
      );
      state = [saved, ...state.where((s) => s.slug != saved.slug)];
      return true;
    }

    // Fallback locale se Supabase non disponibile
    state = [spot, ...state.where((s) => s.slug != spot.slug)];
    return false;
  }

  Future<bool> updateCustomSpot(SpotEntry spot) async {
    final repository = ref.read(spotsRepositoryProvider);
    if (repository == null) return false;
    try {
      final saved = await repository.updateCustomSpot(spot: spot);
      state = state.map((s) => s.slug == saved.slug ? saved : s).toList();
      return true;
    } catch (e) {
      debugPrint('[Spots] updateCustomSpot error: $e');
      return false;
    }
  }
}
