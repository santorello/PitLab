import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../media/media_upload_controller.dart';
import '../media/media_upload_labels.dart';
import '../media/media_upload_service.dart';
import '../media/media_upload_state.dart';
import 'image_transfer_progress_card.dart';

/// Campo copertina: URL a mano oppure foto dal dispositivo.
///
/// Un gestore ha le foto sul telefono, non un URL: senza il pulsante di
/// caricamento il campo resta vuoto. Il file viene ridimensionato e caricato
/// dal MediaUploadService, poi l'URL pubblico finisce nel [controller].
class CoverImageField extends ConsumerStatefulWidget {
  const CoverImageField({
    required this.controller,
    required this.entityType,
    this.label = 'URL immagine di copertina',
    this.uploadLabel = 'Carica foto dal dispositivo',
    this.progressLabel = 'Preparazione copertina',
    this.onUploaded,
    super.key,
  });

  final TextEditingController controller;

  /// tracks | shops | events | spots | profiles | builds | places
  final String entityType;
  final String label;
  final String uploadLabel;
  final String progressLabel;

  /// Chiamata dopo un upload riuscito, con l'URL pubblico.
  final void Function(String publicUrl)? onUploaded;

  @override
  ConsumerState<CoverImageField> createState() => _CoverImageFieldState();
}

class _CoverImageFieldState extends ConsumerState<CoverImageField> {
  bool _uploading = false;
  MediaUploadBatchState? _transferState;

  Future<void> _pickAndUpload() async {
    final messenger = ScaffoldMessenger.of(context);
    final uploadService = ref.read(mediaUploadServiceProvider);
    final userId = ref.read(effectiveUserIdProvider);
    if (uploadService == null || userId == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Devi essere autenticato per caricare immagini.'),
        ),
      );
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = picked?.files.single.bytes;
    if (bytes == null) return;

    final uploadController = MediaUploadController(
      totalItems: 1,
      initialStageLabel: widget.progressLabel,
    );
    setState(() {
      _uploading = true;
      _transferState = uploadController.snapshot;
    });

    try {
      final result = await uploadService.uploadImage(
        bytes: bytes,
        userId: userId,
        entityType: widget.entityType,
        filePrefix: 'cover',
        onProgress: (stage, progress) {
          if (!mounted) return;
          uploadController.setStageLabel(mediaUploadStageLabel(context, stage));
          uploadController.updateItem(
            index: 0,
            stage: stage,
            progress: progress,
          );
          setState(() => _transferState = uploadController.snapshot);
        },
      );
      if (!mounted) return;
      uploadController.markDone(0);
      setState(() {
        _uploading = false;
        _transferState = null;
        widget.controller.text = result.publicUrl;
      });
      widget.onUploaded?.call(result.publicUrl);
    } on MediaUploadException catch (e) {
      if (!mounted) return;
      uploadController.markError(0);
      setState(() {
        _uploading = false;
        _transferState = uploadController.snapshot;
      });
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      uploadController.markError(0);
      setState(() {
        _uploading = false;
        _transferState = uploadController.snapshot;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Errore caricamento copertina: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: 'https://...',
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _uploading ? null : _pickAndUpload,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(widget.uploadLabel),
        ),
        if (_uploading || _transferState != null) ...[
          const SizedBox(height: 10),
          ImageTransferProgressCard(
            label: widget.progressLabel,
            batchState: _transferState,
            icon: Icons.image_outlined,
          ),
        ],
      ],
    );
  }
}
