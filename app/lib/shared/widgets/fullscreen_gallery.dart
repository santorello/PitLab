import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'adaptive_image.dart';

/// Galleria a tutto schermo stile Instagram: scorrimento tra le foto,
/// zoom con pizzico o doppio tocco, contatore, frecce e tastiera su PC.
/// Unica implementazione per build, spot ed eventi.
Future<void> openFullscreenGallery(
  BuildContext context,
  List<String> images, {
  int initialIndex = 0,
}) {
  if (images.isEmpty) return Future.value();
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    builder: (_) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: _FullscreenGallery(
        images: images,
        initialIndex: initialIndex.clamp(0, images.length - 1),
      ),
    ),
  );
}

class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  final _focusNode = FocusNode();
  // Con lo zoom attivo lo scorrimento tra foto si blocca, altrimenti
  // spostarsi dentro la foto ingrandita cambierebbe pagina.
  bool _zoomed = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final target = _index + delta;
    if (target < 0 || target >= widget.images.length) return;
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.images.length;
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) _go(1);
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) _go(-1);
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
        }
      },
      child: Stack(
        children: [
          // Su web il trascinamento col mouse e' disattivato di default:
          // lo abilitiamo, cosi' si scorre anche da PC.
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: PageView.builder(
              controller: _controller,
              physics: _zoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: count,
              onPageChanged: (value) => setState(() {
                _index = value;
                _zoomed = false;
              }),
              itemBuilder: (context, index) => _ZoomableImage(
                source: widget.images[index],
                onZoomChanged: (zoomed) {
                  if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                },
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton.filledTonal(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ),
          if (count > 1) ...[
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(140),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      '${_index + 1} / $count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_index > 0)
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton.filledTonal(
                    onPressed: () => _go(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                ),
              ),
            if (_index < count - 1)
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton.filledTonal(
                    onPressed: () => _go(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: GalleryDots(count: count, index: _index, light: true),
            ),
          ],
        ],
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.source, required this.onZoomChanged});

  final String source;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final _transform = TransformationController();
  TapDownDetails? _doubleTap;

  @override
  void initState() {
    super.initState();
    _transform.addListener(() {
      widget.onZoomChanged(_transform.value.getMaxScaleOnAxis() > 1.01);
    });
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    if (_transform.value.getMaxScaleOnAxis() > 1.01) {
      _transform.value = Matrix4.identity();
      return;
    }
    final position = _doubleTap?.localPosition ?? Offset.zero;
    const scale = 2.5;
    _transform.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(
        -position.dx * (scale - 1),
        -position.dy * (scale - 1),
        0,
      );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTap = details,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 5,
        // SizedBox.expand: senza vincoli stretti l'immagine resta alla sua
        // misura originale (piccola) invece di riempire lo schermo.
        child: SizedBox.expand(
          child: AdaptiveImage(
            source: widget.source,
            fit: BoxFit.contain,
            fallback: const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

/// Carosello in pagina: foto grandi scorrevoli con pallini; un tocco apre
/// la galleria a tutto schermo sulla foto corrente.
class InlineImageCarousel extends StatefulWidget {
  const InlineImageCarousel({
    required this.images,
    required this.fallback,
    this.aspectRatio = 4 / 3,
    this.borderRadius = 18,
    super.key,
  });

  final List<String> images;
  final Widget fallback;
  final double aspectRatio;
  final double borderRadius;

  @override
  State<InlineImageCarousel> createState() => _InlineImageCarouselState();
}

class _InlineImageCarouselState extends State<InlineImageCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: images.isEmpty
            ? widget.fallback
            : Stack(
                fit: StackFit.expand,
                children: [
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: images.length,
                      onPageChanged: (value) => setState(() => _index = value),
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () => openFullscreenGallery(
                          context,
                          images,
                          initialIndex: index,
                        ),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.zoomIn,
                          child: AdaptiveImage(
                            source: images[index],
                            fit: BoxFit.cover,
                            fallback: widget.fallback,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: GalleryDots(
                        count: images.length,
                        index: _index,
                        light: true,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class GalleryDots extends StatelessWidget {
  const GalleryDots({
    required this.count,
    required this.index,
    this.light = false,
    super.key,
  });

  final int count;
  final int index;
  final bool light;

  @override
  Widget build(BuildContext context) {
    // Oltre 10 foto i pallini diventano rumore: basta il contatore.
    if (count < 2 || count > 10) return const SizedBox.shrink();
    final active = light ? Colors.white : Theme.of(context).colorScheme.primary;
    final idle = light ? Colors.white54 : Colors.black26;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index ? active : idle,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}
