import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/media/media_upload_controller.dart';
import '../../../shared/media/media_upload_labels.dart';
import '../../../shared/media/media_upload_state.dart';
import '../../../shared/utils/local_image_data_url.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/external_links_section.dart';
import '../../../shared/widgets/image_transfer_progress_card.dart';
import '../../auth/application/auth_providers.dart';
import '../application/shop_permissions_providers.dart';
import '../application/shop_editor_providers.dart';

class ShopEditorScreen extends ConsumerStatefulWidget {
  const ShopEditorScreen({
    required this.slug,
    this.isCreating = false,
    super.key,
  });

  final String slug;
  final bool isCreating;

  @override
  ConsumerState<ShopEditorScreen> createState() => _ShopEditorScreenState();
}

class _ShopEditorScreenState extends ConsumerState<ShopEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _websiteController;
  late final TextEditingController _organizationController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _galleryController;
  late final TextEditingController _serviceLabelsController;
  late final TextEditingController _contactsController;
  late final TextEditingController _hoursController;
  late final TextEditingController _notesController;
  bool _hydrated = false;
  bool _uploadingCover = false;
  bool _uploadingGallery = false;
  MediaUploadBatchState? _coverTransferState;
  MediaUploadBatchState? _galleryTransferState;
  String _localCoverImage = '';
  List<String> _localGalleryImages = const [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _subtitleController = TextEditingController();
    _cityController = TextEditingController();
    _addressController = TextEditingController();
    _websiteController = TextEditingController();
    _organizationController = TextEditingController();
    _imageUrlController = TextEditingController();
    _galleryController = TextEditingController();
    _serviceLabelsController = TextEditingController();
    _contactsController = TextEditingController();
    _hoursController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nameController.text.isNotEmpty) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    if (widget.isCreating) {
      _hoursController.text = 'Sab-Dom - 09:30-18:30';
      _hydrated = true;
      return;
    }
    // Per editor di shop esistenti: fetch deterministico del draft o del negozio reale.
    // editableShopOrPublishedProvider gestisce sia il cache locale che il fetch da DB.
    // Nota: didChangeDependencies è sincrono, quindi leggiamo solo dal editableShopProvider
    // (cache senza rete). Per il fetch async, useremo build() con ref.listen().
    final stored = ref.read(editableShopProvider(widget.slug));
    if (stored != null) {
      _hydrated = true;
      _nameController.text = stored.name;
      _subtitleController.text = stored.subtitle;
      _cityController.text = stored.city;
      _addressController.text = stored.address;
      _websiteController.text = stored.website;
      _organizationController.text = stored.organizationName;
      _syncImageFields(stored.imageUrl, stored.galleryImages);
      _serviceLabelsController.text = stored.serviceLabels.join('\n');
      _contactsController.text = stored.contacts;
      _hoursController.text = stored.hours;
      _notesController.text = stored.notes;
      return;
    }
    // Fallback: non abbiamo nulla in cache, verrà ricaricato in build() tramite ref.listen()
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _organizationController.dispose();
    _imageUrlController.dispose();
    _galleryController.dispose();
    _serviceLabelsController.dispose();
    _contactsController.dispose();
    _hoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _syncImageFields(String coverImage, List<String> galleryImages) {
    final cover = coverImage.trim();
    if (isLocalImageDataUrlTooLarge(cover)) {
      _localCoverImage = '';
      _imageUrlController.text = '';
    } else if (cover.startsWith('data:image')) {
      _localCoverImage = cover;
      _imageUrlController.text = '';
    } else {
      _localCoverImage = '';
      _imageUrlController.text = cover;
    }

    final localGallery = <String>[];
    final externalGallery = <String>[];
    for (final image in galleryImages.take(maxShopGalleryImages)) {
      final value = image.trim();
      if (value.isEmpty) {
        continue;
      }
      if (isLocalImageDataUrlTooLarge(value)) {
        continue;
      }
      if (value.startsWith('data:image')) {
        localGallery.add(value);
      } else {
        externalGallery.add(value);
      }
    }
    _localGalleryImages = localGallery;
    _galleryController.text = externalGallery.join('\n');
  }

  static String _imageUploadErrorMessage(
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canEditShopAsync = ref.watch(canEditShopSlugProvider(widget.slug));
    // Nota: editableShopOrPublishedProvider è async, quindi AsyncValue.
    // Usiamo ref.listen() per sincronizzare i dati ai controller solo la prima volta.
    ref.listen<AsyncValue<EditableShopRecord?>>(
      editableShopOrPublishedProvider(widget.slug),
      (prev, next) {
        if (_hydrated) return;
        next.whenData((data) {
          if (data == null || !mounted) return;
          _hydrated = true;
          _nameController.text = data.name;
          _subtitleController.text = data.subtitle;
          _cityController.text = data.city;
          _addressController.text = data.address;
          _websiteController.text = data.website;
          _organizationController.text = data.organizationName;
          _syncImageFields(data.imageUrl, data.galleryImages);
          _serviceLabelsController.text = data.serviceLabels.join('\n');
          _contactsController.text = data.contacts;
          _hoursController.text = data.hours;
          _notesController.text = data.notes;
          if (mounted) {
            setState(() {});
          }
        });
      },
    );
    final imageUrl = _localCoverImage.isNotEmpty
        ? _localCoverImage
        : _imageUrlController.text.trim();

    // In modalita' creazione il form e' sempre accessibile a chi ha gia' superato
    // il redirect del router (`requireShopManager` sul percorso `/shops/new`):
    // bypassiamo l'AsyncValue di `canEditShopSlugProvider` che per uno slug fittizio
    // ('__new__') puo' restare in loading e nascondere l'intero form.
    final canEditShop = widget.isCreating
        ? true
        : canEditShopAsync.maybeWhen(
            data: (value) => value,
            orElse: () => false,
          );
    final galleryImages = [
      ..._galleryController.text
          .split('\n')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty),
      ..._localGalleryImages,
    ].take(maxShopGalleryImages).toList();
    final serviceLabels = _parseServiceLabels(_serviceLabelsController.text);

    return ContentScaffold(
      title: widget.isCreating ? 'Nuovo negozio' : l10n.shopDetailTitle,
      description: widget.isCreating
          ? 'Compila i campi e invia il negozio in approvazione.'
          : l10n.shopDetailDescription(_nameController.text.isNotEmpty ? _nameController.text : ''),
      child: ListView(
        children: [
          // ── Cover preview ──────────────────────────────────────────
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: AdaptiveImage(
                  source: imageUrl,
                  fit: BoxFit.cover,
                  fallback: Container(
                    color: AppColors.concrete,
                    alignment: Alignment.center,
                    child: Text(
                      l10n.shopImagePreviewUnavailable,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
            ),
          if (imageUrl.isNotEmpty) const SizedBox(height: 16),

          // ── Form principale ────────────────────────────────────────
          if (canEditShop)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.shopProfileModeTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.shopProfileModeBody,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.steel),
                    ),
                    const SizedBox(height: 20),

                    // Identità
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: l10n.shopEditNameLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _subtitleController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: l10n.shopEditSubtitleLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'Città'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Indirizzo'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _websiteController,
                      decoration: const InputDecoration(labelText: 'Sito web'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _organizationController,
                      decoration: const InputDecoration(
                        labelText: 'Società o negozio',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Cover image
                    Text(
                      'Immagine di copertina',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _imageUrlController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: l10n.shopEditImageUrlLabel,
                        hintText: 'https://...',
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final uploadController = MediaUploadController(
                          totalItems: 1,
                          initialStageLabel: 'Sto preparando la cover negozio',
                        );
                        setState(() {
                          _uploadingCover = true;
                          _coverTransferState = uploadController.snapshot;
                        });
                        final picked = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          withData: true,
                        );
                        final bytes = picked?.files.single.bytes;
                        if (bytes == null) {
                          if (mounted) {
                            setState(() {
                              _uploadingCover = false;
                              _coverTransferState = null;
                            });
                          }
                          return;
                        }
                        final imageResult =
                            await localImageDataUrlResultFromBytes(
                              bytes: bytes,
                              onProgress: (stage, progress) {
                                if (!mounted) {
                                  return;
                                }
                                uploadController.setStageLabel(
                                  mediaUploadStageLabel(context, stage),
                                );
                                uploadController.updateItem(
                                  index: 0,
                                  stage: stage,
                                  progress: progress,
                                );
                                setState(() {
                                  _coverTransferState = uploadController.snapshot;
                                });
                              },
                            );
                        if (!mounted) return;
                        if (imageResult.dataUrl == null) {
                          uploadController.markError(0);
                        } else {
                          uploadController.markDone(0);
                        }
                        setState(() {
                          _uploadingCover = false;
                          _coverTransferState = null;
                        });
                        final dataUrl = imageResult.dataUrl;
                        if (dataUrl == null) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                _imageUploadErrorMessage(
                                  l10n,
                                  imageResult.failure,
                                ),
                              ),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _localCoverImage = dataUrl;
                        });
                      },
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(l10n.shopImageUploadAction),
                    ),
                    if (_uploadingCover) ...[
                      const SizedBox(height: 10),
                      ImageTransferProgressCard(
                        label: 'Preparazione cover negozio',
                        batchState: _coverTransferState,
                        icon: Icons.image_outlined,
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Galleria
                    Text(
                      'Galleria foto',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _galleryController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: l10n.shopGalleryFieldLabel,
                        hintText: 'Un URL per riga',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.shopGalleryLimitHint(
                        galleryImages.length,
                        maxShopGalleryImages,
                      ),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.steel),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() {
                          _uploadingGallery = true;
                          _galleryTransferState = null;
                        });
                        final picked = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          withData: true,
                          allowMultiple: true,
                        );
                        final files = picked?.files ?? const [];
                        if (files.isEmpty) {
                          if (mounted) {
                            setState(() {
                              _uploadingGallery = false;
                              _galleryTransferState = null;
                            });
                          }
                          return;
                        }
                        final existingCount = galleryImages.length;
                        final remainingSlots =
                            maxShopGalleryImages - existingCount;
                        if (remainingSlots <= 0) {
                          setState(() {
                            _uploadingGallery = false;
                            _galleryTransferState = null;
                          });
                          return;
                        }
                        final takeCount =
                            remainingSlots < maxLocalGalleryImages
                            ? remainingSlots
                            : maxLocalGalleryImages;
                        final uploadController = MediaUploadController(
                          totalItems: takeCount,
                          initialStageLabel:
                              'Sto preparando la galleria negozio',
                        );
                        setState(() {
                          _galleryTransferState = uploadController.snapshot;
                        });
                        final dataUrls = <String>[];
                        LocalImageDataUrlFailure? lastFailure;
                        var index = 0;
                        for (final file in files.take(takeCount)) {
                          final itemIndex = index;
                          final bytes = file.bytes;
                          if (bytes == null) {
                            uploadController.markError(itemIndex);
                            index += 1;
                            continue;
                          }
                          final imageResult =
                              await localImageDataUrlResultFromBytes(
                                bytes: bytes,
                                onProgress: (stage, progress) {
                                  if (!mounted) {
                                    return;
                                  }
                                  uploadController.setStageLabel(
                                    mediaUploadStageLabel(context, stage),
                                  );
                                  uploadController.updateItem(
                                    index: itemIndex,
                                    stage: stage,
                                    progress: progress,
                                  );
                                  setState(() {
                                    _galleryTransferState =
                                        uploadController.snapshot;
                                  });
                                },
                              );
                          final dataUrl = imageResult.dataUrl;
                          if (dataUrl != null) {
                            dataUrls.add(dataUrl);
                            uploadController.markDone(itemIndex);
                          } else {
                            lastFailure = imageResult.failure;
                            uploadController.markError(itemIndex);
                          }
                          index += 1;
                        }
                        if (!mounted) return;
                        setState(() {
                          _uploadingGallery = false;
                          _galleryTransferState = null;
                        });
                        if (lastFailure != null) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                _imageUploadErrorMessage(l10n, lastFailure),
                              ),
                            ),
                          );
                        }
                        setState(() {
                          final current = _galleryController.text
                              .split('\n')
                              .map((item) => item.trim())
                              .where((item) => item.isNotEmpty)
                              .toList();
                          _galleryController.text = current.join('\n');
                          _localGalleryImages = [
                            ..._localGalleryImages,
                            ...dataUrls,
                          ];
                        });
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(l10n.shopGalleryUploadAction),
                    ),
                    if (_uploadingGallery) ...[
                      const SizedBox(height: 10),
                      ImageTransferProgressCard(
                        label: 'Preparazione galleria negozio',
                        batchState: _galleryTransferState,
                        icon: Icons.collections_outlined,
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Servizi e info
                    Text(
                      'Servizi e info operative',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _serviceLabelsController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Servizi e punti forti',
                        helperText: 'Uno per riga oppure separati da virgola.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _hoursController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.shopEditHoursLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contactsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.shopEditContactsLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: l10n.shopEditNotesLabel,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Azioni
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final router = GoRouter.of(context);
                            // effectiveUserIdProvider: in impersonazione il negozio
                            // viene attributito all'utente osservato, non all'admin.
                            final userId = ref.read(effectiveUserIdProvider) ?? '';
                            final slug = widget.isCreating
                                ? _slugify(_nameController.text)
                                : widget.slug;
                            try {
                              final savedRemotely = await ref
                                  .read(editableShopDraftsProvider.notifier)
                                  .save(
                                    EditableShopRecord(
                                      id: ref.read(editableShopProvider(widget.slug))?.id ?? '',
                                      slug: slug,
                                      name: _nameController.text.trim(),
                                      userId: userId,
                                      subtitle: _subtitleController.text.trim(),
                                      imageUrl: _localCoverImage.isNotEmpty
                                          ? _localCoverImage
                                          : _imageUrlController.text.trim(),
                                      galleryImages: galleryImages,
                                      address: _addressController.text.trim(),
                                      city: _cityController.text.trim(),
                                      website: _websiteController.text.trim(),
                                      organizationName:
                                          _organizationController.text.trim(),
                                      serviceLabels: serviceLabels,
                                      approvalStatus: widget.isCreating
                                          ? 'draft'
                                          : ref.read(editableShopProvider(widget.slug))?.approvalStatus ?? 'draft',
                                      contacts: _contactsController.text.trim(),
                                      hours: _hoursController.text.trim(),
                                      notes: _notesController.text.trim(),
                                    ),
                                  );
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    savedRemotely
                                        ? (widget.isCreating
                                              ? 'Bozza negozio salvata su Supabase.'
                                              : l10n.shopEditSavedMessage)
                                        : 'Bozza negozio salvata solo in locale.',
                                  ),
                                ),
                              );
                              if (widget.isCreating) {
                                router.go('/shops');
                              }
                            } catch (error) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Errore nel salvataggio del negozio: $error',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: Text(
                            widget.isCreating
                                ? 'Salva bozza'
                                : l10n.shopEditSave,
                          ),
                        ),
                        if (widget.isCreating)
                          OutlinedButton.icon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final router = GoRouter.of(context);
                              // effectiveUserIdProvider: in impersonazione il negozio
                              // viene attributito all'utente osservato, non all'admin.
                              final userId =
                                  ref.read(effectiveUserIdProvider) ?? '';
                              final slug = _slugify(_nameController.text);
                              try {
                                final savedRemotely = await ref
                                    .read(editableShopDraftsProvider.notifier)
                                    .save(
                                      EditableShopRecord(
                                        id: ref.read(editableShopProvider(widget.slug))?.id ?? '',
                                        slug: slug,
                                        name: _nameController.text.trim(),
                                        userId: userId,
                                        subtitle: _subtitleController.text.trim(),
                                        imageUrl: _localCoverImage.isNotEmpty
                                            ? _localCoverImage
                                            : _imageUrlController.text.trim(),
                                        galleryImages: galleryImages,
                                        address: _addressController.text.trim(),
                                        city: _cityController.text.trim(),
                                        website: _websiteController.text.trim(),
                                        organizationName:
                                            _organizationController.text.trim(),
                                        serviceLabels: serviceLabels,
                                        approvalStatus: 'pending',
                                        submittedAt:
                                            DateTime.now().toIso8601String(),
                                        contacts: _contactsController.text.trim(),
                                        hours: _hoursController.text.trim(),
                                        notes: _notesController.text.trim(),
                                      ),
                                    );
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      savedRemotely
                                          ? 'Negozio inviato alla coda approvazioni admin.'
                                          : 'Negozio salvato solo in locale: Supabase non disponibile.',
                                    ),
                                  ),
                                );
                                router.go('/shops');
                              } catch (error) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Errore nell\'invio del negozio: $error',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.rule_outlined),
                            label: const Text('Invia in approvazione'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ── Link esterni ───────────────────────────────────────────
          ExternalLinksSection(
            entityType: 'shop',
            entityId: widget.slug,
            title: l10n.externalLinksTitle,
            body: l10n.externalLinksShopBody,
            editable: canEditShop,
          ),

          // ── Galleria foto ──────────────────────────────────────────
          if (galleryImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.galleryButton,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: galleryImages
                          .map(
                            (image) => ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 180,
                                height: 120,
                                child: AdaptiveImage(
                                  source: image,
                                  fit: BoxFit.cover,
                                  fallback: const ColoredBox(
                                    color: Color(0xFFEDEFF3),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Note ───────────────────────────────────────────────────
          if (_notesController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _notesController.text,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.steel),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _slugify(String input) {
    final source = input.trim().isEmpty ? 'nuovo-negozio' : input.trim();
    return source
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  List<String> _parseServiceLabels(String raw) {
    return raw
        .split(RegExp(r'[\n,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .take(8)
        .toList();
  }
}
