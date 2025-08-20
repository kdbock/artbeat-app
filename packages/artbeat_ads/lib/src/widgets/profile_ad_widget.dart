import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/ad_model.dart';
import '../models/ad_location.dart';
import '../services/ad_service.dart';

/// A widget that displays ads specifically for the profile screen
class ProfileAdWidget extends StatefulWidget {
  final EdgeInsets? margin;
  final double? height;
  final bool showPlaceholder;

  const ProfileAdWidget({
    super.key,
    this.margin,
    this.height,
    this.showPlaceholder = true,
  });

  @override
  State<ProfileAdWidget> createState() => _ProfileAdWidgetState();
}

class _ProfileAdWidgetState extends State<ProfileAdWidget> {
  final AdService _adService = AdService();
  AdModel? _currentAd;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final ad = await _adService.getRandomAdForLocation(
        AdLocation.communityFeed,
      );

      if (mounted) {
        setState(() {
          _currentAd = ad;
          _isLoading = false;
        });

        // Track ad impression
        if (ad != null) {
          _trackAdImpression(ad);
        }
      }
    } catch (e) {
      debugPrint('Error loading profile ad: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _handleAdTap(AdModel ad) {
    // Log ad click for analytics
    debugPrint('Ad clicked: ${ad.title}');

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Track ad click
    _trackAdClick(ad);

    // Navigate to ad target (artist profile, artwork, etc.)
    _navigateToAdTarget(ad);
  }

  /// Track ad impression
  void _trackAdImpression(AdModel ad) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _adService.trackAdImpression(ad.id, user.uid);
    }
  }

  /// Track ad click
  void _trackAdClick(AdModel ad) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _adService.trackAdClick(ad.id, user.uid);
    }
  }

  /// Navigate to the appropriate target based on ad content
  void _navigateToAdTarget(AdModel ad) {
    if (!mounted) return;

    // Navigate based on targetId if available
    if (ad.targetId != null && ad.targetId!.isNotEmpty) {
      _navigateToTarget(ad.targetId!);
    } else {
      // Fallback: navigate based on owner type
      _navigateToOwnerProfile(ad.ownerId);
    }
  }

  /// Navigate to a specific target (artist, artwork, gallery, etc.)
  void _navigateToTarget(String targetId) {
    // Try to determine the target type from the targetId prefix or other indicators
    // For now, we'll try artist profile first as it's most common
    Navigator.pushNamed(
      context,
      '/artist/profile',
      arguments: {'artistId': targetId},
    ).catchError((_) {
      // If artist profile fails, try artwork
      return Navigator.pushNamed(
        context,
        '/artwork/details',
        arguments: {'artworkId': targetId},
      ).catchError((_) {
        // If that fails too, show a generic message
        _showNavigationError();
        return null;
      });
    });
  }

  /// Navigate to the owner's profile
  void _navigateToOwnerProfile(String ownerId) {
    // For now, assume owner profile is accessible via user profile route
    Navigator.pushNamed(
      context,
      '/profile/view',
      arguments: {'userId': ownerId},
    ).catchError((_) {
      _showNavigationError();
      return null;
    });
  }

  /// Show error message when navigation fails
  void _showNavigationError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to navigate to ad content'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingPlaceholder();
    }

    if (_hasError || _currentAd == null) {
      return widget.showPlaceholder
          ? _buildPlaceholder()
          : const SizedBox.shrink();
    }

    return _buildAdContainer(_currentAd!);
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      margin: widget.margin ?? const EdgeInsets.all(16),
      height: widget.height ?? 100,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ArtbeatColors.primaryPurple,
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Loading ad...',
              style: TextStyle(
                color: ArtbeatColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      margin: widget.margin ?? const EdgeInsets.all(16),
      height: widget.height ?? 100,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              color: ArtbeatColors.textSecondary,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              'Advertisement Space',
              style: TextStyle(
                color: ArtbeatColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Support local artists',
              style: TextStyle(
                color: ArtbeatColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdContainer(AdModel ad) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.all(16),
      height: widget.height ?? 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArtbeatColors.border.withAlpha(128)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ad Content
          GestureDetector(
            onTap: () => _handleAdTap(ad),
            child: Row(
              children: [
                // Ad Image
                Container(
                  width: 80,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: ImageManagementService().getOptimizedImage(
                      imageUrl: ad.imageUrl,
                      fit: BoxFit.cover,
                      width: 80,
                      height: widget.height ?? 100,
                      isThumbnail: true,
                      errorWidget: Container(
                        color: ArtbeatColors.backgroundSecondary,
                        child: const Icon(
                          Icons.image_outlined,
                          color: ArtbeatColors.textSecondary,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                // Ad Text Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ad.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ArtbeatColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ad.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: ArtbeatColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 14,
                              color: ArtbeatColors.primaryPurple,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Learn More',
                              style: TextStyle(
                                fontSize: 12,
                                color: ArtbeatColors.primaryPurple,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Ad Label
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(128),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Ad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
