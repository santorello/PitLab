import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/bootstrap/app_config.dart';

const String legalDocumentVersion = '2026-04-03-draft';

class UserConsentRecord {
  const UserConsentRecord({
    required this.consentType,
    required this.accepted,
    required this.documentVersion,
    required this.source,
    this.updatedAt,
  });

  final String consentType;
  final bool accepted;
  final String documentVersion;
  final String source;
  final DateTime? updatedAt;
}

class UserProfileRecord {
  const UserProfileRecord({
    required this.displayName,
    required this.preferredLanguage,
    required this.role,
    this.avatarUrl,
    this.publicSlug,
    this.isPublic = false,
  });

  final String displayName;
  final String preferredLanguage;
  final String role;
  final String? avatarUrl;

  /// Slug univoco per il profilo pubblico (opzionale).
  final String? publicSlug;

  /// Se true, il profilo è visibile ai guest tramite /u/:publicSlug.
  final bool isPublic;
}

class AuthProfileRepository {
  const AuthProfileRepository(this._client);

  final SupabaseClient _client;

  Future<String?> fetchPreferredLanguage(String userId) async {
    final response = await _client
        .from('profiles')
        .select('preferred_language')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return response['preferred_language'] as String?;
  }

  Future<UserProfileRecord?> fetchProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select('display_name, avatar_url, preferred_language, role, public_slug, is_public')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return UserProfileRecord(
      displayName: response['display_name'] as String? ?? '',
      avatarUrl: response['avatar_url'] as String?,
      preferredLanguage: response['preferred_language'] as String? ?? 'it',
      role: response['role'] as String? ?? 'user',
      publicSlug: response['public_slug'] as String?,
      isPublic: response['is_public'] as bool? ?? false,
    );
  }

  Future<void> updatePublicProfileSettings({
    required String userId,
    required bool isPublic,
    String? publicSlug,
  }) async {
    await _client.from('profiles').update({
      'is_public': isPublic,
      'public_slug': publicSlug?.trim().isEmpty == true ? null : publicSlug?.trim(),
    }).eq('id', userId);
  }

  Future<void> upsertPreferredLanguage({
    required String userId,
    required String languageCode,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'preferred_language': languageCode,
    }, onConflict: 'id');
  }

  Future<void> upsertProfileBasics({
    required String userId,
    required String displayName,
    required String languageCode,
    String? avatarUrl,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'display_name': displayName,
      'preferred_language': languageCode,
      'avatar_url': avatarUrl,
    }, onConflict: 'id');
  }

  Future<void> applyRegistrationRoleIntent({
    required String userId,
    required String selectedRole,
  }) async {
    final normalizedRole = switch (selectedRole) {
      'shop_owner' => 'shop_owner',
      'track_organizer' => 'track_organizer',
      _ => 'user',
    };

    if (normalizedRole == 'user') {
      return;
    }

    final current = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    final currentRole = current?['role'] as String? ?? 'user';
    if (currentRole != 'user') {
      debugPrint(
        '[AuthFlow] Skip role intent update for user=$userId currentRole=$currentRole requestedRole=$normalizedRole',
      );
      return;
    }

    await _client.from('profiles').upsert({
      'id': userId,
      'role': normalizedRole,
    }, onConflict: 'id');
    debugPrint('[AuthFlow] Applied registration role intent for user=$userId role=$normalizedRole');
  }

  Future<void> upsertUserConsent({
    required String userId,
    required String consentType,
    required bool accepted,
    required String documentVersion,
    required String source,
  }) async {
    try {
      await _client.from('user_consents').upsert({
        'user_id': userId,
        'consent_type': consentType,
        'accepted': accepted,
        'document_version': documentVersion,
        'source': source,
      }, onConflict: 'user_id,consent_type');
    } catch (error) {
      debugPrint(
        '[ConsentFlow] Unable to persist consentType=$consentType for user=$userId: $error',
      );
    }
  }

  Future<List<UserConsentRecord>> fetchUserConsents(String userId) async {
    try {
      final response = await _client
          .from('user_consents')
          .select('consent_type, accepted, document_version, source, updated_at')
          .eq('user_id', userId)
          .order('consent_type');

      return (response as List<dynamic>).map((row) {
        final map = row as Map<String, dynamic>;
        return UserConsentRecord(
          consentType: map['consent_type'] as String,
          accepted: map['accepted'] as bool? ?? false,
          documentVersion: map['document_version'] as String? ?? legalDocumentVersion,
          source: map['source'] as String? ?? 'unknown',
          updatedAt: map['updated_at'] == null
              ? null
              : DateTime.tryParse(map['updated_at'] as String),
        );
      }).toList();
    } catch (error) {
      debugPrint('[ConsentFlow] Unable to fetch user consents for user=$userId: $error');
      return const [];
    }
  }
}

