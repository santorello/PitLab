import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/local_storage_providers.dart';
import '../../features/auth/application/auth_providers.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class ExternalLinkRecord {
  const ExternalLinkRecord({
    required this.id,
    required this.provider,
    required this.label,
    required this.url,
    required this.isPublic,
    this.entityType,
    this.entityId,
  });

  final String id;
  final String provider;
  final String label;
  final String url;
  final bool isPublic;

  /// Popolati solo quando il record proviene da Supabase.
  final String? entityType;
  final String? entityId;

  /// Chiave composta usata come key nella mappa locale del provider.
  String? get entityKey {
    final t = entityType;
    final i = entityId;
    if (t == null || i == null) return null;
    return '$t:$i';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'provider': provider,
      'label': label,
      'url': url,
      'is_public': isPublic,
    };
  }

  factory ExternalLinkRecord.fromMap(Map<String, dynamic> map) {
    return ExternalLinkRecord(
      id: map['id'] as String? ?? '',
      provider: map['provider'] as String? ?? 'website',
      label: map['label'] as String? ?? '',
      url: map['url'] as String? ?? '',
      isPublic: map['is_public'] as bool? ?? true,
    );
  }

  factory ExternalLinkRecord.fromRow(Map<String, dynamic> row) {
    return ExternalLinkRecord(
      id: row['id'] as String? ?? '',
      provider: row['provider'] as String? ?? 'website',
      label: row['label'] as String? ?? '',
      url: row['url'] as String? ?? '',
      isPublic: row['is_public'] as bool? ?? true,
      entityType: row['entity_type'] as String?,
      entityId: row['entity_id'] as String?,
    );
  }
}

const externalLinkProviders = [
  'website',
  'instagram',
  'facebook',
  'youtube',
  'tiktok',
  'whatsapp',
  'telegram',
];

// ── Repository Supabase ───────────────────────────────────────────────────────

