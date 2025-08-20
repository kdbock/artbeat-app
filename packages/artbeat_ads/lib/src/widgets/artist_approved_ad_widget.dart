import 'dart:async';
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/ad_artist_approved_model.dart';
import '../services/ad_artist_approved_service.dart';
import 'ad_display_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/ad_image_utils.dart';

/// Widget to display Artist Approved Ads with GIF animation support
class ArtistApprovedAdWidget extends StatefulWidget {
  final AdArtistApprovedModel ad;
  final AdDisplayType displayType;
  final VoidCallback? onTap;
  final String analyticsLocation;

  const ArtistApprovedAdWidget({
    super.key,
    required this.ad,
    this.displayType = AdDisplayType.rectangle,
    this.onTap,
    this.analyticsLocation = 'dashboard',
  });

  @override
  State<ArtistApprovedAdWidget> createState() => _ArtistApprovedAdWidgetState();
}

class _ArtistApprovedAdWidgetState extends State<ArtistApprovedAdWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Timer _imageTimer;
  int _currentImageIndex = 0;
  bool _hasTrackedImpression = false;
  final AdArtistApprovedService _adService = AdArtistApprovedService();

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for smooth transitions
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Start the GIF animation if auto-play is enabled
    if (widget.ad.autoPlay && widget.ad.artworkImageUrls.length > 1) {
      _startImageAnimation();
    }

    // Track impression after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackImpression();
    });
  }

  @override
  void dispose() {
    _imageTimer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startImageAnimation() {
    _imageTimer = Timer.periodic(
      Duration(milliseconds: widget.ad.animationSpeed),
      (timer) {
        if (mounted && widget.ad.artworkImageUrls.isNotEmpty) {
          setState(() {
            _currentImageIndex =
                (_currentImageIndex + 1) % widget.ad.artworkImageUrls.length;
          });
          _animationController.forward(from: 0);
        }
      },
    );
  }

  void _trackImpression() {
    if (_hasTrackedImpression) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _adService.trackAdImpression(
        widget.ad.id,
        user.uid,
        widget.analyticsLocation,
      );
      _hasTrackedImpression = true;
    }
  }

  void _handleTap() {
    // Track click
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _adService.trackAdClick(widget.ad.id, user.uid, widget.analyticsLocation);
    }

    // Execute custom onTap or default behavior
    if (widget.onTap != null) {
      widget.onTap!();
    } else if (widget.ad.destinationUrl != null) {
      // Default behavior: navigate to destination URL or artist profile
      _navigateToDestination();
    }
  }

  void _navigateToDestination() {
    // TODO: Implement navigation to artist profile or external URL
    // This would depend on your app's navigation structure
    debugPrint('Navigate to: ${widget.ad.destinationUrl}');
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.displayType == AdDisplayType.square
        ? const Size(300, 300)
        : const Size(400, 200);

    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: size.width,
        height: size.height,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section with GIF animation
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: _buildAnimatedImage(size),
              ),
            ),

            // Content section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Artist avatar and name row
                    Row(
                      children: [
                        // Artist avatar
                        CircleAvatar(
                          radius: 12,
                          backgroundImage:
                              _isValidImageUrl(widget.ad.avatarImageUrl)
                              ? NetworkImage(widget.ad.avatarImageUrl)
                              : null,
                          child: !_isValidImageUrl(widget.ad.avatarImageUrl)
                              ? const Icon(Icons.person, size: 12)
                              : null,
                        ),
                        const SizedBox(width: 6),

                        // Artist name and tagline
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.ad.title,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontSize: 12,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.ad.tagline.isNotEmpty)
                                Text(
                                  widget.ad.tagline,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.black54,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 10,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),

                        // CTA button (moved to the right side)
                        if (widget.ad.ctaText != null)
                          TextButton(
                            onPressed: _handleTap,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              widget.ad.ctaText!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Description (flexible, not expanded)
                    if (widget.ad.description.isNotEmpty)
                      Flexible(
                        child: Text(
                          widget.ad.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.black54, fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedImage(Size size) {
    if (widget.ad.artworkImageUrls.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image, size: 48, color: Colors.grey),
        ),
      );
    }

    // If only one image, show it statically
    if (widget.ad.artworkImageUrls.length == 1) {
      return ImageManagementService().getOptimizedImage(
        imageUrl: widget.ad.artworkImageUrls.first,
        fit: BoxFit.cover,
        width: size.width,
        height: size.height * 0.6,
        isThumbnail: true,
        errorWidget: const Icon(Icons.broken_image, size: 48),
      );
    }

    // Multiple images - show with animation
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Current image
            Positioned.fill(
              child: ImageManagementService().getOptimizedImage(
                imageUrl: widget.ad.artworkImageUrls[_currentImageIndex],
                fit: BoxFit.cover,
                width: size.width,
                height: size.height * 0.6,
                isThumbnail: true,
                errorWidget: const Icon(Icons.broken_image, size: 48),
              ),
            ),

            // Animation indicator (optional)
            if (widget.ad.autoPlay)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${_currentImageIndex + 1}/${widget.ad.artworkImageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Validates if the image URL is valid and not a placeholder
  bool _isValidImageUrl(String url) {
    return AdImageUtils.isValidImageUrl(url);
  }
}
