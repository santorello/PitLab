import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/models/user_build.dart';
import '../../../shared/media/media_upload_service.dart';
import '../../../shared/utils/local_image_data_url.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/empty_state_panel.dart';
import '../../../shared/widgets/pill.dart';
import '../../../shared/widgets/processing_status_badge.dart';
import '../../auth/application/auth_providers.dart';
import '../../pitcoin/providers/pitcoin_providers.dart';
import '../application/garage_providers.dart';

class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return ContentScaffold(
        title: l10n.garageTitle,
        description: l10n.garageDescription,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppColors.steel),
              const SizedBox(height: 16),
              Text(
                'Accedi per accedere al tuo garage.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Accedi'),
              ),
            ],
          ),
        ),
      );
    }

    final garageState = ref.watch(garageProvider);

    return ContentScaffold(
      title: l10n.garageTitle,
      description: l10n.garageDescription,
      child: _GarageBody(state: garageState),
    );
  }
}

class _GarageBody extends ConsumerWidget {
  const _GarageBody({required this.state});

  final GarageState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (state.isLoading && state.builds.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.builds.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.steel),
            const SizedBox(height: 12),
            Text('Errore nel caricamento del garage.',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ref.read(garageProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    final publicCount = state.builds.where((b) => b.isPublic).length;

    return ListView(
      children: [
        // ── Hero ──────────────────────────────────────────────────────────
        Card(
          color: AppColors.graphite,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.garageHeroTitle,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.garageHeroBody,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.concrete),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _FlagChip(label: l10n.garageBuildsCount(state.builds.length)),
                    _FlagChip(label: l10n.garagePublicBuildsCount(publicCount)),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: state.isSaving
                      ? null
                      : () => _openBuildDialog(context, ref, l10n),
                  icon: state.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(l10n.garageAddBuildAction),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // ── Build list ────────────────────────────────────────────────────
        if (state.builds.isEmpty)
          EmptyStatePanel(
            icon: Icons.precision_manufacturing_outlined,
            title: l10n.garageBuildsTitle,
            subtitle: 'Nessuna build ancora. Aggiungi il tuo primo modello!',
            compact: true,
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🚗 ${l10n.garageBuildsTitle}',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  ...state.builds.map(
                    (build) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BuildCard(
                        userBuild: build,
                        photoCount: l10n.garagePhotoCount(build.imageUrls.length),
                        visibilityLabel: build.isPublic
                            ? l10n.garageBuildVisibilityPublic
                            : l10n.garageBuildVisibilityPrivate,
                        onEdit: () =>
                            _openBuildDialog(context, ref, l10n, existing: build),
                        onToggleVisibility: () =>
                            ref.read(garageProvider.notifier).toggleVisibility(build),
                        onDelete: () => _confirmDelete(context, ref, l10n, build),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openBuildDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    UserBuild? existing,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final metaCtrl = TextEditingController(text: existing?.meta ?? '');
    final imageUrlCtrl = TextEditingController();
    final specsCtrl =
        TextEditingController(text: existing?.specs.join(', ') ?? '');

    var isPublic = existing?.isPublic ?? false;

    // Image URLs: separate external URLs from data-URL blobs.
    // Data-URL blobs are shown in the editor but NOT sent to Supabase.
    var pickedImages = <String>[...?existing?.imageUrls];
    if (existing != null) {
      final externalImage = existing.imageUrls
          .where((url) => !url.startsWith('data:image'))
          .cast<String?>()
          .firstWhere(
            (url) => url != null && url.trim().isNotEmpty,
            orElse: () => '',
          )
          ?.trim() ??
          '';
      if (externalImage.isNotEmpty) {
        imageUrlCtrl.text = externalImage;
        pickedImages =
            pickedImages.where((url) => url != externalImage).toList();
      }
    }

    var isUploadingImages = false;
    final uploadService = ref.read(mediaUploadServiceProvider);
    final currentUserId = ref.read(currentUserProvider)?.id;

    final result = await showDialog<UserBuild>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null
              ? l10n.garageAddBuildAction
              : l10n.garageEditBuildAction),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration:
                        InputDecoration(labelText: l10n.garageBuildTitleLabel),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: metaCtrl,
                    decoration:
                        InputDecoration(labelText: l10n.garageBuildMetaLabel),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: imageUrlCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.garageBuildImageUrlLabel,
                      hintText: 'Link immagine principale opzionale',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          if (uploadService == null || currentUserId == null) {
                            messenger.showSnackBar(SnackBar(
                              content: Text(l10n.mediaUploadNotAuthenticated),
                            ));
                            return;
                          }
                          setDialogState(() => isUploadingImages = true);
                          final remainingSlots =
                              maxGarageBuildImages - pickedImages.length;
                          if (remainingSlots <= 0) {
                            setDialogState(() => isUploadingImages = false);
                            messenger.showSnackBar(SnackBar(
                              content: Text(l10n.garageBuildMaxImagesReached(
                                  maxGarageBuildImages)),
                            ));
                            return;
                          }
                          final picked = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            withData: true,
                            allowMultiple: true,
                          );
                          final files = picked?.files ?? const [];
                          if (files.isEmpty) {
                            setDialogState(() => isUploadingImages = false);
                            return;
                          }
                          final uploadedUrls = <String>[];
                          String? lastError;
                          for (final file in files.take(remainingSlots)) {
                            final bytes = file.bytes;
                            if (bytes == null) continue;
                            try {
                              final result = await uploadService.uploadImage(
                                bytes: bytes,
                                userId: currentUserId,
                                entityType: 'builds',
                                filePrefix: 'photo',
                              );
                              uploadedUrls.add(result.publicUrl);
                            } on MediaUploadException catch (e) {
                              lastError = e.message;
                            } catch (e) {
                              lastError = l10n.mediaUploadGenericError;
                            }
                          }
                          setDialogState(() {
                            isUploadingImages = false;
                            pickedImages = [
                              ...pickedImages,
                              ...uploadedUrls,
                            ].take(maxGarageBuildImages).toList();
                          });
                          if (lastError != null) {
                            messenger.showSnackBar(SnackBar(
                              content: Text(lastError),
                            ));
                          }
                        },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(l10n.garageUploadPhotosAction),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F7F3),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.concrete),
                        ),
                        child: Text(
                          l10n.garageBuildImagesCount(
                              pickedImages.length, maxGarageBuildImages),
                          style: Theme.of(ctx).textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                  if (isUploadingImages) ...[
                    const SizedBox(height: 10),
                    ProcessingStatusBadge(
                      label: l10n.processingUploadImages,
                      icon: Icons.photo_library_outlined,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    l10n.garageBuildImagesHelper(maxGarageBuildImages),
                    style: Theme.of(ctx)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.steel),
                  ),
                  if (pickedImages.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
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
                                  width: 128,
                                  height: 96,
                                  child: AdaptiveImage(
                                    source: image,
                                    fit: BoxFit.cover,
                                    fallback: const ColoredBox(
                                        color: Color(0xFFEDEFF3)),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Material(
                                  color: Colors.black54,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      setDialogState(() {
                                        pickedImages = List<String>.from(
                                            pickedImages)
                                          ..removeAt(index);
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.close,
                                          size: 16, color: Colors.white),
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: specsCtrl,
                    decoration: InputDecoration(
                        labelText: l10n.garageBuildSpecsHint),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: isPublic,
                    onChanged: (val) => setDialogState(() => isPublic = val),
                    title: Text(l10n.garageBuildPublicToggle),
                    contentPadding: EdgeInsets.zero,
                  ),
                  // TODO: Supabase Storage per le immagini locali (post-beta).
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                  MaterialLocalizations.of(dialogContext).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                final meta = metaCtrl.text.trim();
                if (title.isEmpty || meta.isEmpty) return;
                final externalImage = imageUrlCtrl.text.trim();
                // Solo URL http/https vanno nel DB. I data-URL blob
                // sono troppo grandi e non vengono persistiti.
                final persistedImageUrls = <String>[
                  if (externalImage.isNotEmpty) externalImage,
                  ...pickedImages.where(
                      (url) => !url.startsWith('data:image')),
                ].take(maxGarageBuildImages).toList();
                Navigator.of(dialogContext).pop(
                  UserBuild(
                    id: existing?.id ?? '',
                    ownerId: existing?.ownerId ?? '',
                    title: title,
                    meta: meta,
                    specs: specsCtrl.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList(),
                    imageUrls: persistedImageUrls,
                    isPublic: isPublic,
                  ),
                );
              },
              child: Text(l10n.garageBuildSaveAction),
            ),
          ],
        ),
      ),
    );

    titleCtrl.dispose();
    metaCtrl.dispose();
    imageUrlCtrl.dispose();
    specsCtrl.dispose();

    if (result == null) return;

    final controller = ref.read(garageProvider.notifier);
    bool ok;
    if (existing == null) {
      ok = await controller.createBuild(result);
    } else {
      ok = await controller.updateBuild(result.copyWith(id: existing.id, ownerId: existing.ownerId));
    }

    if (ok) {
      // D13: aggiorna subito il saldo PitCoin (build_created/published).
      ref.invalidate(effectiveUserPitcoinBalanceProvider);
      ref.invalidate(effectiveUserPitcoinRecentDeltaProvider);
    }

    if (context.mounted) {
      messenger.showSnackBar(SnackBar(
        content: Text(ok
            ? (existing == null
                ? l10n.garageBuildCreatedMessage
                : l10n.garageBuildUpdatedMessage)
            : 'Errore nel salvataggio. Riprova.'),
      ));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    UserBuild build,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina build'),
        content: Text('Eliminare "${build.title}"? L\'operazione non è reversibile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(garageProvider.notifier).deleteBuild(build);
    }
  }

}

