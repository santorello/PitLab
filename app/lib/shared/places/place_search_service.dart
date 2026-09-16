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

/// Geocoding via Open-Meteo: gratuito, senza API key, CORS-friendly.
/// Usato come provider principale quando manca la key MapTiler (es. dev) e
/// come fallback quando MapTiler fallisce o non restituisce risultati.
class OpenMeteoPlaceSearchService implements PlaceSearchProvider {
  OpenMeteoPlaceSearchService(this._client);

  final http.Client _client;
  final Map<String, List<PlaceSelection>> _cache =
      <String, List<PlaceSelection>>{};

  static const providerName = 'open-meteo';

  @override
  Future<List<PlaceSelection>> search(PlaceSearchRequest request) async {
    final normalizedQuery = request.query.trim();
    if (normalizedQuery.length < 2) {
      return const [];
    }

    final cached = _cache[request.cacheKey];
    if (cached != null) {
      return cached;
    }

    final uri = Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      <String, String>{
        'name': normalizedQuery,
        'count': request.limit.toString(),
        'language': request.language.toLowerCase(),
        'format': 'json',
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
    final rawResults =
        (decoded['results'] as List<dynamic>? ?? const <dynamic>[]);
    final mapped = rawResults
        .whereType<Map<String, dynamic>>()
        .map(_mapResult)
        .where((item) => item.label.trim().isNotEmpty)
        .toList(growable: false);

    // Preferisce il paese richiesto; se il filtro svuota i risultati, li tiene tutti.
    final wantedCc = request.countryCode.trim().toUpperCase();
    var results = mapped;
    if (wantedCc.isNotEmpty) {
      final filtered = mapped
          .where((p) => (p.countryCode ?? '').toUpperCase() == wantedCc)
          .toList(growable: false);
      if (filtered.isNotEmpty) {
        results = filtered;
      }
    }

    _cache[request.cacheKey] = results;
    return results;
  }

  static PlaceSelection _mapResult(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final admin1 = json['admin1'] as String?;
    final country = json['country'] as String?;
    final countryCode = json['country_code'] as String?;

    final subtitleParts = <String>[
      if ((admin1 ?? '').trim().isNotEmpty) admin1!.trim(),
      if ((country ?? '').trim().isNotEmpty) country!.trim(),
    ];
    final label = <String>[
      name.trim(),
      ...subtitleParts,
    ].where((s) => s.isNotEmpty).join(', ');

    return PlaceSelection(
      label: label.isEmpty ? name : label,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      provider: providerName,
      providerPlaceId: ((json['id'] as num?)?.toInt() ?? 0).toString(),
      title: name,
      subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(', '),
      countryCode: countryCode,
      country: country,
      region: admin1,
      city: name,
      address: null,
    );
  }
}

/// Geocoding Photon (komoot, dati OpenStreetMap): trova anche parchi, vie e civici.
/// Gratis senza key; l'istanza pubblica chiede uso ragionevole (debounce 300 ms nel picker).
class PhotonPlaceSearchService implements PlaceSearchProvider {
  PhotonPlaceSearchService(this._client);

  final http.Client _client;
  final Map<String, List<PlaceSelection>> _cache =
      <String, List<PlaceSelection>>{};

  static const providerName = 'photon';
  // Photon traduce solo in queste lingue; altrimenti nomi locali (italiani in Italia).
  static const _langs = {'en', 'de', 'fr'};

