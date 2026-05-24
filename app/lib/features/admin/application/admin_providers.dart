import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/auth_providers.dart';

// ─── Record types ────────────────────────────────────────────────────────────

class AdminOverviewRecord {
  const AdminOverviewRecord({
    required this.usersCount,
    required this.tracksCount,
    required this.shopsCount,
    required this.eventsCount,
    required this.trackCategoriesCount,
    required this.pendingApprovalsCount,
  });

  final int usersCount;
  final int tracksCount;
  final int shopsCount;
  final int eventsCount;
  final int trackCategoriesCount;
  final int pendingApprovalsCount;
}

class AdminTrackCategoryRecord {
  const AdminTrackCategoryRecord({
    required this.id,
    required this.key,
    required this.labelIt,
    required this.labelEn,
    required this.sortOrder,
  });

  final String id;
  final String key;
  final String labelIt;
  final String labelEn;
  final int sortOrder;
}

/// Preview record (used in recent users widget)
class AdminUserPreviewRecord {
  const AdminUserPreviewRecord({
    required this.id,
    required this.displayName,
    required this.role,
    required this.preferredLanguage,
  });

  final String id;
  final String displayName;
  final String role;
  final String preferredLanguage;
}

/// Full user record with created_at (used in complete users list)
class AdminFullUserRecord {
  const AdminFullUserRecord({
    required this.id,
    required this.displayName,
    required this.role,
    required this.preferredLanguage,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String role;
  final String preferredLanguage;
  final String createdAt;
}

class AdminApprovalRecord {
  const AdminApprovalRecord({
    required this.id,
    required this.entityType,
    required this.title,
    required this.subtitle,
    required this.ownerLabel,
    required this.locationLabel,
    required this.submittedAtLabel,
    required this.route,
    required this.needsReview,
  });

  final String id;
  final String entityType;
  final String title;
  final String subtitle;
  final String ownerLabel;
  final String locationLabel;
  final String submittedAtLabel;
  final String route;
  final bool needsReview;
}

/// A track record visible to admin (includes non-public and unapproved)
class AdminTrackRecord {
  const AdminTrackRecord({
    required this.id,
    required this.slug,
    required this.name,
    required this.city,
    required this.approvalStatus,
    required this.isPublic,
  });

  final String id;
  final String slug;
  final String name;
  final String city;
  final String approvalStatus;
  final bool isPublic;
}

/// A shop record visible to admin (includes non-public and unapproved)
class AdminShopRecord {
  const AdminShopRecord({
    required this.id,
    required this.slug,
    required this.name,
    required this.city,
    required this.approvalStatus,
    required this.isPublic,
  });

  final String id;
  final String slug;
  final String name;
  final String city;
  final String approvalStatus;
  final bool isPublic;
}

/// An event record visible to admin
class AdminEventRecord {
  const AdminEventRecord({
    required this.id,
    required this.title,
    required this.startAt,
    required this.visibility,
    required this.source,
  });

  final String id;
  final String title;
  final String startAt;
  final String visibility;
  final String source;

  bool get supportsVisibilityToggle => source == 'events';
}

// ─── Repository ──────────────────────────────────────────────────────────────

class AdminRepository {
  const AdminRepository(this._client);

  final SupabaseClient _client;

  Future<int> _count(String table) async {
    final response = await _client.from(table).select('id');
    return (response as List<dynamic>).length;
  }

  // ── Overview ──────────────────────────────────────────────────────────────

  Future<AdminOverviewRecord> fetchOverview() async {
    final usersCount = await _count('profiles');
    final tracksCount = await _count('tracks');
    final shopsCount = await _count('shops');
    final officialEventsCount = await _count('events');
    final communityEventsCount = await _count('community_events');
    final trackCategoriesCount = await _count('track_categories');
    return AdminOverviewRecord(
      usersCount: usersCount,
      tracksCount: tracksCount,
      shopsCount: shopsCount,
      eventsCount: officialEventsCount + communityEventsCount,
      trackCategoriesCount: trackCategoriesCount,
      pendingApprovalsCount: 0,
    );
  }

  // ── Track categories ──────────────────────────────────────────────────────

  Future<List<AdminTrackCategoryRecord>> fetchTrackCategories() async {
    final response = await _client
        .from('track_categories')
        .select('id, key, label_it, label_en, sort_order')
        .order('sort_order')
        .order('label_it');

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => AdminTrackCategoryRecord(
            id: row['id'] as String? ?? '',
            key: row['key'] as String? ?? '',
            labelIt: row['label_it'] as String? ?? '',
            labelEn: row['label_en'] as String? ?? '',
            sortOrder: row['sort_order'] as int? ?? 0,
          ),
        )
        .toList();
  }

  Future<void> createTrackCategory(String label) async {
    final normalized = label.trim();
    if (normalized.isEmpty) return;
    final key = normalized
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final sortOrder = DateTime.now().millisecondsSinceEpoch % max(1, 1000000);
    await _client.from('track_categories').insert({
      'key': key.isEmpty ? 'category_$sortOrder' : key,
      'label_it': normalized,
      'label_en': normalized,
      'sort_order': sortOrder,
    });
  }

  Future<void> deleteTrackCategory(String id) async {
    await _client.from('track_categories').delete().eq('id', id);
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<List<AdminUserPreviewRecord>> fetchRecentUsers() async {
    final response = await _client
        .from('profiles')
        .select('id, display_name, role, preferred_language')
        .order('created_at', ascending: false)
        .limit(8);

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => AdminUserPreviewRecord(
            id: row['id'] as String? ?? '',
            displayName: row['display_name'] as String? ?? '',
            role: row['role'] as String? ?? 'user',
            preferredLanguage: row['preferred_language'] as String? ?? 'it',
          ),
        )
        .toList();
  }

  Future<List<AdminFullUserRecord>> fetchAllUsers({int limit = 100}) async {
    final response = await _client
        .from('profiles')
        .select('id, display_name, role, preferred_language, created_at')
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => AdminFullUserRecord(
            id: row['id'] as String? ?? '',
            displayName: row['display_name'] as String? ?? '',
            role: row['role'] as String? ?? 'user',
            preferredLanguage: row['preferred_language'] as String? ?? 'it',
            createdAt: row['created_at'] as String? ?? '',
          ),
        )
        .toList();
  }

