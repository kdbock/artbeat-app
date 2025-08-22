import 'package:flutter/material.dart';
import '../models/ad_location.dart';
import 'simple_ad_placement_widget.dart';

/// Banner ad widget for top/bottom placement
class BannerAdWidget extends StatelessWidget {
  final AdLocation location;
  final bool showAtTop;
  final EdgeInsets? padding;

  const BannerAdWidget({
    super.key,
    required this.location,
    this.showAtTop = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleAdPlacementWidget(
      location: location,
      padding: padding ?? const EdgeInsets.all(8.0),
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
    return SimpleAdPlacementWidget(location: location ?? AdLocation.dashboard);
  }
}

/// Legacy compatibility function
Widget InFeedAdWidget({
  AdLocation? location,
  dynamic displayType,
  String? analyticsLocation,
}) {
  return SimpleAdPlacementWidget(
    location: location ?? AdLocation.communityFeed,
  );
}
