import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/locale_controller.dart';
import '../../features/auth/application/auth_providers.dart';
import '../l10n/generated/app_localizations.dart';
import '../navigation/app_router.dart';
import '../theme/app_theme.dart';

class PitLapBootstrap extends ConsumerWidget {
  const PitLapBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'PitLap',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      builder: (context, child) => _AuthRedirectHandler(
        router: router,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class _AuthRedirectHandler extends ConsumerStatefulWidget {
  const _AuthRedirectHandler({
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<_AuthRedirectHandler> createState() => _AuthRedirectHandlerState();
}

class _AuthRedirectHandlerState extends ConsumerState<_AuthRedirectHandler> {
  ProviderSubscription<AsyncValue<AuthState?>>? _authStateSubscription;
  String? _handledRedirect;
  bool _isHandlingCode = false;
  String? _appliedProfileLanguage;
  String? _handledAuthError;
  bool _persistingConsent = false;
  String? _handledConsentMarker;
  String? _handledRoleIntentMarker;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncLocaleWithProfile();
      await _handleAuthCallback();
    });

    _authStateSubscription = ref.listenManual(authStateProvider, (previous, next) {
      next.whenData((_) {
        _syncLocaleWithProfile();
        _applyRegistrationRoleIntentFromCallback();
        _persistConsentFromCallback();
        _handlePendingRedirect();
      });
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.close();
    super.dispose();
  }

  Future<void> _syncLocaleWithProfile() async {
    final repository = ref.read(authProfileRepositoryProvider);
    final user = ref.read(authClientProvider)?.auth.currentUser;
    if (repository == null || user == null) {
      debugPrint(
        '[AuthFlow] Skip locale sync: repository=${repository != null} user=${user?.id}',
      );
      return;
    }

    final preferredLanguage = await repository.fetchPreferredLanguage(user.id);
    debugPrint(
      '[AuthFlow] Fetched preferred language for ${user.id}: $preferredLanguage',
    );
    if (preferredLanguage == null || preferredLanguage.isEmpty) {
      return;
    }

    if (_appliedProfileLanguage == preferredLanguage) {
      return;
    }

    _appliedProfileLanguage = preferredLanguage;
    ref.read(localeProvider.notifier).setLocale(Locale(preferredLanguage));
  }

  Future<void> _handleAuthCallback() async {
    if (_isHandlingCode) {
      debugPrint('[AuthFlow] Callback already in progress, skipping.');
      return;
    }

    final callbackErrorCode = _authErrorCodeFromUri(Uri.base);
    final code = Uri.base.queryParameters['code'];
    final redirectPath = Uri.base.queryParameters['redirect'];
    final currentUser = ref.read(authClientProvider)?.auth.currentUser;
    debugPrint(
      '[AuthFlow] Handle callback uri=${Uri.base} codePresent=${code != null && code.isNotEmpty} redirect=$redirectPath error=$callbackErrorCode',
    );
    if (callbackErrorCode != null && callbackErrorCode.isNotEmpty) {
      _redirectToLoginWithError(
        redirectPath: redirectPath,
        errorCode: callbackErrorCode,
      );
      return;
    }

    if (code == null || code.isEmpty) {
      await _persistConsentFromCallback();
      await _applyRegistrationRoleIntentFromCallback();
      await _handlePendingRedirect();
      return;
    }

    if (currentUser != null) {
      debugPrint(
        '[AuthFlow] Session already present before code exchange. user=${currentUser.id}',
      );
      await _persistConsentFromCallback();
      await _applyRegistrationRoleIntentFromCallback();
      await _handlePendingRedirect();
      return;
    }

    final client = ref.read(authClientProvider);
    if (client == null) {
      debugPrint('[AuthFlow] No auth client available during callback.');
      return;
    }

    _isHandlingCode = true;
    var exchanged = false;
    try {
      debugPrint('[AuthFlow] Exchanging code for session...');
      await client.auth.exchangeCodeForSession(code);
      exchanged = true;
      await _persistConsentFromCallback();
      await _applyRegistrationRoleIntentFromCallback();
      debugPrint(
        '[AuthFlow] Code exchanged successfully. Current user=${client.auth.currentUser?.id}',
      );
    } catch (error) {
      debugPrint('[AuthFlow] Code exchange failed: $error');
      if (client.auth.currentUser != null) {
        debugPrint(
          '[AuthFlow] Session is available even after exchange failure. user=${client.auth.currentUser?.id}',
        );
        exchanged = true;
        await _persistConsentFromCallback();
        await _applyRegistrationRoleIntentFromCallback();
      }
      // Leave the user on the current page; the login screen can be retried.
    } finally {
      _isHandlingCode = false;
    }

    if (exchanged && redirectPath != null && redirectPath.isNotEmpty) {
      _handledRedirect = redirectPath;
      debugPrint('[AuthFlow] Navigating to redirect after exchange: $redirectPath');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        widget.router.go(redirectPath);
      });
      return;
    }

    await _handlePendingRedirect();
  }

  Future<void> _handlePendingRedirect() async {
    final user = ref.read(authClientProvider)?.auth.currentUser;
    final redirectPath = Uri.base.queryParameters['redirect'];
    final callbackErrorCode = _authErrorCodeFromUri(Uri.base);
    debugPrint(
      '[AuthFlow] Handle pending redirect user=${user?.id} redirect=$redirectPath handled=$_handledRedirect',
    );
    if (callbackErrorCode != null && callbackErrorCode.isNotEmpty) {
      return;
    }
    if (user == null || redirectPath == null || redirectPath.isEmpty) {
      return;
    }

    if (_handledRedirect == redirectPath) {
      return;
    }

    await _persistConsentFromCallback();
    await _applyRegistrationRoleIntentFromCallback();
    _handledRedirect = redirectPath;
    debugPrint('[AuthFlow] Navigating to pending redirect: $redirectPath');
    widget.router.go(redirectPath);
  }

  void _redirectToLoginWithError({
    required String? redirectPath,
    required String errorCode,
  }) {
    final target = redirectPath ?? '/';
    final marker = '$target|$errorCode';
    if (_handledAuthError == marker) {
      return;
    }

    _handledAuthError = marker;
    debugPrint(
      '[AuthFlow] Redirecting to login after auth error: error=$errorCode redirect=$target',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // Use replace() instead of go() to avoid go_router 17.1 internal match assertion
      // when transitioning from a URI with many query params (magic link) to /login.
      // This avoids the urlPathToCompare.startsWith assertion in go_router match.dart:256.
      widget.router.replace(
        '/login?redirect=${Uri.encodeComponent(target)}&authError=${Uri.encodeComponent(errorCode)}',
      );
    });
  }