  /// Ricerca paginata server-side.
  /// Il totale esatto non è disponibile senza FetchOptions (rimosso in
  /// postgrest-dart 2.x): usa [hasMore] = list.length >= limit per la
  /// paginazione.
  Future<List<AdminFullUserRecord>> searchUsersPage({
    String query = '',
    String? roleFilter,
    int offset = 0,
    int limit = 30,
  }) async {
    var q = _client
        .from('profiles')
        .select('id, display_name, role, preferred_language, created_at');

    if (query.isNotEmpty) {
      q = q.ilike('display_name', '%$query%');
    }
    if (roleFilter != null) {
      q = q.eq('role', roleFilter);
    }

    final data = await q
        .order('display_name')
        .range(offset, offset + limit - 1);

    return (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => AdminFullUserRecord(
            id: row['id'] as String? ?? '',
            displayName: row['display_name'] as String? ?? '',
            role: row['role'] as String? ?? 'user',
            preferredLanguage: row['preferred_language'] as String? ?? 'it',
            createdAt: row['created_at'] as String? ?? '',
          ),
        )
        .toList();
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await _client.from('profiles').update({'role': newRole}).eq('id', userId);
  }

  Future<void> updateUserDisplayName(String userId, String displayName) async {
    await _client
        .from('profiles')
        .update({'display_name': displayName.trim()})
        .eq('id', userId);
  }

  // ── Tracks ────────────────────────────────────────────────────────────────

