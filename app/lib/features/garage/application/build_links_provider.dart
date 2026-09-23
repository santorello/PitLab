import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tracks/application/tracks_providers.dart';
import 'public_builds_provider.dart';

/// Un luogo a cui si puo' collegare una build (vista `link_targets`,
/// delta 2026-09-23-build-links).
class LinkTarget {
  const LinkTarget({
    required this.entityType,
    required this.entityId,
    required this.name,
    required this.city,
    this.slug,
  });

  factory LinkTarget.fromMap(Map<String, dynamic> map) => LinkTarget(
        entityType: map['entity_type'] as String? ?? '',
        entityId: map['entity_id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        city: map['city'] as String? ?? '',
        slug: map['slug'] as String?,
      );

  final String entityType;
  final String entityId;
  final String name;
  final String city;
  final String? slug;

  String get key => '$entityType:$entityId';

  String get kindLabel => switch (entityType) {
        'track' => 'Pista',
        'shop' => 'Negozio',
        'spot' => 'Spot',
        _ => 'Evento',
      };

  String get route => switch (entityType) {
        'track' => '/track/$slug',
        'shop' => '/shop/$slug',
        'spot' => '/spot/$slug',
        _ => '/event/$entityId',
      };
}

/// Luoghi collegati a una build, con aggiunta e rimozione (solo proprietario,
/// lo garantisce la RLS).
class BuildLinksNotifier extends AsyncNotifier<List<LinkTarget>> {
  BuildLinksNotifier(this._buildId);

  final String _buildId;

  @override
  Future<List<LinkTarget>> build() async {
    final client = ref.watch(supabaseClientProvider);
    if (client == null) return const [];
    final links = await client
        .from('build_links')
        .select('entity_type, entity_id')
        .eq('build_id', _buildId)
        .order('created_at');
    final ids = (links as List<dynamic>)
        .whereType<Map>()
        .map((row) => row['entity_id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return const [];
    final rows = await client
        .from('link_targets')
        .select('entity_type, entity_id, slug, name, city')
        .inFilter('entity_id', ids);
    final byKey = {
      for (final row in (rows as List<dynamic>).whereType<Map>())
        '${row['entity_type']}:${row['entity_id']}':
            LinkTarget.fromMap(row.cast<String, dynamic>()),
    };
    // Stesso ordine dei collegamenti; un luogo sparito (es. cancellato) si salta.
    return [
      for (final row in links.whereType<Map>())
        ?byKey['${row['entity_type']}:${row['entity_id']}'],
    ];
  }

  /// null = ok, altrimenti messaggio da mostrare.
  Future<String?> add(LinkTarget target) async {
    final client = ref.read(supabaseClientProvider);
    final current = state.value ?? const [];
    if (client == null) return 'Connessione non disponibile.';
    if (current.any((t) => t.key == target.key)) return null;
    try {
      await client.from('build_links').insert({
        'build_id': _buildId,
        'entity_type': target.entityType,
        'entity_id': target.entityId,
      });
      state = AsyncData([...current, target]);
      ref.invalidate(buildsSeenHereProvider(
          (entityType: target.entityType, entityId: target.entityId)));
      return null;
    } catch (error) {
      final text = error.toString();
      if (text.contains('build_links_limit') || text.contains('al massimo 8')) {
        return 'Una build puo\' essere collegata al massimo a 8 luoghi.';
      }
      return 'Collegamento non salvato. Riprova.';
    }
  }

  Future<String?> remove(LinkTarget target) async {
    final client = ref.read(supabaseClientProvider);
    final current = state.value ?? const [];
    if (client == null) return 'Connessione non disponibile.';
    try {
      await client
          .from('build_links')
          .delete()
          .eq('build_id', _buildId)
          .eq('entity_type', target.entityType)
          .eq('entity_id', target.entityId);
      state = AsyncData(current.where((t) => t.key != target.key).toList());
      ref.invalidate(buildsSeenHereProvider(
          (entityType: target.entityType, entityId: target.entityId)));
      return null;
    } catch (_) {
      return 'Collegamento non rimosso. Riprova.';
    }
  }
}

final buildLinksProvider = AsyncNotifierProvider.autoDispose
    .family<BuildLinksNotifier, List<LinkTarget>, String>(
        BuildLinksNotifier.new);

/// Ricerca dei luoghi collegabili per nome.
final linkTargetSearchProvider = FutureProvider.autoDispose
    .family<List<LinkTarget>, String>((ref, query) async {
  final client = ref.watch(supabaseClientProvider);
  final q = query.trim();
  if (client == null || q.length < 2) return const [];
  // I caratteri jolly di ilike vanno neutralizzati nel testo dell'utente.
  final safe = q.replaceAll(RegExp(r'[%_,()]'), ' ');
  final rows = await client
      .from('link_targets')
      .select('entity_type, entity_id, slug, name, city')
      .or('name.ilike.%$safe%,city.ilike.%$safe%')
      .order('name')
      .limit(20);
  return (rows as List<dynamic>)
      .whereType<Map>()
      .map((row) => LinkTarget.fromMap(row.cast<String, dynamic>()))
      .toList();
});

typedef LinkedEntity = ({String entityType, String entityId});

/// Build pubbliche collegate a un luogo ("Build viste qui"), piu' recenti prima.
// Niente autoDispose: la striscia sta in fondo a pagine con ListView, che
// smonta e rimonta i figli mentre si scorre; con autoDispose la richiesta
// ripartiva da capo a ogni passaggio e la striscia non arrivava mai
// (collaudo 23/09). Si aggiorna con invalidate quando si collega un luogo.
final buildsSeenHereProvider =
    FutureProvider.family<List<PublicBuildListing>, LinkedEntity>(
        (ref, entity) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null || entity.entityId.isEmpty) return const [];
  final links = await client
      .from('build_links')
      .select('build_id')
      .eq('entity_type', entity.entityType)
      .eq('entity_id', entity.entityId)
      .order('created_at', ascending: false)
      .limit(20);
  final ids = (links as List<dynamic>)
      .whereType<Map>()
      .map((row) => row['build_id'] as String? ?? '')
      .where((id) => id.isNotEmpty)
      .toList();
  if (ids.isEmpty) return const [];
  final rows = await client
      .from('user_builds')
      .select('id, owner_id, title, meta, specs, image_urls, created_at')
      .inFilter('id', ids)
      .eq('is_public', true);
  final byId = {
    for (final row in (rows as List<dynamic>).whereType<Map>())
      row['id'] as String? ?? '': row.cast<String, dynamic>(),
  };
  return [
    for (final id in ids)
      if (byId[id] case final row?) PublicBuildListing.fromMap(row),
  ];
});
