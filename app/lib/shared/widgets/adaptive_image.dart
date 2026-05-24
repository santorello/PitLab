import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../utils/local_image_data_url.dart';

class AdaptiveImage extends StatelessWidget {
  const AdaptiveImage({
    required this.source,
    required this.fit,
    required this.fallback,
    this.width,
    this.height,
    super.key,
  });

  final String? source;
  final BoxFit fit;
  final Widget fallback;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final resolved = source?.trim();
    if (resolved == null || resolved.isEmpty) {
      return fallback;
    }
    if (isLocalImageDataUrlTooLarge(resolved)) {
      return fallback;
    }

    final bytes = _tryDecodeDataUrl(resolved);
    if (bytes != null) {
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: 1200,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return Image.network(
      resolved,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: 1200,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  static Uint8List? _tryDecodeDataUrl(String value) {
    final commaIndex = value.indexOf(',');
    if (!value.startsWith('data:image') || commaIndex < 0) {
      return null;
    }

    try {
      return base64Decode(value.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }
}