// ── Widgets ───────────────────────────────────────────────────────────────

class _BuildCard extends StatelessWidget {
  const _BuildCard({
    required this.userBuild,
    required this.photoCount,
    required this.visibilityLabel,
    required this.onEdit,
    required this.onToggleVisibility,
    required this.onDelete,
  });

  final UserBuild userBuild;
  final String photoCount;
  final String visibilityLabel;
  final VoidCallback onEdit;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFE6EAF0), Color(0xFFD6DCE5)]),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: userBuild.primaryImageUrl.isEmpty
                    ? const Icon(Icons.photo_camera_back_outlined,
                        color: AppColors.steel)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: AdaptiveImage(
                          source: userBuild.primaryImageUrl,
                          fit: BoxFit.cover,
                          fallback: const Icon(
                              Icons.photo_camera_back_outlined,
                              color: AppColors.steel),
                        ),
                      ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userBuild.title,
                        style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text(userBuild.meta,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.steel)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(photoCount,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.signalOrange)),
                  SizedBox(height: AppSpacing.xs),
                  Pill(
                    label: visibilityLabel,
                    tone: userBuild.isPublic ? PillTone.success : PillTone.neutral,
                  ),
                ],
              ),
            ],
          ),
          if (userBuild.specs.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children:
                  userBuild.specs.map((s) => _SpecChip(label: s)).toList(),
            ),
          ],
          if (userBuild.imageUrls.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: userBuild.imageUrls.length,
                separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: SizedBox(
                    width: 104,
                    child: AdaptiveImage(
                      source: userBuild.imageUrls[index],
                      fit: BoxFit.cover,
                      fallback: ColoredBox(color: AppColors.surfaceMuted),
                    ),
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(
                    AppLocalizations.of(context)!.garageEditBuildAction),
              ),
              OutlinedButton.icon(
                onPressed: onToggleVisibility,
                icon: Icon(userBuild.isPublic
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                label: Text(userBuild.isPublic
                    ? AppLocalizations.of(context)!.garageSetPrivateAction
                    : AppLocalizations.of(context)!.garageSetPublicAction),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Elimina'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
