import 'package:flutter/material.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';

enum LegalDocumentType { privacy, terms, cookies }

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
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
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

class _LegalSection {
  const _LegalSection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}
