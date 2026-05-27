import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/not_found_screen.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/admin/presentation/admin_settings_screen.dart';
import '../../features/discovery/presentation/nearby_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/garage/presentation/garage_screen.dart';
import '../../features/garage/presentation/public_builds_screen.dart';
import '../../features/legal/presentation/legal_document_screen.dart';
import '../../features/manager/presentation/manager_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/pitcoin/presentation/pitcoin_history_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/public_profile_screen.dart';
import '../../features/profile/presentation/public_profiles_screen.dart';
import '../../features/shops/presentation/shop_detail_screen.dart';
import '../../features/shops/presentation/shop_editor_screen.dart';
import '../../features/shops/presentation/shops_screen.dart';
import '../../features/spots/presentation/spot_detail_screen.dart';
import '../../features/spots/presentation/spots_map_screen.dart';
import '../../features/spots/presentation/spots_screen.dart';
import '../../features/submissions/presentation/submit_place_screen.dart';
import '../../features/tracks/presentation/track_detail_screen.dart';
import '../../features/tracks/presentation/track_editor_screen.dart';
import '../../features/community/presentation/community_home_screen.dart';
import '../../features/tracks/presentation/tracks_home_screen.dart';
import '../../features/tracks/presentation/managed_track_editor_screen.dart';
import '../../shared/models/submitted_track.dart';

// ---------------------------------------------------------------------------
// RouterNotifier
//
// Wrappa lo stato di autenticazione in un ChangeNotifier in modo che il
// GoRouter possa ascoltare i cambiamenti senza dover essere ricreato da zero.
// Pattern: usare ref.listen (non ref.watch) per aggiornare le variabili
// locali e notificare il router di rivalutare i redirect.
// ---------------------------------------------------------------------------

