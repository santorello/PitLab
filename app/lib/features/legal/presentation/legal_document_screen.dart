import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../auth/application/auth_providers.dart';

enum LegalDocumentType { privacy, terms, cookies }

/// Pagine legali statiche pubbliche, generate da `docs/legal/*.md` con
/// `tools/build_legal_pages.py` e servite da Cloudflare Pages.
///
/// Sono HTML puro senza login: Google Play e l'App Store richiedono una URL
/// della privacy policy raggiungibile senza installare l'app, e il testo deve
/// restare leggibile anche se la web app Flutter non carica. Le schermate
/// in-app qui sotto restano una sintesi; il testo vincolante e' quello.
const String _legalBaseUrl = 'https://pitlap.app/legal';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    required this.type,
    super.key,
  });

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sections = _sectionsFor(context);

    return ContentScaffold(
      title: _titleFor(l10n),
      description: _descriptionFor(l10n),
      child: ListView.separated(
        itemCount: sections.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == sections.length) {
            return _FullTextFooter(type: type);
          }
          final section = sections[index];
          return Card(
            color: AppColors.panel,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.graphite,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    section.body,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppColors.steel),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _titleFor(AppLocalizations l10n) => switch (type) {
        LegalDocumentType.privacy => l10n.legalPrivacyTitle,
        LegalDocumentType.terms => l10n.legalTermsTitle,
        LegalDocumentType.cookies => l10n.legalCookiesTitle,
      };

  String _descriptionFor(AppLocalizations l10n) => switch (type) {
        LegalDocumentType.privacy => l10n.legalPrivacyDescription,
        LegalDocumentType.terms => l10n.legalTermsDescription,
        LegalDocumentType.cookies => l10n.legalCookiesDescription,
      };

  List<_LegalSection> _sectionsFor(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (type) {
      LegalDocumentType.privacy => [
          _LegalSection(
            title: l10n.legalPrivacySectionCollectedTitle,
            body: l10n.legalPrivacySectionCollectedBody,
          ),
          _LegalSection(
            title: l10n.legalPrivacySectionPurposeTitle,
            body: l10n.legalPrivacySectionPurposeBody,
          ),
          _LegalSection(
            title: l10n.legalPrivacySectionLegalBasisTitle,
            body: l10n.legalPrivacySectionLegalBasisBody,
          ),
          _LegalSection(
            title: l10n.legalPrivacySectionRightsTitle,
            body: l10n.legalPrivacySectionRightsBody,
          ),
          _LegalSection(
            title: l10n.legalPrivacySectionControllerTitle,
            body: l10n.legalPrivacySectionControllerBody,
          ),
          _LegalSection(
            title: l10n.legalPrivacySectionProcessorsTitle,
            body: l10n.legalPrivacySectionProcessorsBody,
          ),
          _LegalSection(
            title: l10n.legalPrivacySectionTransfersTitle,
            body: l10n.legalPrivacySectionTransfersBody,
          ),
          _LegalSection(
            title: l10n.legalPrivacySectionRetentionTitle,
            body: l10n.legalPrivacySectionRetentionBody,
          ),
          _LegalSection(
            title: l10n.legalPrivacySectionSecurityTitle,
            body: l10n.legalPrivacySectionSecurityBody,
          ),
          _LegalSection(
            title: l10n.legalPrivacySectionAgeTitle,
            body: l10n.legalPrivacySectionAgeBody,
          ),
        ],
      LegalDocumentType.terms => [
          _LegalSection(
            title: l10n.legalTermsSectionServiceTitle,
            body: l10n.legalTermsSectionServiceBody,
          ),
          _LegalSection(
            title: l10n.legalTermsSectionUseTitle,
            body: l10n.legalTermsSectionUseBody,
          ),
          _LegalSection(
            title: l10n.legalTermsSectionContentTitle,
            body: l10n.legalTermsSectionContentBody,
          ),
          _LegalSection(
            title: l10n.legalTermsSectionAvailabilityTitle,
            body: l10n.legalTermsSectionAvailabilityBody,
          ),
          _LegalSection(
            title: l10n.legalTermsSectionIPTitle,
            body: l10n.legalTermsSectionIPBody,
          ),
          _LegalSection(
            title: l10n.legalTermsSectionLiabilityTitle,
            body: l10n.legalTermsSectionLiabilityBody,
          ),
          _LegalSection(
            title: l10n.legalTermsSectionGoverningTitle,
            body: l10n.legalTermsSectionGoverningBody,
          ),
        ],
      LegalDocumentType.cookies => [
          _LegalSection(
            title: l10n.legalCookiesSectionWhatTitle,
            body: l10n.legalCookiesSectionWhatBody,
          ),
          _LegalSection(
            title: l10n.legalCookiesSectionTechnicalTitle,
            body: l10n.legalCookiesSectionTechnicalBody,
          ),
          _LegalSection(
            title: l10n.legalCookiesSectionAnalyticsTitle,
            body: l10n.legalCookiesSectionAnalyticsBody,
          ),
          _LegalSection(
            title: l10n.legalCookiesSectionMarketingTitle,
            body: l10n.legalCookiesSectionMarketingBody,
          ),
          _LegalSection(
            title: l10n.legalCookiesSectionStatusTitle,
            body: l10n.legalCookiesSectionStatusBody,
          ),
        ],
    };
  }
}

/// Rimanda al testo integrale pubblico e mostra la versione accettata,
/// la stessa registrata in `user_consents.document_version`.
class _FullTextFooter extends StatelessWidget {
  const _FullTextFooter({required this.type});

  final LegalDocumentType type;

  String get _fileName => switch (type) {
        LegalDocumentType.privacy => 'privacy-policy.html',
        LegalDocumentType.terms => 'termini-di-servizio.html',
        LegalDocumentType.cookies => 'cookie-policy.html',
      };

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse('$_legalBaseUrl/$_fileName');
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(content: Text(uri.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: AppColors.panel,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.legalFullTextHint,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.steel),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _open(context),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(l10n.legalFullTextAction),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.legalVersionLabel(legalDocumentVersion),
              style: textTheme.bodySmall?.copyWith(color: AppColors.steel),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}
