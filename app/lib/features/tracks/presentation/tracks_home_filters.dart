import '../../../shared/models/track_list_item.dart';

List<String> extractTrackCities(List<TrackListItem> tracks) {
  final cities = tracks
      .map((track) => track.city.trim())
      .where((city) => city.isNotEmpty)
      .toSet()
      .toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return cities;
}

bool matchesTrackHomeFilters(
  TrackListItem track, {
  required String searchQuery,
  required String? activeCategory,
  required String? activeCity,
}) {
  final blob = [
    track.name,
    track.city,
    track.shortDescription,
    track.statusMessage,
    track.slug,
  ].join(' ').toLowerCase();

  final normalizedSearch = searchQuery.trim().toLowerCase();
  final normalizedCity = activeCity?.trim().toLowerCase();

  if (normalizedSearch.isNotEmpty && !blob.contains(normalizedSearch)) {
    return false;
  }

  if (normalizedCity != null &&
      normalizedCity.isNotEmpty &&
      track.city.trim().toLowerCase() != normalizedCity) {
    return false;
  }

  if (activeCategory == null) {
    return true;
  }

  return track.categoryKeys.contains(activeCategory);
}
