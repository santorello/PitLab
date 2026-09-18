// I contatori della dashboard admin devono usare il COUNT lato server:
// scaricare le righe dava numeri sbagliati oltre il limite di PostgREST.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pitlap_app/features/admin/application/admin_providers.dart';

void main() {
  test('i conteggi admin arrivano da content-range, non dalle righe', () async {
    final asked = <String>[];
    final client = SupabaseClient(
      'https://example.test',
      'offline-test-key',
      httpClient: MockClient((request) async {
        asked.add(request.headers['prefer'] ?? '');
        return http.Response(
          jsonEncode(const <Map<String, dynamic>>[]),
          200,
          headers: {
            'content-type': 'application/json',
            'content-range': '*/1500',
          },
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);

    final overview = await AdminRepository(client).fetchOverview();

    expect(overview.usersCount, 1500);
    expect(overview.tracksCount, 1500);
    // eventi = events + community_events
    expect(overview.eventsCount, 3000);
    expect(asked.every((p) => p.contains('count=exact')), isTrue);
  });

  test('le approvazioni pendenti sono contate lato server', () async {
    final client = SupabaseClient(
      'https://example.test',
      'offline-test-key',
      httpClient: MockClient((request) async {
        expect(request.url.query, contains('approval_status'));
        return http.Response(
          jsonEncode(const <Map<String, dynamic>>[]),
          200,
          headers: {
            'content-type': 'application/json',
            'content-range': '*/3',
          },
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    final repository = AdminRepository(client);

    expect(await repository.countPendingTracks(), 3);
    expect(await repository.countPendingShops(), 3);
  });
}
