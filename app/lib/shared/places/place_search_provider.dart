import 'place_selection.dart';

class PlaceSearchRequest {
  const PlaceSearchRequest({
    required this.query,
    this.language = 'it',
    this.countryCode = 'IT',
    this.limit = 6,
    this.types = const <String>[],
  });

  final String query;
  final String language;
  final String countryCode;
  final int limit;
  final List<String> types;

  String get cacheKey {
    final normalizedTypes = [...types]..sort();
    return '${language.toLowerCase()}|${countryCode.toUpperCase()}|$limit|${normalizedTypes.join(',')}|${query.trim().toLowerCase()}';
  }
}

abstract class PlaceSearchProvider {
  Future<List<PlaceSelection>> search(PlaceSearchRequest request);
}
