import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/auth/application/auth_providers.dart';
import '../domain/activity_feed_item.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Feed globale (non filtrato) — per guest e utenti senza interessi
// ─────────────────────────────────────────────────────────────────────────────

final activityFeedProvider =
    FutureProvider.autoDispose<List<ActivityFeedItem>>((ref) async {
  final client = ref.watch(authClientProvider);
  if (client == null) return [];

  final rows = await client
      .from('activity_feed')
      .select()
      .limit(30);

  return (rows as List<dynamic>)
      .whereType<Map<String, dynamic>>()
      .map(ActivityFeedItem.fromMap)
      .toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// DORMANT — Provider KYC / feed personalizzato
// Questi provider sono disabilitati per beta: tutti gli utenti usano
// activityFeedProvider (feed globale). Riattivare quando user_interests[]
// sarà parte del flusso onboarding e il feed personalizzato sarà pronto.
// ─────────────────────────────────────────────────────────────────────────────

// ignore_for_file: unused_element
final _userInterestsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final client = ref.watch(authClientProvider);
  final user = ref.watch(currentUserProvider);
  if (client == null || user == null) return [];

  final response = await client
      .from('profiles')
      .select('user_interests')
      .eq('id', user.id)
      .maybeSingle();

  if (response == null) return [];
  final raw = response['user_interests'];
  if (raw == null) return [];
  return (raw as List<dynamic>).whereType<String>().toList();
});

/// DORMANT — true se l'utente ha interessi configurati (onboarding KYC completato)
// ignore: unused_element
final hasUserInterestsProvider = Provider.autoDispose<bool>((ref) {
  final interestsAsync = ref.watch(_userInterestsProvider);
  return interestsAsync.maybeWhen(
    data: (interests) => interests.isNotEmpty,
    orElse: () => false,
  );
});

/// DORMANT — Feed filtrato per interessi: seleziona solo le righe il cui payload
/// contiene categorie compatibili con gli interessi dell'utente.
/// Per track_status e track_event, filtra sul campo category_keys del payload.
/// Per new_spot, filtra su best_for / surface.
/// Per community_event, non filtra (sempre incluso).
// ignore: unused_element
final personalizedFeedProvider =
    FutureProvider.autoDispose<List<ActivityFeedItem>>((ref) async {
  final client = ref.watch(authClientProvider);
  if (client == null) return [];

  final interestsAsync = ref.watch(_userInterestsProvider);
  final interests = interestsAsync.maybeWhen(
    data: (v) => v,
    orElse: () => <String>[],
  );

  // Se non ci sono interessi, restituisce il feed globale
  if (interests.isEmpty) {
    return ref.watch(activityFeedProvider).maybeWhen(
      data: (items) => items,
      orElse: () => [],
    );
  }

  // Fetch tutto il feed (la VIEW è già ottimizzata a 30 righe)
  final allAsync = ref.watch(activityFeedProvider);
  final all = allAsync.maybeWhen(data: (items) => items, orElse: () => <ActivityFeedItem>[]);

  return all.where((item) {
    // Community events: sempre inclusi
    if (item.eventType == 'community_event') return true;

    // Track status e track_event: filtra su categorie della pista se disponibili
    if (item.eventType == 'track_status' || item.eventType == 'track_event') {
      final catKeys = item.payload['category_keys'];
      if (catKeys == null) return true; // includi se non ci sono dati di categoria
      final cats = (catKeys as List<dynamic>).whereType<String>().toList();
      return cats.isEmpty || interests.any((i) => cats.contains(i));
    }

    // New spot: filtra su best_for
    if (item.eventType == 'new_spot') {
      final bestFor = (item.payload['best_for'] as String?) ?? '';
      return interests.any((i) => bestFor.toLowerCase().contains(i));
    }

    return true;
  }).toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// "Pulse" — contatori live per la home vetrina
// ─────────────────────────────────────────────────────────────────────────────

class FeedPulse {
  const FeedPulse({
    required this.openTracks,
    required this.eventsThisWeek,
    required this.newSpotsThisMonth,
  });

  final int openTracks;
  final int eventsThisWeek;
  final int newSpotsThisMonth;
}

final feedPulseProvider = FutureProvider.autoDispose<FeedPulse>((ref) async {
  final client = ref.watch(authClientProvider);
  if (client == null) return const FeedPulse(openTracks: 0, eventsThisWeek: 0, newSpotsThisMonth: 0);

  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final startOfMonth = DateTime(now.year, now.month, 1);

  // Recupera i conteggi con tre query parallele.
  // supabase_flutter v2 non espone FetchOptions: usiamo select minimo + .length.
  final futures = await Future.wait<List<dynamic>>([
    // Piste aperte
    client
        .from('track_status_current')
        .select('track_id')
        .eq('status', 'open'),

    // Eventi questa settimana
    client
        .from('events')
        .select('id')
        .gte('start_at', startOfWeek.toIso8601String()),

    // Nuovi spot questo mese
    client
        .from('spots')
        .select('id')
        .gte('created_at', startOfMonth.toIso8601String()),
  ]);

  return FeedPulse(
    openTracks:        futures[0].length,
    eventsThisWeek:    futures[1].length,
    newSpotsThisMonth: futures[2].length,
  );
});