class _RouterNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Stato iniziale letto una volta sola (ref.read, non ref.watch).
  // I cambiamenti successivi arrivano tramite ref.listen → _RouterNotifier.
  var currentUser = ref.read(currentUserProvider);
  var isAdmin = ref.read(isAdminProvider);
  var canManageTracks = ref.read(canManageTracksProvider);
  var canManageShops = ref.read(canManageShopsProvider);

  final notifier = _RouterNotifier();

  // Aggiorna le variabili locali e segnala al router di rivalutare i redirect.
  // Il GoRouter NON viene ricreato: solo la funzione redirect è rieseguita.
  ref.listen<User?>(currentUserProvider, (_, next) {
    currentUser = next;
    notifier.notify();
  });
  ref.listen<bool>(isAdminProvider, (_, next) {
    isAdmin = next;
    notifier.notify();
  });
  ref.listen<bool>(canManageTracksProvider, (_, next) {
    canManageTracks = next;
    notifier.notify();
  });
  ref.listen<bool>(canManageShopsProvider, (_, next) {
    canManageShops = next;
    notifier.notify();
  });

  // Dispose del notifier quando il provider viene dismesso.
  ref.onDispose(notifier.dispose);

  // ---------------------------------------------------------------------------
  // Helper redirect
  // ---------------------------------------------------------------------------

  String? requireAuth(GoRouterState state) {
    if (currentUser != null) return null;
    return '/login?redirect=${Uri.encodeComponent(state.uri.toString())}';
  }

  String? requireAdmin(GoRouterState state) {
    final authRedirect = requireAuth(state);
    if (authRedirect != null) return authRedirect;
    return isAdmin ? null : '/';
  }

  String? requireTrackManager(GoRouterState state) {
    final authRedirect = requireAuth(state);
    if (authRedirect != null) return authRedirect;
    return canManageTracks ? null : '/';
  }

  String? requireShopManager(GoRouterState state) {
    final authRedirect = requireAuth(state);
    if (authRedirect != null) return authRedirect;
    return canManageShops ? null : '/';
  }

  // ---------------------------------------------------------------------------
  // GoRouter
  // ---------------------------------------------------------------------------

  return GoRouter(
    initialLocation: '/',
    // refreshListenable fa sì che GoRouter rivaluti i redirect quando lo stato
    // di autenticazione cambia, senza ricreare l'intera istanza del router.
    refreshListenable: notifier,
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const CommunityHomeScreen(),
          ),
          GoRoute(
            path: '/tracks',
            name: 'tracks',
            builder: (context, state) => const TracksHomeScreen(),
          ),
          GoRoute(
            path: '/nearby',
            name: 'nearby',
            builder: (context, state) => const NearbyScreen(),
          ),
          GoRoute(
            path: '/spots',
            name: 'spots',
            builder: (context, state) => const SpotsScreen(),
          ),
          GoRoute(
            path: '/spots/map',
            name: 'spots-map',
            builder: (context, state) => const SpotsMapScreen(),
          ),
          GoRoute(
            path: '/spot/:slug',
            name: 'spot-detail',
            builder: (context, state) =>
                SpotDetailScreen(slug: state.pathParameters['slug']!),
          ),
          GoRoute(
            path: '/events',
            name: 'events',
            builder: (context, state) => const EventsScreen(),
          ),
          GoRoute(
            path: '/event/:eventId',
            name: 'event-detail',
            builder: (context, state) =>
                EventDetailScreen(eventId: state.pathParameters['eventId']!),
          ),
          GoRoute(
            path: '/shops',
            name: 'shops',
            builder: (context, state) => const ShopsScreen(),
          ),
          GoRoute(
            path: '/shop/:slug',
            name: 'shop-detail',
            builder: (context, state) =>
                ShopDetailScreen(slug: state.pathParameters['slug']!),
          ),
          GoRoute(
            path: '/shop/:slug/edit',
            name: 'shop-edit',
            redirect: (context, state) => requireAuth(state),
            builder: (context, state) =>
                ShopEditorScreen(slug: state.pathParameters['slug']!),
          ),
          GoRoute(
            path: '/shops/new',
            name: 'shop-create',
            redirect: (context, state) => requireShopManager(state),
            builder: (context, state) =>
                const ShopEditorScreen(slug: '__new__', isCreating: true),
          ),
          GoRoute(
            path: '/track/:slug',
            name: 'track-detail',
            builder: (context, state) => TrackDetailScreen(
              slug: state.pathParameters['slug']!,
              openArrivalOnLoad:
                  state.uri.queryParameters['intent'] == 'arrival',
            ),
          ),
          GoRoute(
            path: '/garage',
            name: 'garage',
            redirect: (context, state) => requireAuth(state),
            builder: (context, state) => const GarageScreen(),
          ),
          GoRoute(
            path: '/builds',
            name: 'public-builds',
            builder: (context, state) => const PublicBuildsScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            redirect: (context, state) => requireAuth(state),
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/activity',
            name: 'profile-activity',
            redirect: (context, state) => requireAuth(state),
            builder: (context, state) => const PitcoinHistoryScreen(),
          ),
          GoRoute(
            path: '/admin',
            name: 'admin',
            redirect: (context, state) => requireAdmin(state),
            builder: (context, state) => const AdminSettingsScreen(),
          ),
          GoRoute(
            path: '/onboarding',
            name: 'onboarding',
            redirect: (context, state) => requireAuth(state),
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/u/:publicSlug',
            name: 'public-profile',
            builder: (context, state) => PublicProfileScreen(
              publicSlug: state.pathParameters['publicSlug']!,
            ),
          ),
          GoRoute(
            path: '/profiles',
            name: 'public-profiles',
            builder: (context, state) => const PublicProfilesScreen(),
          ),
          GoRoute(
            path: '/legal/privacy',
            name: 'legal-privacy',
            builder: (context, state) =>
                const LegalDocumentScreen(type: LegalDocumentType.privacy),
          ),
          GoRoute(
            path: '/legal/terms',
            name: 'legal-terms',
            builder: (context, state) =>
                const LegalDocumentScreen(type: LegalDocumentType.terms),
          ),
          GoRoute(
            path: '/legal/cookies',
            name: 'legal-cookies',
            builder: (context, state) =>
                const LegalDocumentScreen(type: LegalDocumentType.cookies),
          ),
          GoRoute(
            path: '/manager',
            name: 'manager',
            redirect: (context, state) => requireTrackManager(state),
            builder: (context, state) => const ManagerScreen(),
          ),
          GoRoute(
            path: '/manager/tracks/new',
            name: 'track-create',
            redirect: (context, state) => requireTrackManager(state),
            builder: (context, state) => const TrackEditorScreen(),
          ),
          GoRoute(
            path: '/manager/tracks/draft/edit',
            name: 'draft-track-edit',
            redirect: (context, state) => requireTrackManager(state),
            builder: (context, state) => TrackEditorScreen(
              initialDraft: state.extra as SubmittedTrack?,
            ),
          ),
          GoRoute(
            path: '/manager/tracks/:slug/edit',
            name: 'track-edit',
            redirect: (context, state) => requireTrackManager(state),
            builder: (context, state) => ManagedTrackEditorScreen(
              slug: state.pathParameters['slug']!,
            ),
          ),
          GoRoute(
            path: '/submit-place',
            name: 'submit-place',
            redirect: (context, state) => requireAuth(state),
            builder: (context, state) => SubmitPlaceScreen(
              initialType: state.uri.queryParameters['type'] ?? 'track',
              initialSpotSlug: state.uri.queryParameters['spotSlug'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginScreen(
          redirectPath: state.uri.queryParameters['redirect'],
          authErrorCode: state.uri.queryParameters['authError'],
        ),
      ),
    ],
  );
});
