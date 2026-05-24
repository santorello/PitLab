import '../models/user_build.dart';

abstract class GarageRepository {
  /// Ritorna tutte le build dell'utente (pubbliche e private).
  /// La RLS Supabase garantisce che solo il proprietario veda le proprie private.
  Future<List<UserBuild>> fetchBuilds({required String userId});

  /// Crea una nuova build e ritorna il record con l'UUID assegnato.
  Future<UserBuild> createBuild({
    required String userId,
    required UserBuild build,
  });

  /// Aggiorna una build esistente.
  Future<UserBuild> updateBuild({required UserBuild build});

  /// Elimina una build.
  Future<void> deleteBuild({required String buildId});

  /// Aggiorna solo il flag is_public.
  Future<void> toggleVisibility({
    required String buildId,
    required bool isPublic,
  });
}
