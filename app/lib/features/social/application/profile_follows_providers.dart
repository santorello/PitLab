import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/bootstrap/error_reporting.dart';
import '../../auth/application/auth_providers.dart';
import '../../pitcoin/providers/pitcoin_providers.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class ProfileFollowsRepository {
  const ProfileFollowsRepository(this._client);

  final SupabaseClient _client;

  /// Returns the set of profile UUIDs that [userId] currently follows.
  Future<Set<String>> fetchFollowedProfileIds({
    required String userId,
  }) async {
    final response = await _client
        .from('profile_follows')
        .select('followed_id')
        .eq('follower_id', userId);

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((row) => row['followed_id'] as String?)
        .whereType<String>()
        .toSet();
  }

  /// Upsert or delete a follow row (idempotent — mirrors shop_follows pattern).
  Future<void> setProfileFollowed({
    required String followedId,
    required String followerId,
    required bool followed,
  }) async {
    if (followed) {
      await _client.from('profile_follows').upsert({
        'follower_id': followerId,
        'followed_id': followedId,
      }, onConflict: 'follower_id,followed_id');
      return;
    }
    await _client
        .from('profile_follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('followed_id', followedId);
  }

  /// Calls the security-definer RPC — accessible by both anon and authenticated.
  Future<int> fetchFollowerCount({required String profileId}) async {
    try {
      final response = await _client.rpc(
        'get_profile_follower_count',
        params: {'profile_uuid': profileId},
      );
      if (response is int) return response;
      if (response is num) return response.toInt();
      return 0;
    } catch (e, st) {
      AppErrorReporter.report(e, st, context: 'profile_follows_providers');
      return 0;
    }
  }
}

// ── Repository provider ───────────────────────────────────────────────────────

final profileFollowsRepositoryProvider =
    Provider<ProfileFollowsRepository?>((ref) {
  final client = ref.watch(authClientProvider);
  if (client == null) return null;
  return ProfileFollowsRepository(client);
});

// ── Derived providers ─────────────────────────────────────────────────────────

final isProfileFollowedProvider =
    Provider.family<bool, String>((ref, profileId) {
  return ref.watch(followedProfileIdsProvider).contains(profileId);
});

final profileFollowerCountProvider =
    FutureProvider.family<int, String>((ref, profileId) async {
  final repository = ref.watch(profileFollowsRepositoryProvider);
  if (repository == null) {
    return ref.watch(followedProfileIdsProvider).contains(profileId) ? 1 : 0;
  }
  try {
    return repository.fetchFollowerCount(profileId: profileId);
  } catch (e, st) {
    AppErrorReporter.report(e, st, context: 'profile_follows_providers');
    return ref.watch(followedProfileIdsProvider).contains(profileId) ? 1 : 0;
  }
});

// ── Controller ────────────────────────────────────────────────────────────────

final followedProfileIdsProvider =
    NotifierProvider<FollowedProfileIdsController, Set<String>>(
  FollowedProfileIdsController.new,
);

class FollowedProfileIdsController extends Notifier<Set<String>> {
  String? _loadedForKey;
  Set<String> _cached = <String>{};

  @override
  Set<String> build() {
    final repository = ref.watch(profileFollowsRepositoryProvider);
    final user = ref.watch(currentUserProvider);
    final nextKey =
        repository != null && user != null ? 'remote:${user.id}' : 'guest';

    if (_loadedForKey != nextKey) {
      _loadedForKey = nextKey;
      if (repository != null && user != null) {
        unawaited(_restoreRemote(repository: repository, userId: user.id));
      } else {
        _cached = <String>{};
        state = _cached;
      }
    }

    return _cached;
  }

  Future<void> _restoreRemote({
    required ProfileFollowsRepository repository,
    required String userId,
  }) async {
    try {
      final ids = await repository.fetchFollowedProfileIds(userId: userId);
      _cached = ids;
      state = ids;
    } catch (e, st) {
      AppErrorReporter.report(e, st, context: 'profile_follows_providers');
      _cached = <String>{};
      state = _cached;
    }
  }

  /// Optimistically toggles follow state, persists in background, then
  /// invalidates PitCoin balance (follow triggers DB award).
  bool toggle(String profileId) {
    final repository = ref.read(profileFollowsRepositoryProvider);
    final user = ref.read(currentUserProvider);
    final next = <String>{...state};
    final nowFollowed = !next.contains(profileId);
    if (nowFollowed) {
      next.add(profileId);
    } else {
      next.remove(profileId);
    }
    _cached = next;
    state = next;

    if (repository != null && user != null) {
      unawaited(
        repository
            .setProfileFollowed(
              followedId: profileId,
              followerId: user.id,
              followed: nowFollowed,
            )
            .then((_) {
          // Re-fetch follower count after the write settles.
          Future<void>.delayed(
            const Duration(milliseconds: 1500),
            () => ref.invalidate(profileFollowerCountProvider(profileId)),
          );
          // Invalidate PitCoin balance so earned coins appear immediately.
          ref.invalidate(effectiveUserPitcoinBalanceProvider);
          ref.invalidate(effectiveUserPitcoinRecentDeltaProvider);
        }),
      );
    }

    return nowFollowed;
  }
}
