import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/utils/db_list_parser.dart';
import '../../tracks/application/tracks_providers.dart';

class PublicProfileListing {
  const PublicProfileListing({
    required this.id,
    required this.publicSlug,
    required this.displayName,
    required this.role,
    required this.publicBuildCount,
    this.avatarUrl,
    this.previewImageUrl,
  });

  final String id;
  final String publicSlug;
  final String displayName;
  final String role;
  final int publicBuildCount;
  final String? avatarUrl;
  final String? previewImageUrl;

  String get roleLabel => switch (role) {
        'track_organizer' => 'Organizzatore pista',
        'shop_owner' || 'shop_manager' => 'Gestore negozio',
        'admin' => 'Admin PitLap',
        _ => 'Pilota',
      };

  factory PublicProfileListing.fromMap(
    Map<String, dynamic> map, {
    int publicBuildCount = 0,
    String? previewImageUrl,
  }) {
    return PublicProfileListing(
      id: map['id'] as String? ?? '',
      publicSlug: map['public_slug'] as String? ?? '',
      displayName: map['display_name'] as String? ?? 'Pilota PitLap',
      role: map['role'] as String? ?? 'user',
      avatarUrl: map['avatar_url'] as String?,
      publicBuildCount: publicBuildCount,
      previewImageUrl: previewImageUrl,
    );
  }
}

class PublicProfilesRepository {
  const PublicProfilesRepository(this._client);

  final SupabaseClient _client;

  Future<List<PublicProfileListing>> fetchPublicProfiles() async {
    try {
      final profileRows = await _client
          .from('profiles')
          .select('id, public_slug, display_name, avatar_url, role')
          .eq('is_public', true)
          .order('display_name');

      final profileMaps = (profileRows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .where((row) => (row['public_slug'] as String? ?? '').isNotEmpty)
          .toList();

      final profileIds = profileMaps
          .map((row) => row['id'] as String?)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final buildCounts = <String, int>{};
      final buildPreviews = <String, String>{};

      if (profileIds.isNotEmpty) {
        final buildRows = await _client
            .from('user_builds')
            .select('owner_id, image_urls')
            .eq('is_public', true)
            .inFilter('owner_id', profileIds)
            .order('created_at', ascending: false);

        for (final row in (buildRows as List<dynamic>)
            .whereType<Map<String, dynamic>>()) {
          final ownerId = row['owner_id'] as String? ?? '';
          if (ownerId.isEmpty) continue;
          buildCounts[ownerId] = (buildCounts[ownerId] ?? 0) + 1;

          if (!buildPreviews.containsKey(ownerId)) {
            final images = parseDbStringList(row['image_urls']);
            if (images.isNotEmpty) {
              buildPreviews[ownerId] = images.first;
            }
          }
        }
      }

      return profileMaps
          .map(
            (row) => PublicProfileListing.fromMap(
              row,
              publicBuildCount: buildCounts[row['id'] as String? ?? ''] ?? 0,
              previewImageUrl: buildPreviews[row['id'] as String? ?? ''],
            ),
          )
          .toList();
    } catch (error) {
      debugPrint('[PublicProfiles] fetchPublicProfiles error: $error');
      rethrow;
    }
  }
}

final publicProfilesRepositoryProvider =
    Provider<PublicProfilesRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return PublicProfilesRepository(client);
});

final publicProfilesProvider =
    FutureProvider<List<PublicProfileListing>>((ref) async {
  final repository = ref.watch(publicProfilesRepositoryProvider);
  if (repository == null) return const [];
  return repository.fetchPublicProfiles();
});
