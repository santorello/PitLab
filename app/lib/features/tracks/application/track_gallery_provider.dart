import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tracks_providers.dart';

/// Foto della galleria pista: righe `track_media` con media_type = 'gallery'.
/// `storage_path` e' il percorso nel bucket `media` (serve per eliminare);
/// l'URL pubblico si ricava dal path.
class TrackGalleryPhoto {
  const TrackGalleryPhoto({
    required this.id,
    required this.storagePath,
    required this.url,
  });

  final String id;
  final String storagePath;
  final String url;
}

final trackGalleryProvider =
    FutureProvider.family<List<TrackGalleryPhoto>, String>((ref, trackId) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null || !isPublishedTrackId(trackId)) return const [];
  final rows = await client
      .from('track_media')
      .select('id, storage_path')
      .eq('track_id', trackId)
      .eq('media_type', 'gallery')
      .order('sort_order')
      .order('created_at');
  final bucket = client.storage.from('media');
  return [
    for (final row in rows)
      TrackGalleryPhoto(
        id: row['id'] as String,
        storagePath: row['storage_path'] as String,
        url: bucket.getPublicUrl(row['storage_path'] as String),
      ),
  ];
});
