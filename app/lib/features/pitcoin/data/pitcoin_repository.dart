import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/pitcoin_action_definition.dart';
import 'models/pitcoin_badge.dart';
import 'models/pitcoin_balance.dart';
import 'models/pitcoin_transaction.dart';

/// Repository read-only sul sistema PitCoin.
///
/// Tutte le scritture su `pitcoin_transactions` e `user_badges` avvengono
/// esclusivamente lato Postgres via trigger `SECURITY DEFINER`: il client
/// non insertisce mai direttamente (vedi `docs/pitcoin-system.md` §7).
class PitcoinRepository {
  const PitcoinRepository(this._client);

  final SupabaseClient _client;

  /// Recupera il balance dell'utente.
  ///
  /// Tenta prima `user_pitcoin_balances` (visibile a owner+admin via RLS).
  /// Se non accessibile o vuoto, fallback alla view pubblica `public_user_pitcoin`
  /// (espone solo `total_points` per profili public).
  /// Ritorna null se non esiste alcun record.
  Future<PitcoinBalance?> fetchBalance(String userId) async {
    try {
      final response = await _client
          .from('user_pitcoin_balances')
          .select('user_id, total_points, lifetime_earned, last_action_at')
          .eq('user_id', userId)
          .maybeSingle();
      if (response != null) {
        return PitcoinBalance.fromMap(response);
      }
    } catch (e) {
      debugPrint('[Pitcoin] fetchBalance owner-path failed: $e');
    }

    try {
      final publicResponse = await _client
          .from('public_user_pitcoin')
          .select('user_id, public_slug, total_points')
          .eq('user_id', userId)
          .maybeSingle();
      if (publicResponse != null) {
        return PitcoinBalance.fromPublicMap(publicResponse);
      }
    } catch (e) {
      debugPrint('[Pitcoin] fetchBalance public-path failed: $e');
    }

    return null;
  }

  /// Variante per recupero balance via public_slug (profilo pubblico).
  Future<PitcoinBalance?> fetchBalanceBySlug(String publicSlug) async {
    try {
      final response = await _client
          .from('public_user_pitcoin')
          .select('user_id, public_slug, total_points')
          .eq('public_slug', publicSlug)
          .maybeSingle();
      if (response == null) return null;
      return PitcoinBalance.fromPublicMap(response);
    } catch (e) {
      debugPrint('[Pitcoin] fetchBalanceBySlug failed: $e');
      return null;
    }
  }

  /// Storico transazioni dell'utente (paginato, desc per awarded_at).
  /// Visibile solo a owner+admin via RLS — restituisce lista vuota se
  /// negato dalla policy.
  Future<List<PitcoinTransaction>> fetchTransactions(
    String userId, {
    int limit = 30,
    DateTime? before,
  }) async {
    try {
      var query = _client
          .from('pitcoin_transactions')
          .select(
            'id, user_id, action_key, points, source_table, source_id, metadata, awarded_at',
          )
          .eq('user_id', userId);

      if (before != null) {
        query = query.lt('awarded_at', before.toUtc().toIso8601String());
      }

      final response = await query
          .order('awarded_at', ascending: false)
          .limit(limit);

      return (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(PitcoinTransaction.fromMap)
          .toList();
    } catch (e) {
      debugPrint('[Pitcoin] fetchTransactions failed: $e');
      return const [];
    }
  }

  /// Conteggio + somma punti delle transazioni delle ultime [days] giornate.
  /// Usata dalla card "delta ultimi 7 giorni" in profilo.
  Future<int> fetchRecentDeltaPoints(
    String userId, {
    int days = 7,
  }) async {
    try {
      final since = DateTime.now().toUtc().subtract(Duration(days: days));
      final response = await _client
          .from('pitcoin_transactions')
          .select('points')
          .eq('user_id', userId)
          .gte('awarded_at', since.toIso8601String());

      var sum = 0;
      for (final row in (response as List<dynamic>)) {
        if (row is Map<String, dynamic>) {
          sum += (row['points'] as num?)?.toInt() ?? 0;
        }
      }
      return sum;
    } catch (e) {
      debugPrint('[Pitcoin] fetchRecentDeltaPoints failed: $e');
      return 0;
    }
  }

  /// Catalogo completo delle azioni abilitate.
  /// Visibile a tutti (anche anon) via RLS.
  Future<List<PitcoinActionDefinition>> fetchActionDefinitions() async {
    try {
      final response = await _client
          .from('pitcoin_action_definitions')
          .select(
            'action_key, name_it, name_en, description_it, description_en, category, base_points',
          )
          .eq('enabled', true)
          .order('category')
          .order('action_key');

      return (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(PitcoinActionDefinition.fromMap)
          .toList();
    } catch (e) {
      debugPrint('[Pitcoin] fetchActionDefinitions failed: $e');
      return const [];
    }
  }

  /// Badge ottenute dall'utente (owner-path).
  /// Fa una JOIN sulla definizione per restituire un oggetto completo.
  Future<List<PitcoinBadge>> fetchUserBadges(String userId) async {
    try {
      final response = await _client
          .from('user_badges')
          .select(
            'badge_key, awarded_at, '
            'pitcoin_badge_definitions(badge_key, name_it, name_en, description_it, description_en, icon_asset, category, tier, sort_order)',
          )
          .eq('user_id', userId)
          .order('awarded_at', ascending: false);

      return (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(PitcoinBadge.fromJoinedMap)
          .toList();
    } catch (e) {
      debugPrint('[Pitcoin] fetchUserBadges owner-path failed: $e');
    }

    // Fallback: view pubblica `public_user_badges` (joinata su definizione).
    try {
      final response = await _client
          .from('public_user_badges')
          .select(
            'badge_key, awarded_at, '
            'pitcoin_badge_definitions(badge_key, name_it, name_en, description_it, description_en, icon_asset, category, tier, sort_order)',
          )
          .eq('user_id', userId)
          .order('awarded_at', ascending: false);

      return (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(PitcoinBadge.fromJoinedMap)
          .toList();
    } catch (e) {
      debugPrint('[Pitcoin] fetchUserBadges public-path failed: $e');
      return const [];
    }
  }

  /// Variante per recupero badge ottenute via public_slug (profilo pubblico).
  Future<List<PitcoinBadge>> fetchUserBadgesBySlug(String publicSlug) async {
    try {
      final response = await _client
          .from('public_user_badges')
          .select(
            'badge_key, awarded_at, public_slug, '
            'pitcoin_badge_definitions(badge_key, name_it, name_en, description_it, description_en, icon_asset, category, tier, sort_order)',
          )
          .eq('public_slug', publicSlug)
          .order('awarded_at', ascending: false);

      return (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(PitcoinBadge.fromJoinedMap)
          .toList();
    } catch (e) {
      debugPrint('[Pitcoin] fetchUserBadgesBySlug failed: $e');
      return const [];
    }
  }

  /// Catalogo completo delle badge definizione (anche quelle non ancora sbloccate).
  Future<List<PitcoinBadge>> fetchAllBadgeDefinitions() async {
    try {
      final response = await _client
          .from('pitcoin_badge_definitions')
          .select(
            'badge_key, name_it, name_en, description_it, description_en, icon_asset, category, tier, sort_order',
          )
          .eq('enabled', true)
          .order('sort_order')
          .order('badge_key');

      return (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((row) => PitcoinBadge.fromDefinitionMap(row))
          .toList();
    } catch (e) {
      debugPrint('[Pitcoin] fetchAllBadgeDefinitions failed: $e');
      return const [];
    }
  }
}
