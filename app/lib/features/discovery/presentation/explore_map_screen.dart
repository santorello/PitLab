import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../events/application/public_events_provider.dart';
import '../../shops/application/public_shops_provider.dart';
import '../../spots/application/spots_providers.dart';
import '../../tracks/application/tracks_providers.dart';

/// Esplora (proposta B, mockup "PitLap Esplora Mappa" del 23/09/2026):
/// mappa a tutto schermo, ricerca e una sola riga di filtri, segnaposti
/// raggruppati senza nomi, scheda al tocco, elenco in un pannello dal basso
/// (telefono) o in una colonna a sinistra (PC).
class ExploreMapScreen extends ConsumerStatefulWidget {
  const ExploreMapScreen({super.key});

  @override
  ConsumerState<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

enum _Kind { track, spot, shop, event }

const _eventColor = Color(0xFF7C3AED);

Color _kindColor(_Kind kind) => switch (kind) {
      _Kind.track => AppColors.signalOrange,
      _Kind.spot => AppColors.wetBlue,
      _Kind.shop => AppColors.openGreen,
      _Kind.event => _eventColor,
    };

IconData _kindIcon(_Kind kind) => switch (kind) {
      _Kind.track => Icons.flag,
      _Kind.spot => Icons.location_on,
      _Kind.shop => Icons.storefront,
      _Kind.event => Icons.event,
    };

String _kindLabel(_Kind kind) => switch (kind) {
      _Kind.track => 'Pista',
      _Kind.spot => 'Spot',
      _Kind.shop => 'Negozio',
      _Kind.event => 'Evento',
    };

/// Un luogo qualsiasi, ridotto a quello che serve a mappa, scheda ed elenco.
class _Place {
  const _Place({
    required this.kind,
    required this.key,
    required this.name,
    required this.city,
    required this.point,
    required this.route,
    this.imageUrl = '',
    this.status,
  });

  final _Kind kind;
  final String key;
  final String name;
  final String city;
  final LatLng point;
  final String route;
  final String imageUrl;

  /// Riga di stato: "Aperta oggi", "Chiusa oggi", data dell'evento...
  final ({String label, Color color})? status;
}

class _ExploreMapScreenState extends ConsumerState<ExploreMapScreen> {
  final _map = MapController();
  final _search = TextEditingController();
  _Kind? _filter; // null = Tutto
  String _query = '';
  String? _selectedKey;
  double _zoom = 8.2;
  LatLng _center = const LatLng(45.46, 9.19); // Milano
  bool _fitted = false;
  bool _locating = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_Place> _allPlaces() {
    final tracks = ref.watch(publicTrackPinsProvider).asData?.value ?? const [];
    final spots = ref.watch(spotEntriesProvider);
    final shops = ref.watch(publicShopsProvider).asData?.value ?? const [];
    final events =
        ref.watch(publicUpcomingEventsProvider).asData?.value ?? const [];
    return [
      for (final t in tracks)
        _Place(
          kind: _Kind.track,
          key: 'track:${t.slug}',
          name: t.name,
          city: t.city,
          point: LatLng(t.latitude, t.longitude),
          route: '/track/${t.slug}',
          status: switch (t.status) {
            'open' => (label: 'Aperta oggi', color: AppColors.openGreen),
            'closed' => (label: 'Chiusa oggi', color: AppColors.closedRed),
            _ => null,
          },
        ),
      for (final s in spots)
        if (s.latitude != null && s.longitude != null)
          _Place(
            kind: _Kind.spot,
            key: 'spot:${s.slug}',
            name: s.title,
            city: s.city,
            point: LatLng(s.latitude!, s.longitude!),
            route: '/spot/${s.slug}',
            imageUrl: s.imageUrls.isEmpty ? '' : s.imageUrls.first,
            status: (s.videoUrl ?? '').trim().isEmpty
                ? null
                : (label: 'Video disponibile', color: AppColors.wetBlue),
          ),
      for (final s in shops)
        if (s.latitude != null && s.longitude != null)
          _Place(
            kind: _Kind.shop,
            key: 'shop:${s.slug}',
            name: s.name,
            city: s.city,
            point: LatLng(s.latitude!, s.longitude!),
            route: '/shop/${s.slug}',
            imageUrl: s.imageUrl,
          ),
      for (final e in events)
        if (e.latitude != null && e.longitude != null)
          _Place(
            kind: _Kind.event,
            key: 'event:${e.id}',
            name: e.title,
            city: e.location,
            point: LatLng(e.latitude!, e.longitude!),
            route: '/event/${e.id}',
            imageUrl: e.imageUrls.isEmpty ? '' : e.imageUrls.first,
            status: (label: e.date, color: _eventColor),
          ),
    ];
  }

