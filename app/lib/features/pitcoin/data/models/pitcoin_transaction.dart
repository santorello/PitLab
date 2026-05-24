/// Singola riga del ledger `pitcoin_transactions`.
///
/// Visibile solo all'owner del profilo (e agli admin via RLS).
class PitcoinTransaction {
  const PitcoinTransaction({
    required this.id,
    required this.userId,
    required this.actionKey,
    required this.points,
    required this.awardedAt,
    this.sourceTable,
    this.sourceId,
    this.metadata = const {},
  });

  /// UUID della transazione.
  final String id;

  /// UUID dell'utente destinatario dei PitCoin.
  final String userId;

  /// Chiave dell'azione (FK su `pitcoin_action_definitions.action_key`).
  final String actionKey;

  /// Punti accreditati (puo' essere 0 per placeholder di submission o
  /// negativo per future revoche).
  final int points;

  /// Nome tabella sorgente che ha generato l'accreditamento (per il deep-link
  /// dello storico verso l'entita' originale).
  final String? sourceTable;

  /// UUID dell'entita' sorgente (es. track_id, build_id, spot_id).
  final String? sourceId;

  /// Metadata opzionale (es. {"source":"backfill"}).
  final Map<String, dynamic> metadata;

  /// Quando l'accreditamento e' avvenuto.
  final DateTime awardedAt;

  factory PitcoinTransaction.fromMap(Map<String, dynamic> map) {
    final awardedRaw = map['awarded_at'];
    final awardedAt = awardedRaw is String
        ? DateTime.tryParse(awardedRaw) ?? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.fromMillisecondsSinceEpoch(0);

    final rawMeta = map['metadata'];
    final metadata = rawMeta is Map<String, dynamic>
        ? rawMeta
        : (rawMeta is Map ? rawMeta.cast<String, dynamic>() : const <String, dynamic>{});

    return PitcoinTransaction(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      actionKey: map['action_key'] as String? ?? '',
      points: (map['points'] as num?)?.toInt() ?? 0,
      sourceTable: map['source_table'] as String?,
      sourceId: map['source_id'] as String?,
      metadata: metadata,
      awardedAt: awardedAt,
    );
  }
}
