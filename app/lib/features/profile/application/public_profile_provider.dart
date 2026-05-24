import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../tracks/application/tracks_providers.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class PublicBuildRecord {
  const PublicBuildRecord({
    required this.id,
    required this.title,
    required this.meta,
    required this.specs,
    required this.imageUrls,
  });

  final String id;
  final String title;
  final String meta;
  final String specs;
  final List<String> imageUrls;

  factory PublicBuildRecord.fromMap(Map<String, dynamic> map) {
    return PublicBuildRecord(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      meta: map['meta'] as String? ?? '',
      specs: switch (map['specs']) {
        final List<dynamic> list => list.whereType<String>().join(', '),
        final String s => s,
        _ => '',
      },
      imageUrls: (map['image_urls'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}

class PublicProfileRecord {
  const PublicProfileRecord({
    required this.id,
    required this.publicSlug,
    required this.displayName,
    required this.avatarUrl,
    required this.role,
    required this.builds,
  });

  final String id;
  final String publicSlug;
  final String displayName;
  final String? avatarUrl;
  final String role;
  final List<PublicBuildRecord> builds;

  factory PublicProfileRecord.fromMap(
    Map<String, dynamic> map, {
    List<PublicBuildRecord> builds = const [],
  }) {
    return PublicProfileRecord(
      id: map['id'] as String? ?? '',
      publicSlug: map['public_slug'] as String? ?? '',
      displayName: map['display_name'] as String? ?? 'Pilota',
      avatarUrl: map['avatar_url'] as String?,
      role: map['role'] as String? ?? 'user',
      builds: builds,
    );
  }
}

// ── Repository ────────────────────────────────────────────────────────────────

class PublicProfileRepository {
  const PublicProfileRepository(this._client);

  final SupabaseClient _client;

  /// Recupera un profilo pubblico dal suo slug.
  /// Ritorna null se lo slug non esiste o il profilo non è marcato is_public.
  Future<PublicProfileRecord?> fetchBySlug(String slug) async {
    try {
      final profileData = await _client
          .from('profiles')
          .select('id, public_slug, display_name, avatar_url, role')
          .eq('public_slug', slug)
          .eq('is_public', true)
          .maybeSingle();

      if (profileData == null) return null;

      final userId = profileData['id'] as String;

      final buildsData = await _client
          .from('user_builds')
          .select('id, title, meta, specs, image_urls')
          .eq('owner_id', userId)
          .eq('is_public', true)
          .order('created_at', ascending: false);

      final builds = (buildsData as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(PublicBuildRecord.fromMap)
          .toList();

      return PublicProfileRecord.fromMap(profileData, builds: builds);
    } catch (e) {
      debugPrint('[PublicProfile] fetchBySlug error: $e');
      rethrow;
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final publicProfileRepositoryProvider = Provider<PublicProfileRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return PublicProfileRepository(client);
});

final publicProfileProvider =
    FutureProvider.family<PublicProfileRecord?, String>((ref, slug) async {
  final repository = ref.watch(publicProfileRepositoryProvider);
  if (repository == null) return null;
  return repository.fetchBySlug(slug);
});
