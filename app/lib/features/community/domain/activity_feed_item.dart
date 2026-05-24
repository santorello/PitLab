/// Modello per un singolo elemento del community feed.
/// Mappa le colonne della VIEW `activity_feed` su Supabase.
class ActivityFeedItem {
  const ActivityFeedItem({
    required this.actorType,
    required this.actorId,
    required this.actorName,
    required this.actorCity,
    required this.eventType,
    required this.title,
    required this.subtitle,
    required this.payload,
    required this.createdAt,
    this.actorSlug,
  });

  /// 'track' | 'spot' | 'community'
  final String actorType;
  final String actorId;
  final String actorName;
  final String? actorSlug;
  final String actorCity;

  /// 'track_status' | 'track_event' | 'community_event' | 'new_spot'
  final String eventType;

  final String title;
  final String subtitle;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  String? get primaryImageUrl {
    final payloadImages = payload['image_urls'];
    if (payloadImages is List) {
      for (final image in payloadImages) {
        final value = image is String ? image.trim() : '';
        if (value.isNotEmpty) return value;
      }
    }

    final payloadImage = payload['image_url'];
    if (payloadImage is String && payloadImage.trim().isNotEmpty) {
      return payloadImage.trim();
    }

    return null;
  }

  DateTime? get eventDate {
    for (final key in const ['starts_at', 'start_at']) {
      final value = payload[key];
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed.toLocal();
      }
    }
    return null;
  }

  factory ActivityFeedItem.fromMap(Map<String, dynamic> map) {
    return ActivityFeedItem(
      actorType: (map['actor_type'] as String?) ?? 'community',
      actorId:   (map['actor_id']   as String?) ?? '',
      actorName: (map['actor_name'] as String?) ?? '',
      actorSlug: map['actor_slug']  as String?,
      actorCity: (map['actor_city'] as String?) ?? '',
      eventType: (map['event_type'] as String?) ?? '',
      title:     (map['title']     as String?) ?? '',
      subtitle:  (map['subtitle']  as String?) ?? '',
      payload:   (map['payload']   as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ?? DateTime(2026),
    );
  }
}
