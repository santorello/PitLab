/// Rollup PitCoin per un singolo utente.
///
/// Letto dalla tabella `user_pitcoin_balances` (owner/admin) o dalla view
/// `public_user_pitcoin` (chiunque, solo se profilo public).
class PitcoinBalance {
  const PitcoinBalance({
    required this.userId,
    required this.totalPoints,
    required this.lifetimeEarned,
    this.lastActionAt,
  });

  /// UUID del profilo proprietario del balance.
  final String userId;

  /// Somma cumulativa attuale (puo' includere delta negativi futuri).
  final int totalPoints;

  /// Somma delle sole transazioni positive nella vita dell'account.
  final int lifetimeEarned;

  /// Timestamp dell'ultimo accreditamento, null se nessuna transazione.
  final DateTime? lastActionAt;

  factory PitcoinBalance.fromMap(Map<String, dynamic> map) {
    final last = map['last_action_at'];
    return PitcoinBalance(
      userId: map['user_id'] as String? ?? '',
      totalPoints: (map['total_points'] as num?)?.toInt() ?? 0,
      lifetimeEarned: (map['lifetime_earned'] as num?)?.toInt() ??
          ((map['total_points'] as num?)?.toInt() ?? 0),
      lastActionAt: last is String ? DateTime.tryParse(last) : null,
    );
  }

  /// Variante derivata dalla view pubblica `public_user_pitcoin`, che espone
  /// solo `user_id`, `public_slug` e `total_points`.
  factory PitcoinBalance.fromPublicMap(Map<String, dynamic> map) {
    return PitcoinBalance(
      userId: map['user_id'] as String? ?? '',
      totalPoints: (map['total_points'] as num?)?.toInt() ?? 0,
      lifetimeEarned: (map['total_points'] as num?)?.toInt() ?? 0,
      lastActionAt: null,
    );
  }
}