  @override
  Future<List<PlaceSelection>> search(PlaceSearchRequest request) async {
    final query = request.query.trim();
    if (query.length < 2) return const [];
    final cached = _cache[request.cacheKey];
    if (cached != null) return cached;

    final lang = request.language.toLowerCase();
    final uri = Uri.https('photon.komoot.io', '/api/', <String, String>{
      'q': query,
      'limit': request.limit.toString(),
      if (_langs.contains(lang)) 'lang': lang,
      // Preferenza (non filtro) per l'Italia centrale.
      'lat': '42.5',
      'lon': '12.5',
    });

    final response = await _client.get(
      uri,
      headers: const <String, String>{'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Place search failed (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final mapped = (decoded['features'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_mapFeature)
        .whereType<PlaceSelection>()
        .toList(growable: false);

    final wanted = request.countryCode.trim().toUpperCase();
    final inCountry = mapped
        .where((p) => (p.countryCode ?? '').toUpperCase() == wanted)
        .toList(growable: false);
    final results = inCountry.isNotEmpty ? inCountry : mapped;
    _cache[request.cacheKey] = results;
    return results;
  }

  static PlaceSelection? _mapFeature(Map<String, dynamic> feature) {
    final coords = ((feature['geometry'] as Map<String, dynamic>?)?['coordinates']
            as List<dynamic>? ??
        const <dynamic>[])
        .whereType<num>()
        .toList(growable: false);
    if (coords.length < 2) return null;
    final p = feature['properties'] as Map<String, dynamic>? ?? const {};
    String? str(String key) {
      final v = (p[key] as String?)?.trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    final street = [str('street'), str('housenumber')].whereType<String>().join(' ');
    final city = str('city') ?? str('town') ?? str('village') ?? str('county');
    final name = str('name') ?? (street.isEmpty ? null : street);
    if (name == null) return null;
    final subtitleParts = <String>[
      if (street.isNotEmpty && street != name) street,
      if (city != null && city != name) city,
      ?str('state'),
      ?str('country'),
    ];
    final subtitle = subtitleParts.join(', ');

    return PlaceSelection(
      label: [name, if (city != null && city != name) city].join(', '),
      latitude: coords[1].toDouble(),
      longitude: coords[0].toDouble(),
      provider: providerName,
      providerPlaceId: '${p['osm_type'] ?? ''}${p['osm_id'] ?? ''}',
      title: name,
      subtitle: subtitle.isEmpty ? null : subtitle,
      countryCode: str('countrycode'),
      country: str('country'),
      region: str('state'),
      city: city ?? name,
      address: [name, ...subtitleParts].join(', '),
    );
  }
}

/// Prova il provider principale; se lancia o non trova nulla, usa il fallback.
class FallbackPlaceSearchService implements PlaceSearchProvider {
  FallbackPlaceSearchService(this._primary, this._fallback);

  final PlaceSearchProvider _primary;
  final PlaceSearchProvider _fallback;

  @override
  Future<List<PlaceSelection>> search(PlaceSearchRequest request) async {
    try {
      final primary = await _primary.search(request);
      if (primary.isNotEmpty) {
        return primary;
      }
      return await _fallback.search(request);
    } catch (_) {
      return _fallback.search(request);
    }
  }
}

final placeSearchHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final placeSearchProvider = Provider<PlaceSearchProvider>((ref) {
  final client = ref.watch(placeSearchHttpClientProvider);
  // MapTiler (se c'è la key) → Photon (luoghi precisi) → Open-Meteo (solo città, riserva).
  final photonThenOpenMeteo = FallbackPlaceSearchService(
    PhotonPlaceSearchService(client),
    OpenMeteoPlaceSearchService(client),
  );
  if (AppConfig.hasMapTilerConfig) {
    return FallbackPlaceSearchService(
      MapTilerPlaceSearchService(client),
      photonThenOpenMeteo,
    );
  }
  return photonThenOpenMeteo;
});

/// Testo scritto senza scegliere un suggerimento → primo risultato (preferendo l'Italia).
/// null se il testo è troppo corto, non trova nulla o la ricerca fallisce.
Future<PlaceSelection?> resolvePlaceText(
  PlaceSearchProvider service,
  String text,
) async {
  final query = text.trim();
  if (query.length < 2) return null;
  try {
    final found = await service.search(PlaceSearchRequest(query: query));
    return found.isEmpty ? null : found.first;
  } catch (_) {
    return null;
  }
}