  Future<List<AdminTrackRecord>> fetchAllTracks() async {
    final response = await _client
        .from('tracks')
        .select('id, slug, name, city, approval_status, is_public')
        .order('name');

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => AdminTrackRecord(
            id: row['id'] as String? ?? '',
            slug: row['slug'] as String? ?? '',
            name: row['name'] as String? ?? '',
            city: row['city'] as String? ?? '',
            approvalStatus: row['approval_status'] as String? ?? 'draft',
            isPublic: row['is_public'] as bool? ?? false,
          ),
        )
        .toList();
  }

  Future<void> updateTrackApproval(String trackId, String status) async {
    // 'approved' → also make the track publicly visible.
    // 'rejected' / 'pending' → hide it from the public list.
    final isPublic = status == 'approved';
    await _client
        .from('tracks')
        .update({'approval_status': status, 'is_public': isPublic})
        .eq('id', trackId);
  }

  Future<void> deleteTrack(String trackId) async {
    await _client.from('tracks').delete().eq('id', trackId);
  }

  /// Conta le piste con approval_status = 'pending'.
  Future<int> countPendingTracks() async {
    final response = await _client
        .from('tracks')
        .select('id')
        .eq('approval_status', 'pending');
    return (response as List<dynamic>).length;
  }

  /// Conta i negozi con approval_status = 'pending'.
  Future<int> countPendingShops() async {
    final response = await _client
        .from('shops')
        .select('id')
        .eq('approval_status', 'pending');
    return (response as List<dynamic>).length;
  }

  /// Recupera le piste in attesa di approvazione come coda admin.
  Future<List<AdminApprovalRecord>> fetchPendingTrackSubmissions() async {
    final response = await _client
        .from('tracks')
        .select('id, slug, name, city, short_description, organization_name, submitted_by, created_at')
        .eq('approval_status', 'pending')
        .order('created_at');

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((row) {
          final id = row['id'] as String? ?? '';
          final name = row['name'] as String? ?? '';
          final slug = row['slug'] as String? ?? '';
          final city = row['city'] as String? ?? '';
          final shortDesc = row['short_description'] as String? ?? '';
          final orgName = row['organization_name'] as String? ?? '';
          final submittedBy = row['submitted_by'] as String? ?? '';
          final createdAt = row['created_at'] as String?;
          return AdminApprovalRecord(
            id: 'track-$id',
            entityType: 'Pista',
            title: name,
            subtitle: shortDesc,
            ownerLabel: orgName.isEmpty ? submittedBy : orgName,
            locationLabel: city,
            submittedAtLabel: _submittedAtLabelFromIso(createdAt),
            route: '/track/$slug',
            needsReview: true,
          );
        })
        .toList();
  }

  // ── Shops ─────────────────────────────────────────────────────────────────

  Future<List<AdminShopRecord>> fetchAllShops() async {
    final response = await _client
        .from('shops')
        .select('id, slug, name, city, approval_status, is_public')
        .order('name');

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => AdminShopRecord(
            id: row['id'] as String? ?? '',
            slug: row['slug'] as String? ?? '',
            name: row['name'] as String? ?? '',
            city: row['city'] as String? ?? '',
            approvalStatus: row['approval_status'] as String? ?? 'draft',
            isPublic: row['is_public'] as bool? ?? false,
          ),
        )
        .toList();
  }

  Future<List<AdminApprovalRecord>> fetchPendingShopSubmissions() async {
    final response = await _client
        .from('shops')
        .select(
          'id, slug, name, subtitle, organization_name, city, submitted_by, updated_at',
        )
        .eq('approval_status', 'pending')
        .order('updated_at', ascending: false);

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((row) {
          final submittedBy = row['submitted_by'] as String? ?? '';
          final organizationName = row['organization_name'] as String? ?? '';
          return AdminApprovalRecord(
            id: 'shop-${row['id'] as String? ?? ''}',
            entityType: 'Negozio',
            title: row['name'] as String? ?? '',
            subtitle: row['subtitle'] as String? ?? '',
            ownerLabel: organizationName.isEmpty ? submittedBy : organizationName,
            locationLabel: row['city'] as String? ?? 'N/D',
            submittedAtLabel: _submittedAtLabelFromIso(
              row['updated_at'] as String?,
            ),
            route: '/shop/${row['slug'] as String? ?? ''}',
            needsReview: true,
          );
        })
        .toList();
  }

  Future<void> updateShopApproval(String shopId, String status) async {
    await _client
        .from('shops')
        .update({'approval_status': status})
        .eq('id', shopId);
  }

  Future<void> updateShopVisibility(String shopId, {required bool isPublic}) async {
    await _client
        .from('shops')
        .update({'is_public': isPublic})
        .eq('id', shopId);
  }

  Future<void> deleteShop(String shopId) async {
    await _client.from('shops').delete().eq('id', shopId);
  }

  // ── Events ────────────────────────────────────────────────────────────────

  Future<List<AdminEventRecord>> fetchAllEvents({int limit = 100}) async {
    final officialResponse = await _client
        .from('events')
        .select('id, title, start_at, visibility')
        .order('start_at', ascending: false)
        .limit(limit);

    final communityResponse = await _client
        .from('community_events')
        .select('id, title, starts_at')
        .order('starts_at', ascending: false)
        .limit(limit);

    final officialEvents = (officialResponse as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => AdminEventRecord(
            id: row['id'] as String? ?? '',
            title: row['title'] as String? ?? '',
            startAt: row['start_at'] as String? ?? '',
            visibility: row['visibility'] as String? ?? 'public',
            source: 'events',
          ),
        )
        .toList();

    final communityEvents = (communityResponse as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => AdminEventRecord(
            id: row['id'] as String? ?? '',
            title: row['title'] as String? ?? '',
            startAt: row['starts_at'] as String? ?? '',
            visibility: 'public',
            source: 'community_events',
          ),
        )
        .toList();

    final combined = [...officialEvents, ...communityEvents];
    combined.sort((a, b) {
      final aDate = DateTime.tryParse(a.startAt);
      final bDate = DateTime.tryParse(b.startAt);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return combined.take(limit).toList();
  }

  Future<void> updateEventVisibility(String eventId, String visibility) async {
    await _client
        .from('events')
        .update({'visibility': visibility})
        .eq('id', eventId);
  }

  Future<void> deleteEvent(AdminEventRecord event) async {
    await _client.from(event.source).delete().eq('id', event.id);
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final adminRepositoryProvider = Provider<AdminRepository?>((ref) {
  final client = ref.watch(authClientProvider);
  if (client == null) return null;
  return AdminRepository(client);
});

final adminOverviewProvider = FutureProvider<AdminOverviewRecord?>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final role = ref.watch(effectiveUserRoleProvider);
  if (repository == null || role != 'admin') return null;
  final results = await Future.wait([
    repository.fetchOverview(),
    repository.countPendingTracks(),
    repository.countPendingShops(),
  ]);
  final overview = results[0] as AdminOverviewRecord;
  final pendingTracks = results[1] as int;
  final pendingShops = results[2] as int;
  return AdminOverviewRecord(
    usersCount: overview.usersCount,
    tracksCount: overview.tracksCount,
    shopsCount: overview.shopsCount,
    eventsCount: overview.eventsCount,
    trackCategoriesCount: overview.trackCategoriesCount,
    pendingApprovalsCount: pendingTracks + pendingShops,
  );
});

final adminTrackCategoriesProvider =
    FutureProvider<List<AdminTrackCategoryRecord>>((ref) async {
      final repository = ref.watch(adminRepositoryProvider);
      final role = ref.watch(effectiveUserRoleProvider);
      if (repository == null || role != 'admin') return const [];
      return repository.fetchTrackCategories();
    });

final adminRecentUsersProvider =
    FutureProvider<List<AdminUserPreviewRecord>>((ref) async {
      final repository = ref.watch(adminRepositoryProvider);
      final role = ref.watch(effectiveUserRoleProvider);
      if (repository == null || role != 'admin') return const [];
      return repository.fetchRecentUsers();
    });

final adminAllUsersProvider =
    FutureProvider<List<AdminFullUserRecord>>((ref) async {
      final repository = ref.watch(adminRepositoryProvider);
      final role = ref.watch(effectiveUserRoleProvider);
      if (repository == null || role != 'admin') return const [];
      return repository.fetchAllUsers();
    });

final adminAllTracksProvider =
    FutureProvider<List<AdminTrackRecord>>((ref) async {
      final repository = ref.watch(adminRepositoryProvider);
      final role = ref.watch(effectiveUserRoleProvider);
      if (repository == null || role != 'admin') return const [];
      return repository.fetchAllTracks();
    });

final adminAllShopsProvider =
    FutureProvider<List<AdminShopRecord>>((ref) async {
      final repository = ref.watch(adminRepositoryProvider);
      final role = ref.watch(effectiveUserRoleProvider);
      if (repository == null || role != 'admin') return const [];
      return repository.fetchAllShops();
    });

final adminAllEventsProvider =
    FutureProvider<List<AdminEventRecord>>((ref) async {
      final repository = ref.watch(adminRepositoryProvider);
      final role = ref.watch(effectiveUserRoleProvider);
      if (repository == null || role != 'admin') return const [];
      return repository.fetchAllEvents();
    });

/// Coda approvazioni per admin.
/// Track e negozi sono entrambi letti da Supabase.
final adminApprovalQueueProvider = FutureProvider<List<AdminApprovalRecord>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final role = ref.watch(effectiveUserRoleProvider);
  if (role != 'admin') return const [];

  // Track items from Supabase
  final trackItems = repository == null
      ? <AdminApprovalRecord>[]
      : await repository.fetchPendingTrackSubmissions();

  final shopItems = repository == null
      ? <AdminApprovalRecord>[]
      : await repository.fetchPendingShopSubmissions();

  return [...trackItems, ...shopItems];
});

