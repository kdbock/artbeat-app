import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ad_model.dart';
import '../models/ad_location.dart';
import '../services/simple_ad_service.dart';
import 'simple_ad_display_widget.dart';

/// Simple widget to display ads in specific locations throughout the app
class SimpleAdPlacementWidget extends StatelessWidget {
  final AdLocation location;
  final EdgeInsets? padding;
  final bool showIfEmpty;
  final Widget Function(BuildContext)? emptyBuilder;
  final bool trackAnalytics;

  const SimpleAdPlacementWidget({
    super.key,
    required this.location,
    this.padding,
    this.showIfEmpty = false,
    this.emptyBuilder,
    this.trackAnalytics = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleAdService>(
      builder: (context, adService, child) {
        return StreamBuilder<List<AdModel>>(
          stream: adService.getAdsByLocation(location),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return showIfEmpty
                  ? _buildPlaceholder()
                  : const SizedBox.shrink();
            }

            if (snapshot.hasError) {
              debugPrint(
                'Error loading ads for ${location.name}: ${snapshot.error}',
              );
              return showIfEmpty
                  ? _buildPlaceholder()
                  : const SizedBox.shrink();
            }

            final ads = snapshot.data ?? [];

            if (ads.isEmpty) {
              if (emptyBuilder != null) {
                return emptyBuilder!(context);
              }
              return showIfEmpty
                  ? _buildPlaceholder()
                  : const SizedBox.shrink();
            }

            // Show the first active ad (you could implement rotation logic here)
            final ad = ads.first;

            return Container(
              padding: padding ?? const EdgeInsets.all(8.0),
              child: SimpleAdDisplayWidget(
                ad: ad,
                location: location,
                trackAnalytics: trackAnalytics,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      padding: padding ?? const EdgeInsets.all(8.0),
      child: Container(
        width: double.infinity, // Allow full width instead of fixed 320
        height: 50, // Default to small ad size
        constraints: const BoxConstraints(
          maxWidth: 400,
        ), // Max width constraint
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Text(
            'Ad Space',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

/// Helper widget to easily add ads to any screen
class AdSpaceWidget extends StatelessWidget {
  final AdLocation location;
  final String? customLabel;
  final double? width;
  final double? height;
  final bool trackAnalytics;

  const AdSpaceWidget({
    super.key,
    required this.location,
    this.customLabel,
    this.width,
    this.height,
    this.trackAnalytics = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleAdService>(
      builder: (context, adService, child) {
        return FutureBuilder<int>(
          future: adService.getActiveAdsCount(location),
          builder: (context, snapshot) {
            // Handle error case explicitly
            if (snapshot.hasError) {
              debugPrint('Error getting ad count: ${snapshot.error}');
              // Fall through to show placeholder
            }

            final hasAds = (snapshot.data ?? 0) > 0;

            if (hasAds) {
              return SimpleAdPlacementWidget(
                location: location,
                trackAnalytics: trackAnalytics,
              );
            }

            // Show placeholder for development/testing or when there's an error
            return Container(
              width:
                  width ??
                  double.infinity, // Allow full width instead of fixed 320
              height: height ?? 50,
              constraints: BoxConstraints(
                maxWidth: width ?? 400,
              ), // Max width constraint
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customLabel ?? '${location.displayName} Ad',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
