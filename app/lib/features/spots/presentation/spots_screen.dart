import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/card_stat_row.dart';
import '../../../shared/widgets/place_card.dart';
import '../application/spots_providers.dart';
import '../domain/spot_catalog.dart';
import '../domain/spot_tags.dart';

class SpotsScreen extends ConsumerStatefulWidget {
  const SpotsScreen({super.key});

  @override
  ConsumerState<SpotsScreen> createState() => _SpotsScreenState();
}

class _SpotsScreenState extends ConsumerState<SpotsScreen> {
  // ponytail: filtro solo su "Ideale per", singola scelta; terreno se servirà.
  Set<String> _filter = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spots = ref
        .watch(spotEntriesProvider)
        .where((s) => _filter.isEmpty || s.bestForTags.contains(_filter.first))
        .toList();

    return ContentScaffold(
      title: l10n.spotsTitle,
      description: l10n.spotsDescription,
      child: ListView(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: compact ? WrapAlignment.start : WrapAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go('/submit-place?type=spot'),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: Text(l10n.spotsSubmitAction),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/spots/map'),
                    icon: const Icon(Icons.map_outlined),
                    label: Text(l10n.openMapButton),
                  ),
                ],
              );

              // Il badge decorativo "Spot di guida" e' stato tolto: non
              // portava informazione e su telefono occupava una riga intera.
              return Align(
                alignment:
                    compact ? Alignment.centerLeft : Alignment.centerRight,
                child: actions,
              );
            },
          ),
          const SizedBox(height: 18),
          SpotTagPicker(
            title: _localeText(context, it: 'Filtra per', en: 'Filter by'),
            tags: spotBestForTags,
            selected: _filter,
            multi: false,
            onChanged: (v) => setState(() => _filter = v),
          ),
          const SizedBox(height: 18),
          ...spots.map(
            (spot) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _SpotCard(spot: spot),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  const _SpotCard({required this.spot});

  final SpotEntry spot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Build media
    final media = _SpotMedia(spot: spot);

    // Overline "CITTÀ · CATEGORIA".
    final overlineParts = [spot.city, spot.category]
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final overline = overlineParts.isEmpty ? 'Spot' : overlineParts.join(' · ');

    // Riga statistiche: adatto a + fondo + foto.
    final stats = <CardStat>[];
    for (final tag in [
      ...spotTagsFor(spotBestForTags, spot.bestForTags).take(2),
      ...spotTagsFor(spotSurfaceTags, spot.surfaceTags).take(1),
    ]) {
      stats.add(CardStat(icon: tag.icon, text: tag.label(context)));
    }
    if (spot.bestForTags.isEmpty && spot.bestFor.isNotEmpty) {
      stats.add(CardStat(
          icon: Icons.sports_motorsports_outlined, text: spot.bestFor));
    }
    if (spot.photoCount > 0) {
      stats.add(CardStat(
          icon: Icons.photo_library_outlined,
          text: l10n.spotsPhotosCount(spot.photoCount)));
    }
    final signals = <Widget>[CardStatRow(stats: stats)];

    // Build footer leading CTA
    final footerLeading = FilledButton.icon(
      onPressed: () => context.go('/spot/${spot.slug}'),
      icon: const Icon(Icons.lock_open_outlined),
      label: Text(
        _localeText(
          context,
          it: 'Apri spot',
          en: 'Open spot',
        ),
      ),
    );

    // Build footer actions
    final footerActions = <Widget>[
      IconButton(
        onPressed: () => _openSpotMap(spot),
        icon: const Icon(Icons.map_outlined),
        tooltip: l10n.openMapButton,
      ),
    ];

    return PlaceCard(
      media: media,
      title: spot.title,
      overline: overline,
      signals: signals,
      body: spot.note.isNotEmpty ? spot.note : null,
      footerLeading: footerLeading,
      footerActions: footerActions.isNotEmpty ? footerActions : null,
      onTap: () => context.go('/spot/${spot.slug}'),
      variant: PlaceCardVariant.standard,
    );
  }
}

class _SpotMedia extends StatelessWidget {
  const _SpotMedia({required this.spot});

  final SpotEntry spot;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.graphite),
      child: Stack(
        children: [
          Positioned.fill(
            child: spot.imageUrls.isNotEmpty
                ? AdaptiveImage(
                    source: spot.imageUrls.first,
                    fit: BoxFit.cover,
                    fallback: const ColoredBox(color: AppColors.graphite),
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          spot.imageAccent.withValues(alpha: 0.92),
                          AppColors.graphite,
                        ],
                      ),
                    ),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.46),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -24,
            right: -18,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -28,
            left: -24,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openSpotMap(SpotEntry spot) async {
  final query = spot.latitude != null && spot.longitude != null
      ? '${spot.latitude},${spot.longitude}'
      : Uri.encodeComponent('${spot.title} ${spot.city}');
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$query',
  );
  await launchUrl(uri, mode: LaunchMode.platformDefault);
}

String _localeText(
  BuildContext context, {
  required String it,
  required String en,
}) {
  return Localizations.localeOf(context).languageCode == 'it' ? it : en;
}