  List<_Place> _visible(List<_Place> all) {
    final q = _query.trim().toLowerCase();
    return all
        .where((p) => _filter == null || p.kind == _filter)
        .where((p) =>
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.city.toLowerCase().contains(q))
        .toList();
  }

  // ponytail: raggruppamento a griglia (celle di ~56 px allo zoom corrente),
  // ricalcolato a ogni movimento. I gruppi possono "saltare" sul bordo di una
  // cella; se da' fastidio, flutter_map_marker_cluster fa il lavoro vero.
  List<List<_Place>> _cluster(List<_Place> places) {
    if (_zoom >= 13) return [for (final p in places) [p]];
    final degPerPx = 360 / (256 * math.pow(2, _zoom));
    final cellLng = 56 * degPerPx;
    final cellLat = cellLng * math.cos(_center.latitude * math.pi / 180);
    final cells = <String, List<_Place>>{};
    for (final p in places) {
      final k = '${(p.point.latitude / cellLat).floor()}:'
          '${(p.point.longitude / cellLng).floor()}';
      (cells[k] ??= []).add(p);
    }
    return cells.values.toList();
  }

  void _fit(List<_Place> places) {
    if (places.isEmpty) return;
    if (places.length == 1) {
      _map.move(places.first.point, 12);
      return;
    }
    _map.fitCamera(CameraFit.coordinates(
      coordinates: [for (final p in places) p.point],
      padding: const EdgeInsets.all(56),
    ));
  }

  Future<void> _locate() async {
    final messenger = ScaffoldMessenger.of(context);
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
      _map.move(LatLng(pos.latitude, pos.longitude), 11);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Posizione non disponibile: sposta la mappa a mano.'),
      ));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _select(_Place place, {bool moveMap = false}) {
    setState(() => _selectedKey = place.key);
    if (moveMap) _map.move(place.point, math.max(_zoom, 11));
  }

