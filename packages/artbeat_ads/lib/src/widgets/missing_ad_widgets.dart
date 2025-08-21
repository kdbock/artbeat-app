import 'package:flutter/material.dart';
import '../models/ad_location.dart';
import 'ad_display_widget.dart';

/// Simple placeholder for BetweenSectionsAdWidget
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
    return AdDisplayWidget(location: location);
  }
}

/// Simple placeholder for InFeedAdWidget
Widget InFeedAdWidget({
  AdLocation? location,
  dynamic displayType,
  String? analyticsLocation,
}) {
  return AdDisplayWidget(location: location);
}
