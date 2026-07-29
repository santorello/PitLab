import 'dart:convert';
import 'dart:typed_data';

import 'package:pitlap_app/app/bootstrap/error_reporting.dart';
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
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: child,
        );
      },
    );
  }

  static Uint8List? _tryDecodeDataUrl(String value) {
    final commaIndex = value.indexOf(',');
    if (!value.startsWith('data:image') || commaIndex < 0) {
      return null;
    }

    try {
      return base64Decode(value.substring(commaIndex + 1));
    } catch (e, st) {
      AppErrorReporter.report(e, st, context: 'adaptive_image');
      return null;
    }
  }
}
