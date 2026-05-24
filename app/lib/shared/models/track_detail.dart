class TrackDetail {
  const TrackDetail({
    required this.id,
    required this.slug,
    required this.name,
    required this.city,
    required this.country,
    required this.shortDescription,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.externalMapUrl,
    required this.status,
    required this.statusMessage,
    required this.availableServices,
    required this.availableServiceKeys,
    this.categoryKeys = const [],
  });

  final String id;
  final String slug;
  final String name;
  final String city;
  final String country;
  final String shortDescription;
  final String description;
  final String address;
  final double? latitude;
  final double? longitude;
  final String externalMapUrl;
  final String status;
  final String statusMessage;
  final List<String> availableServices;
  final List<String> availableServiceKeys;

  /// Chiavi categoria reali da track_category_links → track_categories.key
  final List<String> categoryKeys;

  factory TrackDetail.fromMap(
    Map<String, dynamic> map, {
    String preferredLanguageCode = 'it',
  }) {
    final statusMap = map['track_status_current'];
    final services = map['track_services'];

    final categoryLinks =
        map['track_category_links'] as List<dynamic>? ?? const [];
    final parsedCategoryKeys = categoryLinks
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

    return TrackDetail(
      id: map['id'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      name: map['name'] as String? ?? '',
      city: map['city'] as String? ?? '',
      country: map['country'] as String? ?? '',
      shortDescription: map['short_description'] as String? ?? '',
      description: map['description'] as String? ?? '',
      address: map['address'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      externalMapUrl: map['external_map_url'] as String? ?? '',
      status: statusMap is Map<String, dynamic>
          ? statusMap['status'] as String? ?? 'unknown'
          : 'unknown',
      statusMessage: statusMap is Map<String, dynamic>
          ? statusMap['message'] as String? ?? ''
          : '',
      availableServices: services is List<dynamic>
          ? services
              .whereType<Map<String, dynamic>>()
              .where((service) => service['is_available'] == true)
              .map((service) {
                final type = service['service_types'];
                if (type is Map<String, dynamic>) {
                  final labelIt = type['label_it'] as String?;
                  final labelEn = type['label_en'] as String?;
                  return preferredLanguageCode == 'en'
                      ? (labelEn ?? labelIt ?? '')
                      : (labelIt ?? labelEn ?? '');
                }
                return '';
              })
              .where((label) => label.isNotEmpty)
              .toList()
          : const [],
      availableServiceKeys: services is List<dynamic>
          ? services
              .whereType<Map<String, dynamic>>()
              .where((service) => service['is_available'] == true)
              .map((service) {
                final type = service['service_types'];
                if (type is Map<String, dynamic>) {
                  return type['key'] as String? ?? '';
                }
                return '';
              })
              .where((key) => key.isNotEmpty)
              .toList()
          : const [],
      categoryKeys: parsedCategoryKeys,
    );
  }
}