final authClientProvider = Provider<SupabaseClient?>((ref) {
  if (!AppConfig.hasSupabaseConfig) {
    return null;
  }

  return Supabase.instance.client;
});

final authProfileRepositoryProvider = Provider<AuthProfileRepository?>((ref) {
  final client = ref.watch(authClientProvider);
  if (client == null) {
    return null;
  }

  return AuthProfileRepository(client);
});

final authStateProvider = StreamProvider<AuthState?>((ref) {
  final client = ref.watch(authClientProvider);
  if (client == null) {
    return Stream<AuthState?>.value(null);
  }

  return client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  final client = ref.watch(authClientProvider);
  return client?.auth.currentUser;
});

final preferredLanguageProfileProvider = FutureProvider<String?>((ref) async {
  final repository = ref.watch(authProfileRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (repository == null || user == null) {
    return null;
  }

  return repository.fetchPreferredLanguage(user.id);
});

final userProfileProvider = FutureProvider<UserProfileRecord?>((ref) async {
  final repository = ref.watch(authProfileRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (repository == null || user == null) {
    return null;
  }

  return repository.fetchProfile(user.id);
});

final currentUserRoleProvider = Provider<String>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile?.role ?? 'user',
    orElse: () => 'user',
  );
});

/// Stato completo di impersonazione: identità specifica di un utente.
/// Usato per simulare la vista e i diritti di un utente preciso senza
/// toccare la sessione Supabase.
class ImpersonationState {
  const ImpersonationState({
    required this.userId,
    required this.displayName,
    required this.role,
  });

  final String userId;
  final String displayName;
  final String role;
}

final impersonationProvider =
    NotifierProvider<ImpersonationController, ImpersonationState?>(
      ImpersonationController.new,
    );

class ImpersonationController extends Notifier<ImpersonationState?> {
  @override
  ImpersonationState? build() => null;

  /// Impersona un utente specifico ereditandone nome e ruolo.
  void impersonateUser({
    required String userId,
    required String displayName,
    required String role,
  }) {
    state = ImpersonationState(
      userId: userId,
      displayName: displayName,
      role: role,
    );
  }

  /// Smette di impersonare, tornando al ruolo reale.
  void stop() {
    state = null;
  }
}

/// Provider derivato — compatibilità con il codice che legge solo il ruolo.
final impersonatedRoleProvider = Provider<String?>((ref) {
  return ref.watch(impersonationProvider)?.role;
});

final isImpersonatingProvider = Provider<bool>((ref) {
  return ref.watch(impersonationProvider) != null;
});

final effectiveUserIdProvider = Provider<String?>((ref) {
  final impersonation = ref.watch(impersonationProvider);
  if (impersonation != null) {
    return impersonation.userId;
  }
  return ref.watch(currentUserProvider)?.id;
});

final effectiveUserProfileProvider = FutureProvider<UserProfileRecord?>((
  ref,
) async {
  final repository = ref.watch(authProfileRepositoryProvider);
  final userId = ref.watch(effectiveUserIdProvider);
  if (repository == null || userId == null) {
    return null;
  }

  return repository.fetchProfile(userId);
});

final effectiveUserConsentsProvider =
    FutureProvider<List<UserConsentRecord>>((ref) async {
      final repository = ref.watch(authProfileRepositoryProvider);
      final userId = ref.watch(effectiveUserIdProvider);
      if (repository == null || userId == null) {
        return const [];
      }

      return repository.fetchUserConsents(userId);
    });

final effectiveUserRoleProvider = Provider<String>((ref) {
  final actualRole = ref.watch(currentUserRoleProvider);
  final impersonatedRole = ref.watch(impersonatedRoleProvider);
  return impersonatedRole ?? actualRole;
});

final canManageShopsProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final role = ref.watch(effectiveUserRoleProvider);
  return currentUser != null && (role == 'shop_owner' || role == 'admin');
});

final canManageTracksProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final role = ref.watch(effectiveUserRoleProvider);
  return currentUser != null && (role == 'track_organizer' || role == 'admin');
});

final isAdminProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  // Usa effectiveUserRoleProvider: rispetta l'impersonazione.
  // Un admin che impersona uno shop_owner non vede l'UI admin.
  final role = ref.watch(effectiveUserRoleProvider);
  return currentUser != null && role == 'admin';
});

final userConsentsProvider = FutureProvider<List<UserConsentRecord>>((ref) async {
  final repository = ref.watch(authProfileRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (repository == null || user == null) {
    return const [];
  }

  return repository.fetchUserConsents(user.id);
});
