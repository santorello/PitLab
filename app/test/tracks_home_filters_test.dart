import 'package:flutter_test/flutter_test.dart';
import 'package:pitlap_app/features/tracks/presentation/tracks_home_filters.dart';
import 'package:pitlap_app/shared/models/track_list_item.dart';

void main() {
  const parmaBuggy = TrackListItem(
    id: '1',
    slug: 'parma-buggy',
    name: 'Parma Buggy Arena',
    city: 'Parma',
    shortDescription: 'Offroad racing track',
    status: 'open',
    statusMessage: 'Dry and ready',
    availableServiceCount: 3,
    categoryKeys: ['buggy', 'outdoor'],
  );

  const rhoMiniZ = TrackListItem(
    id: '2',
    slug: 'rho-mini-z',
    name: 'Rho Mini-Z Club',
    city: 'Rho',
    shortDescription: 'Indoor mini-z layout',
    status: 'open',
    statusMessage: 'Club night',
    availableServiceCount: 2,
    categoryKeys: ['mini_z', 'indoor'],
  );

  const parmaScaler = TrackListItem(
    id: '3',
    slug: 'parma-scaler',
    name: 'Parma Rock Garden',
    city: 'Parma',
    shortDescription: 'Scaler trail area',
    status: 'wet',
    statusMessage: 'Mud session',
    availableServiceCount: 1,
    categoryKeys: ['scaler', 'outdoor'],
  );

  test('extractTrackCities returns unique sorted cities', () {
    final cities = extractTrackCities([
      parmaBuggy,
      rhoMiniZ,
      parmaScaler,
    ]);

    expect(cities, ['Parma', 'Rho']);
  });

  test('matchesTrackHomeFilters matches combined search category and city', () {
    final matches = matchesTrackHomeFilters(
      parmaBuggy,
      searchQuery: 'buggy',
      activeCategory: 'buggy',
      activeCity: 'Parma',
    );

    expect(matches, isTrue);
  });

  test('matchesTrackHomeFilters rejects non matching city', () {
    final matches = matchesTrackHomeFilters(
      parmaBuggy,
      searchQuery: '',
      activeCategory: null,
      activeCity: 'Rho',
    );

    expect(matches, isFalse);
  });
}
