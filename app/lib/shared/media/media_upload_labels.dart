import 'package:flutter/widgets.dart';

import 'media_upload_state.dart';

String mediaUploadStageLabel(
  BuildContext context,
  MediaUploadStage stage,
) {
  final languageCode = Localizations.localeOf(context).languageCode.toLowerCase();
  final isItalian = languageCode == 'it';
  return switch (stage) {
    MediaUploadStage.queued => isItalian ? 'In coda' : 'Queued',
    MediaUploadStage.preparing => isItalian
        ? 'Sto preparando il file'
        : 'Preparing file',
    MediaUploadStage.uploading => isItalian
        ? 'Caricamento in corso'
        : 'Uploading',
    MediaUploadStage.processing => isItalian
        ? 'Sto ottimizzando il file'
        : 'Processing file',
    MediaUploadStage.done => isItalian ? 'File pronto' : 'File ready',
    MediaUploadStage.error => isItalian ? 'Errore file' : 'File error',
  };
}
