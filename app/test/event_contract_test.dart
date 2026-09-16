// Casi dalla review Astra 6 (16/09/2026), HTTP simulato: nessuna chiamata a Supabase.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pitlap_app/features/events/application/public_events_provider.dart';

http.Response _json(Object rows, http.Request request) => http.Response(
      jsonEncode(rows),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );

void main() {
  test('evento community in vetrina si apre anche dal dettaglio', () async {
    const id = '11111111-2222-3333-4444-555555555555';
    final event = <String, dynamic>{
      'id': id,
      'title': 'Community race',
      'starts_at':
          DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String(),
    };
    final client = SupabaseClient(
      'https://example.test',
      'offline-test-key',
      httpClient: MockClient((request) async => _json(
            request.url.path.endsWith('/community_events') ? [event] : [],
            request,
          )),
    );
    addTearDown(client.dispose);
    final repository = PublicEventsRepository(client);

    final listed = await repository.fetchUpcomingPublicEvents();
    expect(listed.single.id, id);
    expect(await repository.fetchPublicEventById(id), isNotNull);
  });

  test('evento in corso resta tra gli attivi', () async {
    final now = DateTime.now().toUtc();
    final event = <String, dynamic>{
      'id': 'ongoing-1',
      'title': 'Two day race',
      'start_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
      'end_at': now.add(const Duration(days: 1)).toIso8601String(),
    };
    final client = SupabaseClient(
      'https://example.test',
      'offline-test-key',
      httpClient: MockClient((request) async {
        if (!request.url.path.endsWith('/events')) return _json([], request);
        final q = request.url.queryParameters;
        final start = DateTime.parse(event['start_at'] as String);
        // Simula il server: vetrina = filtro `or` su end_at; archivio = start_at < now.
        final active = (q['or'] ?? '').contains('end_at.gte');
        final pastBound = q['start_at']?.startsWith('lt.') == true;
        final included = active || (pastBound && start.isBefore(now));
        return _json(included ? [event] : [], request);
      }),
    );
    addTearDown(client.dispose);
    final repository = PublicEventsRepository(client);

    final active = await repository.fetchUpcomingPublicEvents();
    final past = await repository.fetchPastPublicEvents();
    expect(active.map((e) => e.id), contains('ongoing-1'));
    expect(past.map((e) => e.id), isNot(contains('ongoing-1')));
  });
}
