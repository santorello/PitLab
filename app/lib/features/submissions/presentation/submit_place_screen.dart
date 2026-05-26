import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/media/media_upload_controller.dart';
import '../../../shared/media/media_upload_labels.dart';
import '../../../shared/media/media_upload_state.dart';
import '../../../shared/places/place_selection.dart';
import '../../../shared/utils/local_image_data_url.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/image_transfer_progress_card.dart';
import '../../../shared/widgets/place_map_preview_card.dart';
import '../../../shared/widgets/place_picker_field.dart';
import '../../../shared/widgets/processing_status_badge.dart';
import '../../auth/application/auth_providers.dart';
import '../../../shared/models/submitted_track.dart';
import '../../spots/application/spots_providers.dart';
import '../../tracks/application/tracks_providers.dart';
import '../../spots/domain/spot_catalog.dart';

class SubmitPlaceScreen extends ConsumerStatefulWidget {
  const SubmitPlaceScreen({
    this.initialType = 'track',
    this.initialSpotSlug,
    super.key,
  });

  final String initialType;
  final String? initialSpotSlug;

  @override
  ConsumerState<SubmitPlaceScreen> createState() => _SubmitPlaceScreenState();
}

class _SubmitPlaceScreenState extends ConsumerState<SubmitPlaceScreen> {
  late String _submissionType;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  List<String> _pickedImages = <String>[];
  bool _isUploadingImages = false;
  MediaUploadBatchState? _imageTransferState;
  bool _isResolvingLocation = false;
  double? _latitude;
  double? _longitude;
  PlaceSelection? _selectedSpotPlace;
  bool _spotDraftLoaded = false;

