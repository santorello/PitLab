import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/card_stat_row.dart';
import '../../../shared/widgets/place_card.dart';
import '../../../shared/models/track_map_pin.dart';
import '../../events/application/public_events_provider.dart';
import '../../location/application/user_location_context_provider.dart';
import '../../profile/application/profile_hub_providers.dart';
import '../../shops/application/public_shops_provider.dart';
import '../../spots/application/spots_providers.dart';
import '../../spots/domain/spot_tags.dart';
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
  // null = tutti. Default 50 km (se c'è un punto di partenza).
  double? _radiusKm = 50;
  ({double lat, double lon})? _gps;
  bool _locating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _useGps() async {
    final messenger = ScaffoldMessenger.of(context);
    final denied = _t(context, 'Posizione non disponibile: uso la tua città di casa.',
        'Location unavailable: using your home city.');
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('permission denied');
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _gps = (lat: pos.latitude, lon: pos.longitude));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(denied)));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tracksAsync = ref.watch(publicTracksProvider);
    final pinsBySlug = {
      for (final pin in ref.watch(publicTrackPinsProvider).asData?.value ??
          const <TrackMapPin>[])
        pin.slug: pin,
    };
    final shopsAsync = ref.watch(publicShopsProvider);
    final spots = ref.watch(spotEntriesProvider);
    final events = ref.watch(publicUpcomingEventsProvider).asData?.value ??
        const <CreatedEventRecord>[];
    final home = ref.watch(userLocationContextProvider).asData?.value;

    final origin = _gps ??
        (home != null && home.hasCoordinates
            ? (lat: home.latitude!, lon: home.longitude!)
            : null);
    final originLabel = _gps != null
        ? _t(context, 'dalla tua posizione', 'from your location')
        : origin != null
            ? _t(context, 'da ${home!.label}', 'from ${home!.label}')
            : null;

    final items = <_NearbyItem>[
      ...tracksAsync.maybeWhen(
        data: (tracks) => tracks.map(
          (track) => _NearbyItem(
            title: track.name,
            subtitle: track.city,
            badge: l10n.nearbyBadgeTrack,
            note: track.statusMessage.isNotEmpty
                ? track.statusMessage
                : track.shortDescription,
            type: 'track',
            route: '/track/${track.slug}',
            imageUrl: '',
            primaryMeta: _statusLabel(context, track.status),
            secondaryMeta: track.availableServiceCount <= 0
                ? l10n.nearbyNoServices
                : l10n.nearbyServicesCount(track.availableServiceCount),
            actionLabel: l10n.nearbyOpenTrack,
            latitude: pinsBySlug[track.slug]?.latitude,
            longitude: pinsBySlug[track.slug]?.longitude,
          ),
        ),
        orElse: () => const <_NearbyItem>[],
      ),
      ...spots.map(
        (spot) => _NearbyItem(
          title: spot.title,
          subtitle: spot.city,
          badge: 'Spot',
          note: spot.note,
          type: 'spot',
          route: '/spot/${spot.slug}',
          imageUrl: spot.imageUrls.isEmpty ? '' : spot.imageUrls.first,
          primaryMeta: spotTagsFor(spotBestForTags, spot.bestForTags)
                  .firstOrNull
                  ?.label(context) ??
              '',
          secondaryMeta: spotTagsFor(spotSurfaceTags, spot.surfaceTags)
                  .firstOrNull
                  ?.label(context) ??
              '',
          actionLabel: _t(context, 'Apri spot', 'Open spot'),
          latitude: spot.latitude,
          longitude: spot.longitude,
        ),
      ),
      ...events.map(
        (event) => _NearbyItem(
          title: event.title,
          subtitle: event.location,
          badge: _t(context, 'Evento', 'Event'),
          note: event.note,
          type: 'event',
          route: '/event/${event.id}',
          imageUrl: event.imageSource ?? '',
          primaryMeta: event.date,
          secondaryMeta: event.venue ?? '',
          actionLabel: _t(context, 'Apri evento', 'Open event'),
          latitude: event.latitude,
          longitude: event.longitude,
        ),
      ),
      ...shopsAsync.maybeWhen(
        data: (shops) => shops.map(
          (shop) => _NearbyItem(
            title: shop.name,
            subtitle: shop.city,
            badge: l10n.nearbyBadgeShop,
            note: shop.shortDescription.isNotEmpty
                ? shop.shortDescription
                : shop.subtitle,
            type: 'shop',
            route: '/shop/${shop.slug}',
            imageUrl: shop.imageUrl,
            primaryMeta: shop.serviceLabels.isNotEmpty
                ? shop.serviceLabels.first
                : l10n.nearbyShopGeneric,
            secondaryMeta:
                shop.serviceLabels.length > 1 ? shop.serviceLabels[1] : '',
            actionLabel: l10n.nearbyOpenShop,
            latitude: shop.latitude,
            longitude: shop.longitude,
          ),
        ),
        orElse: () => const <_NearbyItem>[],
      ),
    ];

    double? kmOf(_NearbyItem item) =>
        origin == null || item.latitude == null || item.longitude == null
            ? null
            : distanceKmBetween(
                fromLatitude: origin.lat,
                fromLongitude: origin.lon,
                toLatitude: item.latitude!,
                toLongitude: item.longitude!,
              );

    final filtered = <({_NearbyItem item, double? km})>[
      for (final item in items)
        if ((_type == 'all' || item.type == _type) &&
            (_query.isEmpty ||
                [item.title, item.subtitle, item.note, item.primaryMeta, item.secondaryMeta]
                    .join(' ')
                    .toLowerCase()
                    .contains(_query)))
          (item: item, km: kmOf(item)),
    ].where((e) {
      if (origin == null || _radiusKm == null) return true;
      return e.km != null && e.km! <= _radiusKm!;
    }).toList()
      ..sort((a, b) {
        if (a.km == null && b.km == null) return a.item.title.compareTo(b.item.title);
        if (a.km == null) return 1;
        if (b.km == null) return -1;
        return a.km!.compareTo(b.km!);
      });

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
              for (final (key, label) in [
                ('all', l10n.nearbyFilterAll),
                ('track', l10n.nearbyFilterTracks),
                ('spot', 'Spot'),
                ('event', _t(context, 'Eventi', 'Events')),
                ('shop', l10n.nearbyFilterShops),
              ])
                _TypeChip(
                  label: label,
                  selected: _type == key,
                  onTap: () => setState(() => _type = key),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (origin != null)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final km in <double?>[10, 25, 50, null])
                  _TypeChip(
                    label: km == null
                        ? _t(context, 'Ovunque', 'Anywhere')
                        : '${km.toInt()} km',
                    selected: _radiusKm == km,
                    onTap: () => setState(() => _radiusKm = km),
                  ),
                Text(
                  originLabel!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.steel),
                ),
              ],
            )
          else
            Text(
              _t(
                context,
                'Imposta la città nel profilo o usa "Vicino a me" per vedere le distanze.',
                'Set your city in your profile or use "Near me" to see distances.',
              ),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.steel),
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
                onPressed: _locating ? null : _useGps,
                icon: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_outlined),
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
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NearbyPreviewCard(
                title: e.item.title,
                subtitle: e.item.subtitle,
                badge: e.item.badge,
                type: e.item.type,
                note: e.item.note,
                distance: e.km == null ? '' : _formatKm(e.km!),
                imageUrl: e.item.imageUrl,
                primaryMeta: e.item.primaryMeta,
                secondaryMeta: e.item.secondaryMeta,
                actionLabel: e.item.actionLabel,
                onTap: () => context.go(e.item.route),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _t(BuildContext context, String it, String en) =>
    Localizations.localeOf(context).languageCode == 'en' ? en : it;

String _formatKm(double km) => km < 10
    ? '${km.toStringAsFixed(1).replaceAll('.', ',')} km'
    : '${km.round()} km';

IconData _typeIcon(String type) => switch (type) {
      'shop' => Icons.storefront_outlined,
      'spot' => Icons.terrain_outlined,
      'event' => Icons.event_outlined,
      _ => Icons.flag_outlined,
    };

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
    required this.imageUrl,
    required this.primaryMeta,
    required this.secondaryMeta,
    required this.actionLabel,
    this.latitude,
    this.longitude,
  });

  final String title;
  final String subtitle;
  final String badge;
  final String note;
  final String type;
  final String route;
  final String imageUrl;
  final String primaryMeta;
  final String secondaryMeta;
  final String actionLabel;
  final double? latitude;
  final double? longitude;
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
      icon: Icon(_typeIcon(type)),
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
                _typeIcon(type),
                color: AppColors.graphite.withAlpha(140),
                size: 30,
              ),
            ),
    );
  }
}


