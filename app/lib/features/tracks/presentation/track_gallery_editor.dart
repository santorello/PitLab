import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/media/media_upload_controller.dart';
import '../../../shared/media/media_upload_labels.dart';
import '../../../shared/media/media_upload_service.dart';
import '../../../shared/media/media_upload_state.dart';
import '../../../shared/utils/local_image_data_url.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/fullscreen_gallery.dart';
import '../../../shared/widgets/image_transfer_progress_card.dart';
import '../../auth/application/auth_providers.dart';
import '../application/track_gallery_provider.dart';
import '../application/tracks_providers.dart';
import 'package:pitlap_app/app/l10n/tr.dart';

/// Galleria pista per il gestore: carica piu' foto, elimina, sposta prima.
/// Le foto vengono salvate SUBITO in `track_media` (non serve "Salva"):
/// cosi' un gestore che chiude la pagina non perde quello che ha caricato.
class TrackGalleryEditor extends ConsumerStatefulWidget {
  const TrackGalleryEditor({required this.trackId, super.key});

  final String trackId;

  @override
  ConsumerState<TrackGalleryEditor> createState() => _TrackGalleryEditorState();
}

class _TrackGalleryEditorState extends ConsumerState<TrackGalleryEditor> {
  bool _busy = false;
  MediaUploadBatchState? _transferState;

  void _refresh() => ref.invalidate(trackGalleryProvider(widget.trackId));

  Future<void> _addPhotos(int alreadyThere) async {
    final messenger = ScaffoldMessenger.of(context);
    final client = ref.read(supabaseClientProvider);
    final uploadService = ref.read(mediaUploadServiceProvider);
    final userId = ref.read(effectiveUserIdProvider);
    if (client == null || uploadService == null || userId == null) {
      messenger.showSnackBar(SnackBar(
        content: Text(tr('Devi essere autenticato per caricare immagini.')),
      ));
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (picked == null || !mounted) return;
    final free = maxTrackGalleryImages - alreadyThere;
    final files = picked.files.where((f) => f.bytes != null).take(free).toList();
    if (files.isEmpty) return;
    if (picked.files.length > free) {
      messenger.showSnackBar(SnackBar(
        content: Text(trf(
          'Massimo {0} foto per pista: caricate solo le prime {1}.',
          [maxTrackGalleryImages, free],
        )),
      ));
    }

    final controller = MediaUploadController(
      totalItems: files.length,
      initialStageLabel: tr('Preparazione foto pista'),
    );
    setState(() {
      _busy = true;
      _transferState = controller.snapshot;
    });

    var failed = 0;
    String? lastError;
    // Una foto alla volta: la decodifica di foto grandi usa molta memoria.
    for (var i = 0; i < files.length; i++) {
      try {
        final result = await uploadService.uploadImage(
          bytes: files[i].bytes!,
          userId: userId,
          entityType: 'tracks',
          filePrefix: 'gallery',
          onProgress: (stage, progress) {
            if (!mounted) return;
            controller.setStageLabel(mediaUploadStageLabel(context, stage));
            controller.updateItem(index: i, stage: stage, progress: progress);
            setState(() => _transferState = controller.snapshot);
          },
        );
        await client.from('track_media').insert({
          'track_id': widget.trackId,
          'storage_path': result.storagePath,
          'media_type': 'gallery',
          'sort_order': alreadyThere + i,
        });
        controller.markDone(i);
      } catch (e) {
        failed++;
        lastError = e is MediaUploadException ? e.message : '$e';
        controller.markError(i);
      }
      if (mounted) setState(() => _transferState = controller.snapshot);
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _transferState = failed == 0 ? null : controller.snapshot;
    });
    _refresh();
    messenger.showSnackBar(SnackBar(
      content: Text(failed == 0
          ? trf('Foto aggiunte alla galleria: {0}', [files.length])
          : trf('{0} foto non caricate: {1}', [failed, lastError])),
    ));
  }

  Future<void> _delete(TrackGalleryPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Eliminare questa foto?')),
        content: Text(tr('La foto viene tolta dalla galleria della pista.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('Annulla')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tr('Elimina')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      await ref.read(supabaseClientProvider)!
          .from('track_media')
          .delete()
          .eq('id', photo.id);
      // Il file nel bucket si elimina solo se e' nella cartella di chi
      // agisce (policy storage): per foto di altri resta, innocuo.
      await ref
          .read(mediaUploadServiceProvider)
          ?.deleteImage(storagePath: photo.storagePath);
    });
  }

  Future<void> _moveEarlier(List<TrackGalleryPhoto> photos, int index) async {
    final reordered = [...photos]
      ..insert(index - 1, photos[index])
      ..removeAt(index + 1);
    final client = ref.read(supabaseClientProvider)!;
    // ponytail: riscrive l'ordine di tutte le foto (max 10 update).
    await _run(() => Future.wait([
          for (var i = 0; i < reordered.length; i++)
            client
                .from('track_media')
                .update({'sort_order': i}).eq('id', reordered[i].id),
        ]));
  }

  Future<void> _run(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(trf('Operazione non riuscita: {0}', [e]))),
      );
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final galleryAsync = ref.watch(trackGalleryProvider(widget.trackId));
    final photos = galleryAsync.asData?.value ?? const <TrackGalleryPhoto>[];
    final urls = [for (final p in photos) p.url];
    final full = photos.length >= maxTrackGalleryImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (galleryAsync.hasError)
          Text(trf('Errore caricamento galleria: {0}', [galleryAsync.error])),
        if (photos.isNotEmpty)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < photos.length; i++)
                _Thumb(
                  url: photos[i].url,
                  onOpen: () =>
                      openFullscreenGallery(context, urls, initialIndex: i),
                  onDelete: _busy ? null : () => _delete(photos[i]),
                  onMoveEarlier:
                      _busy || i == 0 ? null : () => _moveEarlier(photos, i),
                ),
            ],
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy || full ? null : () => _addPhotos(photos.length),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(trf(
            'Aggiungi foto ({0}/{1})',
            [photos.length, maxTrackGalleryImages],
          )),
        ),
        if (_transferState != null) ...[
          const SizedBox(height: 10),
          ImageTransferProgressCard(
            label: tr('Preparazione foto pista'),
            batchState: _transferState,
          ),
        ],
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.url,
    required this.onOpen,
    required this.onDelete,
    required this.onMoveEarlier,
  });

  final String url;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;
  final VoidCallback? onMoveEarlier;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onTap: onOpen,
              child: AdaptiveImage(
                source: url,
                fit: BoxFit.cover,
                fallback: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              tooltip: tr('Elimina'),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
            ),
          ),
          if (onMoveEarlier != null)
            Positioned(
              bottom: 2,
              left: 2,
              child: IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                tooltip: tr('Sposta prima'),
                onPressed: onMoveEarlier,
                icon: const Icon(Icons.chevron_left, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}
