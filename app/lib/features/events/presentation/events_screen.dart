import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/media/media_upload_controller.dart';
import '../../../shared/media/media_upload_labels.dart';
import '../../../shared/media/media_upload_service.dart';
import '../../../shared/media/media_upload_state.dart';
import '../../../shared/utils/local_image_data_url.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/image_transfer_progress_card.dart';
import '../../../shared/widgets/card_stat_row.dart';
import '../../../shared/widgets/place_card.dart';
import '../../auth/application/auth_providers.dart';
import '../../profile/application/profile_hub_providers.dart';
import '../application/public_events_provider.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  bool _featuredExpanded = true;
  bool _archiveExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customEvents = ref.watch(myActiveCreatedEventsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final featuredEventsAsync = ref.watch(publicUpcomingEventsProvider);
    final pastEventsAsync = ref.watch(publicPastEventsProvider);
    return ContentScaffold(
      title: l10n.eventsTitle,
      description: l10n.eventsDescription,
      child: ListView(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.signalOrange.withAlpha(22),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.signalOrange.withAlpha(80)),
                ),
                child: Text(
                  '🎉 ${_localeText(context, it: 'Gare & Appuntamenti', en: 'Races & Events')}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _handleCreatePressed(context, currentUser),
                icon: const Icon(Icons.add_circle_outline),
                label: Text(l10n.eventsCreateAction),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => setState(() {
                      _featuredExpanded = !_featuredExpanded;
                    }),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _localeText(
                                context,
                                it: '✨ In evidenza',
                                en: '✨ Highlights',
                              ),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Icon(
                            _featuredExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: AppColors.steel,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          _localeText(
                            context,
                            it:
                                'Una selezione rapida per capire dove c\'e movimento e cosa vale la pena aprire.',
                            en:
                                'A quick selection to see where activity is happening and what is worth opening.',
                          ),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(color: AppColors.steel),
                        ),
                        const SizedBox(height: 18),
                        if (featuredEventsAsync.isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          ...featuredEventsAsync.maybeWhen(
                            data: (events) => events.map(
                              (event) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _EventCard(
                                  onTap: () => _openEventDetail(context, event.id),
                                  onShare: () =>
                                      _handleSharePressed(context, event.id),
                                  date: event.date,
                                  title: event.title,
                                  location: event.location,
                                  note: event.note,
                                  badge: event.badge,
                                  imageSource: null,
                                  imageCount: 0,
                                  creatorLabel: event.creatorLabel,
                                  primaryLabel: currentUser == null
                                      ? _localeText(
                                          context,
                                          it: 'Accedi per vedere il dettaglio',
                                          en: 'Sign in to view details',
                                        )
                                      : l10n.eventsOpenAction,
                                ),
                              ),
                            ).toList(),
                            orElse: () => const [],
                          ),
                          if (featuredEventsAsync.maybeWhen(
                                data: (e) => e.isEmpty,
                                orElse: () => false,
                              ))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                _localeText(
                                  context,
                                  it: 'Nessun evento in programma al momento.',
                                  en: 'No upcoming events at the moment.',
                                ),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.steel),
                              ),
                            ),
                        ],
                      ],
                    ),
                    secondChild: const SizedBox.shrink(),
                    crossFadeState: _featuredExpanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 180),
                    firstCurve: Curves.easeOut,
                    secondCurve: Curves.easeOut,
                    sizeCurve: Curves.easeOut,
                  ),
                  if (!_featuredExpanded) ...[
                    const SizedBox(height: 8),
                    Text(
                      featuredEventsAsync.maybeWhen(
                        data: (events) => _localeText(
                          context,
                          it: '${events.length} eventi nascosti',
                          en: '${events.length} hidden events',
                        ),
                        orElse: () => _localeText(
                          context,
                          it: 'Sezione chiusa',
                          en: 'Section collapsed',
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.steel,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          // ── I tuoi eventi attivi ──────────────────────────────────────────
          if (customEvents.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.eventsCreatedByYouTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    ...customEvents.map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _EventCard(
                          onTap: () => _openEventDetail(context, event.id),
                          onShare: () => _handleSharePressed(context, event.id),
                          onEdit: () => _openEditEventDialog(context, event),
                          date: event.date,
                          endDate: event.endsAt != null
                              ? MaterialLocalizations.of(context)
                                    .formatShortMonthDay(event.endsAt!.toLocal())
                              : null,
                          title: event.title,
                          location: event.location,
                          note: event.note,
                          badge: l10n.eventsPublicBadge,
                          imageSource: event.imageSource,
                          imageCount: event.imageUrls.length,
                          creatorLabel: event.creatorLabel,
                          primaryLabel: currentUser == null
                              ? _localeText(
                                  context,
                                  it: 'Accedi per vedere il dettaglio',
                                  en: 'Sign in to view details',
                                )
                              : l10n.eventsOpenAction,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 18),
          _PastEventsSection(
            eventsAsync: pastEventsAsync,
            expanded: _archiveExpanded,
            isSignedIn: currentUser != null,
            onExpansionChanged: (value) {
              setState(() {
                _archiveExpanded = value;
              });
            },
            onOpen: (eventId) => _openEventDetail(context, eventId),
            onShare: (eventId) => _handleSharePressed(context, eventId),
          ),
        ],
      ),
    );
  }

  void _handleCreatePressed(BuildContext context, Object? currentUser) {
    if (currentUser == null) {
      context.go('/login?redirect=${Uri.encodeComponent('/events')}');
      return;
    }
    _openCreateEventDialog(context);
  }

  void _openEventDetail(BuildContext context, String eventId) {
    context.go('/event/$eventId');
  }

  void _handleSharePressed(BuildContext context, String eventId) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      context.go('/login?redirect=${Uri.encodeComponent('/event/$eventId')}');
      return;
    }
    _shareEvent(context, eventId);
  }

  Future<void> _openCreateEventDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    // Usa effectiveUserId/Profile per supportare correttamente l'impersonazione:
    // quando l'admin osserva Claudia Ferri, l'evento risulta di Claudia.
    final effectiveUserId = ref.read(effectiveUserIdProvider);
    final effectiveUser = ref.read(currentUserProvider); // per email fallback
    final profile = ref
        .read(effectiveUserProfileProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final uploadService = ref.read(mediaUploadServiceProvider);
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final venueController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    DateTime? selectedEndDate;
    var pickedImages = <String>[];
    var isUploadingImages = false;
    MediaUploadBatchState? imageTransferState;

    final created = await showDialog<CreatedEventRecord>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.eventsCreateDialogTitle),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: l10n.eventsCreateTitleLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: locationController,
                        decoration: InputDecoration(
                          labelText: l10n.eventsCreateLocationLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: venueController,
                        decoration: InputDecoration(
                          labelText: l10n.eventsCreateVenueLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l10n.eventsCreateNoteLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: isUploadingImages
                                ? null
                                : () async {
                                    final remaining =
                                        maxEventImages - pickedImages.length;
                                    if (remaining <= 0) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _localeText(
                                              context,
                                              it:
                                                  'Hai raggiunto il massimo di 5 foto per evento.',
                                              en:
                                                  'You reached the maximum of 5 photos per event.',
                                            ),
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    if (uploadService == null || effectiveUserId == null) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _localeText(
                                              context,
                                              it: 'Devi essere autenticato per caricare immagini.',
                                              en: 'You must be signed in to upload images.',
                                            ),
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    setDialogState(() {
                                      isUploadingImages = true;
                                      imageTransferState = null;
                                    });
                                    final uploadingEventPhotosLabel =
                                        _localeText(
                                      context,
                                      it: 'Sto caricando le foto evento',
                                      en: 'Uploading event photos',
                                    );
                                    final picked =
                                        await FilePicker.platform.pickFiles(
                                          type: FileType.image,
                                          allowMultiple: true,
                                          withData: true,
                                        );
                                    if (picked == null) {
                                      setDialogState(() {
                                        isUploadingImages = false;
                                        imageTransferState = null;
                                      });
                                      return;
                                    }
                                    final selectedFiles = picked.files
                                        .take(remaining)
                                        .toList(growable: false);
                                    final uploadController =
                                        MediaUploadController(
                                          totalItems: selectedFiles.length,
                                          initialStageLabel:
                                              uploadingEventPhotosLabel,
                                        );
                                    setDialogState(() {
                                      imageTransferState =
                                          uploadController.snapshot;
                                    });
                                    final nextImages = <String>[];
                                    String? lastError;
                                    for (
                                      var index = 0;
                                      index < selectedFiles.length;
                                      index++
                                    ) {
                                      final bytes = selectedFiles[index].bytes;
                                      if (bytes == null) {
                                        uploadController.markError(index);
                                        if (context.mounted) {
                                          setDialogState(() {
                                            imageTransferState =
                                                uploadController.snapshot;
                                          });
                                        }
                                        continue;
                                      }
                                      try {
                                        final result = await uploadService.uploadImage(
                                          bytes: bytes,
                                          userId: effectiveUserId,
                                          entityType: 'events',
                                          filePrefix: 'photo',
                                          onProgress: (stage, progress) {
                                            if (!context.mounted) return;
                                            uploadController.setStageLabel(
                                              mediaUploadStageLabel(context, stage),
                                            );
                                            uploadController.updateItem(
                                              index: index,
                                              stage: stage,
                                              progress: progress,
                                            );
                                            setDialogState(() {
                                              imageTransferState =
                                                  uploadController.snapshot;
                                            });
                                          },
                                        );
                                        nextImages.add(result.publicUrl);
                                        uploadController.markDone(index);
                                      } on MediaUploadException catch (e) {
                                        lastError = e.message;
                                        uploadController.markError(index);
                                      } catch (e) {
                                        lastError = 'Errore caricamento foto ${index + 1}';
                                        uploadController.markError(index);
                                      }
                                      if (context.mounted) {
                                        setDialogState(() {
                                          imageTransferState =
                                              uploadController.snapshot;
                                        });
                                      }
                                    }
                                    if (!context.mounted) {
                                      return;
                                    }
                                    setDialogState(() {
                                      isUploadingImages = false;
                                      pickedImages = [
                                        ...pickedImages,
                                        ...nextImages,
                                      ].take(maxEventImages).toList();
                                      imageTransferState = null;
                                    });
                                    if (nextImages.isEmpty && lastError != null) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text(lastError)),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(l10n.eventsCreateImageAction),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _localeText(
                              context,
                              it: '${pickedImages.length}/5 foto',
                              en: '${pickedImages.length}/5 photos',
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.steel),
                          ),
                        ],
                      ),
                      if (isUploadingImages) ...[
                        const SizedBox(height: 10),
                        ImageTransferProgressCard(
                          label: _localeText(
                            context,
                            it: 'Preparazione foto evento',
                            en: 'Preparing event photos',
                          ),
                          batchState: imageTransferState,
                          icon: Icons.photo_library_outlined,
                        ),
                      ],
                      if (pickedImages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 112,
                          child: ListView.separated(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: pickedImages.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final image = pickedImages[index];
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SizedBox(
                                      width: 140,
                                      child: AdaptiveImage(
                                        source: image,
                                        fit: BoxFit.cover,
                                        fallback: const ColoredBox(
                                          color: Color(0xFFF2F4F7),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: InkWell(
                                      onTap: () {
                                        setDialogState(() {
                                          pickedImages =
                                              List<String>.from(pickedImages)
                                                ..removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // ── Data inizio ───────────────────────────────────
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.eventsCreateDateLabel),
                        subtitle: Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(selectedDate),
                        ),
                        trailing: const Icon(Icons.calendar_today_outlined),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 1),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                              if (selectedEndDate != null &&
                                  selectedEndDate!.isBefore(picked)) {
                                selectedEndDate = null;
                              }
                            });
                          }
                        },
                      ),
                      // ── Data fine (opzionale) ─────────────────────────
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _localeText(
                            context,
                            it: 'Data fine (opzionale)',
                            en: 'End date (optional)',
                          ),
                        ),
                        subtitle: Text(
                          selectedEndDate != null
                              ? MaterialLocalizations.of(
                                  context,
                                ).formatMediumDate(selectedEndDate!)
                              : _localeText(
                                  context,
                                  it: 'Stesso giorno',
                                  en: 'Same day',
                                ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selectedEndDate != null)
                              IconButton(
                                onPressed: () =>
                                    setDialogState(() => selectedEndDate = null),
                                icon: const Icon(Icons.clear, size: 18),
                              ),
                            const Icon(Icons.event_outlined),
                          ],
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedEndDate ??
                                selectedDate.add(const Duration(days: 1)),
                            firstDate: selectedDate,
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedEndDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                MaterialLocalizations.of(dialogContext).cancelButtonLabel,
              ),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                final location = locationController.text.trim();
                if (title.isEmpty || location.isEmpty) {
                  return;
                }
                Navigator.of(dialogContext).pop(
                  CreatedEventRecord(
                    id: 'created-${DateTime.now().microsecondsSinceEpoch}',
                    date: MaterialLocalizations.of(
                      dialogContext,
                    ).formatShortMonthDay(selectedDate),
                    title: title,
                    location: location,
                    note: noteController.text.trim().isEmpty
                        ? l10n.eventsCreateDefaultNote
                        : noteController.text.trim(),
                    badge: l10n.eventsBadgeCommunity,
                    creatorLabel: _resolveCreatorLabel(
                      currentUserEmail: effectiveUser?.email,
                      displayName: profile?.displayName,
                      role: profile?.role ?? 'user',
                    ),
                    creatorRole: profile?.role ?? 'user',
                    authorUserId: effectiveUserId,
                    venue: venueController.text.trim(),
                    imageUrls: pickedImages,
                    startsAtIso: selectedDate.toIso8601String(),
                    endsAtIso: selectedEndDate?.toIso8601String(),
                  ),
                );
              },
              child: Text(l10n.eventsCreateSave),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      titleController.dispose();
      locationController.dispose();
      venueController.dispose();
      noteController.dispose();
    });

    if (created == null || !mounted) {
      return;
    }

    ref.read(createdEventsProvider.notifier).add(created);

    messenger.showSnackBar(SnackBar(content: Text(l10n.eventsCreateSuccess)));
  }

  Future<void> _openEditEventDialog(
    BuildContext context,
    CreatedEventRecord original,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final titleController = TextEditingController(text: original.title);
    final locationController = TextEditingController(text: original.location);
    final venueController = TextEditingController(text: original.venue ?? '');
    final noteController = TextEditingController(
      text: original.note == l10n.eventsCreateDefaultNote ? '' : original.note,
    );
    DateTime selectedDate = original.startsAt?.toLocal() ??
        DateTime.now().add(const Duration(days: 7));
    DateTime? selectedEndDate = original.endsAt?.toLocal();
    var pickedImages = List<String>.from(original.imageUrls);

    final updated = await showDialog<CreatedEventRecord>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Modifica evento'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: l10n.eventsCreateTitleLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: locationController,
                        decoration: InputDecoration(
                          labelText: l10n.eventsCreateLocationLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: venueController,
                        decoration: InputDecoration(
                          labelText: l10n.eventsCreateVenueLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l10n.eventsCreateNoteLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.eventsCreateDateLabel),
                        subtitle: Text(
                          MaterialLocalizations.of(context).formatMediumDate(selectedDate),
                        ),
                        trailing: const Icon(Icons.calendar_today_outlined),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                              if (selectedEndDate != null &&
                                  selectedEndDate!.isBefore(picked)) {
                                selectedEndDate = null;
                              }
                            });
                          }
                        },
                      ),
                      // ── Data fine (opzionale) ─────────────────────────
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _localeText(
                            context,
                            it: 'Data fine (opzionale)',
                            en: 'End date (optional)',
                          ),
                        ),
                        subtitle: Text(
                          selectedEndDate != null
                              ? MaterialLocalizations.of(
                                  context,
                                ).formatMediumDate(selectedEndDate!)
                              : _localeText(
                                  context,
                                  it: 'Stesso giorno',
                                  en: 'Same day',
                                ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selectedEndDate != null)
                              IconButton(
                                onPressed: () =>
                                    setDialogState(() => selectedEndDate = null),
                                icon: const Icon(Icons.clear, size: 18),
                              ),
                            const Icon(Icons.event_outlined),
                          ],
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedEndDate ??
                                selectedDate.add(const Duration(days: 1)),
                            firstDate: selectedDate,
                            lastDate: DateTime.now().add(
                              const Duration(days: 730),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedEndDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                final location = locationController.text.trim();
                if (title.isEmpty || location.isEmpty) return;
                Navigator.of(dialogContext).pop(
                  CreatedEventRecord(
                    id: original.id,
                    date: MaterialLocalizations.of(dialogContext).formatShortMonthDay(selectedDate),
                    title: title,
                    location: location,
                    note: noteController.text.trim().isEmpty
                        ? l10n.eventsCreateDefaultNote
                        : noteController.text.trim(),
                    badge: original.badge,
                    creatorLabel: original.creatorLabel,
                    creatorRole: original.creatorRole,
                    authorUserId: original.authorUserId,
                    venue: venueController.text.trim(),
                    imageUrls: pickedImages,
                    startsAtIso: selectedDate.toIso8601String(),
                    endsAtIso: selectedEndDate?.toIso8601String(),
                  ),
                );
              },
              child: Text(l10n.eventsCreateSave),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      titleController.dispose();
      locationController.dispose();
      venueController.dispose();
      noteController.dispose();
    });

    if (updated == null || !mounted) return;

    ref.read(createdEventsProvider.notifier).update(updated);
    messenger.showSnackBar(
      const SnackBar(content: Text('Evento aggiornato con successo.')),
    );
  }

  static String _resolveCreatorLabel({
    required String? currentUserEmail,
    required String? displayName,
    required String role,
  }) {
    final resolvedDisplay = displayName?.trim();
    if (resolvedDisplay != null && resolvedDisplay.isNotEmpty) {
      return resolvedDisplay;
    }
    if (currentUserEmail != null && currentUserEmail.contains('@')) {
      return currentUserEmail.split('@').first;
    }
    return role;
  }

  Future<void> _shareEvent(BuildContext context, String eventId) async {
    final l10n = AppLocalizations.of(context)!;
    // Eventi locali ottimistici (id `created-…`) non sono ancora persistiti:
    // il link sarebbe morto per chiunque altro. Non condividere.
    if (eventId.startsWith('created-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento non ancora pubblicato: non condivisibile.'),
        ),
      );
      return;
    }
    final link = _eventShareLink(eventId);
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.eventsShareCopied)));
  }

  static String _eventShareLink(String eventId) {
    final base = Uri.base;
    final path = base.path.isEmpty ? '/' : base.path;
    return '${base.scheme}://${base.authority}$path#/event/$eventId';
  }

}

