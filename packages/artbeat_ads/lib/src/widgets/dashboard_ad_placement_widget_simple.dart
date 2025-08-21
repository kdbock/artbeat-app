import 'package:flutter/material.dart';
import '../models/ad_location.dart';
import 'ad_display_widget.dart';

/// Simplified widget for placing rotating ads in dashboard screens
class DashboardAdPlacementWidget extends StatelessWidget {
  final AdLocation location;
  final String analyticsLocation;
  final EdgeInsets? margin;
  final double? height;

  const DashboardAdPlacementWidget({
    super.key,
    required this.location,
    this.analyticsLocation = 'dashboard',
    this.margin,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget adWidget = const AdDisplayWidget();

    // Apply height constraint if specified
    if (height != null) {
      adWidget = SizedBox(height: height, child: adWidget);
    }

    // Apply margin if specified
    if (margin != null) {
      adWidget = Padding(padding: margin!, child: adWidget);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: adWidget,
    );
  }
}