  String? _authErrorCodeFromUri(Uri uri) {
    final queryError = uri.queryParameters['error_code'];
    if (queryError != null && queryError.isNotEmpty) {
      return queryError;
    }

    final fragment = uri.fragment;
    if (fragment.isEmpty) {
      return null;
    }

    final fragmentQuery = Uri.splitQueryString(fragment, encoding: utf8);
    final fragmentError = fragmentQuery['error_code'];
    if (fragmentError != null && fragmentError.isNotEmpty) {
      return fragmentError;
    }

    return null;
  }

  Future<void> _persistConsentFromCallback() async {
    if (_persistingConsent) {
      return;
    }

    final repository = ref.read(authProfileRepositoryProvider);
    final user = ref.read(authClientProvider)?.auth.currentUser;
    if (repository == null || user == null) {
      debugPrint('[ConsentFlow] Skip consent persistence: repository=${repository != null} user=${user?.id}');
      return;
    }

    final query = Uri.base.queryParameters;
    final termsAccepted = query['termsAccepted'] == '1';
    final privacySeen = query['privacySeen'] == '1';
    final marketingAccepted = query['marketingAccepted'] == '1';
    final version = query['legalVersion'] ?? legalDocumentVersion;
    final source = query['legalSource'] ?? 'web_magic_link';
    final marker = '${user.id}|$version|$source|$termsAccepted|$privacySeen|$marketingAccepted';

    if (!termsAccepted && !privacySeen && !query.containsKey('marketingAccepted')) {
      debugPrint('[ConsentFlow] No consent markers found in callback URL.');
      return;
    }

    if (_handledConsentMarker == marker) {
      debugPrint('[ConsentFlow] Consent marker already handled: $marker');
      return;
    }

    debugPrint(
      '[ConsentFlow] Persisting consents for user=${user.id} version=$version source=$source terms=$termsAccepted privacy=$privacySeen marketing=$marketingAccepted',
    );
    _persistingConsent = true;
    try {
      if (termsAccepted) {
        await repository.upsertUserConsent(
          userId: user.id,
          consentType: 'terms_accepted',
          accepted: true,
          documentVersion: version,
          source: source,
        );
      }

      if (privacySeen) {
        await repository.upsertUserConsent(
          userId: user.id,
          consentType: 'privacy_notice_seen',
          accepted: true,
          documentVersion: version,
          source: source,
        );
      }

      if (query.containsKey('marketingAccepted')) {
        await repository.upsertUserConsent(
          userId: user.id,
          consentType: 'marketing_email_opt_in',
          accepted: marketingAccepted,
          documentVersion: version,
          source: source,
        );
      }

      _handledConsentMarker = marker;
      debugPrint('[ConsentFlow] Consent persistence completed for user=${user.id}');
    } finally {
      _persistingConsent = false;
    }
  }

  Future<void> _applyRegistrationRoleIntentFromCallback() async {
    final repository = ref.read(authProfileRepositoryProvider);
    final user = ref.read(authClientProvider)?.auth.currentUser;
    final requestedRole = Uri.base.queryParameters['roleIntent'];

    if (repository == null || user == null) {
      debugPrint('[AuthFlow] Skip role intent application: repository=${repository != null} user=${user?.id}');
      return;
    }

    if (requestedRole == null || requestedRole.isEmpty) {
      return;
    }

    final marker = '${user.id}|$requestedRole';
    if (_handledRoleIntentMarker == marker) {
      return;
    }

    await repository.applyRegistrationRoleIntent(
      userId: user.id,
      selectedRole: requestedRole,
    );
    _handledRoleIntentMarker = marker;
    ref.invalidate(userProfileProvider);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
