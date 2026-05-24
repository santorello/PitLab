import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../features/shops/application/public_shops_provider.dart';
import '../../../features/tracks/application/tracks_providers.dart';
import '../../../shared/models/track_map_pin.dart';
import '../application/spots_providers.dart';
import '../domain/spot_catalog.dart';

// ─── Tipi di selezione mappa ─────────────────────────────────────────────────

enum _MarkerType { track, spot, shop }

class _MapSelection {
  const _MapSelection({required this.type, required this.slug});
  final _MarkerType type;
  final String slug;
}

// ─── Schermata principale ────────────────────────────────────────────────────

class SpotsMapScreen extends ConsumerStatefulWidget {
  const SpotsMapScreen({super.key});

  @override
  ConsumerState<SpotsMapScreen> createState() => _SpotsMapScreenState();
}

class _SpotsMapScreenState extends ConsumerState<SpotsMapScreen> {
  final MapController _mapController = MapController();
  _MapSelection? _selection;

  // Filtri layer
  bool _showTracks = true;
  bool _showSpots = true;
  bool _showShops = true;

  @override
  Widget build(BuildContext context) {
    final spotsAll = ref.watch(spotEntriesProvider);
    final trackPinsAsync = ref.watch(publicTrackPinsProvider);
    final shopsAsync = ref.watch(publicShopsProvider);

    final mappableSpots = _showSpots
        ? spotsAll
              .where((s) => s.latitude != null && s.longitude != null)
              .toList()
        : <SpotEntry>[];

    final trackPins = _showTracks
        ? trackPinsAsync.maybeWhen(
            data: (pins) => pins,
            orElse: () => const <TrackMapPin>[],
          )
        : <TrackMapPin>[];

    final shopPins = _showShops
        ? shopsAsync.maybeWhen(
            data: (shops) => shops
                .where((s) => s.latitude != null && s.longitude != null)
                .toList(),
            orElse: () => const <PublicShop>[],
          )
        : <PublicShop>[];

    // Calcola il centro iniziale combinando i due layer
    final allLats = [
      ...mappableSpots.map((s) => s.latitude!),
      ...trackPins.map((t) => t.latitude),
      ...shopPins.map((s) => s.latitude!),
    ];
    final allLngs = [
      ...mappableSpots.map((s) => s.longitude!),
      ...trackPins.map((t) => t.longitude),
      ...shopPins.map((s) => s.longitude!),
    ];
    final initialCenter = _centerFor(allLats, allLngs);
    final hasPoints = allLats.isNotEmpty;

    return ContentScaffold(
      title: 'Mappa',
      description:
          'Piste, spot e negozi RC sulla stessa mappa. Tocca un marker per il dettaglio.',
      child: ListView(
        children: [
          // ── Hero card ─────────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mappa unificata',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tutte le piste, gli spot e i negozi in un\'unica vista interattiva.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.steel,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Toggle Piste
                      _LayerChip(
                        label: 'Piste',
                        icon: Icons.flag_outlined,
                        color: AppColors.signalOrange,
                        active: _showTracks,
                        onTap: () =>
                            setState(() => _showTracks = !_showTracks),
                      ),
                      // Toggle Spot
                      _LayerChip(
                        label: 'Spot',
                        icon: Icons.location_on_outlined,
                        color: AppColors.wetBlue,
                        active: _showSpots,
                        onTap: () =>
                            setState(() => _showSpots = !_showSpots),
                      ),
                      // Toggle Negozi
                      _LayerChip(
                        label: 'Negozi',
                        icon: Icons.storefront_outlined,
                        color: AppColors.openGreen,
                        active: _showShops,
                        onTap: () =>
                            setState(() => _showShops = !_showShops),
                      ),
                      // Adatta vista
                      if (hasPoints)
                        OutlinedButton.icon(
                          onPressed: () =>
                              _fitMap(mappableSpots, trackPins, shopPins),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.graphite,
                            side: const BorderSide(color: AppColors.concrete),
                          ),
                          icon: const Icon(Icons.center_focus_strong_outlined),
                          label: const Text('Adatta vista'),
                        ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.go('/submit-place?type=spot'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.graphite,
                          side: const BorderSide(color: AppColors.concrete),
                        ),
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: const Text('Segnala Spot'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Layout: mappa + pannello dettaglio ────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 980;

              // Pannello mappa
              final mapPanel = _UnifiedMapPanel(
                mapController: _mapController,
                spots: mappableSpots,
                tracks: trackPins,
                shops: shopPins,
                selection: _selection,
                initialCenter: initialCenter,
                initialZoom: hasPoints ? 8.4 : 9.0,
                onSelectSpot: (slug) => setState(() => _selection =
                    _MapSelection(type: _MarkerType.spot, slug: slug)),
                onSelectTrack: (slug) => setState(() => _selection =
                    _MapSelection(type: _MarkerType.track, slug: slug)),
                onSelectShop: (slug) => setState(() => _selection =
                    _MapSelection(type: _MarkerType.shop, slug: slug)),
              );

              // Pannello dettaglio
              final detailPanel = _buildDetailPanel(
                context,
                spotsAll,
                shopPins,
              );

              if (stacked) {
                return Column(
                  children: [
                    mapPanel,
                    const SizedBox(height: 18),
                    detailPanel,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: mapPanel),
                  const SizedBox(width: 18),
                  Expanded(flex: 2, child: detailPanel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(
    BuildContext context,
    List<SpotEntry> spots,
    List<PublicShop> shops,
  ) {
    final sel = _selection;

    if (sel == null) {
      // Nessuna selezione: mostra un hint
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app_outlined,
                  size: 40, color: AppColors.concrete),
              const SizedBox(height: 12),
              Text(
                'Tocca un marker per il dettaglio',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.steel,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (sel.type == _MarkerType.spot) {
      final spot = spots.firstWhere(
        (s) => s.slug == sel.slug,
        orElse: () => spots.first,
      );
      return _SelectedSpotPanel(spot: spot);
    }

    if (sel.type == _MarkerType.shop) {
      if (shops.isEmpty) return const SizedBox.shrink();
      final shop = shops.firstWhere(
        (s) => s.slug == sel.slug,
        orElse: () => shops.first,
      );
      return _SelectedShopPanel(shop: shop);
    }

    // Track detail — usa tutti i pin (non filtrati per layer visibile)
    final allTrackPins =
        ref.read(publicTrackPinsProvider).asData?.value ??
        const <TrackMapPin>[];
    if (allTrackPins.isEmpty) return const SizedBox.shrink();
    final track = allTrackPins.firstWhere(
      (t) => t.slug == sel.slug,
      orElse: () => allTrackPins.first,
    );
    return _SelectedTrackPanel(track: track);
  }

  void _fitMap(
    List<SpotEntry> spots,
    List<TrackMapPin> tracks,
    List<PublicShop> shops,
  ) {
    final lats = [
      ...spots.map((s) => s.latitude!),
      ...tracks.map((t) => t.latitude),
      ...shops.map((s) => s.latitude!),
    ];
    final lngs = [
      ...spots.map((s) => s.longitude!),
      ...tracks.map((t) => t.longitude),
      ...shops.map((s) => s.longitude!),
    ];
    if (lats.isEmpty) return;

    final bounds = LatLngBounds(
      LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
      LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
    );
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(64),
      ),
    );
  }
}

// ─── Pannello mappa ──────────────────────────────────────────────────────────

class _UnifiedMapPanel extends StatelessWidget {
  const _UnifiedMapPanel({
    required this.mapController,
    required this.spots,
    required this.tracks,
    required this.shops,
    required this.selection,
    required this.initialCenter,
    required this.initialZoom,
    required this.onSelectSpot,
    required this.onSelectTrack,
    required this.onSelectShop,
  });

  final MapController mapController;
  final List<SpotEntry> spots;
  final List<TrackMapPin> tracks;
  final List<PublicShop> shops;
  final _MapSelection? selection;
  final LatLng initialCenter;
  final double initialZoom;
  final ValueChanged<String> onSelectSpot;
  final ValueChanged<String> onSelectTrack;
  final ValueChanged<String> onSelectShop;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 540,
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: initialZoom,
                onTap: (_, _) {},
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'pitlap_app',
                  maxZoom: 19,
                ),
                // Layer piste (marker arancio con bandierina)
                MarkerLayer(
                  markers: tracks
                      .map(
                        (track) => Marker(
                          point: LatLng(track.latitude, track.longitude),
                          width: 148,
                          height: 82,
                          child: _TrackMarker(
                            track: track,
                            selected: selection?.type == _MarkerType.track &&
                                selection?.slug == track.slug,
                            onTap: () => onSelectTrack(track.slug),
                          ),
                        ),
                      )
                      .toList(),
                ),
                // Layer spot (marker blu con pin)
                MarkerLayer(
                  markers: spots
                      .map(
                        (spot) => Marker(
                          point: LatLng(spot.latitude!, spot.longitude!),
                          width: 148,
                          height: 82,
                          child: _SpotMarker(
                            spot: spot,
                            selected: selection?.type == _MarkerType.spot &&
                                selection?.slug == spot.slug,
                            onTap: () => onSelectSpot(spot.slug),
                          ),
                        ),
                      )
                      .toList(),
                ),
                // Layer negozi (marker verde con storefront)
                MarkerLayer(
                  markers: shops
                      .map(
                        (shop) => Marker(
                          point: LatLng(shop.latitude!, shop.longitude!),
                          width: 148,
                          height: 82,
                          child: _ShopMarker(
                            shop: shop,
                            selected: selection?.type == _MarkerType.shop &&
                                selection?.slug == shop.slug,
                            onTap: () => onSelectShop(shop.slug),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          // Barra inferiore con contatori
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F7F3),
              border: Border(top: BorderSide(color: AppColors.concrete)),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _CountChip(
                  icon: Icons.flag,
                  color: AppColors.signalOrange,
                  label: '${tracks.length} piste',
                ),
                _CountChip(
                  icon: Icons.location_on,
                  color: AppColors.wetBlue,
                  label: '${spots.length} spot',
                ),
                _CountChip(
                  icon: Icons.storefront,
                  color: AppColors.openGreen,
                  label: '${shops.length} negozi',
                ),
                Text(
                  'Mappa interattiva — dati reali',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.steel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Marker pista ─────────────────────────────────────────────────────────────

class _TrackMarker extends StatelessWidget {
  const _TrackMarker({
    required this.track,
    required this.selected,
    required this.onTap,
  });

  final TrackMapPin track;
  final bool selected;
  final VoidCallback onTap;

  Color get _statusColor {
    return switch (track.status) {
      'open' => AppColors.openGreen,
      'closed' => AppColors.closedRed,
      _ => AppColors.steel,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icona con dot di stato
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: selected ? 42 : 36,
                height: selected ? 42 : 36,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.signalOrange
                      : AppColors.signalOrange.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.flag, color: Colors.white, size: 18),
              ),
              // Dot stato pista
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Label
          Container(
            constraints: const BoxConstraints(maxWidth: 140),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? AppColors.signalOrange
                    : AppColors.concrete,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              track.name,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Marker spot ──────────────────────────────────────────────────────────────

class _SpotMarker extends StatelessWidget {
  const _SpotMarker({
    required this.spot,
    required this.selected,
    required this.onTap,
  });

  final SpotEntry spot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: selected ? 42 : 36,
            height: selected ? 42 : 36,
            decoration: BoxDecoration(
              color: selected ? AppColors.wetBlue : AppColors.graphite,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxWidth: 140),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? AppColors.wetBlue : AppColors.concrete,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              spot.title,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Marker negozio ──────────────────────────────────────────────────────────

class _ShopMarker extends StatelessWidget {
  const _ShopMarker({
    required this.shop,
    required this.selected,
    required this.onTap,
  });

  final PublicShop shop;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: selected ? 42 : 36,
            height: selected ? 42 : 36,
            decoration: BoxDecoration(
              color: selected ? AppColors.openGreen : AppColors.openGreen,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxWidth: 140),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? AppColors.openGreen : AppColors.concrete,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              shop.name,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pannello dettaglio pista ─────────────────────────────────────────────────

class _SelectedTrackPanel extends StatelessWidget {
  const _SelectedTrackPanel({required this.track});

  final TrackMapPin track;

  Color get _statusColor {
    return switch (track.status) {
      'open' => AppColors.openGreen,
      'closed' => AppColors.closedRed,
      _ => AppColors.steel,
    };
  }

  String get _statusLabel {
    return switch (track.status) {
      'open' => 'Aperta',
      'closed' => 'Chiusa',
      _ => 'Stato sconosciuto',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge tipo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.signalOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: AppColors.signalOrange.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag,
                      size: 13, color: AppColors.signalOrange),
                  const SizedBox(width: 5),
                  Text(
                    'Pista RC',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.signalOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              track.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              track.city,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.steel,
              ),
            ),
            const SizedBox(height: 14),
            // Badge stato
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _statusLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/track/${track.slug}'),
              icon: const Icon(Icons.open_in_new_outlined),
              label: const Text('Apri pista'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.signalOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pannello dettaglio spot ──────────────────────────────────────────────────

class _SelectedSpotPanel extends StatelessWidget {
  const _SelectedSpotPanel({required this.spot});

  final SpotEntry spot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge tipo
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.wetBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: AppColors.wetBlue.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on,
                      size: 13, color: AppColors.wetBlue),
                  const SizedBox(width: 5),
                  Text(
                    'Spot',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.wetBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(spot.title,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              '${spot.city} — ${spot.category}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.steel,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoChip(label: spot.bestFor),
                _InfoChip(label: spot.surface),
              ],
            ),
            const SizedBox(height: 12),
            Text(spot.note,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/spot/${spot.slug}'),
                  icon: const Icon(Icons.open_in_new_outlined),
                  label: const Text('Apri spot'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.wetBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openMap(spot),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Apri in mappa'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pannello dettaglio negozio ───────────────────────────────────────────────

class _SelectedShopPanel extends StatelessWidget {
  const _SelectedShopPanel({required this.shop});

  final PublicShop shop;

  @override
  Widget build(BuildContext context) {
    final services = shop.serviceLabels.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.openGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.openGreen.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    size: 13,
                    color: AppColors.openGreen,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Negozio',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.openGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(shop.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              shop.city,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.steel,
              ),
            ),
            if (shop.subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                shop.subtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            if (services.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: services.map((label) => _InfoChip(label: label)).toList(),
              ),
            ],
            if (shop.address.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                shop.address,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.steel,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/shop/${shop.slug}'),
                  icon: const Icon(Icons.open_in_new_outlined),
                  label: const Text('Apri negozio'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.openGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openShopMap(shop),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Indicazioni'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget di supporto ───────────────────────────────────────────────────────

class _LayerChip extends StatelessWidget {
  const _LayerChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? color : AppColors.concrete,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? color : AppColors.steel),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? color : AppColors.steel,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.concrete),
      ),
      child: Text(label),
    );
  }
}

// ─── Utility ─────────────────────────────────────────────────────────────────

LatLng _centerFor(List<double> lats, List<double> lngs) {
  if (lats.isEmpty) {
    // Centro Italia / Nord Italia di default
    return const LatLng(44.8015, 10.2402);
  }
  final latAvg =
      lats.reduce((a, b) => a + b) / lats.length;
  final lngAvg =
      lngs.reduce((a, b) => a + b) / lngs.length;
  return LatLng(latAvg, lngAvg);
}

Future<void> _openMap(SpotEntry spot) async {
  final query = spot.latitude != null && spot.longitude != null
      ? '${spot.latitude},${spot.longitude}'
      : Uri.encodeComponent('${spot.title} ${spot.city}');
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$query',
  );
  await launchUrl(uri, mode: LaunchMode.platformDefault);
}

Future<void> _openShopMap(PublicShop shop) async {
  final directUrl = shop.externalMapUrl.trim();
  if (directUrl.isNotEmpty) {
    await launchUrl(Uri.parse(directUrl), mode: LaunchMode.platformDefault);
    return;
  }

  final query = shop.latitude != null && shop.longitude != null
      ? '${shop.latitude},${shop.longitude}'
      : Uri.encodeComponent('${shop.name} ${shop.city} ${shop.address}');
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$query',
  );
  await launchUrl(uri, mode: LaunchMode.platformDefault);
}
