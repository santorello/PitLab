import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/utils/share_entity.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/external_links_section.dart';
import '../../comments/presentation/comments_section.dart';
import '../application/public_shops_provider.dart';
import '../application/shop_follows_providers.dart';
import '../application/shop_permissions_providers.dart';
import '../../auth/application/auth_providers.dart';

class ShopDetailScreen extends ConsumerWidget {
  const ShopDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final shopAsync = ref.watch(publicShopDetailProvider(slug));

    return shopAsync.when(
      loading: () => ContentScaffold(
        title: l10n.shopDetailTitle,
        description: '',
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ContentScaffold(
        title: l10n.shopDetailTitle,
        description: '',
        child: Center(child: Text('$e')),
      ),
      data: (shop) {
        if (shop == null) {
          return ContentScaffold(
            title: l10n.shopDetailTitle,
            description: '',
            child: _EmptyShopState(l10n: l10n),
          );
        }
        return ContentScaffold(
          title: shop.name,
          description: shop.subtitle.isNotEmpty
              ? shop.subtitle
              : shop.shortDescription,
          child: _ShopDetailBody(shop: shop, slug: slug),
        );
      },
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _ShopDetailBody extends ConsumerWidget {
  const _ShopDetailBody({required this.shop, required this.slug});

  final PublicShop shop;
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final canEdit = ref.watch(canEditShopSlugProvider(slug)).maybeWhen(
      data: (v) => v,
      orElse: () => false,
    );
    final isSaved = ref.watch(isShopFollowedProvider(shop.id));
    final followerCount = ref.watch(shopFollowerCountProvider(shop.id))
        .maybeWhen(data: (v) => v, orElse: () => 0);
    final currentUser = ref.watch(currentUserProvider);

    return ListView(
      children: [
        // ── Hero ─────────────────────────────────────────────────────
        _ShopHero(
          shop: shop,
          isSaved: isSaved,
          followerCount: followerCount,
          canEdit: canEdit,
          currentUser: currentUser,
          slug: slug,
          l10n: l10n,
          ref: ref,
        ),

        const SizedBox(height: 16),

        // ── Servizi / specialità ──────────────────────────────────────
        if (shop.serviceLabels.isNotEmpty) ...[
          _DetailSection(
            title: l10n.shopSpecialtiesTitle,
            icon: Icons.build_circle_outlined,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: shop.serviceLabels
                  .map((s) => _ServiceChip(label: s))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Orari ────────────────────────────────────────────────────
        if (shop.hours.trim().isNotEmpty) ...[
          _DetailSection(
            title: l10n.shopHoursTitle,
            icon: Icons.access_time_outlined,
            child: _HoursDisplay(hours: shop.hours),
          ),
          const SizedBox(height: 16),
        ],

        // ── Contatti e posizione ──────────────────────────────────────
        if (shop.phone.isNotEmpty ||
            shop.website.isNotEmpty ||
            shop.address.isNotEmpty ||
            shop.contacts.isNotEmpty) ...[
          _ContactsSection(shop: shop, l10n: l10n),
          const SizedBox(height: 16),
        ],

        // ── Note ─────────────────────────────────────────────────────
        if (shop.notes.trim().isNotEmpty) ...[
          _DetailSection(
            title: 'Note dal negozio',
            icon: Icons.info_outline,
            child: Text(
              shop.notes,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppColors.steel, height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Galleria ─────────────────────────────────────────────────
        if (shop.galleryImages.isNotEmpty) ...[
          _GallerySection(images: shop.galleryImages, l10n: l10n),
          const SizedBox(height: 16),
        ],

        // ── Link esterni ──────────────────────────────────────────────
        ExternalLinksSection(
          entityType: 'shop',
          entityId: slug,
          title: l10n.externalLinksTitle,
          body: l10n.externalLinksShopBody,
          editable: canEdit,
        ),

        const SizedBox(height: 16),

        // Sezione commenti (shop.id è UUID dal DB).
        CommentsSection(
          entityType: 'shop',
          entityId: shop.id,
        ),

        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

// ── Hero section ──────────────────────────────────────────────────────────────

class _ShopHero extends StatelessWidget {
  const _ShopHero({
    required this.shop,
    required this.isSaved,
    required this.followerCount,
    required this.canEdit,
    required this.currentUser,
    required this.slug,
    required this.l10n,
    required this.ref,
  });

  final PublicShop shop;
  final bool isSaved;
  final int followerCount;
  final bool canEdit;
  final dynamic currentUser;
  final String slug;
  final AppLocalizations l10n;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final gallerySources = shop.galleryImages
        .map((image) => image.trim())
        .where((image) => image.isNotEmpty)
        .toList();
    final heroImage = shop.imageUrl.trim().isNotEmpty
        ? shop.imageUrl.trim()
        : gallerySources.isEmpty
            ? null
            : gallerySources.first;
    final hasImage = heroImage != null && heroImage.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cover image
          if (hasImage)
            SizedBox(
              height: 240,
              width: double.infinity,
              child: AdaptiveImage(
                source: heroImage,
                fit: BoxFit.cover,
                fallback: _FallbackCover(),
              ),
            )
          else
            _FallbackCover(),

          // Contenuto header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge tipo + azioni
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TypeBadge(label: '🏪 Negozio RC'),
                          if (shop.city.isNotEmpty)
                            _LocationBadge(city: shop.city),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Follow + Edit buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.outlined(
                          onPressed: () {
                            if (currentUser == null) {
                              context.go(
                                '/login?redirect=${Uri.encodeComponent('/shop/$slug')}',
                              );
                              return;
                            }
                            ref
                                .read(followedShopIdsProvider.notifier)
                                .toggle(shop.id);
                            // Delayed invalidation: wait for Supabase
                            // upsert/delete to commit before re-fetching.
                            Future<void>.delayed(
                              const Duration(milliseconds: 1500),
                              () => ref.invalidate(shopFollowerCountProvider(shop.id)),
                            );
                          },
                          icon: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved
                                ? AppColors.signalOrange
                                : AppColors.steel,
                          ),
                          tooltip: isSaved
                              ? l10n.shopSavedAction
                              : l10n.shopSaveAction,
                        ),
                        const SizedBox(width: 4),
                        IconButton.outlined(
                          onPressed: () => shareEntity(
                            context: context,
                            entityType: 'shop',
                            entityId: slug,
                          ),
                          icon: const Icon(Icons.ios_share_outlined),
                          tooltip: l10n.shareAction,
                        ),
                        if (canEdit) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () =>
                                context.go('/shop/$slug/edit'),
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 16,
                            ),
                            label: Text(l10n.shopEditAction),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Nome negozio
                Text(
                  shop.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                // Organizzazione / sottotitolo
                if (shop.organizationName.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    shop.organizationName,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.steel),
                  ),
                ],

                // Descrizione
                if (shop.shortDescription.trim().isNotEmpty ||
                    shop.subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    shop.subtitle.isNotEmpty
                        ? shop.subtitle
                        : shop.shortDescription,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: AppColors.steel, height: 1.5),
                  ),
                ],

                // Meta row: follower
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 15,
                      color: AppColors.steel,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$followerCount ${followerCount == 1 ? 'persona salva' : 'persone salvano'} questo negozio',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.steel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sezione contatti ──────────────────────────────────────────────────────────

class _ContactsSection extends StatelessWidget {
  const _ContactsSection({required this.shop, required this.l10n});

  final PublicShop shop;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Costruisce la lista contatti unificata:
    // prima i campi strutturati (phone, website, address),
    // poi il testo libero dal campo contacts
    final structuredContacts = <_ContactEntry>[];

    if (shop.phone.trim().isNotEmpty) {
      structuredContacts.add(
        _ContactEntry(
          icon: Icons.phone_outlined,
          label: shop.phone.trim(),
          onTap: () => launchUrl(Uri.parse('tel:${shop.phone.trim()}')),
          copyValue: shop.phone.trim(),
        ),
      );
    }
    if (shop.website.trim().isNotEmpty) {
      final url = shop.website.trim();
      structuredContacts.add(
        _ContactEntry(
          icon: Icons.language_outlined,
          label: url.replaceFirst(RegExp(r'^https?://'), ''),
          onTap: () => launchUrl(
            Uri.parse(url.startsWith('http') ? url : 'https://$url'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      );
    }
    if (shop.address.trim().isNotEmpty) {
      structuredContacts.add(
        _ContactEntry(
          icon: Icons.place_outlined,
          label: shop.address.trim(),
          onTap: () => launchUrl(
            Uri.parse(
              'https://maps.google.com/?q=${Uri.encodeComponent(shop.address.trim())}',
            ),
            mode: LaunchMode.externalApplication,
          ),
        ),
      );
    }

    // Extra contatti da testo libero
    final extraLines = shop.contacts
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return _DetailSection(
      title: l10n.shopContactsTitle,
      icon: Icons.contacts_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...structuredContacts.map((entry) => _ContactRow(entry: entry)),
          ...extraLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.steel),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // CTA rapide
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (shop.phone.trim().isNotEmpty)
                FilledButton.tonalIcon(
                  onPressed: () =>
                      launchUrl(Uri.parse('tel:${shop.phone.trim()}')),
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: Text(l10n.shopCallButton),
                ),
              if (shop.address.trim().isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(
                      'https://maps.google.com/?q=${Uri.encodeComponent(shop.address.trim())}',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(l10n.shopDirectionsButton),
                ),
              if (shop.website.trim().isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    final url = shop.website.trim();
                    launchUrl(
                      Uri.parse(
                        url.startsWith('http') ? url : 'https://$url',
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  icon: const Icon(Icons.open_in_new_outlined, size: 18),
                  label: const Text('Sito web'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactEntry {
  const _ContactEntry({
    required this.icon,
    required this.label,
    required this.onTap,
    this.copyValue,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? copyValue;
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.entry});

  final _ContactEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(entry.icon, size: 18, color: AppColors.steel),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: entry.onTap,
              child: Text(
                entry.label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.signalOrange,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.signalOrange.withAlpha(100),
                ),
              ),
            ),
          ),
          if (entry.copyValue != null)
            IconButton(
              icon: const Icon(Icons.copy_outlined, size: 16),
              color: AppColors.steel,
              tooltip: 'Copia',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: entry.copyValue!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copiato negli appunti'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Orari ─────────────────────────────────────────────────────────────────────

class _HoursDisplay extends StatelessWidget {
  const _HoursDisplay({required this.hours});

  final String hours;

  @override
  Widget build(BuildContext context) {
    final lines = hours
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        // Prova a separare giorni / orario se c'è " - "
        final parts = line.split(' - ');
        if (parts.length >= 2) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    parts.first.trim(),
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(
                    parts.sublist(1).join(' - ').trim(),
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.steel),
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.steel),
          ),
        );
      }).toList(),
    );
  }
}

// ── Galleria ──────────────────────────────────────────────────────────────────

class _GallerySection extends StatelessWidget {
  const _GallerySection({required this.images, required this.l10n});

  final List<String> images;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: l10n.galleryButton,
      icon: Icons.photo_library_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
          final itemSize =
              (constraints.maxWidth - (crossAxisCount - 1) * 10) /
              crossAxisCount;

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: images.take(8).map((url) {
              return GestureDetector(
                onTap: () => _openFullscreen(context, url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: SizedBox(
                    width: itemSize,
                    height: itemSize,
                    child: AdaptiveImage(
                      source: url,
                      fit: BoxFit.cover,
                      fallback: Container(
                        color: const Color(0xFFEDEFF3),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xFFBBBBBB),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _openFullscreen(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: AdaptiveImage(
                  source: url,
                  fit: BoxFit.contain,
                  fallback: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white38,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Componenti di layout ──────────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.graphite),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.signalOrange.withAlpha(14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.signalOrange.withAlpha(60)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.graphite,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.signalOrange.withAlpha(22),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.signalOrange.withAlpha(80)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.graphite,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LocationBadge extends StatelessWidget {
  const _LocationBadge({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceCool,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.place_outlined, size: 14, color: AppColors.steel),
          const SizedBox(width: 4),
          Text(city, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _FallbackCover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE7D8), Color(0xFFF3F5F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.storefront_outlined,
          size: 56,
          color: AppColors.graphite.withAlpha(100),
        ),
      ),
    );
  }
}

class _EmptyShopState extends StatelessWidget {
  const _EmptyShopState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 72,
            color: AppColors.steel.withAlpha(100),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.shopNoResults,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: AppColors.steel),
          ),
          const SizedBox(height: 8),
          Text(
            'Il negozio cercato non è disponibile o non è ancora stato pubblicato.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.steel),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
