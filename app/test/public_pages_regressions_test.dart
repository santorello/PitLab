import 'package:flutter_test/flutter_test.dart';
import 'package:pitlap_app/features/events/application/public_events_provider.dart';

void main() {
  test('mapPublicEventRow prefers track city for public event location', () {
    final event = mapPublicEventRow({
      'id': 'event-1',
      'title': 'Campionato Offroad',
      'description': 'Finale regionale',
      'start_at': '2026-05-10T08:00:00.000Z',
      'tracks': {
        'name': 'Parma Buggy Arena',
        'city': 'Parma',
      },
    });

    expect(event.id, 'event-1');
    expect(event.title, 'Campionato Offroad');
    expect(event.location, 'Parma');
    expect(event.creatorLabel, 'Parma Buggy Arena');
    expect(event.venue, 'Parma Buggy Arena');
  });

  test('mapPublicEventRow falls back to track name when city is missing', () {
    final event = mapPublicEventRow({
      'id': 'event-2',
      'title': 'Club Night',
      'description': 'Sessione serale',
      'start_at': '2026-05-11T18:30:00.000Z',
      'tracks': {
        'name': 'Rho Mini-Z Club',
        'city': '',
      },
    });

    expect(event.location, 'Rho Mini-Z Club');
    expect(event.creatorLabel, 'Rho Mini-Z Club');
  });

  test('mapPublicEventRow keeps empty location when no track payload exists', () {
    final event = mapPublicEventRow({
      'id': 'event-3',
      'title': 'Community Meetup',
      'description': 'Open paddock',
      'start_at': '2026-05-12T10:00:00.000Z',
    });

    expect(event.location, '');
    expect(event.creatorLabel, '');
    expect(event.venue, '');
  });
}
