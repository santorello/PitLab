import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/pill.dart';
import '../../../shared/widgets/place_card.dart';
import '../application/spots_providers.dart';
import '../domain/spot_catalog.dart';

class SpotsScreen extends ConsumerWidget {
  const SpotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final spots = ref.watch(spotEntriesProvider);

    return ContentScaffold(
      title: l10n.spotsTitle,
      description: l10n.spotsDescription,
      child: ListView(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.signalOrange.withAlpha(22),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.signalOrange.withAlpha(80)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.push_pin_outlined,
                      size: 18,
                      color: AppColors.signalOrange,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Spot di guida',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
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

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    badge,
                    const SizedBox(height: 12),
                    actions,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: badge,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(child: actions),
                ],
              );
            },
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

    // Build type badge
    final typeBadge = Pill(
      label: spot.category,
      tone: PillTone.warning,
    );

    // Build location subtitle
    final subtitle = [
      spot.city,
      if ((spot.address ?? '').trim().isNotEmpty) spot.address!.trim(),
    ].join(' · ');

    // Build signals: bestFor + surface + photo count
    final signals = <Widget>[];
    if (spot.bestFor.isNotEmpty) {
      signals.add(
        Pill(
          label: spot.bestFor,
          tone: PillTone.signal,
          icon: Icons.sports_motorsports_outlined,
        ),
      );
    }
    if (spot.surface.isNotEmpty &&
        !spot.surface.toLowerCase().contains('confermare')) {
      signals.add(
        Pill(
          label: spot.surface,
          tone: PillTone.neutral,
          icon: Icons.terrain_outlined,
        ),
      );
    }
    signals.add(
      Pill(
        label: l10n.spotsPhotosCount(spot.photoCount),
        tone: PillTone.neutral,
        icon: Icons.photo_library_outlined,
      ),
    );

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
      subtitle: subtitle,
      typeBadge: typeBadge,
      signals: signals.isNotEmpty ? signals : null,
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
