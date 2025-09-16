import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../models/ad_model.dart';
import '../models/ad_size.dart';
import '../models/image_fit.dart';
import '../models/ad_location.dart';
import '../services/ad_analytics_service.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Simplified ad display widget that handles image rotation and click actions
class SimpleAdDisplayWidget extends StatefulWidget {
  final AdModel ad;
  final AdLocation location;
  final VoidCallback? onTap;
  final bool showCloseButton;
  final bool trackAnalytics;
  final AdAnalyticsService? analyticsService;

  const SimpleAdDisplayWidget({
    super.key,
    required this.ad,
    required this.location,
    this.onTap,
    this.showCloseButton = false,
    this.trackAnalytics = true,
    this.analyticsService,
  });

  @override
  State<SimpleAdDisplayWidget> createState() => _SimpleAdDisplayWidgetState();
}

class _SimpleAdDisplayWidgetState extends State<SimpleAdDisplayWidget> {
  int _currentImageIndex = 0;
  Timer? _rotationTimer;
  Timer? _impressionTimer;
  bool _impressionTracked = false;
  DateTime? _viewStartTime;

  AdAnalyticsService? _analyticsService;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Ensure initial image index is valid
    if (widget.ad.artworkUrls.isNotEmpty) {
      _currentImageIndex = _currentImageIndex.clamp(
        0,
        widget.ad.artworkUrls.length - 1,
      );
    }
    if (widget.trackAnalytics) {
      _analyticsService = widget.analyticsService ?? AdAnalyticsService();
      _getCurrentUserId();
    }
    _startImageRotation();
    _trackImpression();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _impressionTimer?.cancel();
    _trackViewDuration();
    super.dispose();
  }

  void _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid;
  }

  void _trackImpression() {
    if (!widget.trackAnalytics) return;

    // Track impression after 1 second to ensure genuine view
    _impressionTimer = Timer(const Duration(seconds: 1), () {
      if (mounted && !_impressionTracked) {
        _impressionTracked = true;
        _viewStartTime = DateTime.now();

        if (_analyticsService != null) {
          _analyticsService!.trackAdImpression(
            widget.ad.id,
            widget.ad.ownerId,
            viewerId: _currentUserId,
            location: widget.location,
            metadata: {
              'adSize': widget.ad.size.name,
              'adType': widget.ad.type.name,
              'hasMultipleImages': widget.ad.artworkUrls.length > 1,
            },
          );
        }
      }
    });
  }

  void _trackViewDuration() {
    if (!widget.trackAnalytics || _viewStartTime == null) return;

    final viewDuration = DateTime.now().difference(_viewStartTime!);
    if (viewDuration.inSeconds >= 1) {
      // Update impression with view duration (could be done with a separate call)
      // For now, we'll track it in click metadata when user interacts
    }
  }

  void _startImageRotation() {
    // Only rotate if there are multiple images
    if (widget.ad.artworkUrls.length > 1) {
      _rotationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted && widget.ad.artworkUrls.isNotEmpty) {
          setState(() {
            _currentImageIndex =
                (_currentImageIndex + 1) % widget.ad.artworkUrls.length;
          });
        }
      });
    }
  }

  Future<void> _handleTap() async {
    // Track click analytics
    if (widget.trackAnalytics && _analyticsService != null) {
      final viewDuration = _viewStartTime != null
          ? DateTime.now().difference(_viewStartTime!)
          : null;

      _analyticsService!.trackAdClick(
        widget.ad.id,
        widget.ad.ownerId,
        viewerId: _currentUserId,
        location: widget.location,
        destinationUrl: widget.ad.destinationUrl,
        clickType: 'ad_tap',
        metadata: {
          'adSize': widget.ad.size.name,
          'adType': widget.ad.type.name,
          'currentImageIndex': _currentImageIndex,
          'viewDurationSeconds': viewDuration?.inSeconds,
          'hasDestinationUrl': widget.ad.destinationUrl?.isNotEmpty == true,
        },
      );
    }

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
        AppLogger.error('Error launching URL: $e');
      }
    }
  }

  String get _currentImageUrl {
    if (widget.ad.artworkUrls.isEmpty) {
      return widget.ad.imageUrl;
    }
    // Ensure the index is within bounds
    final safeIndex = _currentImageIndex.clamp(
      0,
      widget.ad.artworkUrls.length - 1,
    );
    return widget.ad.artworkUrls[safeIndex];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive dimensions
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 32; // Account for padding

        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : widget.ad.size.height.toDouble();

        // Maintain aspect ratio while respecting constraints
        final aspectRatio = widget.ad.size.width / widget.ad.size.height;
        final constrainedWidth = availableWidth.clamp(
          200.0,
          400.0,
        ); // Allow up to 400px for better display
        final calculatedHeight = constrainedWidth / aspectRatio;
        const minHeight = 50.0;
        final maxHeight = availableHeight.isFinite
            ? availableHeight
            : calculatedHeight;
        final constrainedHeight = calculatedHeight.clamp(
          minHeight.clamp(0.0, maxHeight),
          maxHeight,
        );

        return Semantics(
          label: 'Advertisement',
          hint: 'Tap to interact with advertisement',
          button: true,
          child: GestureDetector(
            onTap: _handleTap,
            child: Container(
              width: constrainedWidth,
              height: constrainedHeight,
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

                  // Sponsored/Ad disclosure label (legal requirement)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Sponsored',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
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
                          '${(_currentImageIndex.clamp(0, widget.ad.artworkUrls.length - 1) + 1)}/${widget.ad.artworkUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            CachedNetworkImage(
              imageUrl: _currentImageUrl,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              fit: widget.ad.imageFit.boxFit,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.error, color: Colors.grey),
                ),
              ),
            ),

            // Overlay content for larger ads (only show if we have meaningful space)
            if (constraints.maxHeight >= 100)
              LayoutBuilder(
                builder: (context, overlayConstraints) {
                  // Only show overlay if we have at least 40px height and 60px width
                  final hasEnoughSpace =
                      overlayConstraints.maxHeight >= 40 &&
                      overlayConstraints.maxWidth >= 60;
                  return hasEnoughSpace
                      ? _buildOverlayContent()
                      : const SizedBox.shrink();
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildOverlayContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes based on available space
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;

        // Determine if we have enough space for different elements
        final hasSpaceForTitle = availableHeight > 30;
        final hasSpaceForDescription = availableHeight > 60;
        final hasSpaceForCTA =
            availableHeight > 80 &&
            widget.ad.ctaText != null &&
            widget.ad.ctaText!.isNotEmpty;

        // Calculate responsive font sizes
        final titleFontSize = availableHeight > 50
            ? 14.0
            : (availableHeight > 35 ? 12.0 : 10.0);
        final descriptionFontSize = availableHeight > 70 ? 12.0 : 10.0;
        final ctaFontSize = availableHeight > 80 ? 10.0 : 8.0;

        // Calculate responsive padding
        final horizontalPadding = availableWidth > 100 ? 8.0 : 4.0;
        final verticalPadding = availableHeight > 50 ? 8.0 : 4.0;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Important: minimize space usage
              children: [
                // Title (only if we have space)
                if (hasSpaceForTitle)
                  Text(
                    widget.ad.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: titleFontSize,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                // Description (only for large ads with enough space)
                if (hasSpaceForDescription)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      widget.ad.description,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: descriptionFontSize,
                      ),
                      maxLines: availableHeight > 80 ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // CTA button (only if we have space and CTA text exists)
                if (hasSpaceForCTA)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: availableWidth > 120 ? 12 : 8,
                        vertical: availableHeight > 90 ? 4 : 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(
                          availableHeight > 90 ? 16 : 12,
                        ),
                      ),
                      child: Text(
                        widget.ad.ctaText!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ctaFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
