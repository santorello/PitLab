import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/pill.dart';
import '../../../shared/widgets/place_card.dart';
import '../../auth/application/auth_providers.dart';
import '../../pitcoin/providers/pitcoin_providers.dart';
import '../application/public_shops_provider.dart';
import '../application/shop_editor_providers.dart';
import '../application/shop_follows_providers.dart';

class ShopsScreen extends ConsumerStatefulWidget {
  const ShopsScreen({super.key});

  @override
  ConsumerState<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends ConsumerState<ShopsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canManageShops = ref.watch(canManageShopsProvider);
    final myDrafts = ref.watch(myEditableShopDraftsProvider);
    final shopsAsync = ref.watch(publicShopsProvider);

    final allShops = shopsAsync.maybeWhen(
      data: (list) => list
          .map(
            (s) => _ShopViewModel(
              id: s.id,
              slug: s.slug,
              name: s.name,
              subtitle: s.shortDescription,
              distance: s.city,
              specialties: s.serviceLabels,
              imageUrl: s.imageUrl,
              galleryImages: s.galleryImages,
            ),
          )
          .toList(),
      orElse: () => const <_ShopViewModel>[],
    );

    final shops = allShops.where((shop) {
      if (_query.isEmpty) return true;
      return [shop.name, shop.subtitle, ...shop.specialties]
          .join(' ')
          .toLowerCase()
          .contains(_query);
    }).toList();

