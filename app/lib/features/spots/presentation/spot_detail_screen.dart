import 'package:flutter/material.dart';
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
import '../../auth/application/auth_providers.dart';
import '../../comments/presentation/comments_section.dart';
import '../application/spots_providers.dart';
import '../domain/spot_catalog.dart';

class SpotDetailScreen extends ConsumerWidget {
  const SpotDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final spots = ref.watch(spotEntriesProvider);
    final spot = SpotCatalog.bySlug(slug, spots);
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final impersonation = ref.watch(impersonationProvider);
    final effectiveUserId = impersonation?.userId ?? currentUser?.id;

    if (spot == null) {
      return ContentScaffold(
        title: l10n.spotsTitle,
        description: l10n.spotsDescription,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _localeText(
                context,
                it: 'Spot non trovato.',
                en: 'Spot not found.',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    final canEditSpot =
        (isAdmin && impersonation == null) ||
        (effectiveUserId != null &&
            spot.isCustom &&
            spot.isOwnedByCurrentUser);

    return ContentScaffold(
      title: spot.title,
      description: l10n.spotsDescription,
      child: ListView(
        children: [
          Card(
            color: AppColors.graphite,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (spot.imageUrls.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      child: SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: AdaptiveImage(
                          source: spot.imageUrls.first,
                          fit: BoxFit.cover,
                          fallback: const ColoredBox(color: AppColors.graphite),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      spot.category,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    spot.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    [
                      spot.city,
                      if ((spot.address ?? '').trim().isNotEmpty)
                        spot.address!.trim(),
                    ].join(' · '),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.concrete,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _DetailChip(
                        icon: Icons.sports_motorsports_outlined,
                        label: '${l10n.spotsBestForLabel}: ${spot.bestFor}',
                      ),
                      _DetailChip(
                        icon: Icons.terrain_outlined,
                        label: '${l10n.spotsSurfaceLabel}: ${spot.surface}',
                      ),
                      _DetailChip(
                        icon: Icons.photo_library_outlined,
                        label: l10n.spotsPhotosCount(spot.photoCount),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => canEditSpot
                            ? context.go(
                                '/submit-place?type=spot&spotSlug=${Uri.encodeComponent(spot.slug)}',
                              )
                            : context.go('/submit-place?type=spot'),
                        icon: Icon(
                          canEditSpot
                              ? Icons.edit_outlined
                              : Icons.flag_outlined,
                        ),
                        label: Text(
                          canEditSpot
                              ? _localeText(
                                  context,
                                  it: 'Modifica spot',
                                  en: 'Edit spot',
                                )
                              : l10n.spotsSuggestEditAction,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openSpotMap(spot),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        icon: const Icon(Icons.map_outlined),
                        label: Text(l10n.openMapButton),
                      ),
                      if (spot.id != null)
                        OutlinedButton.icon(
                          onPressed: () => shareEntity(
                            context: context,
                            entityType: 'spot',
                            entityId: spot.slug,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          icon: const Icon(Icons.ios_share_outlined),
                          label: Text(l10n.shareAction),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (spot.imageUrls.isNotEmpty || spot.photoCount > 0) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localeText(
                        context,
                        it: 'Preview visuale',
                        en: 'Visual preview',
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      spot.imageUrls.isEmpty
                          ? _localeText(
                              context,
                              it:
                                  'Le immagini reali non sono ancora caricate, ma lo spot ha già un archivio foto dichiarato.',
                              en:
                                  'Real images are not uploaded yet, but this spot already has a declared photo archive.',
                            )
                          : _localeText(
                              context,
                              it: 'Foto condivise dalla community per capire fondo, spazio e accessi.',
                              en: 'Community photos to understand terrain, space, and access.',
                            ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: spot.imageUrls.isEmpty
                            ? spot.photoCount.clamp(1, 5).toInt()
                            : spot.imageUrls.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          if (spot.imageUrls.isEmpty) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              child: Container(
                                width: 128,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      spot.imageAccent.withValues(alpha: 0.32),
                                      const Color(0xFFF2F4F7),
                                    ],
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Text(
                                    _localeText(
                                      context,
                                      it: 'Archivio in arrivo',
                                      en: 'Archive coming',
                                    ),
                                    style: Theme.of(context).textTheme.labelLarge,
                                  ),
                                ),
                              ),
                            );
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: InkWell(
                              onTap: () =>
                                  _openSpotGallery(context, spot.imageUrls, index),
                              child: SizedBox(
                                width: 128,
                                child: AdaptiveImage(
                                  source: spot.imageUrls[index],
                                  fit: BoxFit.cover,
                                  fallback: const ColoredBox(
                                    color: Color(0xFFEDEFF3),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          if ((spot.videoUrl ?? '').trim().isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localeText(
                        context,
                        it: 'Video spot',
                        en: 'Spot video',
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _localeText(
                        context,
                        it: 'Apri il link condiviso per vedere il punto e il tipo di terreno.',
                        en: 'Open the shared link to see the area and terrain.',
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.tonalIcon(
                      onPressed: () => _openSpotVideo(spot.videoUrl!),
                      icon: const Icon(Icons.ondemand_video_outlined),
                      label: Text(
                        _localeText(
                          context,
                          it: 'Apri video',
                          en: 'Open video',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _localeText(
                      context,
                      it: 'Panoramica spot',
                      en: 'Spot overview',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    spot.note,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppColors.steel),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _DetailChip(
                        icon: Icons.groups_outlined,
                        label: _localeText(
                          context,
                          it: 'Usa lo spot con buon senso',
                          en: 'Use the spot responsibly',
                        ),
                      ),
                      _DetailChip(
                        icon: Icons.map_outlined,
                        label: _localeText(
                          context,
                          it: 'Apri mappa o link video quando disponibile',
                          en: 'Open map or video link when available',
                        ),
                      ),
                      if ((spot.videoUrl ?? '').trim().isNotEmpty)
                        _DetailChip(
                          icon: Icons.ondemand_video_outlined,
                          label: _localeText(
                            context,
                            it: 'Video disponibile',
                            en: 'Video available',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Commenti: solo per spot già persistiti su Supabase (id UUID).
          if (spot.id != null) ...[
            const SizedBox(height: AppSpacing.xl),
            CommentsSection(
              entityType: 'spot',
              entityId: spot.id!,
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _openSpotMap(SpotEntry spot) async {
  final query = spot.latitude != null && spot.longitude != null
      ? '${spot.latitude},${spot.longitude}'
      : Uri.encodeComponent(
          [
            spot.title,
            if ((spot.address ?? '').trim().isNotEmpty) spot.address!.trim(),
            spot.city,
          ].join(' '),
        );
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$query',
  );
  await launchUrl(uri, mode: LaunchMode.platformDefault);
}

Future<void> _openSpotVideo(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    return;
  }
  await launchUrl(uri, mode: LaunchMode.platformDefault);
}

Future<void> _openSpotGallery(
  BuildContext context,
  List<String> images,
  int initialIndex,
) async {
  final controller = PageController(initialPage: initialIndex);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: images.length,
            itemBuilder: (context, index) => InteractiveViewer(
              child: Center(
                child: AdaptiveImage(
                  source: images[index],
                  fit: BoxFit.contain,
                  fallback: const ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: IconButton.filledTonal(
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F3),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.concrete),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.steel),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
        ],
      ),
    );
  }
}

String _localeText(
  BuildContext context, {
  required String it,
  required String en,
}) {
  return Localizations.localeOf(context).languageCode == 'it' ? it : en;
}