  @override
  Widget build(BuildContext context) {
    final all = _allPlaces();
    final visible = _visible(all);
    const distance = Distance();
    final sorted = [...visible]..sort((a, b) => distance
        .as(LengthUnit.Meter, _center, a.point)
        .compareTo(distance.as(LengthUnit.Meter, _center, b.point)));
    final selected =
        visible.where((p) => p.key == _selectedKey).firstOrNull;

    // Prima volta che arrivano i dati: inquadra tutto.
    if (!_fitted && all.isNotEmpty) {
      _fitted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fit(all);
      });
    }

    final map = _buildMap(visible);
    final countLabel = _countLabel(visible.length);

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 380,
              child: Material(
                color: AppColors.panel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _SearchField(
                        controller: _search,
                        onChanged: (v) => setState(() => _query = v),
                        flat: true,
                      ),
                    ),
                    _Filters(
                      value: _filter,
                      onChanged: (k) => setState(() => _filter = k),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    _ListHeader(label: countLabel),
                    Expanded(
                      child: _PlaceList(
                        places: sorted,
                        center: _center,
                        selectedKey: _selectedKey,
                        onTap: (p) => _select(p, moveMap: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Stack(
                children: [
                  map,
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: _MapButtons(
                      locating: _locating,
                      onLocate: _locate,
                      onFit: () => _fit(visible),
                      onZoom: (d) => _map.move(_center, _zoom + d),
                    ),
                  ),
                  if (selected != null)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      width: 340,
                      child: _PlaceCard(
                        place: selected,
                        center: _center,
                        onClose: () => setState(() => _selectedKey = null),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }

      // Telefono: mappa a tutto schermo, controlli sopra, elenco dal basso.
      const peek = 0.26;
      final peekPx = constraints.maxHeight * peek;
      return Stack(
        children: [
          Positioned.fill(child: map),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 8),
                _Filters(
                  value: _filter,
                  onChanged: (k) => setState(() => _filter = k),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: peekPx + 12,
            child: _MapButtons(
              locating: _locating,
              onLocate: _locate,
              onFit: () => _fit(visible),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: peek,
            minChildSize: 0.12,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const [peek],
            builder: (context, scroll) => Material(
              color: AppColors.panel,
              elevation: 8,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: CustomScrollView(
                controller: scroll,
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.concrete,
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        _ListHeader(label: countLabel),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    sliver: SliverList.separated(
                      itemCount: sorted.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _PlaceRow(
                        place: sorted[i],
                        center: _center,
                        selected: sorted[i].key == _selectedKey,
                        onTap: () => _select(sorted[i], moveMap: true),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: peekPx + 12,
              child: _PlaceCard(
                place: selected,
                center: _center,
                onClose: () => setState(() => _selectedKey = null),
              ),
            ),
        ],
      );
    });
  }

  String _countLabel(int n) {
    final what = switch (_filter) {
      null => n == 1 ? 'luogo' : 'luoghi',
      _Kind.track => n == 1 ? 'pista' : 'piste',
      _Kind.spot => 'spot',
      _Kind.shop => n == 1 ? 'negozio' : 'negozi',
      _Kind.event => n == 1 ? 'evento' : 'eventi',
    };
    return '$n $what';
  }

  Widget _buildMap(List<_Place> visible) {
    final groups = _cluster(visible);
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: _zoom,
        minZoom: 4,
        maxZoom: 18,
        onTap: (_, _) => setState(() => _selectedKey = null),
        onPositionChanged: (camera, _) {
          final zoomChanged = (camera.zoom - _zoom).abs() > 0.05;
          _center = camera.center;
          _zoom = camera.zoom;
          // Ricalcolo dei gruppi solo quando cambia lo zoom: spostarsi a
          // zoom fisso non li cambia abbastanza da valere un rebuild.
          if (zoomChanged) setState(() {});
        },
        // Fine di un trascinamento: riordina l'elenco per il nuovo centro.
        onMapEvent: (event) {
          if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
            setState(() {});
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'pitlap_app',
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: [
            for (final g in groups)
              if (g.length == 1)
                Marker(
                  point: g.first.point,
                  width: 44,
                  height: 44,
                  child: _Pin(
                    place: g.first,
                    selected: g.first.key == _selectedKey,
                    onTap: () => _select(g.first),
                  ),
                )
              else
                Marker(
                  point: _centroid(g),
                  width: 52,
                  height: 52,
                  child: _ClusterBubble(
                    places: g,
                    onTap: () => _fit(g),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

LatLng _centroid(List<_Place> g) => LatLng(
      g.map((p) => p.point.latitude).reduce((a, b) => a + b) / g.length,
      g.map((p) => p.point.longitude).reduce((a, b) => a + b) / g.length,
    );

String _distanceLabel(LatLng from, LatLng to) {
  final km = const Distance().as(LengthUnit.Meter, from, to) / 1000;
  return km < 10 ? '${km.toStringAsFixed(1).replaceAll('.', ',')} km' : '${km.round()} km';
}

// ─── Pezzi ────────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    this.flat = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: flat ? 0 : 4,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(999),
      color: AppColors.panel,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cerca pista, spot, negozio, città…',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: flat
                ? const BorderSide(color: AppColors.borderSubtle)
                : BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: flat
                ? const BorderSide(color: AppColors.borderSubtle)
                : BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.panel,
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.value,
    required this.onChanged,
    this.padding = EdgeInsets.zero,
  });

  final _Kind? value;
  final ValueChanged<_Kind?> onChanged;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, _Kind? kind) {
      final selected = value == kind;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(label),
          avatar: kind == null
              ? null
              : CircleAvatar(radius: 5, backgroundColor: _kindColor(kind)),
          selected: selected,
          showCheckmark: false,
          selectedColor: AppColors.graphite,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.graphite,
            fontWeight: FontWeight.w700,
          ),
          backgroundColor: AppColors.panel,
          elevation: 1,
          onSelected: (_) => onChanged(kind),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          chip('Tutto', null),
          chip('Piste', _Kind.track),
          chip('Spot', _Kind.spot),
          chip('Negozi', _Kind.shop),
          chip('Eventi', _Kind.event),
        ],
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const Spacer(),
          Text(
            'più vicini al centro mappa',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.steel),
          ),
        ],
      ),
    );
  }
}

class _PlaceList extends StatelessWidget {
  const _PlaceList({
    required this.places,
    required this.center,
    required this.selectedKey,
    required this.onTap,
  });

  final List<_Place> places;
  final LatLng center;
  final String? selectedKey;
  final ValueChanged<_Place> onTap;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Nessun luogo con questi filtri.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: places.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _PlaceRow(
        place: places[i],
        center: center,
        selected: places[i].key == selectedKey,
        onTap: () => onTap(places[i]),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.place, required this.size});

  final _Place place;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _kindColor(place.kind);
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.55)!],
        ),
      ),
      child: Icon(_kindIcon(place.kind), color: Colors.white, size: size * 0.4),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: place.imageUrl.isEmpty
            ? fallback
            : AdaptiveImage(
                source: place.imageUrl,
                fit: BoxFit.cover,
                fallback: fallback,
              ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final ({String label, Color color}) status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.place,
    required this.center,
    required this.selected,
    required this.onTap,
  });

  final _Place place;
  final LatLng center;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? AppColors.orange50 : AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.signalOrange : AppColors.borderSubtle,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _Thumb(place: place, size: 56),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      [_kindLabel(place.kind), if (place.city.isNotEmpty) place.city]
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.steel),
                    ),
                    if (place.status != null) ...[
                      const SizedBox(height: 3),
                      _StatusTag(status: place.status!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _distanceLabel(center, place.point),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.steel,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.center,
    required this.onClose,
  });

  final _Place place;
  final LatLng center;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      color: AppColors.panel,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumb(place: place, size: 84),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _kindLabel(place.kind).toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _kindColor(place.kind),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Text(
                          place.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        [
                          if (place.city.isNotEmpty) place.city,
                          _distanceLabel(center, place.point),
                        ].join(' · '),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.steel),
                      ),
                      if (place.status != null) ...[
                        const SizedBox(height: 4),
                        _StatusTag(status: place.status!),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          FilledButton(
                            onPressed: () => context.push(place.route),
                            child: const Text('Apri'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => launchUrl(
                              Uri.parse(
                                'https://www.google.com/maps/dir/?api=1&destination='
                                '${place.point.latitude},${place.point.longitude}',
                              ),
                              mode: LaunchMode.externalApplication,
                            ),
                            icon: const Icon(Icons.directions, size: 18),
                            label: const Text('Indicazioni'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: 'Chiudi',
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({
    required this.place,
    required this.selected,
    required this.onTap,
  });

  final _Place place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 40.0 : 32.0;
    return Center(
      child: Tooltip(
        message: place.name,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _kindColor(place.kind),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? _kindColor(place.kind).withValues(alpha: 0.45)
                      : Colors.black26,
                  blurRadius: selected ? 14 : 6,
                  spreadRadius: selected ? 3 : 0,
                ),
              ],
            ),
            child: Icon(
              _kindIcon(place.kind),
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cerchio con il numero di luoghi; l'anello mostra la proporzione dei tipi.
class _ClusterBubble extends StatelessWidget {
  const _ClusterBubble({required this.places, required this.onTap});

  final List<_Place> places;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = places.length;
    final size = n >= 20 ? 52.0 : (n >= 8 ? 46.0 : 40.0);
    final counts = {
      for (final k in _Kind.values)
        k: places.where((p) => p.kind == k).length,
    };
    final stops = <double>[];
    final colors = <Color>[];
    var acc = 0.0;
    for (final k in _Kind.values) {
      final share = counts[k]! / n;
      if (share == 0) continue;
      colors..add(_kindColor(k))..add(_kindColor(k));
      stops..add(acc)..add(acc + share);
      acc += share;
    }
    return Center(
      child: Tooltip(
        message: '$n luoghi: tocca per avvicinarti',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: colors, stops: stops),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8),
              ],
            ),
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.graphite,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$n',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapButtons extends StatelessWidget {
  const _MapButtons({
    required this.locating,
    required this.onLocate,
    required this.onFit,
    this.onZoom,
  });

  final bool locating;
  final VoidCallback onLocate;
  final VoidCallback onFit;

  /// Solo su PC: su telefono basta il pizzico.
  final ValueChanged<double>? onZoom;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, String tip, VoidCallback? onTap) => Material(
          color: AppColors.panel,
          shape: const CircleBorder(),
          elevation: 4,
          child: IconButton(
            tooltip: tip,
            onPressed: onTap,
            icon: Icon(icon, color: AppColors.graphite),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onZoom != null) ...[
          btn(Icons.add, 'Ingrandisci', () => onZoom!(1)),
          const SizedBox(height: 8),
          btn(Icons.remove, 'Riduci', () => onZoom!(-1)),
          const SizedBox(height: 8),
        ],
        btn(Icons.fit_screen_outlined, 'Mostra tutti', onFit),
        const SizedBox(height: 8),
        locating
            ? const SizedBox(
                width: 48,
                height: 48,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            : btn(Icons.my_location, 'La mia posizione', onLocate),
      ],
    );
  }
}