String _submittedAtLabelFromIso(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return 'in attesa';
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return 'in attesa';
  return _submittedAtLabelFromDt(parsed);
}

String _submittedAtLabelFromDt(DateTime parsed) {
  final difference = DateTime.now().difference(parsed);
  if (difference.inMinutes < 60) {
    return 'inviata ${difference.inMinutes.clamp(1, 59)}m fa';
  }
  if (difference.inHours < 24) return 'inviata ${difference.inHours}h fa';
  return 'inviata ${difference.inDays}g fa';
}

// ─── Admin Users Search ───────────────────────────────────────────────────────

class AdminUsersState {
  const AdminUsersState({
    this.users = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.query = '',
    this.roleFilter,
    this.error,
  });

  static const int pageSize = 30;

  final List<AdminFullUserRecord> users;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String query;
  final String? roleFilter;
  final String? error;

  /// Etichetta conteggio: "30+" se ci sono altre pagine, altrimenti il totale esatto.
  String get countLabel =>
      hasMore ? '${users.length}+' : '${users.length}';

  AdminUsersState copyWith({
    List<AdminFullUserRecord>? users,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? query,
    Object? roleFilter = _sentinel,
    String? error,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      query: query ?? this.query,
      roleFilter: roleFilter == _sentinel
          ? this.roleFilter
          : roleFilter as String?,
      error: error ?? this.error,
    );
  }
}

