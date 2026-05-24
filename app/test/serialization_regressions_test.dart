import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitlap_app/features/profile/application/profile_hub_providers.dart';
import 'package:pitlap_app/features/spots/domain/spot_catalog.dart';

void main() {
  test('spot image accent is serialized as signed int32 for Postgres integer', () {
    const color = Color(0xFFD97706);

    expect(colorToSignedArgb32(color), -2525434);
  });

  test('created event local cache strips inline data image payloads', () {
    final event = CreatedEventRecord(
      id: 'event-1',
      date: 'Mar 21 Apr',
      title: 'Test event',
      location: 'Bologna',
      note: 'Note',
      badge: 'Community',
      creatorLabel: 'santorino',
      creatorRole: 'user',
      imageUrls: const [
        'data:image/jpeg;base64,AAAA',
        'https://cdn.pitlap.app/events/cover.jpg',
      ],
    );

    expect(event.toMap()['image_urls'], hasLength(2));
    expect(
      event.toLocalCacheMap()['image_urls'],
      equals(const ['https://cdn.pitlap.app/events/cover.jpg']),
    );
  });
}
