import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/locale_controller.dart';
import '../../app/theme/app_colors.dart';
import '../../features/auth/application/auth_providers.dart';

/// Cambia lingua IT <-> EN e la salva sul profilo se l'utente e' loggato.
void toggleAppLanguage(BuildContext context, WidgetRef ref) {
  final locale = Localizations.localeOf(context);
  final nextLocale =
      locale.languageCode == 'it' ? const Locale('en') : const Locale('it');
  ref.read(localeProvider.notifier).setLocale(nextLocale);
  final repository = ref.read(authProfileRepositoryProvider);
  final user = ref.read(currentUserProvider);
  if (repository != null && user != null) {
    unawaited(
      repository.upsertPreferredLanguage(
        userId: user.id,
        languageCode: nextLocale.languageCode,
      ),
    );
  }
}

/// Pulsante IT/EN condiviso da tutte le intestazioni (Home compresa).
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    return Tooltip(
      message: locale.languageCode == 'it' ? 'Switch to English' : 'Passa a Italiano',
      child: OutlinedButton(
        onPressed: () => toggleAppLanguage(context, ref),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: AppColors.concrete.withAlpha(200)),
          foregroundColor: AppColors.graphite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 16),
            const SizedBox(width: 6),
            Text(
              locale.languageCode.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
