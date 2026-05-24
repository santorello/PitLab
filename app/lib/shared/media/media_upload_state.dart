enum MediaUploadStage { queued, preparing, uploading, processing, done, error }

class MediaUploadItemState {
  const MediaUploadItemState({
    required this.index,
    this.stage = MediaUploadStage.queued,
    this.progress = 0,
    this.hasSucceeded = false,
  });

  final int index;
  final MediaUploadStage stage;
  final double progress;
  final bool hasSucceeded;

  MediaUploadItemState copyWith({
    MediaUploadStage? stage,
    double? progress,
    bool? hasSucceeded,
  }) {
    return MediaUploadItemState(
      index: index,
      stage: stage ?? this.stage,
      progress: progress ?? this.progress,
      hasSucceeded: hasSucceeded ?? this.hasSucceeded,
    );
  }
}

class MediaUploadBatchState {
  const MediaUploadBatchState({
    required this.items,
    required this.stageLabel,
  });

  final List<MediaUploadItemState> items;
  final String stageLabel;

  int get totalCount => items.length;

  int get completedCount => items.where((item) => item.hasSucceeded).length;

  int get failedCount =>
      items.where((item) => item.stage == MediaUploadStage.error).length;

  double get progress {
    if (items.isEmpty) {
      return 0;
    }
    final total = items.fold<double>(
      0,
      (sum, item) => sum + item.progress.clamp(0, 1).toDouble(),
    );
    return total / items.length;
  }

  String get detailsLabel {
    if (failedCount > 0) {
      return '$completedCount di $totalCount immagini pronte - $failedCount con errore';
    }
    return '$completedCount di $totalCount immagini pronte';
  }
}
