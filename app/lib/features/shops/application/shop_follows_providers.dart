import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/auth/application/auth_providers.dart';

class ShopFollowsRepository {
  const ShopFollowsRepository(this._client);

  final SupabaseClient _client;

  Future<Set<String>> fetchFollowedShopIds({
    required String userId,
  }) async {
    final response = await _client
        .from('shop_follows')
        .select('shop_id')
        .eq('user_id', userId);

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((row) => row['shop_id'] as String?)
        .whereType<String>()
        .toSet();
  }

  Future<void> setShopFollowed({
    required String shopId,
    required String userId,
    required bool followed,
  }) async {
    if (followed) {
      await _client.from('shop_follows').upsert({
        'shop_id': shopId,
        'user_id': userId,
      }, onConflict: 'shop_id,user_id');
      return;
    }

    await _client.from('shop_follows').delete().eq('shop_id', shopId).eq('user_id', userId);
  }

  Future<int> fetchShopFollowerCount({
    required String shopId,
  }) async {
    try {
      final response = await _client.rpc(
        'get_shop_follower_count',
        params: {'shop_uuid': shopId},
      );
      if (response is int) return response;
      if (response is num) return response.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }
}

final shopFollowsRepositoryProvider = Provider<ShopFollowsRepository?>((ref) {
  final client = ref.watch(authClientProvider);
  if (client == null) {
    return null;
  }
  return ShopFollowsRepository(client);
});

final followedShopIdsProvider = NotifierProvider<FollowedShopIdsController, Set<String>>(
  FollowedShopIdsController.new,
);

final isShopFollowedProvider = Provider.family<bool, String>((ref, shopId) {
  final followedIds = ref.watch(followedShopIdsProvider);
  return followedIds.contains(shopId);
});

final shopFollowerCountProvider = FutureProvider.family<int, String>((ref, shopId) async {
  final repository = ref.watch(shopFollowsRepositoryProvider);
  if (repository == null) {
    final followedIds = ref.watch(followedShopIdsProvider);
    return followedIds.contains(shopId) ? 1 : 0;
  }

  try {
    return repository.fetchShopFollowerCount(shopId: shopId);
  } catch (_) {
    final followedIds = ref.watch(followedShopIdsProvider);
    return followedIds.contains(shopId) ? 1 : 0;
  }
});

final effectiveFollowedShopIdsProvider = FutureProvider<Set<String>>((ref) async {
  final impersonation = ref.watch(impersonationProvider);
  if (impersonation == null) {
    return ref.watch(followedShopIdsProvider);
  }

  final repository = ref.watch(shopFollowsRepositoryProvider);
  final userId = ref.watch(effectiveUserIdProvider);
  if (repository == null || userId == null) {
    return const <String>{};
  }

  try {
    return repository.fetchFollowedShopIds(userId: userId);
  } catch (_) {
    return const <String>{};
  }
});

class FollowedShopIdsController extends Notifier<Set<String>> {
  String? _loadedForKey;
  Set<String> _cached = <String>{};

  @override
  Set<String> build() {
    final repository = ref.watch(shopFollowsRepositoryProvider);
    final user = ref.watch(currentUserProvider);
    final nextKey = repository != null && user != null ? 'remote:${user.id}' : 'guest';

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
    required ShopFollowsRepository repository,
    required String userId,
  }) async {
    try {
      final followedIds = await repository.fetchFollowedShopIds(userId: userId);
      _cached = followedIds;
      state = followedIds;
    } catch (_) {
      _cached = <String>{};
      state = _cached;
    }
  }

  bool toggle(String shopId) {
    final repository = ref.read(shopFollowsRepositoryProvider);
    final user = ref.read(currentUserProvider);
    final next = <String>{...state};
    final nowFollowed = !next.contains(shopId);
    if (nowFollowed) {
      next.add(shopId);
    } else {
      next.remove(shopId);
    }
    _cached = next;
    state = next;
    if (repository != null && user != null) {
      unawaited(
        repository.setShopFollowed(
          shopId: shopId,
          userId: user.id,
          followed: nowFollowed,
        ),
      );
    }
    return nowFollowed;
  }
}
