import 'package:flutter/material.dart';
import '../models/ad_location.dart';
import 'simple_ad_placement_widget.dart';

/// Banner ad widget for top/bottom placement
class BannerAdWidget extends StatelessWidget {
  final AdLocation location;
  final bool showAtTop;
  final EdgeInsets? padding;
  final double? maxWidth;

  const BannerAdWidget({
    super.key,
    required this.location,
    this.showAtTop = true,
    this.padding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive width based on screen size
        final screenWidth = MediaQuery.of(context).size.width;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screenWidth - 32; // Account for padding

        // Use the smaller of maxWidth (if provided) or available width
        final adWidth = maxWidth != null
            ? maxWidth!.clamp(200.0, availableWidth)
            : availableWidth.clamp(
                200.0,
                400.0,
              ); // Allow up to 400px for better display

        return SizedBox(
          width: adWidth,
          child: SimpleAdPlacementWidget(
            location: location,
            padding: padding ?? const EdgeInsets.all(8.0),
            showIfEmpty: true, // Show placeholder when no ads are available
          ),
        );
      },
    );
  }
}

/// Feed ad widget for content integration
class FeedAdWidget extends StatelessWidget {
  final AdLocation location;
  final int index;
  final EdgeInsets? padding;

  const FeedAdWidget({
    super.key,
    required this.location,
    required this.index,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleAdPlacementWidget(
      location: location,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8.0),
    );
  }
}

/// Legacy compatibility widgets
class BetweenSectionsAdWidget extends StatelessWidget {
  final AdLocation? location;
  final dynamic displayType;
  final String? analyticsLocation;

  const BetweenSectionsAdWidget({
    super.key,
    this.location,
    this.displayType,
    this.analyticsLocation,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleAdPlacementWidget(
      location: location ?? AdLocation.fluidDashboard,
    );
  }
}

/// Legacy compatibility function
Widget InFeedAdWidget({
  AdLocation? location,
  dynamic displayType,
  String? analyticsLocation,
}) {
  return SimpleAdPlacementWidget(
    location: location ?? AdLocation.communityInFeed,
  );
}
