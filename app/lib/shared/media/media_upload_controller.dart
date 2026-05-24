import 'media_upload_state.dart';

class MediaUploadController {
  MediaUploadController({
    required int totalItems,
    required String initialStageLabel,
  }) : _items = List<MediaUploadItemState>.generate(
         totalItems,
         (index) => MediaUploadItemState(index: index),
       ),
       _stageLabel = initialStageLabel;

  final List<MediaUploadItemState> _items;
  String _stageLabel;

  void updateItem({
    required int index,
    required MediaUploadStage stage,
    required double progress,
  }) {
    if (index < 0 || index >= _items.length) {
      return;
    }
    _items[index] = _items[index].copyWith(
      stage: stage,
      progress: progress.clamp(0, 1).toDouble(),
      hasSucceeded: stage == MediaUploadStage.done,
    );
  }

  void markDone(int index) {
    updateItem(index: index, stage: MediaUploadStage.done, progress: 1);
  }

  void markError(int index) {
    updateItem(index: index, stage: MediaUploadStage.error, progress: 1);
  }

  void setStageLabel(String label) {
    _stageLabel = label;
  }

  MediaUploadBatchState get snapshot =>
      MediaUploadBatchState(items: List<MediaUploadItemState>.unmodifiable(_items), stageLabel: _stageLabel);
}
