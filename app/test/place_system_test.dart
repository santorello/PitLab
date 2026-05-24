import 'package:flutter_test/flutter_test.dart';
import 'package:pitlap_app/shared/places/place_selection.dart';

void main() {
  test('place selection serializes and restores canonical fields', () {
    const selection = PlaceSelection(
      label: 'Rho, Lombardia, Italia',
      latitude: 45.5281,
      longitude: 9.0396,
      provider: 'maptiler',
      providerPlaceId: 'municipality.123',
      title: 'Rho',
      subtitle: 'Lombardia, Italia',
      countryCode: 'it',
      country: 'Italia',
      region: 'Lombardia',
      city: 'Rho',
      address: 'Rho, Lombardia, Italia',
    );

    final restored = PlaceSelection.fromMap(selection.toMap());

    expect(restored.label, selection.label);
    expect(restored.latitude, selection.latitude);
    expect(restored.longitude, selection.longitude);
    expect(restored.provider, 'maptiler');
    expect(restored.city, 'Rho');
  });
}
