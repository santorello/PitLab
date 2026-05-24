import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../media/media_upload_state.dart';

const int maxLocalImageBytes = 520 * 1024;
const int maxLocalImageInputBytes = 5 * 1024 * 1024;
const int maxLocalGalleryImages = 3;
const int maxLocalImageDimension = 1200;
const int maxShopGalleryImages = 10;
const int maxTrackGalleryImages = 10;
const int maxGarageBuildImages = 5;
const int maxEventImages = 5;

enum LocalImageDataUrlFailure { inputTooLarge, unreadable, outputTooLarge }

class LocalImageDataUrlResult {
  const LocalImageDataUrlResult._({this.dataUrl, this.failure});

  const LocalImageDataUrlResult.success(String dataUrl)
    : this._(dataUrl: dataUrl);

  const LocalImageDataUrlResult.failure(LocalImageDataUrlFailure failure)
    : this._(failure: failure);

  final String? dataUrl;
  final LocalImageDataUrlFailure? failure;

  bool get hasData => dataUrl != null;
}

Future<String?> localImageDataUrlFromBytes({required Uint8List bytes}) async {
  final result = await localImageDataUrlResultFromBytes(bytes: bytes);
  return result.dataUrl;
}

Future<LocalImageDataUrlResult> localImageDataUrlResultFromBytes({
  required Uint8List bytes,
  void Function(MediaUploadStage stage, double progress)? onProgress,
}) async {
  onProgress?.call(MediaUploadStage.preparing, 0.05);
  if (bytes.lengthInBytes > maxLocalImageInputBytes) {
    return const LocalImageDataUrlResult.failure(
      LocalImageDataUrlFailure.inputTooLarge,
    );
  }

  final source = img.decodeImage(bytes);
  if (source == null) {
    return const LocalImageDataUrlResult.failure(
      LocalImageDataUrlFailure.unreadable,
    );
  }
  onProgress?.call(MediaUploadStage.preparing, 0.22);

  final normalized = img.bakeOrientation(source);
  final resized = _resizeForLocalPreview(normalized);
  onProgress?.call(MediaUploadStage.preparing, 0.48);

  const qualities = [76, 70, 64, 58];
  for (var i = 0; i < qualities.length; i++) {
    final quality = qualities[i];
    onProgress?.call(
      MediaUploadStage.processing,
      0.56 + ((i + 1) / qualities.length) * 0.28,
    );
    final encoded = Uint8List.fromList(
      img.encodeJpg(resized, quality: quality),
    );
    if (encoded.lengthInBytes <= maxLocalImageBytes) {
      onProgress?.call(MediaUploadStage.done, 1);
      return LocalImageDataUrlResult.success(
        'data:image/jpeg;base64,${base64Encode(encoded)}',
      );
    }
  }

  final fallback = _resizeForLocalPreview(resized, dimension: 900);
  onProgress?.call(MediaUploadStage.processing, 0.9);
  final encoded = Uint8List.fromList(img.encodeJpg(fallback, quality: 56));
  if (encoded.lengthInBytes > maxLocalImageBytes) {
    return const LocalImageDataUrlResult.failure(
      LocalImageDataUrlFailure.outputTooLarge,
    );
  }
  onProgress?.call(MediaUploadStage.done, 1);
  return LocalImageDataUrlResult.success(
    'data:image/jpeg;base64,${base64Encode(encoded)}',
  );
}

bool isLocalImageDataUrlTooLarge(String value) {
  if (!value.startsWith('data:image')) {
    return false;
  }
  final commaIndex = value.indexOf(',');
  if (commaIndex < 0) {
    return true;
  }

  final encodedLength = value.length - commaIndex - 1;
  final approximateBytes = (encodedLength * 3) ~/ 4;
  return approximateBytes > maxLocalImageBytes;
}

img.Image _resizeForLocalPreview(
  img.Image source, {
  int dimension = maxLocalImageDimension,
}) {
  if (source.width <= dimension && source.height <= dimension) {
    return source;
  }
  if (source.width >= source.height) {
    return img.copyResize(source, width: dimension);
  }
  return img.copyResize(source, height: dimension);
}
