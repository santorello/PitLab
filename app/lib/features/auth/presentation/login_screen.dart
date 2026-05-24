import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../application/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.redirectPath,
    this.authErrorCode,
  });

  final String? redirectPath;
  final String? authErrorCode;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  bool _submitting = false;
  bool _acceptedTerms = false;
  bool _acceptedPrivacyNotice = false;
  bool _acceptedMarketing = false;
  String _selectedAccountType = 'user';
  ProviderSubscription<User?>? _currentUserSubscription;
  bool _redirectScheduled = false;

  @override
  void initState() {
    super.initState();
    _currentUserSubscription = ref.listenManual(currentUserProvider, (previous, next) {
      if (next == null || _redirectScheduled) {
        return;
      }
      _redirectScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        context.go(widget.redirectPath ?? '/');
      });
    });
  }

  @override
  void dispose() {
    _currentUserSubscription?.close();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Brand header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF6EFE3), Colors.white],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      border: Border.all(color: Color(0xFFE5DDD0)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            children: const [
                              TextSpan(text: 'Pit', style: TextStyle(color: Color(0xFF1A1A1A))),
                              TextSpan(text: 'Lap 🏁', style: TextStyle(color: Color(0xFFFF6B35))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.appTagline,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    margin: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                    ),
                    child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.loginTitle, style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 12),
                      Text(
                        l10n.loginBody,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.loginExistingAccountHint,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
                        ),
                      ),
                      if ((widget.authErrorCode ?? '').isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2F0),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF5C2B8)),
                          ),
                          child: Text(
                            _authErrorMessage(l10n, widget.authErrorCode!),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(labelText: '✉️ ${l10n.emailLabel}'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '👤 ${l10n.loginAccountTypeTitle}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.loginAccountTypeBody,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _AccountTypeChip(
                            label: l10n.loginAccountTypeUser,
                            selected: _selectedAccountType == 'user',
                            onTap: _submitting
                                ? null
                                : () {
                                    setState(() {
                                      _selectedAccountType = 'user';
                                    });
                                  },
                          ),
                          _AccountTypeChip(
                            label: l10n.loginAccountTypeShopOwner,
                            selected: _selectedAccountType == 'shop_owner',
                            onTap: _submitting
                                ? null
                                : () {
                                    setState(() {
                                      _selectedAccountType = 'shop_owner';
                                    });
                                  },
                          ),
                          _AccountTypeChip(
                            label: l10n.loginAccountTypeTrackOrganizer,
                            selected: _selectedAccountType == 'track_organizer',
                            onTap: _submitting
                                ? null
                                : () {
                                    setState(() {
                                      _selectedAccountType = 'track_organizer';
                                    });
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        value: _acceptedTerms,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: _submitting
                            ? null
                            : (value) {
                                setState(() {
                                  _acceptedTerms = value ?? false;
                                });
                              },
                        title: Text(l10n.loginTermsConsentLabel),
                        subtitle: Text(l10n.loginTermsConsentHint),
                      ),
                      CheckboxListTile(
                        value: _acceptedPrivacyNotice,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: _submitting
                            ? null
                            : (value) {
                                setState(() {
                                  _acceptedPrivacyNotice = value ?? false;
                                });
                              },
                        title: Text(l10n.loginPrivacyNoticeLabel),
                        subtitle: Text(l10n.loginPrivacyNoticeHint),
                      ),
                      CheckboxListTile(
                        value: _acceptedMarketing,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: _submitting
                            ? null
                            : (value) {
                                setState(() {
                                  _acceptedMarketing = value ?? false;
                                });
                              },
                        title: Text(l10n.loginMarketingConsentLabel),
                        subtitle: Text(l10n.loginMarketingConsentHint),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.loginLegalDocsHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TextButton(
                            onPressed: () => context.push('/legal/terms'),
                            child: Text(l10n.legalTermsTitle),
                          ),
                          TextButton(
                            onPressed: () => context.push('/legal/privacy'),
                            child: Text(l10n.legalPrivacyTitle),
                          ),
                          TextButton(
                            onPressed: () => context.push('/legal/cookies'),
                            child: Text(l10n.legalCookiesTitle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _sendMagicLink,
                          child: Text(
                            _submitting ? l10n.loginSending : l10n.loginSendLink,
                          ),
                        ),
                      ),
                      if ((widget.redirectPath ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.loginRedirectHint(widget.redirectPath!),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }

  Future<void> _sendMagicLink() async {
    final client = ref.read(authClientProvider);
    final email = _emailController.text.trim();
    if (client == null || email.isEmpty) {
      return;
    }

    if (!_acceptedTerms || !_acceptedPrivacyNotice) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loginRequiredConsentsError),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final redirectPath = widget.redirectPath ?? '/';
      final emailRedirectTo = kIsWeb
          ? Uri(
              scheme: Uri.base.scheme,
              host: Uri.base.host,
              port: Uri.base.hasPort ? Uri.base.port : null,
              path: '/',
              queryParameters: {
                'redirect': redirectPath,
                'termsAccepted': _acceptedTerms ? '1' : '0',
                'privacySeen': _acceptedPrivacyNotice ? '1' : '0',
                'marketingAccepted': _acceptedMarketing ? '1' : '0',
                'roleIntent': _selectedAccountType,
                'legalVersion': legalDocumentVersion,
                'legalSource': 'web_magic_link',
              },
            ).toString()
          : null;

      await client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: emailRedirectTo,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.magicLinkSent),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  String _authErrorMessage(AppLocalizations l10n, String errorCode) {
    switch (errorCode) {
      case 'otp_expired':
        return l10n.loginExpiredLinkError;
      default:
        return l10n.loginGenericAuthError;
    }
  }
}

class _AccountTypeChip extends StatelessWidget {
  const _AccountTypeChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onTap == null ? null : (_) => onTap!(),
    );
  }
}
