import 'package:flutter_test/flutter_test.dart';
import 'package:pitlap_app/shared/media/media_upload_controller.dart';
import 'package:pitlap_app/shared/media/media_upload_state.dart';

void main() {
  test('media upload controller aggregates per-item progress', () {
    final controller = MediaUploadController(
      totalItems: 2,
      initialStageLabel: 'Preparing files',
    );

    controller.updateItem(
      index: 0,
      stage: MediaUploadStage.preparing,
      progress: 0.5,
    );
    controller.markDone(1);

    final snapshot = controller.snapshot;

    expect(snapshot.totalCount, 2);
    expect(snapshot.completedCount, 1);
    expect(snapshot.progress, 0.75);
  });
}
