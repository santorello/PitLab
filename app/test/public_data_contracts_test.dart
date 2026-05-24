import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guest spots query uses the public discovery surface only', () {
    final source = File(
      'Z:\\ProgettiSviluppo\\PitLap\\app\\lib\\features\\spots\\application\\spots_providers.dart',
    ).readAsStringSync();

    expect(source, contains(".from('public_spots')"));
    expect(source, contains('is_owned_by_current_user'));
    expect(source, isNot(contains(".from('public_spots')\n        .select(_columns)")));
  });

  test('guest shop detail keeps approval gating aligned with list view', () {
    final source = File(
      'Z:\\ProgettiSviluppo\\PitLap\\app\\lib\\features\\shops\\application\\public_shops_provider.dart',
    ).readAsStringSync();

    expect(source, contains(".eq('approval_status', 'approved')"));
  });
}
