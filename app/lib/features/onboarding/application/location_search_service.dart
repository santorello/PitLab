import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class LocationSuggestion {
  const LocationSuggestion({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.admin1,
    this.admin2,
    this.country,
    this.countryCode,
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String? admin1;
  final String? admin2;
  final String? country;
  final String? countryCode;

  String get displayLabel {
    final parts = <String>[
      name.trim(),
      if ((admin1 ?? '').trim().isNotEmpty &&
          (admin1 ?? '').trim().toLowerCase() != name.trim().toLowerCase())
        admin1!.trim(),
      if ((country ?? '').trim().isNotEmpty) country!.trim(),
    ];
    return parts.join(', ');
  }

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      admin1: json['admin1'] as String?,
      admin2: json['admin2'] as String?,
      country: json['country'] as String?,
      countryCode: json['country_code'] as String?,
    );
  }
}

class LocationSearchService {
  LocationSearchService(this._client);

  final http.Client _client;
  final Map<String, List<LocationSuggestion>> _cache = <String, List<LocationSuggestion>>{};

  Future<List<LocationSuggestion>> search({
    required String query,
    String language = 'it',
    String countryCode = 'IT',
    int count = 6,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 2) {
      return const [];
    }

    final cacheKey = '${language.toLowerCase()}|${countryCode.toUpperCase()}|${normalizedQuery.toLowerCase()}';
    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final uri = Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      <String, String>{
        'name': normalizedQuery,
        'count': count.toString(),
        'language': language.toLowerCase(),
        'countryCode': countryCode.toUpperCase(),
        'format': 'json',
      },
    );

    final response = await _client.get(
      uri,
      headers: const <String, String>{
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Location search failed (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawResults = (decoded['results'] as List<dynamic>? ?? const <dynamic>[]);
    final results = rawResults
        .whereType<Map<String, dynamic>>()
        .map(LocationSuggestion.fromJson)
        .where((item) => item.name.trim().isNotEmpty)
        .toList(growable: false);

    _cache[cacheKey] = results;
    return results;
  }
}

final locationSearchHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final locationSearchServiceProvider = Provider<LocationSearchService>((ref) {
  final client = ref.watch(locationSearchHttpClientProvider);
  return LocationSearchService(client);
});
