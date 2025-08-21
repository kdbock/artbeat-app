import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../models/ad_model.dart';
import '../models/ad_size.dart';

/// Simplified ad display widget that handles image rotation and click actions
class SimpleAdDisplayWidget extends StatefulWidget {
  final AdModel ad;
  final VoidCallback? onTap;
  final bool showCloseButton;

  const SimpleAdDisplayWidget({
    super.key,
    required this.ad,
    this.onTap,
    this.showCloseButton = false,
  });

  @override
  State<SimpleAdDisplayWidget> createState() => _SimpleAdDisplayWidgetState();
}

class _SimpleAdDisplayWidgetState extends State<SimpleAdDisplayWidget> {
  int _currentImageIndex = 0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _startImageRotation();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _startImageRotation() {
    // Only rotate if there are multiple images
    if (widget.ad.artworkUrls.length > 1) {
      _rotationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) {
          setState(() {
            _currentImageIndex =
                (_currentImageIndex + 1) % widget.ad.artworkUrls.length;
          });
        }
      });
    }
  }

  Future<void> _handleTap() async {
    // Custom tap handler takes precedence
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    // Try to launch destination URL if available
    if (widget.ad.destinationUrl != null &&
        widget.ad.destinationUrl!.isNotEmpty) {
      try {
        final uri = Uri.parse(widget.ad.destinationUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Error launching URL: $e');
      }
    }
  }

  String get _currentImageUrl {
    if (widget.ad.artworkUrls.isEmpty) {
      return widget.ad.imageUrl;
    }
    return widget.ad.artworkUrls[_currentImageIndex];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: widget.ad.size.width.toDouble(),
        height: widget.ad.size.height.toDouble(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main ad content
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildAdContent(),
            ),

            // Close button (if enabled)
            if (widget.showCloseButton)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),

            // Image rotation indicator (if multiple images)
            if (widget.ad.artworkUrls.length > 1)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${widget.ad.artworkUrls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdContent() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          CachedNetworkImage(
            imageUrl: _currentImageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade200,
              child: const Center(child: Icon(Icons.error, color: Colors.grey)),
            ),
          ),

          // Overlay content for larger ads
          if (widget.ad.size.height >= 100) _buildOverlayContent(),
        ],
      ),
    );
  }

  Widget _buildOverlayContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.ad.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Description (only for large ads)
            if (widget.ad.size.height >= 200)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  widget.ad.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // CTA button
            if (widget.ad.ctaText != null && widget.ad.ctaText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.ad.ctaText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
