import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Widget to display an ad in either square or rectangle format.
/// Supports both single image and multiple images with rotation animation.
class AdDisplayWidget extends StatefulWidget {
  final String imageUrl;
  final List<String> artworkUrls; // Multiple images for rotation
  final String title;
  final String description;
  final String? ctaText;
  final VoidCallback? onTap;
  final AdDisplayType displayType; // square or rectangle
  final Duration rotationDuration; // How long each image is shown

  const AdDisplayWidget({
    super.key,
    required this.imageUrl,
    this.artworkUrls = const [],
    required this.title,
    required this.description,
    this.ctaText,
    this.onTap,
    this.displayType = AdDisplayType.rectangle,
    this.rotationDuration = const Duration(
      milliseconds: 1500,
    ), // Faster gif-like cycling
  });

  @override
  State<AdDisplayWidget> createState() => _AdDisplayWidgetState();
}

class _AdDisplayWidgetState extends State<AdDisplayWidget> {
  Timer? _rotationTimer;
  int _currentImageIndex = 0;

  // Get all available images (artwork URLs + fallback to main image)
  List<String> get _allImages {
    if (widget.artworkUrls.isNotEmpty) {
      return widget.artworkUrls;
    } else if (widget.imageUrl.isNotEmpty) {
      return [widget.imageUrl];
    }
    return [];
  }

  bool get _hasMultipleImages => _allImages.length > 1;

  @override
  void initState() {
    super.initState();
    _startRotationTimer();
  }

  @override
  void didUpdateWidget(AdDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart timer if artworkUrls changed
    if (oldWidget.artworkUrls != widget.artworkUrls ||
        oldWidget.rotationDuration != widget.rotationDuration) {
      _rotationTimer?.cancel();
      _currentImageIndex = 0;
      _startRotationTimer();
    }
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _startRotationTimer() {
    if (_hasMultipleImages) {
      debugPrint('🔄 Starting rotation timer for ${_allImages.length} images');
      _rotationTimer = Timer.periodic(widget.rotationDuration, (timer) {
        if (mounted) {
          setState(() {
            _currentImageIndex = (_currentImageIndex + 1) % _allImages.length;
            debugPrint(
              '🖼️ Rotating to image ${_currentImageIndex + 1}/${_allImages.length}',
            );
          });
        }
      });
    } else {
      debugPrint(
        '⚠️ Not starting rotation timer - only ${_allImages.length} images available',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Optimized size for ad display - 300x100 or smaller
    final size = widget.displayType == AdDisplayType.square
        ? const Size(100, 100)
        : const Size(300, 100);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: size.width,
        height: size.height,
        margin: const EdgeInsets.all(4), // Reduced margin for compact display
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            8,
          ), // Smaller radius for compact size
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImageDisplay(size),
        ),
      ),
    );
  }

  Widget _buildImageDisplay(Size size) {
    if (_allImages.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 24, color: Colors.grey),
      );
    }

    final currentImageUrl = _allImages[_currentImageIndex];

    // Check if imageUrl is a local file path
    final isLocalFile =
        currentImageUrl.isNotEmpty &&
        !currentImageUrl.startsWith('http') &&
        File(currentImageUrl).existsSync();

    Widget imageWidget;

    if (isLocalFile) {
      imageWidget = Image.file(
        File(currentImageUrl),
        fit: BoxFit.cover,
        width: size.width,
        height: size.height,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 24),
      );
    } else {
      // Debug: Print what URL we're trying to load
      if (kDebugMode) {
        debugPrint('🔍 AdDisplayWidget loading image: $currentImageUrl');
      }

      // Use direct Image.network for placeholder URLs to bypass potential ImageManagementService issues
      if (currentImageUrl.contains('via.placeholder.com')) {
        if (kDebugMode) {
          debugPrint(
            '🖼️ Using direct Image.network for placeholder: $currentImageUrl',
          );
        }
        imageWidget = Image.network(
          currentImageUrl,
          fit: BoxFit.cover,
          width: size.width,
          height: size.height,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              if (kDebugMode) {
                debugPrint(
                  '✅ Successfully loaded placeholder image: $currentImageUrl',
                );
              }
              return child;
            }
            if (kDebugMode) {
              debugPrint(
                '⏳ Loading placeholder image: $currentImageUrl (${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes})',
              );
            }
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              debugPrint(
                '❌ Failed to load placeholder image: $currentImageUrl - Error: $error',
              );
            }
            return const Icon(Icons.broken_image, size: 24);
          },
        );
      } else {
        if (kDebugMode) {
          debugPrint('🔧 Using ImageManagementService for: $currentImageUrl');
        }
        imageWidget = ImageManagementService().getOptimizedImage(
          imageUrl: currentImageUrl,
          fit: BoxFit.cover,
          width: size.width,
          height: size.height,
          isThumbnail: true,
          errorWidget: const Icon(Icons.broken_image, size: 24),
        );
      }
    }

    // Enhanced animation for gif-like smooth transitions
    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 300,
          ), // Faster, smoother transition
          transitionBuilder: (Widget child, Animation<double> animation) {
            // Use fade transition for smooth gif-like effect
            return FadeTransition(opacity: animation, child: child);
          },
          child: Container(
            key: ValueKey(currentImageUrl),
            width: size.width,
            height: size.height,
            child: imageWidget,
          ),
        ),
        // Subtle progress indicator for multiple images (smaller and less intrusive)
        if (_hasMultipleImages && _allImages.length > 1)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_allImages.length, (index) {
                  return Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentImageIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }
}

enum AdDisplayType { square, rectangle }
