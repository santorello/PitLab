import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/card_stat_row.dart';
import '../../../shared/widgets/place_card.dart';
import '../../shops/application/public_shops_provider.dart';
import '../../tracks/application/tracks_providers.dart';

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _type = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tracksAsync = ref.watch(publicTracksProvider);
    final shopsAsync = ref.watch(publicShopsProvider);
    final items = [
      ...tracksAsync.maybeWhen(
        data: (tracks) => tracks
            .map(
              (track) => _NearbyItem(
                title: track.name,
                subtitle: track.city,
                badge: '🏁 ${l10n.nearbyFilterTracks}',
                note: track.statusMessage.isNotEmpty
                    ? track.statusMessage
                    : track.shortDescription,
                type: 'track',
                route: '/track/${track.slug}',
                distance: '',
                imageUrl: '',
                primaryMeta: _statusLabel(context, track.status),
                secondaryMeta: track.availableServiceCount <= 0
                    ? l10n.nearbyNoServices
                    : l10n.nearbyServicesCount(track.availableServiceCount),
                actionLabel: l10n.nearbyOpenTrack,
                mapQuery: '${track.name} ${track.city}',
              ),
            )
            .toList(),
        orElse: () => const <_NearbyItem>[],
      ),
      ...shopsAsync.maybeWhen(
        data: (shops) => shops
            .map(
              (shop) => _NearbyItem(
                title: shop.name,
                subtitle: shop.city,
                badge: '🏪 ${l10n.nearbyFilterShops}',
                note: shop.shortDescription.isNotEmpty
                    ? shop.shortDescription
                    : shop.subtitle,
                type: 'shop',
                route: '/shop/${shop.slug}',
                distance: '',
                imageUrl: shop.imageUrl,
                primaryMeta: shop.serviceLabels.isNotEmpty
                    ? shop.serviceLabels.first
                    : l10n.nearbyShopGeneric,
                secondaryMeta: shop.serviceLabels.length > 1
                    ? shop.serviceLabels[1]
                    : shop.city,
                actionLabel: l10n.nearbyOpenShop,
                mapQuery: '${shop.name} ${shop.city}',
              ),
            )
            .toList(),
        orElse: () => const <_NearbyItem>[],
      ),
    ];
    final filtered = items.where((item) {
      final matchesQuery =
          _query.isEmpty ||
          [
            item.title,
            item.subtitle,
            item.note,
            item.primaryMeta,
            item.secondaryMeta,
          ].join(' ').toLowerCase().contains(_query);
      final matchesType = _type == 'all' || item.type == _type;
      return matchesQuery && matchesType;
    }).toList();

    return ContentScaffold(
      title: l10n.nearbyTitle,
      description: l10n.nearbyDescription,
      child: ListView(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _query = value.trim().toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: l10n.nearbySearchHint,
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TypeChip(
                label: '🌐 ${l10n.nearbyFilterAll}',
                selected: _type == 'all',
                onTap: () => setState(() => _type = 'all'),
              ),
              _TypeChip(
                label: '🏁 ${l10n.nearbyFilterTracks}',
                selected: _type == 'track',
                onTap: () => setState(() => _type = 'track'),
              ),
              _TypeChip(
                label: '🏪 ${l10n.nearbyFilterShops}',
                selected: _type == 'shop',
                onTap: () => setState(() => _type = 'shop'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final mapButton = FilledButton.icon(
                onPressed: () => context.go('/spots/map'),
                icon: const Icon(Icons.map_outlined),
                label: Text(l10n.openMapButton),
              );
              final nearbyButton = OutlinedButton.icon(
                onPressed: () => context.go('/spots/map'),
                icon: const Icon(Icons.place_outlined),
                label: Text(l10n.nearbyNearMeButton),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    mapButton,
                    const SizedBox(height: 10),
                    nearbyButton,
                  ],
                );
              }

              return Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [mapButton, nearbyButton],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 40,
                      color: AppColors.steel.withAlpha(130),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.nearbyNoResults,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.steel,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ...filtered.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NearbyPreviewCard(
                title: item.title,
                subtitle: item.subtitle,
                badge: item.badge,
                type: item.type,
                note: item.note,
                distance: item.distance,
                imageUrl: item.imageUrl,
                primaryMeta: item.primaryMeta,
                secondaryMeta: item.secondaryMeta,
                actionLabel: item.actionLabel,
                openInMapLabel: l10n.nearbyOpenInMap,
                mapQuery: item.mapQuery,
                onTap: () => context.go(item.route),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context)!;
  return switch (status) {
    'open' => l10n.statusOpen,
    'wet' => l10n.statusWet,
    'closed' => l10n.statusClosed,
    _ => l10n.nearbyStatusUpdating,
  };
}

class _NearbyItem {
  const _NearbyItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.note,
    required this.type,
    required this.route,
    required this.distance,
    required this.imageUrl,
    required this.primaryMeta,
    required this.secondaryMeta,
    required this.actionLabel,
    required this.mapQuery,
  });

  final String title;
  final String subtitle;
  final String badge;
  final String note;
  final String type;
  final String route;
  final String distance;
  final String imageUrl;
  final String primaryMeta;
  final String secondaryMeta;
  final String actionLabel;
  final String mapQuery;
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.signalOrange.withAlpha(35),
      side: BorderSide(
        color: selected ? AppColors.signalOrange : Colors.transparent,
      ),
    );
  }
}