class ExternalLinksRepository {
  const ExternalLinksRepository(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id, owner_id, entity_type, entity_id, provider, label, url, is_public, sort_order';

  Future<List<ExternalLinkRecord>> fetchAllForUser(String userId) async {
    final data = await _client
        .from('external_links')
        .select(_columns)
        .eq('owner_id', userId)
        .order('entity_type')
        .order('sort_order');
    return (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ExternalLinkRecord.fromRow)
        .toList();
  }

  Future<ExternalLinkRecord> insert({
    required String userId,
    required String entityType,
    required String entityId,
    required ExternalLinkRecord link,
    required int sortOrder,
  }) async {
    final payload = {
      'owner_id': userId,
      'entity_type': entityType,
      'entity_id': entityId,
      'provider': link.provider,
      'label': link.label,
      'url': link.url,
      'is_public': link.isPublic,
      'sort_order': sortOrder,
    };
    final data = await _client
        .from('external_links')
        .insert(payload)
        .select(_columns)
        .single();
    return ExternalLinkRecord.fromRow(data);
  }

  Future<void> delete(String linkId) async {
    await _client.from('external_links').delete().eq('id', linkId);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _externalLinksStorageKey = 'external_links_drafts_v1';

String externalLinksEntityKey({
  required String entityType,
  required String entityId,
}) {
  return '$entityType:$entityId';
}

/// Parsa una entityKey del tipo 'shop:my-slug' in (entityType, entityId).
/// Il separatore è il primo ':' — quindi entity_id può contenere ':' solo se
/// è un UUID (che non ne contiene).
(String, String)? _parseEntityKey(String entityKey) {
  final idx = entityKey.indexOf(':');
  if (idx < 1) return null;
  return (entityKey.substring(0, idx), entityKey.substring(idx + 1));
}

// ── Providers ─────────────────────────────────────────────────────────────────

final externalLinksRepositoryProvider =
    Provider<ExternalLinksRepository?>((ref) {
      final client = ref.watch(authClientProvider);
      if (client == null) return null;
      return ExternalLinksRepository(client);
    });

final externalLinksProvider =
    NotifierProvider<ExternalLinksController, Map<String, List<ExternalLinkRecord>>>(
      ExternalLinksController.new,
    );

final externalLinksForEntityProvider =
    Provider.family<List<ExternalLinkRecord>, String>((ref, entityKey) {
      final links = ref.watch(externalLinksProvider);
      return links[entityKey] ?? const [];
    });

// ── Controller ────────────────────────────────────────────────────────────────

class ExternalLinksController
    extends Notifier<Map<String, List<ExternalLinkRecord>>> {
  bool _loaded = false;

  @override
  Map<String, List<ExternalLinkRecord>> build() {
    final user = ref.watch(currentUserProvider);
    final repository = ref.watch(externalLinksRepositoryProvider);
    if (!_loaded) {
      _loaded = true;
      if (repository != null && user != null) {
        Future.microtask(() => _fetchFromSupabase(repository, user.id));
      } else {
        Future.microtask(_restoreFromLocal);
      }
    }
    return const {};
  }

  // ── Supabase ──────────────────────────────────────────────────────────────

  Future<void> _fetchFromSupabase(
    ExternalLinksRepository repository,
    String userId,
  ) async {
    try {
      final links = await repository.fetchAllForUser(userId);
      // Raggruppa i link per entityKey ('entityType:entityId')
      final map = <String, List<ExternalLinkRecord>>{};
      for (final link in links) {
        final key = link.entityKey;
        if (key == null) continue;
        map.putIfAbsent(key, () => []).add(link);
      }
      state = map;
      _persistLocal();
    } catch (e) {
      debugPrint('[ExternalLinks] fetchAllForUser error: $e');
      await _restoreFromLocal();
    }
  }

  // ── SharedPreferences fallback ────────────────────────────────────────────

  Future<void> _restoreFromLocal() async {
    if (state.isNotEmpty) return;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final raw = prefs.getString(_externalLinksStorageKey);
    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    state = decoded.map((key, value) {
      final records = (value as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ExternalLinkRecord.fromMap)
          .where((link) => link.url.trim().isNotEmpty)
          .toList();
      return MapEntry(key, records);
    });
  }

  Future<void> _persistLocal() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final serialized = state.map((key, value) {
        return MapEntry(key, value.map((link) => link.toMap()).toList());
      });
      await prefs.setString(_externalLinksStorageKey, jsonEncode(serialized));
    } catch (e) {
      debugPrint('[ExternalLinks] _persistLocal error: $e');
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> add({
    required String entityKey,
    required ExternalLinkRecord link,
  }) async {
    // Ottimistico: aggiorna lo stato locale immediatamente
    final current = state[entityKey] ?? const [];
    final updated = [link, ...current].take(8).toList();
    state = {...state, entityKey: updated};

    final repository = ref.read(externalLinksRepositoryProvider);
    final user = ref.read(currentUserProvider);

    if (repository != null && user != null) {
      final parsed = _parseEntityKey(entityKey);
      if (parsed != null) {
        final (entityType, entityId) = parsed;
        try {
          final saved = await repository.insert(
            userId: user.id,
            entityType: entityType,
            entityId: entityId,
            link: link,
            sortOrder: current.length,
          );
          // Sostituisci il record temporaneo con quello reale (UUID da server)
          final refreshed = state[entityKey] ?? [];
          state = {
            ...state,
            entityKey: [
              saved,
              ...refreshed.where((l) => l.id != link.id && l.id != saved.id),
            ].take(8).toList(),
          };
        } catch (e) {
          debugPrint('[ExternalLinks] insert error: $e');
        }
      }
    }

    _persistLocal();
  }

  Future<void> remove({
    required String entityKey,
    required String linkId,
  }) async {
    // Ottimistico: rimuovi subito dalla UI
    final current = state[entityKey] ?? const [];
    state = {
      ...state,
      entityKey: current.where((link) => link.id != linkId).toList(),
    };

    final repository = ref.read(externalLinksRepositoryProvider);
    // Cancella da Supabase solo se è un UUID (non un temp-id locale)
    if (repository != null && _looksLikeUuid(linkId)) {
      try {
        await repository.delete(linkId);
      } catch (e) {
        debugPrint('[ExternalLinks] delete error: $e');
      }
    }

    _persistLocal();
  }

  static bool _looksLikeUuid(String id) {
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    ).hasMatch(id);
  }
}
