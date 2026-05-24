import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user_build.dart';
import '../../../shared/repositories/garage_repository.dart';
import '../../auth/application/auth_providers.dart';
import '../../tracks/application/tracks_providers.dart';
import '../infrastructure/supabase_garage_repository.dart';

final garageRepositoryProvider = Provider<GarageRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseGarageRepository(client);
});

// ── Stato delle build ─────────────────────────────────────────────────────

class GarageState {
  const GarageState({
    this.builds = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final List<UserBuild> builds;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  GarageState copyWith({
    List<UserBuild>? builds,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return GarageState(
      builds: builds ?? this.builds,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

final garageProvider = NotifierProvider<GarageController, GarageState>(
  GarageController.new,
);

class GarageController extends Notifier<GarageState> {
  @override
  GarageState build() {
    // Usa effectiveUserIdProvider: in modalità impersonazione mostra
    // le build dell'utente osservato, non dell'admin reale.
    final userId = ref.watch(effectiveUserIdProvider);
    final repository = ref.watch(garageRepositoryProvider);

    if (userId != null && repository != null) {
      // Differire al microtask successivo: build() deve prima restituire
      // lo stato iniziale prima che _loadBuilds() acceda a `state`.
      Future.microtask(() => _loadBuilds(repository: repository, userId: userId));
    }

    return const GarageState(isLoading: true);
  }

  Future<void> _loadBuilds({
    required GarageRepository repository,
    required String userId,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final builds = await repository.fetchBuilds(userId: userId);
      state = state.copyWith(builds: builds, isLoading: false);
    } catch (e) {
      debugPrint('[Garage] load error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createBuild(UserBuild draft) async {
    final repository = ref.read(garageRepositoryProvider);
    // effectiveUserIdProvider: in impersonazione crea la build per l'utente
    // osservato, non per l'admin reale. Il JWT admin ha policy "admins manage all".
    final userId = ref.read(effectiveUserIdProvider);
    if (repository == null || userId == null) return false;

    state = state.copyWith(isSaving: true);
    try {
      final created = await repository.createBuild(
        userId: userId,
        build: draft,
      );
      state = state.copyWith(
        builds: [created, ...state.builds],
        isSaving: false,
      );
      return true;
    } catch (e) {
      debugPrint('[Garage] createBuild error: $e');
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateBuild(UserBuild updated) async {
    final repository = ref.read(garageRepositoryProvider);
    if (repository == null) return false;

    state = state.copyWith(isSaving: true);
    try {
      final saved = await repository.updateBuild(build: updated);
      state = state.copyWith(
        builds: state.builds
            .map((b) => b.id == saved.id ? saved : b)
            .toList(),
        isSaving: false,
      );
      return true;
    } catch (e) {
      debugPrint('[Garage] updateBuild error: $e');
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<void> toggleVisibility(UserBuild build) async {
    final repository = ref.read(garageRepositoryProvider);
    if (repository == null) return;

    final next = !build.isPublic;
    // Ottimistic update
    state = state.copyWith(
      builds: state.builds
          .map((b) => b.id == build.id ? b.copyWith(isPublic: next) : b)
          .toList(),
    );
    try {
      await repository.toggleVisibility(buildId: build.id, isPublic: next);
    } catch (e) {
      debugPrint('[Garage] toggleVisibility error: $e');
      // Rollback
      state = state.copyWith(
        builds: state.builds
            .map((b) => b.id == build.id ? b.copyWith(isPublic: !next) : b)
            .toList(),
        error: e.toString(),
      );
    }
  }

  Future<void> deleteBuild(UserBuild build) async {
    final repository = ref.read(garageRepositoryProvider);
    if (repository == null) return;

    // Ottimistic remove
    state = state.copyWith(
      builds: state.builds.where((b) => b.id != build.id).toList(),
    );
    try {
      await repository.deleteBuild(buildId: build.id);
    } catch (e) {
      debugPrint('[Garage] deleteBuild error: $e');
      // Rollback
      state = state.copyWith(
        builds: [...state.builds, build]
          ..sort((a, b) =>
              (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0))),
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    final repository = ref.read(garageRepositoryProvider);
    final userId = ref.read(effectiveUserIdProvider);
    if (repository == null || userId == null) return;
    await _loadBuilds(repository: repository, userId: userId);
  }
}
