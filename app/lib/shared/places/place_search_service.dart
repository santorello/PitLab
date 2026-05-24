import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../app/bootstrap/app_config.dart';
import 'place_search_provider.dart';
import 'place_selection.dart';

class MapTilerPlaceSearchService implements PlaceSearchProvider {
  MapTilerPlaceSearchService(this._client);

  final http.Client _client;
  final Map<String, List<PlaceSelection>> _cache =
      <String, List<PlaceSelection>>{};

  static const providerName = 'maptiler';

  @override
  Future<List<PlaceSelection>> search(PlaceSearchRequest request) async {
    final normalizedQuery = request.query.trim();
    if (normalizedQuery.length < 2) {
      return const [];
    }
    if (!AppConfig.hasMapTilerConfig) {
      throw Exception('MapTiler API key missing.');
    }

    final cached = _cache[request.cacheKey];
    if (cached != null) {
      return cached;
    }

    final uri = Uri.https(
      'api.maptiler.com',
      '/geocoding/$normalizedQuery.json',
      <String, String>{
        'key': AppConfig.mapTilerApiKey,
        'language': request.language.toLowerCase(),
        'country': request.countryCode.toLowerCase(),
        'limit': request.limit.toString(),
        'autocomplete': 'true',
        if (request.types.isNotEmpty) 'types': request.types.join(','),
      },
    );

    final response = await _client.get(
      uri,
      headers: const <String, String>{'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Place search failed (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final features = (decoded['features'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>();
    final results = features
        .map(_mapFeature)
        .where((item) => item.label.trim().isNotEmpty)
        .toList(growable: false);

    _cache[request.cacheKey] = results;
    return results;
  }

  static PlaceSelection _mapFeature(Map<String, dynamic> feature) {
    final center = (feature['center'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<num>()
        .toList(growable: false);
    final placeName = feature['place_name'] as String? ?? '';
    final text = feature['text'] as String? ?? placeName;
    final context = (feature['context'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    String? contextText(String prefix) {
      for (final item in context) {
        final id = item['id'] as String? ?? '';
        if (id.startsWith(prefix)) {
          return item['text'] as String?;
        }
      }
      return null;
    }

    final region = contextText('region');
    final city =
        contextText('place') ??
        contextText('municipality') ??
        contextText('locality');
    final country = contextText('country');
    final subtitleParts = <String>[
      if ((city ?? '').trim().isNotEmpty &&
          city!.trim().toLowerCase() != text.trim().toLowerCase())
        city.trim(),
      if ((region ?? '').trim().isNotEmpty &&
          region!.trim().toLowerCase() != text.trim().toLowerCase())
        region.trim(),
      if ((country ?? '').trim().isNotEmpty) country!.trim(),
    ];
    final subtitle = subtitleParts.join(', ');

    return PlaceSelection(
      label: placeName.isNotEmpty ? placeName : text,
      latitude: center.length > 1 ? center[1].toDouble() : 0,
      longitude: center.isNotEmpty ? center[0].toDouble() : 0,
      provider: providerName,
      providerPlaceId: feature['id'] as String? ?? '',
      title: text,
      subtitle: subtitle.isEmpty ? null : subtitle,
      countryCode: (feature['properties'] as Map<String, dynamic>?)?['country_code']
          as String?,
      country: country,
      region: region,
      city: city,
      address: placeName.isEmpty ? null : placeName,
    );
  }
}

final placeSearchHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final placeSearchProvider = Provider<PlaceSearchProvider>((ref) {
  final client = ref.watch(placeSearchHttpClientProvider);
  return MapTilerPlaceSearchService(client);
});
