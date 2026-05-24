class TrackListItem {
  const TrackListItem({
    required this.id,
    required this.slug,
    required this.name,
    required this.city,
    required this.shortDescription,
    required this.status,
    required this.statusMessage,
    required this.availableServiceCount,
    this.categoryKeys = const [],
    this.serviceLabels = const [],
    this.imageUrl,
  });

  final String id;
  final String slug;
  final String name;
  final String city;
  final String shortDescription;
  final String status;
  final String statusMessage;
  final int availableServiceCount;
  final List<String> serviceLabels;
  final String? imageUrl;

  /// Chiavi categoria reali da track_category_links → track_categories.key
  /// Es. ['buggy'], ['mini_z'], ['scaler', 'bashing']
  final List<String> categoryKeys;

  factory TrackListItem.fromMap(Map<String, dynamic> map) {
    final statusMap = map['track_status_current'];
    final services = map['track_services'] as List<dynamic>? ?? const [];

    // Legge le categorie se presenti nella risposta (join opzionale)
    final categoryLinks =
        map['track_category_links'] as List<dynamic>? ?? const [];
    final keys = categoryLinks
        .whereType<Map<String, dynamic>>()
        .map((link) {
          final cat = link['track_categories'];
          if (cat is Map<String, dynamic>) {
            return cat['key'] as String?;
          }
          return null;
        })
        .whereType<String>()
        .toList();

    final serviceLabels = services
        .whereType<Map<String, dynamic>>()
        .where((service) => service['is_available'] == true)
        .map((service) => service['service_types'])
        .whereType<Map<String, dynamic>>()
        .map(
          (serviceType) =>
              serviceType['label_it'] as String? ??
              serviceType['label_en'] as String? ??
              '',
        )
        .where((label) => label.trim().isNotEmpty)
        .toList();

    return TrackListItem(
      id: map['id'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      name: map['name'] as String? ?? '',
      city: map['city'] as String? ?? '',
      shortDescription: map['short_description'] as String? ?? '',
      status: statusMap is Map<String, dynamic>
          ? statusMap['status'] as String? ?? 'unknown'
          : 'unknown',
      statusMessage: statusMap is Map<String, dynamic>
          ? statusMap['message'] as String? ?? ''
          : '',
      availableServiceCount: services
          .whereType<Map<String, dynamic>>()
          .where((service) => service['is_available'] == true)
          .length,
      categoryKeys: keys,
      serviceLabels: serviceLabels,
      imageUrl: map['image_url'] as String?,
    );
  }
}
