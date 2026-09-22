import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/utils/db_list_parser.dart';
import '../../../shared/utils/moderation_message.dart';
import '../../auth/application/auth_providers.dart';
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
      // Link al profilo solo se pubblico; il nome si mostra comunque (build pubblica = firmata).
      publicSlug: map['is_public'] == true ? (map['public_slug'] as String? ?? '') : '',
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
    this.likeCount = 0,
  });

  final String id;
  final String ownerId;
  final String title;
  final String meta;
  final List<String> specs;
  final List<String> imageUrls;
  final DateTime? createdAt;
  final PublicBuildAuthor? author;

  /// Like ricevuti (righe di user_build_votes): e' anche il voto per la
  /// Build della settimana.
  final int likeCount;

  String get primaryImageUrl => imageUrls.isEmpty ? '' : imageUrls.first;

  String get authorName => author?.displayName.trim().isNotEmpty == true
      ? author!.displayName.trim()
      : 'Pilota PitLap';

  String get specsLabel => specs.join(' · ');

  factory PublicBuildListing.fromMap(
    Map<String, dynamic> map, {
    PublicBuildAuthor? author,
    int likeCount = 0,
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
      likeCount: likeCount,
    );
  }
}

class PublicBuildsRepository {
  const PublicBuildsRepository(this._client);

  final SupabaseClient _client;

  // ponytail: conteggio lato client, basta finche' le build sono centinaia;
  // con migliaia serve un contatore denormalizzato (task 18, prestazioni).
  Future<Map<String, int>> _likeCounts(List<String> buildIds) async {
    final ids = buildIds.where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) return const {};
    try {
      final rows = await _client
          .from('user_build_votes')
          .select('build_id')
          .inFilter('build_id', ids);
      final counts = <String, int>{};
      for (final row in (rows as List<dynamic>).whereType<Map>()) {
        final id = row['build_id'] as String? ?? '';
        counts[id] = (counts[id] ?? 0) + 1;
      }
      return counts;
    } catch (error) {
      debugPrint('[PublicBuilds] likeCounts error: $error');
      return const {};
    }
  }

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
            // ponytail: gli ospiti vedono solo profili pubblici (RLS anon); per loro resta "Pilota PitLap".
            .select('id, display_name, public_slug, avatar_url, is_public')
            .inFilter('id', ownerIds);

        for (final row in (profileRows as List<dynamic>)
            .whereType<Map<String, dynamic>>()) {
          final author = PublicBuildAuthor.fromMap(row);
          if (author.id.isNotEmpty) {
            authors[author.id] = author;
          }
        }
      }

      final likes = await _likeCounts(
        buildMaps.map((row) => row['id'] as String? ?? '').toList(),
      );

      return buildMaps
          .map(
            (row) => PublicBuildListing.fromMap(
              row,
              author: authors[row['owner_id'] as String? ?? ''],
              likeCount: likes[row['id'] as String? ?? ''] ?? 0,
            ),
          )
          .toList();
    } catch (error) {
      debugPrint('[PublicBuilds] fetchPublicBuilds error: $error');
      rethrow;
    }
  }
}

extension PublicBuildDetailQueries on PublicBuildsRepository {
  /// Una sola build pubblica, con autore e like. null se non esiste o non e'
  /// pubblica (la RLS nasconde le build private).
  Future<PublicBuildListing?> fetchPublicBuild(String id) async {
    final row = await _client
        .from('user_builds')
        .select('id, owner_id, title, meta, specs, image_urls, created_at')
        .eq('id', id)
        .eq('is_public', true)
        .maybeSingle();
    if (row == null) return null;
    PublicBuildAuthor? author;
    final ownerId = row['owner_id'] as String? ?? '';
    if (ownerId.isNotEmpty) {
      final profile = await _client
          .from('profiles')
          .select('id, display_name, public_slug, avatar_url, is_public')
          .eq('id', ownerId)
          .maybeSingle();
      if (profile != null) author = PublicBuildAuthor.fromMap(profile);
    }
    final likes = await _likeCounts([id]);
    return PublicBuildListing.fromMap(
      row,
      author: author,
      likeCount: likes[id] ?? 0,
    );
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

final publicBuildDetailProvider =
    FutureProvider.autoDispose.family<PublicBuildListing?, String>((ref, id) {
  final repository = ref.watch(publicBuildsRepositoryProvider);
  if (repository == null) return Future<PublicBuildListing?>.value();
  return repository.fetchPublicBuild(id);
});

// ── Like alle build ────────────────────────────────────────────────────────

class BuildLikeState {
  const BuildLikeState({required this.count, required this.likedByMe});

  final int count;
  final bool likedByMe;
}

/// Like di una build: conteggio + "mi piace gia'", con aggiornamento
/// ottimistico. Scrive su user_build_votes (RLS: solo build pubbliche e non
/// proprie; trigger rate limit 60 ogni 10 minuti).
class BuildLikeNotifier extends AsyncNotifier<BuildLikeState> {
  BuildLikeNotifier(this._buildId);

  final String _buildId;

  @override
  Future<BuildLikeState> build() async {
    final client = ref.watch(supabaseClientProvider);
    final userId = ref.watch(currentUserProvider)?.id;
    if (client == null) {
      return const BuildLikeState(count: 0, likedByMe: false);
    }
    final rows = await client
        .from('user_build_votes')
        .select('user_id')
        .eq('build_id', _buildId);
    final list = (rows as List<dynamic>).whereType<Map>().toList();
    return BuildLikeState(
      count: list.length,
      likedByMe:
          userId != null && list.any((row) => row['user_id'] == userId),
    );
  }

  /// null = ok, altrimenti messaggio da mostrare.
  Future<String?> toggle() async {
    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserProvider)?.id;
    final current = state.value;
    if (client == null || current == null) return '';
    if (userId == null) return 'Accedi per mettere like alle build.';

    final next = BuildLikeState(
      count: current.count + (current.likedByMe ? -1 : 1),
      likedByMe: !current.likedByMe,
    );
    state = AsyncData(next);
    try {
      if (current.likedByMe) {
        await client
            .from('user_build_votes')
            .delete()
            .eq('build_id', _buildId)
            .eq('user_id', userId);
      } else {
        await client
            .from('user_build_votes')
            .insert({'build_id': _buildId, 'user_id': userId});
      }
      ref.invalidate(publicBuildsProvider);
      return null;
    } catch (error) {
      state = AsyncData(current);
      return rateLimitMessage(error) ??
          'Like non salvato. Riprova tra poco.';
    }
  }
}

final buildLikeProvider = AsyncNotifierProvider.autoDispose
    .family<BuildLikeNotifier, BuildLikeState, String>(BuildLikeNotifier.new);
