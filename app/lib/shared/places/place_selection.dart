class PlaceSelection {
  const PlaceSelection({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.provider,
    required this.providerPlaceId,
    this.title,
    this.subtitle,
    this.countryCode,
    this.country,
    this.region,
    this.city,
    this.address,
  });

  final String label;
  final double latitude;
  final double longitude;
  final String provider;
  final String providerPlaceId;
  final String? title;
  final String? subtitle;
  final String? countryCode;
  final String? country;
  final String? region;
  final String? city;
  final String? address;

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'latitude': latitude,
      'longitude': longitude,
      'provider': provider,
      'provider_place_id': providerPlaceId,
      'title': title,
      'subtitle': subtitle,
      'country_code': countryCode,
      'country': country,
      'region': region,
      'city': city,
      'address': address,
    };
  }

  factory PlaceSelection.fromMap(Map<String, dynamic> map) {
    return PlaceSelection(
      label: map['label'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      provider: map['provider'] as String? ?? 'unknown',
      providerPlaceId: map['provider_place_id'] as String? ?? '',
      title: map['title'] as String?,
      subtitle: map['subtitle'] as String?,
      countryCode: map['country_code'] as String?,
      country: map['country'] as String?,
      region: map['region'] as String?,
      city: map['city'] as String?,
      address: map['address'] as String?,
    );
  }
}
