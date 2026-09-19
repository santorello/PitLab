import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/auth/application/auth_providers.dart';
import '../../../features/tracks/application/tracks_providers.dart';
import '../domain/spot_catalog.dart';
import '../../../shared/utils/moderation_message.dart';
import '../../../shared/utils/moderation_log.dart';

// ── Repository Supabase ───────────────────────────────────────────────────────

class SpotsRepository {
  const SpotsRepository(this._client);

  final SupabaseClient _client;

  static const _publicColumns =
      'id, slug, title, city, category, best_for, surface, note, '
      'image_accent, photo_count, address, latitude, longitude, '
      'image_urls, video_url, is_custom, is_owned_by_current_user, '
      'best_for_tags, surface_tags, access_type, best_season';

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
      'best_for_tags': spot.bestForTags,
      'surface_tags': spot.surfaceTags,
      'access_type': spot.accessType,
      'best_season': spot.bestSeason,
      'is_custom': true,
      'owner_id': userId,
    };
    final data = await _client
        .from('spots')
        .insert(payload)
        .select(
          'id, slug, title, city, category, best_for, surface, note, '
          'image_accent, photo_count, address, latitude, longitude, '
          'image_urls, video_url, is_custom, '
          'best_for_tags, surface_tags, access_type, best_season',
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
      'best_for_tags': spot.bestForTags,
      'surface_tags': spot.surfaceTags,
      'access_type': spot.accessType,
      'best_season': spot.bestSeason,
    };
    final data = await _client
        .from('spots')
        .update(payload)
        .eq('slug', spot.slug)
        .select(
          'id, slug, title, city, category, best_for, surface, note, '
          'image_accent, photo_count, address, latitude, longitude, '
          'image_urls, video_url, is_custom, '
          'best_for_tags, surface_tags, access_type, best_season',
        )
        .single();
    return SpotEntry.fromMap({
      ...data,
      'is_owned_by_current_user': true,
    });
  }

  /// Proposta di modifica da parte di chi non e' owner ne admin.
  /// ponytail: un solo insert, niente tabella di revisioni versionate.
  Future<void> submitEditSuggestion({
    required String userId,
    required String spotId,
    required Map<String, dynamic> payload,
  }) async {
    await _client.from('spot_edit_suggestions').insert({
      'spot_id': spotId,
      'submitted_by': userId,
      'payload': payload,
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

  /// Messaggio dell'ultimo salvataggio fallito, quando e' spiegabile
  /// all'utente (filtro contenuti). Letto subito dopo un metodo che ha
  /// restituito false; null altrimenti.
  String? lastSaveError;

  void _logBlock(Object error, String source, String sample) => logModerationBlock(
        ref.read(supabaseClientProvider),
        error,
        source: source,
        sample: sample,
      );

  @override
  List<SpotEntry> build() {
    final repository = ref.watch(spotsRepositoryProvider);
    if (repository != null && !_loaded) {
      _loaded = true;
      Future.microtask(_fetchFromSupabase);
    }
    // Stato iniziale VUOTO. Prima qui c'erano tre spot dimostrativi cablati
    // (Argine del Taro, Cava Roveri Trail, Campo Volo Nord): luoghi inventati
    // con coordinate reali, visibili anche ai visitatori non autenticati.
    // Difetto A-10 del giro QA 2026-09-13.
    return const <SpotEntry>[];
  }

  Future<void> _fetchFromSupabase() async {
    final repository = ref.read(spotsRepositoryProvider);
    if (repository == null) return;
    try {
      // Assegnazione INCONDIZIONATA: con la guardia `if (spots.isNotEmpty)`
      // un database vuoto lasciava in piedi per sempre lo stato precedente,
      // cioe' gli spot dimostrativi. Un elenco vuoto e' una risposta valida e
      // deve produrre lo stato vuoto della pagina.
      state = await repository.fetchAll();
    } catch (e) {
      debugPrint('[Spots] fetchAll error: $e');
    }
  }

  Future<bool> addCustomSpot(SpotEntry spot) async {
    final repository = ref.read(spotsRepositoryProvider);
    // effectiveUserIdProvider: in impersonazione crea lo spot per l'utente
    // osservato. Il JWT admin soddisfa "admins manage all" sulla tabella spots.
    final userId = ref.read(effectiveUserIdProvider);

    lastSaveError = null;
    if (repository != null && userId != null) {
      try {
        final saved = await repository.insertCustomSpot(
          userId: userId,
          spot: spot,
        );
        state = [saved, ...state.where((s) => s.slug != saved.slug)];
        return true;
      } catch (e) {
        // Testo respinto dal filtro: niente fallback locale, altrimenti lo
        // spot comparirebbe in UI senza essere mai stato salvato.
        lastSaveError = moderationMessage(e);
        if (lastSaveError != null) {
          _logBlock(e, 'spots', '${spot.title} ${spot.note}');
          return false;
        }
        rethrow;
      }
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
      lastSaveError = moderationMessage(e);
      _logBlock(e, 'spots', '${spot.title} ${spot.note}');
      debugPrint('[Spots] updateCustomSpot error: $e');
      return false;
    }
  }

  /// true = proposta registrata. Un secondo invio sullo stesso spot fallisce
  /// per via dell'indice unico sui pending: e' voluto.
  Future<bool> submitEditSuggestion({
    required String userId,
    required String spotId,
    required Map<String, dynamic> payload,
  }) async {
    final repository = ref.read(spotsRepositoryProvider);
    if (repository == null) return false;
    try {
      await repository.submitEditSuggestion(
        userId: userId,
        spotId: spotId,
        payload: payload,
      );
      return true;
    } catch (e) {
      lastSaveError = moderationMessage(e);
      _logBlock(e, 'spot_edit_suggestions', payload.values.join(' '));
      debugPrint('[Spots] submitEditSuggestion error: $e');
      return false;
    }
  }
}
