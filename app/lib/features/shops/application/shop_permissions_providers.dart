import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/auth_providers.dart';
import 'shop_editor_providers.dart';

class ShopOwnershipRepository {
  const ShopOwnershipRepository(this._client);

  final SupabaseClient _client;

  Future<Set<String>> fetchManagedShopSlugs(String userId) async {
    try {
      final response = await _client
          .from('shop_managers')
          .select('shop_id, shops(slug)')
          .eq('user_id', userId);

      return (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((row) => row['shops'])
          .whereType<Map<String, dynamic>>()
          .map((shop) => shop['slug'] as String?)
          .whereType<String>()
          .toSet();
    } catch (error) {
      debugPrint(
        '[ShopOwnership] Unable to fetch managed shops for user=$userId: $error',
      );
      return const <String>{};
    }
  }
}

final shopOwnershipRepositoryProvider = Provider<ShopOwnershipRepository?>((
  ref,
) {
  final client = ref.watch(authClientProvider);
  if (client == null) {
    return null;
  }

  return ShopOwnershipRepository(client);
});

final managedShopSlugsProvider = FutureProvider<Set<String>>((ref) async {
  final repository = ref.watch(shopOwnershipRepositoryProvider);
  // effectiveUserIdProvider: in impersonazione usa l'utente osservato, non l'admin.
  final userId = ref.watch(effectiveUserIdProvider);
  if (repository == null || userId == null) {
    return const <String>{};
  }

  return repository.fetchManagedShopSlugs(userId);
});

final canEditShopSlugProvider = FutureProvider.family<bool, String>((
  ref,
  slug,
) async {
  final canManageShops = ref.watch(canManageShopsProvider);
  final isAdmin = ref.watch(isAdminProvider);
  final impersonation = ref.watch(impersonationProvider);

  // When an admin is impersonating another user, shop edit permissions must
  // follow the impersonated identity, not the real admin account.
  if (isAdmin && impersonation == null) {
    return true;
  }
  if (!canManageShops) {
    return false;
  }

  // effectiveUserIdProvider: in impersonazione confronta con l'utente osservato.
  final effectiveUserId = ref.watch(effectiveUserIdProvider);
  final localDraft = ref.watch(editableShopProvider(slug));
  if (effectiveUserId != null &&
      localDraft != null &&
      localDraft.userId.isNotEmpty &&
      localDraft.userId == effectiveUserId) {
    return true;
  }

  final managedShopSlugs = await ref.watch(managedShopSlugsProvider.future);
  return managedShopSlugs.contains(slug);
});
