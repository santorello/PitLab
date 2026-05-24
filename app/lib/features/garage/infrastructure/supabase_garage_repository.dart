import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/user_build.dart';
import '../../../shared/repositories/garage_repository.dart';

class SupabaseGarageRepository implements GarageRepository {
  const SupabaseGarageRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<UserBuild>> fetchBuilds({required String userId}) async {
    try {
      final data = await _client
          .from('user_builds')
          .select('id, owner_id, title, meta, specs, image_urls, is_public, created_at, updated_at')
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(UserBuild.fromMap)
          .toList();
    } catch (e) {
      debugPrint('[Garage] fetchBuilds error: $e');
      rethrow;
    }
  }

  @override
  Future<UserBuild> createBuild({
    required String userId,
    required UserBuild build,
  }) async {
    final payload = build.toInsertMap(ownerId: userId);
    final data = await _client
        .from('user_builds')
        .insert(payload)
        .select()
        .single();
    return UserBuild.fromMap(data);
  }

  @override
  Future<UserBuild> updateBuild({required UserBuild build}) async {
    final data = await _client
        .from('user_builds')
        .update(build.toUpdateMap())
        .eq('id', build.id)
        .select()
        .single();
    return UserBuild.fromMap(data);
  }

  @override
  Future<void> deleteBuild({required String buildId}) async {
    await _client.from('user_builds').delete().eq('id', buildId);
  }

  @override
  Future<void> toggleVisibility({
    required String buildId,
    required bool isPublic,
  }) async {
    await _client
        .from('user_builds')
        .update({'is_public': isPublic})
        .eq('id', buildId);
  }
}