const _sentinel = Object();

final adminUsersProvider =
    NotifierProvider<AdminUsersController, AdminUsersState>(
      AdminUsersController.new,
    );

class AdminUsersController extends Notifier<AdminUsersState> {
  Timer? _debounce;

  @override
  AdminUsersState build() {
    // Se il client auth non è ancora pronto al primo render, riprova
    // non appena adminRepositoryProvider diventa non-null.
    ref.listen<AdminRepository?>(adminRepositoryProvider, (prev, next) {
      if (next != null && state.isLoading) {
        unawaited(_loadPage(reset: true));
      }
    });
    // Differire _loadPage al microtask successivo: build() deve prima
    // restituire lo stato iniziale, altrimenti `state` risulta non inizializzato
    // e qualsiasi accesso a state.query / state.copyWith() lancia un'eccezione.
    Future.microtask(() => _loadPage(reset: true));
    return const AdminUsersState();
  }

  Future<void> _loadPage({bool reset = false}) async {
    final repo = ref.read(adminRepositoryProvider);
    if (repo == null) return; // il listener sopra rilancerà quando pronto

    final offset = reset ? 0 : state.users.length;

    try {
      final users = await repo.searchUsersPage(
        query: state.query,
        roleFilter: state.roleFilter,
        offset: offset,
        limit: AdminUsersState.pageSize,
      );

      final merged = reset ? users : [...state.users, ...users];
      state = state.copyWith(
        users: merged,
        hasMore: users.length >= AdminUsersState.pageSize,
        isLoading: false,
        isLoadingMore: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  void setQuery(String query) {
    _debounce?.cancel();
    state = state.copyWith(query: query);
    _debounce = Timer(const Duration(milliseconds: 350), () {
      state = state.copyWith(users: [], isLoading: true, hasMore: false);
      unawaited(_loadPage(reset: true));
    });
  }

  void setRoleFilter(String? role) {
    _debounce?.cancel();
    // Nota: non usare `role ?? _sentinel` — se role è null (Tutti), deve
    // resettare il filtro a null, non mantenere il valore precedente.
    state = state.copyWith(
      roleFilter: role,
      users: [],
      isLoading: true,
      hasMore: false,
    );
    unawaited(_loadPage(reset: true));
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _loadPage(reset: false);
  }

  /// Aggiorna in-place un record utente senza ricaricare tutto.
  void patchUser(AdminFullUserRecord updated) {
    state = state.copyWith(
      users: state.users
          .map((u) => u.id == updated.id ? updated : u)
          .toList(),
    );
  }

  void refresh() {
    state = state.copyWith(users: [], isLoading: true, hasMore: false);
    unawaited(_loadPage(reset: true));
  }
}