class _PastEventsSection extends StatelessWidget {
  const _PastEventsSection({
    required this.eventsAsync,
    required this.expanded,
    required this.isSignedIn,
    required this.onExpansionChanged,
    required this.onOpen,
    required this.onShare,
  });

  final AsyncValue<List<CreatedEventRecord>> eventsAsync;
  final bool expanded;
  final bool isSignedIn;
  final ValueChanged<bool> onExpansionChanged;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final countLabel = eventsAsync.maybeWhen(
      data: (events) => _localeText(
        context,
        it: '${events.length} eventi passati',
        en: '${events.length} past events',
      ),
      loading: () => _localeText(
        context,
        it: 'Caricamento storico...',
        en: 'Loading archive...',
      ),
      orElse: () => _localeText(
        context,
        it: 'Storico eventi pubblici',
        en: 'Public event archive',
      ),
    );

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          title: Text(
            _localeText(context, it: 'Eventi passati', en: 'Past events'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            countLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
          ),
          onExpansionChanged: onExpansionChanged,
          trailing: Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            color: AppColors.steel,
          ),
          children: [
            eventsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _localeText(
                    context,
                    it: 'Non riesco a caricare gli eventi passati.',
                    en: 'Past events cannot be loaded right now.',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                ),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _localeText(
                        context,
                        it: 'Nessun evento passato disponibile.',
                        en: 'No past events available.',
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                    ),
                  );
                }

                return Column(
                  children: events
                      .map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _EventCard(
                            onTap: () => onOpen(event.id),
                            onShare: () => onShare(event.id),
                            date: event.date,
                            endDate: event.endsAt != null
                                ? MaterialLocalizations.of(
                                    context,
                                  ).formatShortMonthDay(event.endsAt!.toLocal())
                                : null,
                            title: event.title,
                            location: event.location,
                            note: event.note,
                            badge: l10n.eventsBadgeArchived,
                            imageSource: event.imageSource,
                            imageCount: event.imageUrls.length,
                            creatorLabel: event.creatorLabel,
                            primaryLabel: isSignedIn
                                ? l10n.eventsOpenAction
                                : _localeText(
                                    context,
                                    it: 'Accedi per vedere il dettaglio',
                                    en: 'Sign in to view details',
                                  ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.onTap,
    required this.onShare,
    required this.date,
    required this.title,
    required this.location,
    required this.note,
    required this.badge,
    required this.imageSource,
    required this.imageCount,
    required this.creatorLabel,
    required this.primaryLabel,
    this.onEdit,
    this.endDate,
  });

  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback? onEdit;
  final String date;
  final String? endDate;
  final String title;
  final String location;
  final String note;
  final String badge;
  final String? imageSource;
  final int imageCount;
  final String creatorLabel;
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Build media
    final media = _EventMedia(
      imageSource: imageSource,
      date: date,
      badge: badge,
    );

    // Riga statistiche: data + luogo + organizzatore.
    final signals = <Widget>[
      CardStatRow(
        stats: [
          CardStat(icon: Icons.event_outlined, text: date),
          if (location.isNotEmpty)
            CardStat(icon: Icons.place_outlined, text: location),
          CardStat(icon: Icons.person_outline, text: creatorLabel),
        ],
      ),
    ];

    // Build footer leading CTA
    final footerLeading = FilledButton(
      onPressed: onTap,
      child: Text(primaryLabel),
    );

    // Build footer actions: edit + share
    final footerActions = <Widget>[];
    if (onEdit != null) {
      footerActions.add(
        Tooltip(
          message: 'Modifica evento',
          child: IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        ),
      );
    }
    footerActions.add(
      Tooltip(
        message: l10n.eventsShareAction,
        child: IconButton(
          onPressed: onShare,
          icon: const Icon(Icons.ios_share_outlined, size: 18),
        ),
      ),
    );

    return PlaceCard(
      media: media,
      title: title,
      overline: 'Evento',
      signals: signals,
      body: note.isNotEmpty ? note : null,
      footerLeading: footerLeading,
      footerActions: footerActions.isNotEmpty ? footerActions : null,
      onTap: onTap,
      variant: PlaceCardVariant.standard,
    );
  }
}

class _EventMedia extends StatelessWidget {
  const _EventMedia({
    required this.imageSource,
    required this.date,
    required this.badge,
  });

  final String? imageSource;
  final String date;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageSource != null && imageSource!.trim().isNotEmpty)
          AdaptiveImage(
            source: imageSource,
            fit: BoxFit.cover,
            fallback: ColoredBox(color: AppColors.surfaceMuted),
          )
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE7D8), Color(0xFFF1F4F8)],
              ),
            ),
          ),
        Positioned(
          top: AppSpacing.md,
          left: AppSpacing.md,
          child: _EventFloatingTag(
            icon: Icons.event_outlined,
            label: date,
          ),
        ),
        Positioned(
          bottom: AppSpacing.md,
          left: AppSpacing.md,
          child: _EventFloatingTag(
            icon: Icons.local_offer_outlined,
            label: badge,
          ),
        ),
      ],
    );
  }
}

class _EventFloatingTag extends StatelessWidget {
  const _EventFloatingTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.graphite),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
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
