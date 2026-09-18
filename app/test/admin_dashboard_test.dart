// La control room legge tutto da una sola RPC: qui si verifica che la risposta
// venga letta correttamente e che il caso "non admin" non mostri numeri finti.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pitlap_app/features/admin/application/admin_providers.dart';

SupabaseClient _clientReturning(Object body, {List<String>? calls}) {
  return SupabaseClient(
    'https://example.test',
    'offline-test-key',
    httpClient: MockClient((request) async {
      calls?.add(request.url.path);
      return http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    }),
  );
}

void main() {
  test('una sola chiamata, tutti i numeri letti', () async {
    final calls = <String>[];
    final now = DateTime.now().toUtc();
    final client = _clientReturning({
      'todo': {
        'pending_tracks': 2,
        'pending_shops': 0,
        'oldest_pending_days': 3,
        'reported_comments': 1,
        'feedback': 3,
        'deletion_requests': 1,
        'deletion_oldest_days': 6,
        'content_to_fix': 4,
      },
      'health': {
        'keepalive_at': now.subtract(const Duration(hours: 5)).toIso8601String(),
        'last_signup_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'last_content_at': now.subtract(const Duration(hours: 9)).toIso8601String(),
        'consents_current': 29,
      },
      'counts': {'users': 31, 'users_7d': 14, 'users_prev_7d': 8, 'spots': 12},
      'created_7d': {'spots': 6, 'events': 3, 'builds': 8, 'comments': 21},
      'signups_30d': [
        {'d': '2026-09-17', 'n': 2},
        {'d': '2026-09-18', 'n': 5},
      ],
    }, calls: calls);
    addTearDown(client.dispose);

    final dashboard = await AdminRepository(client).fetchDashboard();

    expect(calls.length, 1, reason: 'una sola chiamata per tutta la dashboard');
    expect(dashboard, isNotNull);
    // 2 + 0 + 1 + 3 + 1 + 4
    expect(dashboard!.todoTotal, 11);
    expect(dashboard.count('users'), 31);
    expect(dashboard.created7d('comments'), 21);
    expect(dashboard.consentsCurrent, 29);
    expect(dashboard.signups30d, [2, 5]);
    expect(dashboard.silenceHours, 9);
  });

  test('non admin: nessun dato, non zeri', () async {
    final client = _clientReturning({'error': 'forbidden'});
    addTearDown(client.dispose);

    expect(await AdminRepository(client).fetchDashboard(), isNull);
  });
}
