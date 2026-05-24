import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../tracks/application/tracks_providers.dart';
import '../data/models/pitcoin_action_definition.dart';
import '../data/models/pitcoin_badge.dart';
import '../data/models/pitcoin_balance.dart';
import '../data/models/pitcoin_transaction.dart';
import '../data/pitcoin_repository.dart';

/// Repository PitCoin: null se Supabase non configurato.
final pitcoinRepositoryProvider = Provider<PitcoinRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return PitcoinRepository(client);
});

// ─── Balance ────────────────────────────────────────────────────────────────

/// Balance di uno specifico userId.
///
/// Per la vista profilo dell'utente loggato passare `effectiveUserIdProvider`
/// per rispettare l'impersonazione admin (vedi auth_providers).
final userPitcoinBalanceProvider =
    FutureProvider.family<PitcoinBalance?, String>((ref, userId) async {
  final repository = ref.watch(pitcoinRepositoryProvider);
  if (repository == null) return null;
  if (userId.trim().isEmpty) return null;
  return repository.fetchBalance(userId);
});

/// Balance recuperato dal public_slug (profilo pubblico /u/:slug).
final pitcoinBalanceBySlugProvider =
    FutureProvider.family<PitcoinBalance?, String>((ref, slug) async {
  final repository = ref.watch(pitcoinRepositoryProvider);
  if (repository == null) return null;
  if (slug.trim().isEmpty) return null;
  return repository.fetchBalanceBySlug(slug);
});

/// Delta punti delle ultime 7 giornate (per la card "+45 questa settimana").
final userPitcoinRecentDeltaProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final repository = ref.watch(pitcoinRepositoryProvider);
  if (repository == null) return 0;
  if (userId.trim().isEmpty) return 0;
  return repository.fetchRecentDeltaPoints(userId, days: 7);
});

// ─── Storico transazioni (paginato) ─────────────────────────────────────────

/// Argomento opaco per richieste paginate dello storico transazioni.
@immutable
class PitcoinTransactionsQuery {
  const PitcoinTransactionsQuery({
    required this.userId,
    this.limit = 30,
    this.before,
  });

  final String userId;
  final int limit;
  final DateTime? before;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PitcoinTransactionsQuery &&
        other.userId == userId &&
        other.limit == limit &&
        other.before == before;
  }

  @override
  int get hashCode => Object.hash(userId, limit, before);
}

/// Lista transazioni del singolo utente (privato).
///
/// Pattern di pagination "load more" lato widget: la prima pagina chiede
/// `before=null`; le successive ripassano l'`awarded_at` dell'ultima riga
/// gia' visibile. La RLS lato server impedisce a non-owner di vedere righe.
final userPitcoinTransactionsProvider =
    FutureProvider.family<List<PitcoinTransaction>, PitcoinTransactionsQuery>(
        (ref, query) async {
  final repository = ref.watch(pitcoinRepositoryProvider);
  if (repository == null) return const [];
  if (query.userId.trim().isEmpty) return const [];
  return repository.fetchTransactions(
    query.userId,
    limit: query.limit,
    before: query.before,
  );
});

// ─── Catalogo azioni ────────────────────────────────────────────────────────

/// Catalogo completo delle action_definitions abilitate.
/// Indicizzato in mappa per lookup veloce nelle righe storico.
final pitcoinActionDefinitionsProvider =
    FutureProvider<Map<String, PitcoinActionDefinition>>((ref) async {
  final repository = ref.watch(pitcoinRepositoryProvider);
  if (repository == null) return const {};
  final list = await repository.fetchActionDefinitions();
  return {for (final def in list) def.actionKey: def};
});

// ─── Badge ──────────────────────────────────────────────────────────────────

/// Badge ottenute da uno specifico userId (owner-path, con fallback su view pubblica).
final userBadgesProvider =
    FutureProvider.family<List<PitcoinBadge>, String>((ref, userId) async {
  final repository = ref.watch(pitcoinRepositoryProvider);
  if (repository == null) return const [];
  if (userId.trim().isEmpty) return const [];
  return repository.fetchUserBadges(userId);
});

/// Badge ottenute via public_slug.
final userBadgesBySlugProvider =
    FutureProvider.family<List<PitcoinBadge>, String>((ref, slug) async {
  final repository = ref.watch(pitcoinRepositoryProvider);
  if (repository == null) return const [];
  if (slug.trim().isEmpty) return const [];
  return repository.fetchUserBadgesBySlug(slug);
});

/// Catalogo completo definizioni badge (anche non ancora sbloccate).
final allBadgeDefinitionsProvider =
    FutureProvider<List<PitcoinBadge>>((ref) async {
  final repository = ref.watch(pitcoinRepositoryProvider);
  if (repository == null) return const [];
  return repository.fetchAllBadgeDefinitions();
});

/// Merge ottimizzato di [allBadgeDefinitionsProvider] + [userBadgesProvider]:
/// ritorna l'elenco completo del catalogo con `awardedAt` valorizzato sui badge
/// effettivamente ottenuti dall'utente. Usato dalla vetrina owner.
final mergedUserBadgesProvider =
    FutureProvider.family<List<PitcoinBadge>, String>((ref, userId) async {
  final catalog = await ref.watch(allBadgeDefinitionsProvider.future);
  if (userId.trim().isEmpty) return catalog;
  final owned = await ref.watch(userBadgesProvider(userId).future);
  final ownedMap = {for (final b in owned) b.badgeKey: b};
  return catalog
      .map((def) {
        final matched = ownedMap[def.badgeKey];
        if (matched == null) return def;
        return def.copyWith(awardedAt: matched.awardedAt);
      })
      .toList();
});

// ─── Convenience: balance + delta per utente effettivo ──────────────────────

/// Balance dell'utente attualmente loggato (o impersonato).
/// Null se utente non autenticato.
final effectiveUserPitcoinBalanceProvider =
    FutureProvider<PitcoinBalance?>((ref) async {
  final userId = ref.watch(effectiveUserIdProvider);
  if (userId == null) return null;
  return ref.watch(userPitcoinBalanceProvider(userId).future);
});

/// Delta 7gg dell'utente attualmente loggato (o impersonato).
final effectiveUserPitcoinRecentDeltaProvider =
    FutureProvider<int>((ref) async {
  final userId = ref.watch(effectiveUserIdProvider);
  if (userId == null) return 0;
  return ref.watch(userPitcoinRecentDeltaProvider(userId).future);
});

/// Badge dell'utente attualmente loggato (o impersonato), merged col catalogo.
final effectiveUserMergedBadgesProvider =
    FutureProvider<List<PitcoinBadge>>((ref) async {
  final userId = ref.watch(effectiveUserIdProvider);
  if (userId == null) {
    return ref.watch(allBadgeDefinitionsProvider.future);
  }
  return ref.watch(mergedUserBadgesProvider(userId).future);
});
