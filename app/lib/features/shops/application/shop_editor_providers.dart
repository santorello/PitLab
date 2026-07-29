import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/auth_providers.dart';

class EditableShopRecord {
  const EditableShopRecord({
    this.id = '',
    required this.slug,
    required this.name,
    this.userId = '',
    required this.subtitle,
    required this.imageUrl,
    required this.galleryImages,
    this.address = '',
    this.city = '',
    this.website = '',
    this.organizationName = '',
    this.serviceLabels = const [],
    this.approvalStatus = 'draft',
    this.submittedAt,
    required this.contacts,
    required this.hours,
    required this.notes,
  });

  final String id;
  final String slug;
  final String name;
  final String userId;
  final String subtitle;
  final String imageUrl;
  final List<String> galleryImages;
  final String address;
  final String city;
  final String website;
  final String organizationName;
  final List<String> serviceLabels;
  final String approvalStatus;
  final String? submittedAt;
  final String contacts;
  final String hours;
  final String notes;

  EditableShopRecord copyWith({
    String? id,
    String? slug,
    String? name,
    String? userId,
    String? subtitle,
    String? imageUrl,
    List<String>? galleryImages,
    String? address,
    String? city,
    String? website,
    String? organizationName,
    List<String>? serviceLabels,
    String? approvalStatus,
    String? submittedAt,
    String? contacts,
    String? hours,
    String? notes,
  }) {
    return EditableShopRecord(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      address: address ?? this.address,
      city: city ?? this.city,
      website: website ?? this.website,
      organizationName: organizationName ?? this.organizationName,
      serviceLabels: serviceLabels ?? this.serviceLabels,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      submittedAt: submittedAt ?? this.submittedAt,
      contacts: contacts ?? this.contacts,
      hours: hours ?? this.hours,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'userId': userId,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'galleryImages': galleryImages,
      'address': address,
      'city': city,
      'website': website,
      'organizationName': organizationName,
      'serviceLabels': serviceLabels,
      'approvalStatus': approvalStatus,
      'submittedAt': submittedAt,
      'contacts': contacts,
      'hours': hours,
      'notes': notes,
    };
  }

