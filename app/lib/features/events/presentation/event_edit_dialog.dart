import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/media/media_upload_controller.dart';
import '../../../shared/media/media_upload_labels.dart';
import '../../../shared/media/media_upload_service.dart';
import '../../../shared/media/media_upload_state.dart';
import '../../../shared/utils/local_image_data_url.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/dialog_controller_scope.dart';
import '../../../shared/widgets/image_transfer_progress_card.dart';
import '../../../shared/widgets/place_map_preview_card.dart';
import '../../../shared/widgets/place_picker_field.dart';
import '../../../shared/places/place_search_service.dart';
import '../../../shared/places/place_selection.dart';
import '../../auth/application/auth_providers.dart';
import '../../profile/application/profile_hub_providers.dart';
import '../application/public_events_provider.dart';
import 'package:pitlap_app/app/l10n/tr.dart';

String _localeText(
  BuildContext context, {
  required String it,
  required String en,
}) {
  return Localizations.localeOf(context).languageCode == 'it' ? it : en;
}

String get _eventSaveFailed =>
    tr('Evento NON salvato: controlla la connessione e riprova.');

/// Dialog di modifica di un evento della community (tabella community_events).
/// Lo usano l'autore (lista Eventi), l'admin dal dettaglio evento e dalla
/// dashboard: la RLS consente l'update all'autore e a is_admin().
Future<bool> showEventEditDialog(
  BuildContext context,
  WidgetRef ref,
  CreatedEventRecord original,
) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final placeSearch = ref.read(placeSearchProvider);
    final uploadService = ref.read(mediaUploadServiceProvider);
    final effectiveUserId = ref.read(effectiveUserIdProvider);
    var isUploadingImages = false;
    MediaUploadBatchState? imageTransferState;
    final titleController = TextEditingController(text: original.title);
    final locationController = TextEditingController(text: original.location);
    PlaceSelection? pickedPlace =
        original.latitude != null && original.longitude != null
            ? PlaceSelection(
                label: original.location,
                latitude: original.latitude!,
                longitude: original.longitude!,
                provider: 'saved',
                providerPlaceId: original.id,
              )
            : null;
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
        return DialogControllerScope(
          controllers: [
            titleController,
            locationController,
            venueController,
            noteController,
          ],
          child: AlertDialog(
          title: Text(tr('Modifica evento')),
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
                      PlacePickerField(
                        controller: locationController,
                        initialSelection: pickedPlace,
                        labelText: l10n.eventsCreateLocationLabel,
                        onSelected: (selection) =>
                            setDialogState(() => pickedPlace = selection),
                      ),
                      if (pickedPlace != null) ...[
                        const SizedBox(height: 12),
                        PlaceMapPreviewCard(
                          selection: pickedPlace!,
                          height: 200,
                          onPointPicked: (pin) =>
                              setDialogState(() => pickedPlace = pin),
                        ),
                      ],
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
                                                  tr('Hai raggiunto il massimo di 5 foto per evento.'),
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
                                              it: tr('Devi essere autenticato per caricare immagini.'),
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
                                      it: tr('Sto caricando le foto evento'),
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
                                        lastError = trf('Errore caricamento foto {0}', [index + 1]);
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
                              it: trf('{0}/5 foto', [pickedImages.length]),
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
                            it: tr('Preparazione foto evento'),
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
                            it: tr('Data fine (opzionale)'),
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
                                  it: tr('Stesso giorno'),
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
              onPressed: () async {
                final title = titleController.text.trim();
                final location = locationController.text.trim();
                if (title.isEmpty || location.isEmpty) return;
                pickedPlace ??= await resolvePlaceText(placeSearch, location);
                if (!dialogContext.mounted) return;
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
                    latitude: pickedPlace?.latitude,
                    longitude: pickedPlace?.longitude,
                  ),
                );
              },
              child: Text(l10n.eventsCreateSave),
            ),
          ],
          ),
        );
      },
    );

    // dispose affidato a DialogControllerScope: un solo postFrameCallback non
    // basta, la route resta montata per tutta l'animazione di uscita.

    if (updated == null || !context.mounted) return false;

    final saved = await ref.read(createdEventsProvider.notifier).update(updated);
    ref.invalidate(publicEventDetailProvider(original.id));
    ref.invalidate(publicUpcomingEventsProvider);
    ref.invalidate(publicPastEventsProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(saved ? tr('Evento aggiornato con successo.') : _eventSaveFailed),
      ),
    );
    return saved;
}
