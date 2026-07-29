import '../models/submitted_track.dart';
import '../models/track_list_item.dart';
import '../models/track_detail.dart';
import '../models/track_arrival_summary.dart';
import '../models/track_map_pin.dart';
import '../models/managed_track_update.dart';
import '../models/today_arrival_status.dart';

abstract class TracksRepository {
  Future<List<TrackListItem>> fetchPublicTracks();

  /// Ritorna le piste pubbliche con coordinate valide per la mappa unificata.
  /// Query leggera: solo slug, name, city, lat, lng, status.
  Future<List<TrackMapPin>> fetchPublicTrackPins();
  Future<List<TrackListItem>> fetchManagedTracks({
    required String userId,
  });
  Future<TrackDetail?> fetchManagedTrackBySlug({
    required String userId,
    required String slug,
    String preferredLanguageCode = 'it',
  });
  Future<TrackDetail?> fetchPublicTrackBySlug(
    String slug, {
    String preferredLanguageCode = 'it',
  });

  /// Come [fetchPublicTrackBySlug] ma senza il filtro `is_public`.
  /// Usato dall'admin per editare piste non ancora pubbliche.
  Future<TrackDetail?> fetchAnyTrackBySlug(
    String slug, {
    String preferredLanguageCode = 'it',
  });
  Future<TodayArrivalStatus?> fetchTodayArrivalStatus({
    required String trackId,
    required String userId,
  });
  Future<TrackArrivalSummary> fetchTodayArrivalSummary({
    required String trackId,
  });
  Future<void> upsertTodayArrivalStatus({
    required String trackId,
    required String userId,
    required String status,
  });
  Future<Set<String>> fetchFollowedTrackIds({
    required String userId,
  });
  Future<int> fetchTrackFollowerCount({
    required String trackId,
  });
  Future<void> setTrackFollowed({
    required String trackId,
    required String userId,
    required bool followed,
  });
  Future<void> saveManagedTrackSnapshot({
    required String trackId,
    required String userId,
    required String status,
    required String message,
    required bool compressedAirAvailable,
    required bool bathroomsAvailable,
  });
  Future<List<ManagedTrackUpdate>> fetchManagedTrackRecentUpdates({
    required String trackId,
    required String userId,
    int limit = 8,
  });
  // ── Track submission (organizer → Supabase) ────────────────────────────

  /// Inserisce una nuova pista con approval_status=draft|pending.
  /// Restituisce il record con l'UUID assegnato da Supabase.
  Future<SubmittedTrack> insertSubmittedTrack({
    required String submittedBy,
    required SubmittedTrack track,
  });

  /// Aggiorna una pista in stato draft|pending (l'organizzatore può correggere).
  Future<SubmittedTrack> updateSubmittedTrack({required SubmittedTrack track});

  /// Ritorna tutte le track dell'organizzatore (draft + pending + rejected).
  Future<List<SubmittedTrack>> fetchSubmittedTracks({required String userId});

  // ── Managed track details ───────────────────────────────────────────────

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
    String? imageUrl,
  });
}
