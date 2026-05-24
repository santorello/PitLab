/// Badge unificato: definizione da `pitcoin_badge_definitions`
/// + (opzionale) data di assegnazione da `user_badges`.
///
/// Quando [awardedAt] e' null la badge non e' ancora stata sbloccata
/// dall'utente in questione (caso usato nella vetrina owner).
class PitcoinBadge {
  const PitcoinBadge({
    required this.badgeKey,
    required this.nameIt,
    required this.nameEn,
    required this.category,
    required this.tier,
    this.descriptionIt,
    this.descriptionEn,
    this.iconAsset,
    this.sortOrder = 0,
    this.awardedAt,
  });

  /// Chiave univoca (es. "explorer_silver").
  final String badgeKey;

  /// Nome localizzato IT.
  final String nameIt;

  /// Nome localizzato EN.
  final String nameEn;

  /// Descrizione opzionale IT.
  final String? descriptionIt;

  /// Descrizione opzionale EN.
  final String? descriptionEn;

  /// Path asset SVG/PNG opzionale (relativo a `app/lib/assets/badges/`).
  final String? iconAsset;

  /// Categoria badge (identity | catalog | operations | engagement | events | milestone).
  final String category;

  /// Tier: bronze | silver | gold | special.
  final String tier;

  /// Ordine di visualizzazione nel catalogo (asc).
  final int sortOrder;

  /// Timestamp di assegnazione: null se l'utente non l'ha ancora ottenuta.
  final DateTime? awardedAt;

  bool get isUnlocked => awardedAt != null;

  factory PitcoinBadge.fromDefinitionMap(
    Map<String, dynamic> map, {
    DateTime? awardedAt,
  }) {
    return PitcoinBadge(
      badgeKey: map['badge_key'] as String? ?? '',
      nameIt: map['name_it'] as String? ?? '',
      nameEn: map['name_en'] as String? ?? '',
      descriptionIt: map['description_it'] as String?,
      descriptionEn: map['description_en'] as String?,
      iconAsset: map['icon_asset'] as String?,
      category: map['category'] as String? ?? 'engagement',
      tier: map['tier'] as String? ?? 'bronze',
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      awardedAt: awardedAt,
    );
  }

  /// Quando arriva direttamente da una JOIN `user_badges`+`pitcoin_badge_definitions`
  /// (la view pubblica `public_user_badges` espone questa forma).
  factory PitcoinBadge.fromJoinedMap(Map<String, dynamic> map) {
    final awardedRaw = map['awarded_at'];
    final awardedAt = awardedRaw is String ? DateTime.tryParse(awardedRaw) : null;
    final definition = map['pitcoin_badge_definitions'];
    if (definition is Map) {
      return PitcoinBadge.fromDefinitionMap(
        definition.cast<String, dynamic>(),
        awardedAt: awardedAt,
      );
    }
    return PitcoinBadge.fromDefinitionMap(map, awardedAt: awardedAt);
  }

  PitcoinBadge copyWith({DateTime? awardedAt}) {
    return PitcoinBadge(
      badgeKey: badgeKey,
      nameIt: nameIt,
      nameEn: nameEn,
      descriptionIt: descriptionIt,
      descriptionEn: descriptionEn,
      iconAsset: iconAsset,
      category: category,
      tier: tier,
      sortOrder: sortOrder,
      awardedAt: awardedAt ?? this.awardedAt,
    );
  }

  String localizedName(String languageCode) {
    if (languageCode == 'en' && nameEn.trim().isNotEmpty) return nameEn;
    if (nameIt.trim().isNotEmpty) return nameIt;
    return badgeKey;
  }

  String? localizedDescription(String languageCode) {
    if (languageCode == 'en') {
      return descriptionEn ?? descriptionIt;
    }
    return descriptionIt ?? descriptionEn;
  }
}