    return ContentScaffold(
      title: l10n.shopsTitle,
      description: l10n.shopsDescription,
      child: ListView(
        children: [
          if (canManageShops) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF6EFE3), Colors.white, Color(0xFFF2F4F7)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Color(0xFFE5DDD0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.signalOrange.withAlpha(22),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.signalOrange.withAlpha(80)),
                    ),
                    child: const Text(
                      '🏪 Gestione negozio',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Crea una nuova scheda negozio, salvala in bozza o inviala in approvazione.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.steel,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.go('/shops/new'),
                        icon: const Icon(Icons.add_business_outlined),
                        label: const Text('Crea negozio'),
                      ),
                      if (myDrafts.any((draft) => draft.approvalStatus == 'pending'))
                        _ShopSignalChip(
                          label:
                              '${myDrafts.where((draft) => draft.approvalStatus == 'pending').length} in approvazione',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (myDrafts.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I tuoi negozi',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bozze, schede in approvazione e negozi gia\' preparati dal tuo account.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.steel,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...myDrafts.map(
                        (draft) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ManagedShopDraftCard(draft: draft),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _query = value.trim().toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: l10n.shopSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.clearSearchAction,
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (shopsAsync.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            ...shops.map(
              (shop) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ShopCard(
                  name: shop.name,
                  subtitle: shop.subtitle,
                  distance: shop.distance,
                  specialties: shop.specialties,
                  imageUrl: shop.imageUrl,
                  galleryImages: shop.galleryImages,
                  shopId: shop.id,
                  onToggleSaved: () {
                    final currentUser = ref.read(currentUserProvider);
                    if (currentUser == null) {
                      context.go(
                        '/login?redirect=${Uri.encodeComponent('/shops')}',
                      );
                      return;
                    }
                    ref.read(followedShopIdsProvider.notifier).toggle(shop.id);
                    // Delayed invalidation: wait for Supabase upsert/delete
                    // to commit before re-fetching the follower count.
                    Future<void>.delayed(const Duration(milliseconds: 1500), () {
                      if (!context.mounted) return;
                      ref.invalidate(shopFollowerCountProvider(shop.id));
                      // D13: aggiorna il saldo PitCoin dopo il follow negozio.
                      ref.invalidate(effectiveUserPitcoinBalanceProvider);
                      ref.invalidate(effectiveUserPitcoinRecentDeltaProvider);
                    });
                  },
                  onTap: () => context.go('/shop/${shop.slug}'),
                ),
              ),
            ),
            if (shops.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront_outlined, size: 48, color: AppColors.steel.withAlpha(130)),
                      const SizedBox(height: 16),
                      Text(
                        l10n.shopNoResults,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.steel),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ShopSignalChip extends StatelessWidget {
  const _ShopSignalChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ShopViewModel {
  const _ShopViewModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.subtitle,
    required this.distance,
    required this.specialties,
    required this.imageUrl,
    required this.galleryImages,
  });

  final String id;
  final String slug;
  final String name;
  final String subtitle;
  final String distance;
  final List<String> specialties;
  final String imageUrl;
  final List<String> galleryImages;
}

class _ManagedShopDraftCard extends StatelessWidget {
  const _ManagedShopDraftCard({required this.draft});

  final EditableShopRecord draft;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (draft.approvalStatus) {
      'pending' => 'In approvazione',
      'approved' => 'Approvato',
      'rejected' => 'Da rivedere',
      _ => 'Bozza negozio',
    };

    return Card(
      color: const Color(0xFFF8F7F3),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 860;
            final media = SizedBox(
              height: compact ? 160 : 180,
              width: compact ? double.infinity : 250,
              child: _ShopMedia(
                imageUrl: draft.imageUrl,
                galleryImages: draft.galleryImages,
              ),
            );
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      draft.name.isEmpty ? draft.slug : draft.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Pill(label: statusLabel, tone: PillTone.neutral),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (draft.city.trim().isNotEmpty) draft.city.trim(),
                    if (draft.address.trim().isNotEmpty) draft.address.trim(),
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.steel,
                  ),
                ),
                if (draft.subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    draft.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (draft.serviceLabels.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: draft.serviceLabels
                        .take(4)
                        .map((label) => Pill(label: label, tone: PillTone.neutral))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => context.go('/shop/${draft.slug}/edit'),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifica'),
                    ),
                    if (draft.approvalStatus == 'approved')
                      OutlinedButton.icon(
                        onPressed: () => context.go('/shop/${draft.slug}'),
                        icon: const Icon(Icons.open_in_new_outlined),
                        label: const Text('Apri scheda'),
                      ),
                  ],
                ),
              ],
            );

            return compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      media,
                      const SizedBox(height: 16),
                      content,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      media,
                      const SizedBox(width: 18),
                      Expanded(child: content),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.shopId,
    required this.name,
    required this.subtitle,
    required this.distance,
    required this.specialties,
    required this.imageUrl,
    required this.galleryImages,
    required this.onToggleSaved,
    required this.onTap,
  });

  final String shopId;
  final String name;
  final String subtitle;
  final String distance;
  final List<String> specialties;
  final String imageUrl;
  final List<String> galleryImages;
  final VoidCallback onToggleSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final l10n = AppLocalizations.of(context)!;
        final saved = ref.watch(isShopFollowedProvider(shopId));
        final countAsync = ref.watch(shopFollowerCountProvider(shopId));
        final count = countAsync.maybeWhen(
          data: (value) => value,
          orElse: () => 0,
        );

        // Build media
        final media = _ShopMedia(
          imageUrl: imageUrl,
          galleryImages: galleryImages,
        );

        // Build type badge
        final typeBadge = const Pill(
          label: 'Negozio',
          tone: PillTone.info,
        );

        // Build signals: specialties (max 3) + follower count
        final signals = <Widget>[];
        final visibleSpecialties =
            specialties.length > 3 ? specialties.take(3).toList() : specialties;
        for (final specialty in visibleSpecialties) {
          signals.add(
            Pill(label: specialty, tone: PillTone.neutral),
          );
        }
        if (specialties.length > 3) {
          signals.add(
            Pill(
              label: '+${specialties.length - 3}',
              tone: PillTone.neutral,
            ),
          );
        }
        // Aggiunta count pill
        signals.add(
          Pill(
            label: l10n.entitySavedCount(count),
            tone: PillTone.neutral,
            icon: Icons.groups_outlined,
          ),
        );

        // Build footer leading CTA
        final footerLeading = FilledButton(
          onPressed: onTap,
          child: Text(l10n.shopOpenDetailsAction),
        );

        // Build footer actions: favorite + distance display
        final footerActions = <Widget>[
          Tooltip(
            message: saved ? l10n.shopSavedAction : l10n.shopSaveAction,
            child: IconButton(
              onPressed: onToggleSaved,
              icon: Icon(
                saved ? Icons.favorite : Icons.favorite_border,
                color: saved ? AppColors.signalOrange : AppColors.steel,
              ),
            ),
          ),
        ];

        return PlaceCard(
          media: media,
          title: name,
          subtitle: distance,
          typeBadge: typeBadge,
          signals: signals.isNotEmpty ? signals : null,
          body: subtitle.isNotEmpty ? subtitle : null,
          footerLeading: footerLeading,
          footerActions: footerActions.isNotEmpty ? footerActions : null,
          onTap: onTap,
          variant: PlaceCardVariant.standard,
        );
      },
    );
  }
}

class _ShopMedia extends StatelessWidget {
  const _ShopMedia({
    required this.imageUrl,
    required this.galleryImages,
  });

  final String imageUrl;
  final List<String> galleryImages;

  @override
  Widget build(BuildContext context) {
    final sources = [
      if (imageUrl.trim().isNotEmpty) imageUrl.trim(),
      ...galleryImages.map((image) => image.trim()).where((image) => image.isNotEmpty),
    ];
    final cover = sources.isEmpty ? '' : sources.first;
    final imageCount = sources.length;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE7D8), Color(0xFFF3F5F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: cover.isEmpty
          ? Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  right: -12,
                  top: -12,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(90),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(170),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text('Shop'),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.storefront_outlined,
                        color: AppColors.graphite.withAlpha(170),
                        size: 34,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                AdaptiveImage(
                  source: cover,
                  fit: BoxFit.cover,
                  fallback: ColoredBox(color: AppColors.surfaceMuted),
                ),
                if (imageCount > 1)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(150),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$imageCount',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
