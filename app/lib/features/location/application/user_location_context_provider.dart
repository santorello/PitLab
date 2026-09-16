import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';

enum UserLocationSource {
  none,
  profile,
}

class UserLocationContext {
  const UserLocationContext({
    required this.source,
    this.city,
    this.country,
    this.latitude,
    this.longitude,
    this.radiusKm = 50,
  });

  final UserLocationSource source;
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;
  final double radiusKm;

  static const none = UserLocationContext(source: UserLocationSource.none);

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get isLocalized => source != UserLocationSource.none;

  String get label {
    final parts = [
      if ((city ?? '').trim().isNotEmpty) city!.trim(),
      if ((country ?? '').trim().isNotEmpty) country!.trim(),
    ];
    return parts.join(', ');
  }
}

final userLocationContextProvider =
    FutureProvider<UserLocationContext>((ref) async {
  final client = ref.watch(authClientProvider);
  final user = ref.watch(currentUserProvider);
  if (client == null || user == null) return UserLocationContext.none;

  // Colonne private leggibili solo via RPC (delta 2026-09-16-profile-private).
  try {
    final rows = await client.rpc('my_profile_private') as List<dynamic>;
    final row = rows.isEmpty ? null : rows.first as Map<String, dynamic>;
    return _locationFromProfileRow(row);
  } catch (error) {
    debugPrint('[LocationContext] profile location unavailable: $error');
    return UserLocationContext.none;
  }
});

UserLocationContext _locationFromProfileRow(Map<String, dynamic>? row) {
  if (row == null) return UserLocationContext.none;

  final preferredCity = (row['preferred_city'] as String?)?.trim();
  final homeCity = (row['home_city'] as String?)?.trim();
  final country = (row['home_country'] as String?)?.trim();
  final latitude = (row['home_latitude'] as num?)?.toDouble();
  final longitude = (row['home_longitude'] as num?)?.toDouble();
  final city = (homeCity?.isNotEmpty == true ? homeCity : preferredCity);

  if ((city ?? '').isEmpty && latitude == null && longitude == null) {
    return UserLocationContext.none;
  }

  return UserLocationContext(
    source: UserLocationSource.profile,
    city: city,
    country: country,
    latitude: latitude,
    longitude: longitude,
  );
}

double distanceKmBetween({
  required double fromLatitude,
  required double fromLongitude,
  required double toLatitude,
  required double toLongitude,
}) {
  const earthRadiusKm = 6371.0088;
  final fromLat = _toRadians(fromLatitude);
  final toLat = _toRadians(toLatitude);
  final deltaLat = _toRadians(toLatitude - fromLatitude);
  final deltaLon = _toRadians(toLongitude - fromLongitude);
  final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
      math.cos(fromLat) *
          math.cos(toLat) *
          math.sin(deltaLon / 2) *
          math.sin(deltaLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _toRadians(double degrees) => degrees * math.pi / 180;

bool isWithinUserRadius({
  required UserLocationContext location,
  required double latitude,
  required double longitude,
}) {
  final fromLatitude = location.latitude;
  final fromLongitude = location.longitude;
  if (fromLatitude == null || fromLongitude == null) return false;

  return distanceKmBetween(
        fromLatitude: fromLatitude,
        fromLongitude: fromLongitude,
        toLatitude: latitude,
        toLongitude: longitude,
      ) <=
      location.radiusKm;
}
