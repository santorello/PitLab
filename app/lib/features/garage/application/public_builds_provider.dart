import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/utils/db_list_parser.dart';
import '../../tracks/application/tracks_providers.dart';

class PublicBuildAuthor {
  const PublicBuildAuthor({
    required this.id,
    required this.displayName,
    required this.publicSlug,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String publicSlug;
  final String? avatarUrl;

  bool get hasPublicProfile => publicSlug.trim().isNotEmpty;

  factory PublicBuildAuthor.fromMap(Map<String, dynamic> map) {
    return PublicBuildAuthor(
      id: map['id'] as String? ?? '',
      displayName: map['display_name'] as String? ?? 'Pilota PitLap',
      publicSlug: map['public_slug'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}

class PublicBuildListing {
  const PublicBuildListing({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.meta,
    required this.specs,
    required this.imageUrls,
    required this.createdAt,
    required this.author,
  });

  final String id;
  final String ownerId;
  final String title;
  final String meta;
  final List<String> specs;
  final List<String> imageUrls;
  final DateTime? createdAt;
  final PublicBuildAuthor? author;

  String get primaryImageUrl => imageUrls.isEmpty ? '' : imageUrls.first;

  String get authorName => author?.displayName.trim().isNotEmpty == true
      ? author!.displayName.trim()
      : 'Pilota PitLap';

  String get specsLabel => specs.join(' · ');

  factory PublicBuildListing.fromMap(
    Map<String, dynamic> map, {
    PublicBuildAuthor? author,
  }) {
    return PublicBuildListing(
      id: map['id'] as String? ?? '',
      ownerId: map['owner_id'] as String? ?? '',
      title: map['title'] as String? ?? 'Build PitLap',
      meta: map['meta'] as String? ?? '',
      specs: parseDbStringList(map['specs']),
      imageUrls: parseDbStringList(map['image_urls']),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
      author: author,
    );
  }
}

class PublicBuildsRepository {
  const PublicBuildsRepository(this._client);

  final SupabaseClient _client;

  Future<List<PublicBuildListing>> fetchPublicBuilds() async {
    try {
      final buildRows = await _client
          .from('user_builds')
          .select('id, owner_id, title, meta, specs, image_urls, created_at')
          .eq('is_public', true)
          .order('created_at', ascending: false);

      final buildMaps = (buildRows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();

      final ownerIds = buildMaps
          .map((row) => row['owner_id'] as String?)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final authors = <String, PublicBuildAuthor>{};
      if (ownerIds.isNotEmpty) {
        final profileRows = await _client
            .from('profiles')
            .select('id, display_name, public_slug, avatar_url')
            .eq('is_public', true)
            .inFilter('id', ownerIds);

        for (final row in (profileRows as List<dynamic>)
            .whereType<Map<String, dynamic>>()) {
          final author = PublicBuildAuthor.fromMap(row);
          if (author.id.isNotEmpty) {
            authors[author.id] = author;
          }
        }
      }

      return buildMaps
          .map(
            (row) => PublicBuildListing.fromMap(
              row,
              author: authors[row['owner_id'] as String? ?? ''],
            ),
          )
          .toList();
    } catch (error) {
      debugPrint('[PublicBuilds] fetchPublicBuilds error: $error');
      rethrow;
    }
  }
}

final publicBuildsRepositoryProvider = Provider<PublicBuildsRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return PublicBuildsRepository(client);
});

final publicBuildsProvider = FutureProvider<List<PublicBuildListing>>((ref) async {
  final repository = ref.watch(publicBuildsRepositoryProvider);
  if (repository == null) return const [];
  return repository.fetchPublicBuilds();
});
