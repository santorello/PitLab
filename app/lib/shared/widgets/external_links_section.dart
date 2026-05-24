import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/app_colors.dart';
import '../application/external_links_providers.dart';

class ExternalLinksSection extends ConsumerWidget {
  const ExternalLinksSection({
    required this.entityType,
    required this.entityId,
    required this.title,
    required this.body,
    required this.editable,
    super.key,
  });

  final String entityType;
  final String entityId;
  final String title;
  final String body;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entityKey = externalLinksEntityKey(
      entityType: entityType,
      entityId: entityId,
    );
    final links = ref.watch(externalLinksForEntityProvider(entityKey));
    final publicLinks = links.where((link) => link.isPublic).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (editable)
                  OutlinedButton.icon(
                    onPressed: () =>
                        _openAddLinkDialog(context, ref, entityKey),
                    icon: const Icon(Icons.add_link_outlined),
                    label: Text(l10n.externalLinksAddAction),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
            ),
            const SizedBox(height: 16),
            if (publicLinks.isEmpty)
              Text(
                l10n.externalLinksEmpty,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: publicLinks
                    .map(
                      (link) => InputChip(
                        avatar: Icon(_providerIcon(link.provider), size: 18),
                        label: Text(
                          link.label.isEmpty
                              ? _providerLabel(l10n, link.provider)
                              : link.label,
                        ),
                        onPressed: () => _openLink(link.url),
                        onDeleted: editable
                            ? () {
                                ref
                                    .read(externalLinksProvider.notifier)
                                    .remove(
                                      entityKey: entityKey,
                                      linkId: link.id,
                                    );
                              }
                            : null,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddLinkDialog(
    BuildContext context,
    WidgetRef ref,
    String entityKey,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final labelController = TextEditingController();
    final urlController = TextEditingController();
    var provider = 'instagram';
    var isPublic = true;
    String? urlError;

    final link = await showDialog<ExternalLinkRecord>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.externalLinksAddTitle),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: provider,
                      decoration: InputDecoration(
                        labelText: l10n.externalLinksProviderLabel,
                      ),
                      items: externalLinkProviders
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(_providerLabel(l10n, value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          provider = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: labelController,
                      decoration: InputDecoration(
                        labelText: l10n.externalLinksLabelField,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urlController,
                      onChanged: (_) {
                        if (urlError == null) {
                          return;
                        }
                        setDialogState(() {
                          urlError = null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: l10n.externalLinksUrlField,
                        hintText: 'instagram.com/pitlap',
                        helperText: l10n.externalLinksUrlHint,
                        errorText: urlError,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: isPublic,
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.externalLinksPublicToggle),
                      onChanged: (value) {
                        setDialogState(() {
                          isPublic = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    final url = _normalizeUrl(urlController.text);
                    if (!_isValidExternalUrl(url)) {
                      setDialogState(() {
                        urlError = l10n.externalLinksInvalidUrlError;
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(
                      ExternalLinkRecord(
                        id: 'link-${DateTime.now().microsecondsSinceEpoch}',
                        provider: provider,
                        label: labelController.text.trim().isEmpty
                            ? _providerLabel(l10n, provider)
                            : labelController.text.trim(),
                        url: url,
                        isPublic: isPublic,
                      ),
                    );
                  },
                  child: Text(l10n.externalLinksSaveAction),
                ),
              ],
            );
          },
        );
      },
    );

    labelController.dispose();
    urlController.dispose();

    if (link == null) {
      return;
    }
    ref
        .read(externalLinksProvider.notifier)
        .add(entityKey: entityKey, link: link);
  }

  static String _normalizeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  static bool _isValidExternalUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.trim().isNotEmpty;
  }

  static Future<void> _openLink(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _providerLabel(AppLocalizations l10n, String provider) {
    return switch (provider) {
      'instagram' => l10n.externalLinkProviderInstagram,
      'facebook' => l10n.externalLinkProviderFacebook,
      'youtube' => l10n.externalLinkProviderYoutube,
      'tiktok' => l10n.externalLinkProviderTiktok,
      'whatsapp' => l10n.externalLinkProviderWhatsapp,
      'telegram' => l10n.externalLinkProviderTelegram,
      _ => l10n.externalLinkProviderWebsite,
    };
  }

  static IconData _providerIcon(String provider) {
    return switch (provider) {
      'youtube' => Icons.ondemand_video_outlined,
      'whatsapp' => Icons.chat_outlined,
      'telegram' => Icons.send_outlined,
      'website' => Icons.language_outlined,
      _ => Icons.alternate_email_outlined,
    };
  }
}
