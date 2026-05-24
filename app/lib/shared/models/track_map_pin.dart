/// Dati minimi di una pista da mostrare sulla mappa unificata.
/// Contiene solo le colonne necessarie; evita join pesanti.
class TrackMapPin {
  const TrackMapPin({
    required this.slug,
    required this.name,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.status = 'unknown',
  });

  final String slug;
  final String name;
  final String city;
  final double latitude;
  final double longitude;

  /// Valore proveniente da `track_status_current.status`.
  /// Es. 'open', 'closed', 'unknown'.
  final String status;

  factory TrackMapPin.fromMap(Map<String, dynamic> map) {
    final statusMap = map['track_status_current'];
    final status = statusMap is Map<String, dynamic>
        ? statusMap['status'] as String? ?? 'unknown'
        : 'unknown';

    return TrackMapPin(
      slug: map['slug'] as String? ?? '',
      name: map['name'] as String? ?? '',
      city: map['city'] as String? ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      status: status,
    );
  }
}
