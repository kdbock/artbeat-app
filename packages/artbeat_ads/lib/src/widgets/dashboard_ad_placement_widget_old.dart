import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ad_location.dart';
import '../models/ad_model.dart';
import '../models/ad_display_type.dart';
import '../services/ad_service.dart';
import 'ad_display_widget.dart';

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
        _currentAd = null;
      });

      // Load regular ads
      final ad = await _adService.getRandomAdForLocation(widget.location);

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
      debugPrint('🔄 Ad placement loading for ${widget.location.name}');
      return const SizedBox.shrink();
    }

    // Don't show anything if there's an error or no ads available
    if (_hasError || _currentAd == null) {
      debugPrint(
        '❌ No ads available for ${widget.location.name} - Error: $_hasError',
      );
      return const SizedBox.shrink();
    }

    debugPrint('✅ Displaying ad for ${widget.location.name}');
    debugPrint(
      '📊 Ad data: title="${_currentAd!.title}", artworkUrls=${_currentAd!.artworkUrls.length} images',
    );
    if (_currentAd!.artworkUrls.isNotEmpty) {
      debugPrint('🖼️ Artwork URLs: ${_currentAd!.artworkUrls}');
    }

    // Build the ad widget - now using simple rotating placeholder version
    Widget adWidget = const AdDisplayWidget();

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

  void _handleAdTap(AdModel ad) {
    // Track the click for analytics
    _trackAdClick(ad);

    // Navigate to destination URL if available
    if (ad.destinationUrl != null && ad.destinationUrl!.isNotEmpty) {
      _navigateToUrl(ad.destinationUrl!);
    } else {
      // Could navigate to ad owner's profile or other default action
      debugPrint('Ad tapped: ${ad.title}');
    }
  }

  void _trackAdClick(AdModel ad) {
    // Track click for regular ads
    try {
      _adService.trackAdClick(
        ad.id,
        'anonymous_user',
      ); // You might want to get actual user ID
    } catch (e) {
      debugPrint('Error tracking regular ad click: $e');
    }
  }

  Future<void> _navigateToUrl(String url) async {
    debugPrint('Navigate to URL: $url');

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch URL: $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open link: $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to open link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 108, // 100px ad + 8px margin
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 108, // 100px ad + 8px margin
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
      height: 108, // 100px ad + 8px margin
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
      displayType: AdDisplayType.rectangle,
      analyticsLocation: analyticsLocation,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 108, // 100px ad + 8px margin
    );
  }
}