  @override
  void initState() {
    super.initState();
    _submissionType = switch (widget.initialType) {
      'spot' || 'shop' || 'track' => widget.initialType,
      _ => 'track',
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final impersonation = ref.watch(impersonationProvider);
    final effectiveUserId = impersonation?.userId ?? currentUser?.id;
    final existingSpot = widget.initialSpotSlug == null
        ? null
        : SpotCatalog.bySlug(
            widget.initialSpotSlug!,
            ref.watch(spotEntriesProvider),
          );
    if (!_spotDraftLoaded &&
        _submissionType == 'spot' &&
        widget.initialSpotSlug != null &&
        existingSpot != null) {
      _spotDraftLoaded = true;
      _nameController.text = existingSpot.title;
      _cityController.text = existingSpot.city;
      _descriptionController.text = existingSpot.note;
      _videoUrlController.text = existingSpot.videoUrl ?? '';
      _addressController.text = existingSpot.address ?? '';
      _pickedImages = List<String>.from(existingSpot.imageUrls);
      _latitude = existingSpot.latitude;
      _longitude = existingSpot.longitude;
      if (existingSpot.latitude != null && existingSpot.longitude != null) {
        _selectedSpotPlace = PlaceSelection(
          label:
              existingSpot.address ??
              '${existingSpot.title}, ${existingSpot.city}',
          latitude: existingSpot.latitude!,
          longitude: existingSpot.longitude!,
          provider: 'pitlap',
          providerPlaceId: existingSpot.id ?? existingSpot.slug,
          title: existingSpot.title,
          subtitle: existingSpot.city,
          city: existingSpot.city,
          address: existingSpot.address,
        );
      }
    }
    final isEditingSpot =
        _submissionType == 'spot' && widget.initialSpotSlug != null;
    final canEditExistingSpot = existingSpot == null ||
        (isAdmin && impersonation == null) ||
        (effectiveUserId != null && existingSpot.isOwnedByCurrentUser);
    return ContentScaffold(
      title: isEditingSpot
          ? _localeText(
              context,
              it: 'Modifica spot',
              en: 'Edit spot',
            )
          : l10n.submitPlaceTitle,
      description: isEditingSpot
          ? _localeText(
              context,
              it: 'Aggiorna foto, posizione e dettagli del tuo spot.',
              en: 'Update photos, location, and details for your spot.',
            )
          : l10n.submitPlaceDescription,
      child: ListView(
        children: [
          if (isEditingSpot && !canEditExistingSpot) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  _localeText(
                    context,
                    it: 'Questo spot puo\' essere modificato solo dall\'owner o da un admin.',
                    en: 'This spot can only be edited by its owner or an admin.',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
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
                    '📬 Invia una segnalazione',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.submissionHeroTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.graphite,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.submissionHeroBody,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.steel,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _submissionType,
            items: [
              DropdownMenuItem(value: 'track', child: Text(l10n.submissionTypeTrack)),
              DropdownMenuItem(value: 'spot', child: Text(l10n.submissionTypeSpot)),
              DropdownMenuItem(value: 'shop', child: Text(l10n.submissionTypeShop)),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _submissionType = value;
              });
            },
            decoration: InputDecoration(labelText: '🔖 ${l10n.submissionTypeLabel}'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: '📝 ${l10n.submissionPlaceName}'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cityController,
            decoration: InputDecoration(labelText: '🏙️ ${l10n.submissionCity}'),
          ),
          const SizedBox(height: 16),
          if (_submissionType == 'spot') ...[
            PlacePickerField(
              controller: _addressController,
              initialSelection: _selectedSpotPlace,
              labelText: _localeText(
                context,
                it: 'Indirizzo / punto mappa',
                en: 'Address / map point',
              ),
              hintText: _localeText(
                context,
                it: 'Cerca un luogo reale e scegli dalla lista',
                en: 'Search a real place and pick from the list',
              ),
              emptyInfoText: _localeText(
                context,
                it: 'Puoi cercare un luogo canonico oppure compilare manualmente e usare la posizione attuale.',
                en: 'You can search a canonical place or fill manually and use your current location.',
              ),
              verifiedInfoBuilder: (selection) => _localeText(
                context,
                it: 'Luogo verificato: ${selection.label}. Coordinate pronte per la mappa.',
                en: 'Verified place: ${selection.label}. Coordinates are ready for the map.',
              ),
              types: const <String>[
                'address',
                'road',
                'locality',
                'place',
                'municipality',
              ],
              onSelected: (selection) {
                setState(() {
                  _selectedSpotPlace = selection;
                  _latitude = selection?.latitude;
                  _longitude = selection?.longitude;
                  final resolvedCity =
                      selection?.city?.trim() ??
                      selection?.region?.trim() ??
                      '';
                  if (resolvedCity.isNotEmpty) {
                    _cityController.text = resolvedCity;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _isResolvingLocation
                      ? null
                      : () => _fillSpotLocationFromDevice(context),
                  icon: const Icon(Icons.my_location_outlined),
                  label: Text(
                    _localeText(
                      context,
                      it: 'Usa posizione attuale',
                      en: 'Use current location',
                    ),
                  ),
                ),
                if (_latitude != null && _longitude != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F7F3),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.concrete),
                    ),
                    child: Text(
                      _localeText(
                        context,
                        it:
                            'GPS ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                        en:
                            'GPS ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                      ),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
              ],
            ),
            if (_isResolvingLocation) ...[
              const SizedBox(height: 12),
              ProcessingStatusBadge(
                label: _localeText(
                  context,
                  it: 'Recupero coordinate e indirizzo in corso',
                  en: 'Resolving coordinates and address',
                ),
                icon: Icons.location_searching_outlined,
              ),
            ],
            if (_selectedSpotPlace != null) ...[
              const SizedBox(height: 12),
              PlaceMapPreviewCard(selection: _selectedSpotPlace!, height: 190),
            ],
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(labelText: l10n.submissionDescription),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _videoUrlController,
            decoration: InputDecoration(
              labelText: _localeText(
                context,
                it: 'Link YouTube o video opzionale',
                en: 'Optional YouTube or video link',
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _localeText(
                      context,
                      it: 'Foto dal dispositivo',
                      en: 'Photos from device',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _localeText(
                      context,
                       it: 'Carica fino a 5 foto locali. La prima foto verra\' usata anche come cover della card spot.',
                       en: 'Upload up to 5 local photos. The first photo will also be used as the spot card cover.',
                     ),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonalIcon(
                    onPressed: _isUploadingImages ? null : () => _pickImages(context),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      _localeText(
                        context,
                        it: 'Carica foto',
                        en: 'Upload photos',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _localeText(
                      context,
                      it: '${_pickedImages.length}/5 foto selezionate',
                      en: '${_pickedImages.length}/5 photos selected',
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.steel),
                  ),
                  if (_isUploadingImages) ...[
                    const SizedBox(height: 12),
                    ImageTransferProgressCard(
                      label: _localeText(
                        context,
                        it: 'Preparazione foto in corso',
                        en: 'Preparing photos',
                      ),
                      batchState: _imageTransferState,
                      icon: Icons.photo_library_outlined,
                    ),
                  ],
                  if (_pickedImages.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _pickedImages.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final image = _pickedImages[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  width: 120,
                                  child: AdaptiveImage(
                                    source: image,
                                    fit: BoxFit.cover,
                                    fallback: const ColoredBox(
                                      color: Color(0xFFEDEFF3),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 6,
                                top: 6,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _pickedImages = List<String>.from(_pickedImages)
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
                                      color: Colors.white,
                                      size: 16,
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.submissionWhatHelpsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.submissionWhatHelpsBody,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.steel,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: () => unawaited(_submit(context)),
              child: Text(
                isEditingSpot
                    ? _localeText(
                        context,
                        it: 'Salva modifiche spot',
                        en: 'Save spot changes',
                      )
                    : l10n.submissionSendButton,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final isEditingSpot =
        _submissionType == 'spot' && widget.initialSpotSlug != null;
    final name = _nameController.text.trim();
    final city = _cityController.text.trim();
    final description = _descriptionController.text.trim();
    final videoUrl = _videoUrlController.text.trim();
    // Pre-cattura messaggio successo prima di qualsiasi await (usa context)
    final successMessage = isEditingSpot
        ? _localeText(
            context,
            it: 'Spot aggiornato con successo.',
            en: 'Spot updated successfully.',
          )
        : l10n.submissionSendSuccess(name, city);
    if (name.isEmpty || city.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.submissionMissingFields)),
      );
      return;
    }

    if (_submissionType == 'spot') {
      final currentUser = ref.read(currentUserProvider);
      final isAdmin = ref.read(isAdminProvider);
      final impersonation = ref.read(impersonationProvider);
      final effectiveUserId = impersonation?.userId ?? currentUser?.id;
      final existingSpot = widget.initialSpotSlug == null
          ? null
          : SpotCatalog.bySlug(
              widget.initialSpotSlug!,
              ref.read(spotEntriesProvider),
            );
      final canEditExistingSpot = existingSpot == null ||
          (isAdmin && impersonation == null) ||
          (effectiveUserId != null && existingSpot.isOwnedByCurrentUser);
      if (!canEditExistingSpot) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _localeText(
                context,
                it: 'Non puoi modificare questo spot.',
                en: 'You cannot edit this spot.',
              ),
            ),
          ),
        );
        return;
      }
      final slug = existingSpot?.slug ?? SpotCatalog.createSlug(name, city);
      final customSpot = SpotEntry(
        slug: slug,
        title: name,
        city: city,
        category: existingSpot?.category ??
            _localeText(
              context,
              it: 'Community',
              en: 'Community',
            ),
        bestFor: existingSpot?.bestFor ??
            _localeText(
              context,
              it: 'Spot condiviso dagli utenti',
              en: 'Community-submitted spot',
            ),
        surface: existingSpot?.surface ??
            _localeText(
              context,
              it: 'Dettagli da confermare',
              en: 'Details to be confirmed',
            ),
        note: description.isEmpty
            ? _localeText(
                context,
                it: 'Nuovo spot condiviso dalla community PitLap.',
                en: 'New spot shared by the PitLap community.',
              )
            : description,
        imageAccent: existingSpot?.imageAccent ?? AppColors.signalOrange,
        photoCount: _pickedImages.length,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        imageUrls: _pickedImages,
        videoUrl: videoUrl.isEmpty ? null : videoUrl,
        isCustom: true,
        isOwnedByCurrentUser: true,
      );
      final remoteUnavailableMessage = _localeText(
        context,
        it:
            'Supabase non disponibile: lo spot non e stato salvato in modo permanente.',
        en: 'Supabase unavailable: the spot was not saved permanently.',
      );
      final savedRemotely = isEditingSpot
          ? await ref
              .read(spotEntriesProvider.notifier)
              .updateCustomSpot(customSpot)
          : await ref
              .read(spotEntriesProvider.notifier)
              .addCustomSpot(customSpot);
      if (!savedRemotely) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(remoteUnavailableMessage),
          ),
        );
        return;
      }
    } else if (_submissionType == 'track') {
      final currentUser = ref.read(currentUserProvider);
      final repository = ref.read(tracksRepositoryProvider);
      if (currentUser != null && repository != null) {
        // data-URL da picker locale non vengono salvati su Supabase
        final coverUrl = _pickedImages.isNotEmpty &&
                _pickedImages.first.startsWith('http')
            ? _pickedImages.first
            : null;
        final track = SubmittedTrack(
          id: '',
          slug: SpotCatalog.createSlug(name, city),
          name: name,
          city: city,
          shortDescription: description.isEmpty
              ? 'Nuova pista inserita dal gestore e pronta per il completamento.'
              : description,
          approvalStatus: 'draft',
          imageUrl: coverUrl,
        );
        try {
          await repository.insertSubmittedTrack(
            submittedBy: currentUser.id,
            track: track,
          );
          if (!mounted) return;
          ref.invalidate(submittedTracksProvider);
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(content: Text('Errore nel salvataggio pista: $e')),
          );
          return;
        }
      }
    }

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(successMessage)),
    );

    final destination = switch (_submissionType) {
      'spot' => widget.initialSpotSlug == null
          ? '/spots'
          : '/spot/${widget.initialSpotSlug}',
      'shop' => '/shops',
      'track' => '/manager',
      _ => '/',
    };
    router.go(destination);
  }

  Future<void> _pickImages(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (_pickedImages.length >= maxEventImages) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _localeText(
              context,
              it: 'Hai già raggiunto il massimo di 5 foto.',
              en: 'You already reached the maximum of 5 photos.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isUploadingImages = true;
      _imageTransferState = null;
    });

    final remaining = maxEventImages - _pickedImages.length;
    final preparingImagesLabel = _localeText(
      context,
      it: 'Sto preparando le foto selezionate',
      en: 'Preparing selected photos',
    );
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (!mounted) {
      return;
    }

    if (picked == null) {
      setState(() {
        _isUploadingImages = false;
        _imageTransferState = null;
      });
      return;
    }

    final selectedFiles = picked.files.take(remaining).toList(growable: false);
    final uploadController = MediaUploadController(
      totalItems: selectedFiles.length,
      initialStageLabel: preparingImagesLabel,
    );
    setState(() {
      _imageTransferState = uploadController.snapshot;
    });

    final nextImages = <String>[];
    LocalImageDataUrlFailure? lastFailure;
    for (var index = 0; index < selectedFiles.length; index++) {
      final file = selectedFiles[index];
      final bytes = file.bytes;
      if (bytes == null) {
        uploadController.markError(index);
        if (mounted) {
          setState(() {
            _imageTransferState = uploadController.snapshot;
          });
        }
        continue;
      }
      final result = await localImageDataUrlResultFromBytes(
        bytes: bytes,
        onProgress: (stage, progress) {
          if (!mounted) {
            return;
          }
          uploadController.setStageLabel(mediaUploadStageLabel(context, stage));
          uploadController.updateItem(
            index: index,
            stage: stage,
            progress: progress,
          );
          setState(() {
            _imageTransferState = uploadController.snapshot;
          });
        },
      );
      final dataUrl = result.dataUrl;
      if (dataUrl == null) {
        lastFailure = result.failure;
        uploadController.markError(index);
        if (mounted) {
          setState(() {
            _imageTransferState = uploadController.snapshot;
          });
        }
        continue;
      }
      nextImages.add(dataUrl);
      uploadController.markDone(index);
      if (mounted) {
        setState(() {
          _imageTransferState = uploadController.snapshot;
        });
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isUploadingImages = false;
      _pickedImages = [..._pickedImages, ...nextImages].take(maxEventImages).toList();
      _imageTransferState = null;
    });

    if (nextImages.isEmpty && lastFailure != null) {
      final errorMessage = _imageUploadErrorMessage(l10n, lastFailure);
      messenger.showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> _fillSpotLocationFromDevice(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final permissionDeniedMessage = _localeText(
      context,
      it: 'Permesso posizione non concesso.',
      en: 'Location permission not granted.',
    );
    final successMessage = _localeText(
      context,
      it: 'Posizione rilevata e campi compilati automaticamente.',
      en: 'Location detected and fields filled automatically.',
    );
    setState(() {
      _isResolvingLocation = true;
    });

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(permissionDeniedMessage);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final placemark = await _safePlacemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final city = [
        placemark?.locality,
        placemark?.subAdministrativeArea,
      ].whereType<String>().firstWhere(
        (value) => value.trim().isNotEmpty,
        orElse: () => '',
      );
      final address = [
        placemark?.street,
        placemark?.subLocality,
        placemark?.postalCode,
        placemark?.locality,
      ].whereType<String>().map((value) => value.trim()).where(
        (value) => value.isNotEmpty,
      ).join(', ');

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedSpotPlace = PlaceSelection(
          label: address.isNotEmpty
              ? address
              : '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
          latitude: position.latitude,
          longitude: position.longitude,
          provider: 'device',
          providerPlaceId: 'device-current',
          title: city.isNotEmpty ? city : null,
          subtitle: address.isNotEmpty ? address : null,
          city: city.isNotEmpty ? city : null,
          address: address.isNotEmpty ? address : null,
        );
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (city.isNotEmpty) {
          _cityController.text = city;
        }
        if (address.isNotEmpty) {
          _addressController.text = address;
        }
        if (_nameController.text.trim().isEmpty && placemark != null) {
          final candidateName = [
            placemark.name,
            placemark.street,
            placemark.subLocality,
          ].whereType<String>().map((value) => value.trim()).firstWhere(
            (value) => value.isNotEmpty,
            orElse: () => '',
          );
          if (candidateName.isNotEmpty) {
            _nameController.text = candidateName;
          }
        }
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(successMessage),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingLocation = false;
        });
      }
    }
  }
}

Future<Placemark?> _safePlacemarkFromCoordinates(
  double latitude,
  double longitude,
) async {
  try {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    return placemarks.isEmpty ? null : placemarks.first;
  } catch (error) {
    debugPrint('[SubmitPlace] Reverse geocoding unavailable: $error');
    return null;
  }
}

String _imageUploadErrorMessage(
  AppLocalizations l10n,
  LocalImageDataUrlFailure? failure,
) {
  return switch (failure) {
    LocalImageDataUrlFailure.inputTooLarge ||
    LocalImageDataUrlFailure.outputTooLarge =>
      l10n.imageUploadTooLargeMessage,
    _ => l10n.imageUploadUnreadableMessage,
  };
}

String _localeText(
  BuildContext context, {
  required String it,
  required String en,
}) {
  return Localizations.localeOf(context).languageCode == 'it' ? it : en;
}
