import 'package:flutter/material.dart';
import '../models/ad_location.dart';
import '../models/ad_artist_approved_model.dart';
import '../services/ad_artist_approved_service.dart';
import 'ad_display_widget.dart';
import 'artist_approved_ad_widget.dart';

/// Widget for placing ads in dashboard screens
class DashboardAdPlacementWidget extends StatefulWidget {
  final AdLocation location;
  final AdDisplayType displayType;
  final String analyticsLocation;
  final EdgeInsets? margin;
  final double? height;

  const DashboardAdPlacementWidget({
    super.key,
    required this.location,
    this.displayType = AdDisplayType.rectangle,
    this.analyticsLocation = 'dashboard',
    this.margin,
    this.height,
  });

  @override
  State<DashboardAdPlacementWidget> createState() =>
      _DashboardAdPlacementWidgetState();
}

class _DashboardAdPlacementWidgetState
    extends State<DashboardAdPlacementWidget> {
  final AdArtistApprovedService _adService = AdArtistApprovedService();
  AdArtistApprovedModel? _currentAd;
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

      final ad = await _adService.getRandomActiveArtistApprovedAd(
        widget.location,
      );

      if (mounted) {
        setState(() {
          _currentAd = ad;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading ad for location ${widget.location}: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything while loading
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // Don't show anything if there's an error or no ad
    if (_hasError || _currentAd == null) {
      return const SizedBox.shrink();
    }

    // Build the ad widget
    Widget adWidget = ArtistApprovedAdWidget(
      ad: _currentAd!,
      displayType: widget.displayType,
      analyticsLocation: widget.analyticsLocation,
      onTap: () => _handleAdTap(_currentAd!),
    );

    // Apply height constraint if specified
    if (widget.height != null) {
      adWidget = SizedBox(height: widget.height, child: adWidget);
    }

    // Apply margin if specified
    if (widget.margin != null) {
      adWidget = Padding(padding: widget.margin!, child: adWidget);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Ad label (optional, for transparency)
          if (_shouldShowAdLabel())
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Sponsored',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // The actual ad
          adWidget,
        ],
      ),
    );
  }

  bool _shouldShowAdLabel() {
    // Show "Sponsored" label for transparency
    return true;
  }

  void _handleAdTap(AdArtistApprovedModel ad) {
    // Navigate to artist profile or destination URL
    if (ad.destinationUrl != null && ad.destinationUrl!.isNotEmpty) {
      _navigateToUrl(ad.destinationUrl!);
    } else {
      _navigateToArtistProfile(ad.artistId);
    }
  }

  void _navigateToUrl(String url) {
    // TODO: Implement URL navigation
    // This could use url_launcher package or in-app browser
    debugPrint('Navigate to URL: $url');
  }

  void _navigateToArtistProfile(String artistId) {
    // TODO: Implement navigation to artist profile
    // This would depend on your app's navigation structure
    debugPrint('Navigate to artist profile: $artistId');

    // Example navigation (adjust based on your routing)
    // Navigator.pushNamed(context, '/artist/profile', arguments: artistId);
  }
}

/// Specialized ad placement widgets for different dashboard sections

class BetweenSectionsAdWidget extends StatelessWidget {
  final AdLocation location;
  final String analyticsLocation;

  const BetweenSectionsAdWidget({
    super.key,
    required this.location,
    this.analyticsLocation = 'dashboard',
  });

  @override
  Widget build(BuildContext context) {
    return DashboardAdPlacementWidget(
      location: location,
      displayType: AdDisplayType.rectangle,
      analyticsLocation: analyticsLocation,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 200,
    );
  }
}

class TopOfPageAdWidget extends StatelessWidget {
  final AdLocation location;
  final String analyticsLocation;

  const TopOfPageAdWidget({
    super.key,
    required this.location,
    this.analyticsLocation = 'dashboard',
  });

  @override
  Widget build(BuildContext context) {
    return DashboardAdPlacementWidget(
      location: location,
      displayType: AdDisplayType.rectangle,
      analyticsLocation: analyticsLocation,
      margin: const EdgeInsets.all(16),
      height: 180,
    );
  }
}

class BottomSectionAdWidget extends StatelessWidget {
  final AdLocation location;
  final String analyticsLocation;

  const BottomSectionAdWidget({
    super.key,
    required this.location,
    this.analyticsLocation = 'dashboard',
  });

  @override
  Widget build(BuildContext context) {
    return DashboardAdPlacementWidget(
      location: location,
      displayType: AdDisplayType.square,
      analyticsLocation: analyticsLocation,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 250,
    );
  }
}

/// Widget for in-feed ads (for community feeds)
class InFeedAdWidget extends StatelessWidget {
  final String analyticsLocation;

  const InFeedAdWidget({super.key, this.analyticsLocation = 'feed'});

  @override
  Widget build(BuildContext context) {
    return DashboardAdPlacementWidget(
      location: AdLocation.communityFeed,
      displayType: AdDisplayType.square,
      analyticsLocation: analyticsLocation,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 300,
    );
  }
}
