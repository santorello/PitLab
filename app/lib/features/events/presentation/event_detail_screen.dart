import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/utils/share_entity.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../comments/presentation/comments_section.dart';
import '../../profile/application/profile_hub_providers.dart';
import '../application/public_events_provider.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final createdEvents = ref.watch(createdEventsProvider);
    final publicEventAsync = ref.watch(publicEventDetailProvider(eventId));
    CreatedEventRecord? createdMatch;
    for (final event in createdEvents) {
      if (event.id == eventId) {
        createdMatch = event;
        break;
      }
    }

    final resolvedRecord =
        createdMatch ??
        publicEventAsync.maybeWhen(
          data: (event) => event,
          orElse: () => null,
        );

    if (publicEventAsync.isLoading && createdMatch == null) {
      return ContentScaffold(
        title: l10n.eventsDetailTitle,
        description: l10n.eventsDetailDescription,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (resolvedRecord == null) {
      return ContentScaffold(
        title: l10n.eventsDetailTitle,
        description: l10n.eventsDetailDescription,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _localeText(
                context,
                it: 'Evento non trovato.',
                en: 'Event not found.',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    final event = _ResolvedEvent(
      title: resolvedRecord.title,
      date: resolvedRecord.date,
      location: resolvedRecord.location,
      note: resolvedRecord.note,
      badge: resolvedRecord.badge,
      creatorLabel: resolvedRecord.creatorLabel,
      venue: resolvedRecord.venue,
      imageUrls: resolvedRecord.imageUrls,
    );

    return ContentScaffold(
      title: l10n.eventsDetailTitle,
      description: l10n.eventsDetailDescription,
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF6EFE3), Colors.white, Color(0xFFF2F4F7)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.signalOrange.withAlpha(22),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.signalOrange.withAlpha(80)),
                  ),
                  child: Text(
                    '🎉 ${event.badge}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.graphite,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.steel),
                    const SizedBox(width: 6),
                    Text(
                      event.location,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.steel),
                    const SizedBox(width: 6),
                    Text(
                      event.date,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
                if (event.creatorLabel != null && event.creatorLabel!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    event.creatorLabel!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.signalOrange,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () => shareEntity(
                    context: context,
                    entityType: 'event',
                    entityId: eventId,
                  ),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: Text(l10n.eventsShareAction),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (event.imageUrls.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      child: InkWell(
                        onTap: () => _openGallery(context, event.imageUrls, 0),
                        child: SizedBox(
                          height: 260,
                          width: double.infinity,
                          child: AdaptiveImage(
                            source: event.imageUrls.first,
                            fit: BoxFit.cover,
                            fallback: const ColoredBox(color: Color(0xFFEDEFF3)),
                          ),
                        ),
                      ),
                    ),
                    if (event.imageUrls.length > 1) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 84,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: event.imageUrls.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) => InkWell(
                            onTap: () =>
                                _openGallery(context, event.imageUrls, index),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: SizedBox(
                                width: 110,
                                child: AdaptiveImage(
                                  source: event.imageUrls[index],
                                  fit: BoxFit.cover,
                                  fallback: const ColoredBox(
                                    color: Color(0xFFEDEFF3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                    '📋 ${l10n.eventsDetailOverviewTitle}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    event.note,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.steel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _DetailChip(label: l10n.eventsDetailTrackContext),
                      if (event.venue != null && event.venue!.isNotEmpty)
                        _DetailChip(label: event.venue!),
                      _DetailChip(label: l10n.eventsDetailLightRsvp),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Commenti sull'evento (entityType 'event', id UUID).
          CommentsSection(
            entityType: 'event',
            entityId: eventId,
          ),
        ],
      ),
    );
  }
}

Future<void> _openGallery(
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

class _ResolvedEvent {
  const _ResolvedEvent({
    required this.title,
    required this.date,
    required this.location,
    required this.note,
    required this.badge,
    this.imageUrls = const [],
    this.creatorLabel,
    this.venue,
  });

  final String title;
  final String date;
  final String location;
  final String note;
  final String badge;
  final List<String> imageUrls;
  final String? creatorLabel;
  final String? venue;
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.signalOrange.withAlpha(18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.signalOrange.withAlpha(70)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.graphite,
          fontWeight: FontWeight.w600,
        ),
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