  factory EditableShopRecord.fromMap(Map<String, dynamic> map) {
    return EditableShopRecord(
      id: map['id'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      name: map['name'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      galleryImages: (map['galleryImages'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      website: map['website'] as String? ?? '',
      organizationName: map['organizationName'] as String? ?? '',
      serviceLabels: (map['serviceLabels'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      approvalStatus: map['approvalStatus'] as String? ?? 'draft',
      submittedAt: map['submittedAt'] as String?,
      contacts: map['contacts'] as String? ?? '',
      hours: map['hours'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }

  factory EditableShopRecord.fromRow(Map<String, dynamic> row) {
    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value.whereType<String>().where((item) => item.isNotEmpty).toList();
      }
      return const [];
    }

    final approvalStatus = row['approval_status'] as String? ?? 'draft';
    final submittedAt = approvalStatus == 'pending'
        ? (row['updated_at'] as String? ?? row['created_at'] as String?)
        : null;

    return EditableShopRecord(
      id: row['id'] as String? ?? '',
      slug: row['slug'] as String? ?? '',
      name: row['name'] as String? ?? '',
      userId: row['submitted_by'] as String? ?? '',
      subtitle: row['subtitle'] as String? ?? row['short_description'] as String? ?? '',
      imageUrl: row['image_url'] as String? ?? '',
      galleryImages: parseStringList(row['gallery_images']),
      address: row['address'] as String? ?? '',
      city: row['city'] as String? ?? '',
      website: row['website_url'] as String? ?? '',
      organizationName: row['organization_name'] as String? ?? '',
      serviceLabels: parseStringList(row['service_labels']),
      approvalStatus: approvalStatus,
      submittedAt: submittedAt,
      contacts: row['contacts'] as String? ?? '',
      hours: row['hours'] as String? ?? '',
      notes: row['notes'] as String? ?? '',
    );
  }
}

const _shopDraftsStorageKey = 'shop_editor_drafts_v1';
const _shopEditorColumns =
    'id, slug, name, short_description, subtitle, organization_name, '
    'address, city, website_url, image_url, gallery_images, service_labels, '
    'hours, contacts, notes, approval_status, submitted_by, created_at, updated_at';

class EditableShopsRepository {
  const EditableShopsRepository(this._client);

  final SupabaseClient _client;

  Future<List<EditableShopRecord>> fetchOwnedAndManaged(String userId) async {
    final ownRows = await _client
        .from('shops')
        .select(_shopEditorColumns)
        .eq('submitted_by', userId)
        .order('updated_at', ascending: false);

    final managedRows = await _client
        .from('shop_managers')
        .select('shop_id, shops($_shopEditorColumns)')
        .eq('user_id', userId);

    final merged = <String, EditableShopRecord>{};

    for (final row in (ownRows as List<dynamic>).whereType<Map<String, dynamic>>()) {
      final record = EditableShopRecord.fromRow(row);
      merged[record.slug] = record;
    }

    for (final row in (managedRows as List<dynamic>).whereType<Map<String, dynamic>>()) {
      final shop = row['shops'];
      if (shop is! Map<String, dynamic>) continue;
      final record = EditableShopRecord.fromRow(shop);
      merged[record.slug] = record;
    }

    final records = merged.values.toList()
      ..sort((a, b) {
        final left = a.submittedAt ?? '';
        final right = b.submittedAt ?? '';
        return right.compareTo(left);
      });
    return records;
  }

  Future<EditableShopRecord> save({
    required String userId,
    required EditableShopRecord record,
  }) async {
    final normalizedStatus = switch (record.approvalStatus) {
      'pending' => 'pending',
      'approved' when record.id.isNotEmpty => 'approved',
      _ => 'draft',
    };
    final sanitizedCover = _sanitizeImage(record.imageUrl);
    final sanitizedGallery = record.galleryImages
        .map(_sanitizeImage)
        .whereType<String>()
        .toList();

    final payload = <String, dynamic>{
      'slug': record.slug,
      'name': record.name,
      'short_description': record.subtitle,
      'subtitle': record.subtitle,
      'organization_name': record.organizationName,
      'address': record.address,
      'city': record.city.isEmpty ? 'Italia' : record.city,
      'website_url': record.website,
      'image_url': sanitizedCover ?? '',
      'gallery_images': sanitizedGallery,
      'service_labels': record.serviceLabels,
      'hours': record.hours,
      'contacts': record.contacts,
      'notes': record.notes,
      'approval_status': normalizedStatus,
      'is_public': normalizedStatus == 'approved',
    };

    String? existingId = record.id.isNotEmpty ? record.id : null;
    if (existingId == null || existingId.isEmpty) {
      final existing = await _client
          .from('shops')
          .select('id')
          .eq('slug', record.slug)
          .maybeSingle();
      existingId = existing?['id'] as String?;
    }

    final data = existingId != null && existingId.isNotEmpty
        ? await _client
              .from('shops')
              .update(payload)
              .eq('id', existingId)
              .select(_shopEditorColumns)
              .single()
        : await _client
              .from('shops')
              .insert({
                ...payload,
                'submitted_by': userId,
              })
              .select(_shopEditorColumns)
              .single();

    return EditableShopRecord.fromRow(data);
  }

  /// Fetcha un negozio per slug indipendentemente dallo stato di approvazione.
  /// Usato dall'editor per pre-popolare il form anche quando il negozio è
  /// in stato pending o draft. La RLS Supabase garantisce che solo owner e
  /// admin possano leggere il proprio negozio non ancora pubblico.
  Future<EditableShopRecord?> fetchBySlugIncludingDrafts(String slug) async {
    final response = await _client
        .from('shops')
        .select(_shopEditorColumns)
        .eq('slug', slug)
        .maybeSingle();
    if (response == null) return null;
    return EditableShopRecord.fromRow(response);
  }

  Future<void> updateApprovalStatus({
    required String shopId,
    required String approvalStatus,
  }) async {
    await _client
        .from('shops')
        .update({
          'approval_status': approvalStatus,
          'is_public': approvalStatus == 'approved',
        })
        .eq('id', shopId);
  }

  static String? _sanitizeImage(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value.startsWith('data:image')) {
      return null;
    }
    return value;
  }
}

final editableShopsRepositoryProvider = Provider<EditableShopsRepository?>((ref) {
  final client = ref.watch(authClientProvider);
  if (client == null) return null;
  return EditableShopsRepository(client);
});

final editableShopDraftsProvider =
    NotifierProvider<EditableShopDraftsController, Map<String, EditableShopRecord>>(
      EditableShopDraftsController.new,
    );

final editableShopProvider = Provider.family<EditableShopRecord?, String>((ref, slug) {
  final drafts = ref.watch(editableShopDraftsProvider);
  return drafts[slug];
});

/// Provider che legge il draft per uno slug specifico oppure fetcha il negozio reale.
/// Usato dall'UI per popolare il form con dati coerenti (draft se esiste, altrimenti shop reale).
/// Nota: usa [EditableShopsRepository] per includere anche i negozi in stato
/// pending/draft (la RLS Supabase limita la visibilità a owner + admin).
final editableShopOrPublishedProvider =
    FutureProvider.family<EditableShopRecord?, String>((ref, slug) async {
  // Priorità 1: cerca il draft nella cache locale
  final drafts = ref.watch(editableShopDraftsProvider);
  if (drafts.containsKey(slug)) {
    return drafts[slug];
  }

  // Priorità 2: fetcha il negozio tramite repository editor (include pending/draft).
  // Non usa publicShopsRepository perché filtra is_public = true e quindi
  // esclude i negozi non ancora approvati.
  final editableRepo = ref.watch(editableShopsRepositoryProvider);
  if (editableRepo != null) {
    final record = await editableRepo.fetchBySlugIncludingDrafts(slug);
    if (record != null) return record;
  }

  // Fallback: nessun draft e nessuno shop trovato
  return null;
});

final myEditableShopDraftsProvider = Provider<List<EditableShopRecord>>((ref) {
  final drafts = ref.watch(editableShopDraftsProvider).values.toList();
  drafts.sort((a, b) {
    final left = a.submittedAt ?? '';
    final right = b.submittedAt ?? '';
    return right.compareTo(left);
  });
  return drafts;
});

class EditableShopDraftsController extends Notifier<Map<String, EditableShopRecord>> {
  // Key-based loading: resetta e ricarica solo quando cambia l'utente effettivo.
  // Stesso pattern di FollowedTrackIdsController — supporta impersonazione.
  String? _loadedForKey;
  Map<String, EditableShopRecord> _cached = const {};

  @override
  Map<String, EditableShopRecord> build() {
    final repository = ref.watch(editableShopsRepositoryProvider);
    // effectiveUserIdProvider: in impersonazione usa l'utente osservato, non l'admin.
    final userId = ref.watch(effectiveUserIdProvider);
    final nextKey = repository != null && userId != null ? 'remote:$userId' : 'guest';

    if (_loadedForKey != nextKey) {
      _loadedForKey = nextKey;
      _cached = const {};
      if (repository != null && userId != null) {
        Future.microtask(() => _restoreRemote(repository, userId));
      } else {
        Future.microtask(_restoreLocal);
      }
    }

    return _cached;
  }

  Future<void> _restoreRemote(
    EditableShopsRepository repository,
    String userId,
  ) async {
    try {
      final records = await repository.fetchOwnedAndManaged(userId);
      _cached = {for (final record in records) record.slug: record};
      state = _cached;
      await _persistLocal();
    } catch (error) {
      debugPrint('[ShopEditor] Unable to fetch remote shops for $userId: $error');
    }
  }

  Future<void> _restoreLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shopDraftsStorageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    state = decoded.map((key, value) {
      return MapEntry(
        key,
        EditableShopRecord.fromMap(value as Map<String, dynamic>),
      );
    });
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = state.map((key, value) {
      return MapEntry(key, value.toMap());
    });
    await prefs.setString(_shopDraftsStorageKey, jsonEncode(serialized));
  }

  Future<bool> save(EditableShopRecord record) async {
    final repository = ref.read(editableShopsRepositoryProvider);
    // effectiveUserIdProvider: in impersonazione il negozio viene creato/aggiornato
    // per conto dell'utente osservato. Il JWT admin soddisfa "is_admin()" nelle policy.
    final userId = ref.read(effectiveUserIdProvider);

    if (repository != null && userId != null) {
      final saved = await repository.save(userId: userId, record: record);
      _cached = {..._cached, saved.slug: saved};
      state = _cached;
      await _persistLocal();
      return true;
    }

    _cached = {..._cached, record.slug: record};
    state = _cached;
    await _persistLocal();
    return false;
  }

  Future<void> updateApprovalStatus({
    required String identifier,
    required String approvalStatus,
  }) async {
    final repository = ref.read(editableShopsRepositoryProvider);
    final existing = state.values
        .cast<EditableShopRecord?>()
        .firstWhere(
          (record) => record != null && (record.id == identifier || record.slug == identifier),
          orElse: () => null,
        );
    if (existing == null) {
      return;
    }

    if (repository != null && existing.id.isNotEmpty) {
      await repository.updateApprovalStatus(
        shopId: existing.id,
        approvalStatus: approvalStatus,
      );
    }

    final updated = existing.copyWith(
      approvalStatus: approvalStatus,
      submittedAt: approvalStatus == 'pending'
          ? DateTime.now().toIso8601String()
          : existing.submittedAt,
    );
    _cached = {..._cached, existing.slug: updated};
    state = _cached;
    await _persistLocal();
  }
}