class _NearbyPreviewCard extends StatelessWidget {
  const _NearbyPreviewCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.type,
    required this.note,
    required this.distance,
    required this.imageUrl,
    required this.primaryMeta,
    required this.secondaryMeta,
    required this.actionLabel,
    required this.openInMapLabel,
    required this.mapQuery,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final String type;
  final String note;
  final String distance;
  final String imageUrl;
  final String primaryMeta;
  final String secondaryMeta;
  final String actionLabel;
  final String openInMapLabel;
  final String mapQuery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Build media
    final media = _NearbyMedia(
      imageUrl: imageUrl,
      type: type,
    );

    // Overline "LUOGO · TIPO".
    final overline =
        [subtitle, badge].where((s) => s.trim().isNotEmpty).join(' · ');

    // Riga statistiche compatta: meta principali + distanza.
    // TODO(geolocation): distanza reale quando la geolocation utente sarà disponibile.
    final signals = <Widget>[
      CardStatRow(
        stats: [
          if (primaryMeta.trim().isNotEmpty) CardStat(text: primaryMeta),
          if (secondaryMeta.trim().isNotEmpty) CardStat(text: secondaryMeta),
          if (distance.trim().isNotEmpty)
            CardStat(icon: Icons.place_outlined, text: distance),
        ],
      ),
    ];

    // Build footer leading CTA
    final footerLeading = FilledButton.icon(
      onPressed: onTap,
      icon: Icon(
        type == 'shop' ? Icons.storefront_outlined : Icons.flag_outlined,
      ),
      label: Text(actionLabel),
    );

    // Build footer actions: map button
    // TODO(navigation): considerare se il pulsante mappa nella card nearby deve aprire
    // la mappa centrata su questo item. Attualmente naviga alla mappa generale.
    final footerActions = <Widget>[];

    return PlaceCard(
      media: media,
      title: title,
      overline: overline.isNotEmpty ? overline : null,
      signals: signals,
      body: note.isNotEmpty ? note : null,
      footerLeading: footerLeading,
      footerActions: footerActions.isNotEmpty ? footerActions : null,
      onTap: onTap,
      variant: PlaceCardVariant.compact,
    );
  }
}

class _NearbyMedia extends StatelessWidget {
  const _NearbyMedia({
    required this.imageUrl,
    required this.type,
  });

  final String imageUrl;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE7D8), Color(0xFFF3F5F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: imageUrl.trim().isNotEmpty
          ? AdaptiveImage(
              source: imageUrl,
              fit: BoxFit.cover,
              fallback: ColoredBox(color: AppColors.surfaceMuted),
            )
          : Center(
              child: Icon(
                type == 'shop' ? Icons.storefront_outlined : Icons.flag_outlined,
                color: AppColors.graphite.withAlpha(140),
                size: 30,
              ),
            ),
    );
  }
}


