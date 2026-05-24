/// Definizione di un'azione che genera PitCoin (catalogo amministrabile).
///
/// Letto da `pitcoin_action_definitions`. Usato dalla UI dello storico per
/// risolvere il testo localizzato di una transazione e l'icona di categoria.
class PitcoinActionDefinition {
  const PitcoinActionDefinition({
    required this.actionKey,
    required this.nameIt,
    required this.nameEn,
    required this.category,
    required this.basePoints,
    this.descriptionIt,
    this.descriptionEn,
  });

  /// Chiave univoca (es. "spot_approved", "arrival_checkin").
  final String actionKey;

  /// Nome localizzato IT (titolo "Spot approvato").
  final String nameIt;

  /// Nome localizzato EN.
  final String nameEn;

  /// Descrizione opzionale IT.
  final String? descriptionIt;

  /// Descrizione opzionale EN.
  final String? descriptionEn;

  /// Categoria (identity | garage | catalog | operations | events | engagement).
  final String category;

  /// Punti base accreditati ad ogni invocazione (snapshot per UI).
  final int basePoints;

  factory PitcoinActionDefinition.fromMap(Map<String, dynamic> map) {
    return PitcoinActionDefinition(
      actionKey: map['action_key'] as String? ?? '',
      nameIt: map['name_it'] as String? ?? '',
      nameEn: map['name_en'] as String? ?? '',
      descriptionIt: map['description_it'] as String?,
      descriptionEn: map['description_en'] as String?,
      category: map['category'] as String? ?? 'engagement',
      basePoints: (map['base_points'] as num?)?.toInt() ?? 0,
    );
  }

  /// Restituisce il nome localizzato in base al language code (`it` | `en`).
  String localizedName(String languageCode) {
    if (languageCode == 'en' && nameEn.trim().isNotEmpty) return nameEn;
    if (nameIt.trim().isNotEmpty) return nameIt;
    if (nameEn.trim().isNotEmpty) return nameEn;
    return actionKey;
  }
}
