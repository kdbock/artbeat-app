import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';

import '../models/ad_model.dart';
import '../models/ad_location.dart';
import '../services/simple_ad_service.dart';
import 'simple_ad_display_widget.dart';

/// Ad placement widget that rotates through multiple ads for the same location
class RotatingAdPlacementWidget extends StatefulWidget {
  final AdLocation location;
  final EdgeInsets? padding;
  final bool showIfEmpty;
  final Widget Function(BuildContext)? emptyBuilder;
  final bool trackAnalytics;
  final Duration rotationInterval;
  final int? adIndex; // Optional index to show a specific ad from the pool

  const RotatingAdPlacementWidget({
    super.key,
    required this.location,
    this.padding,
    this.showIfEmpty = false,
    this.emptyBuilder,
    this.trackAnalytics = true,
    this.rotationInterval = const Duration(seconds: 30),
    this.adIndex,
  });

  @override
  State<RotatingAdPlacementWidget> createState() =>
      _RotatingAdPlacementWidgetState();
}

class _RotatingAdPlacementWidgetState extends State<RotatingAdPlacementWidget> {
  int _currentAdIndex = 0;
  Timer? _rotationTimer;
  List<AdModel> _cachedAds = [];

  @override
  void initState() {
    super.initState();
    // If a specific ad index is provided, use it
    if (widget.adIndex != null) {
      _currentAdIndex = widget.adIndex!;
    } else {
      // Otherwise, start with a random index to ensure different widgets show different ads initially
      _currentAdIndex = Random().nextInt(
        1000,
      ); // Will be modded by actual ad count
    }
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _startRotation(List<AdModel> ads) {
    _rotationTimer?.cancel();

    if (ads.length <= 1 || widget.adIndex != null) {
      // Don't rotate if there's only one ad or if a specific index is requested
      return;
    }

    _rotationTimer = Timer.periodic(widget.rotationInterval, (timer) {
      if (mounted && ads.isNotEmpty) {
        setState(() {
          _currentAdIndex = (_currentAdIndex + 1) % ads.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleAdService>(
      builder: (context, adService, child) {
        return StreamBuilder<List<AdModel>>(
          stream: adService.getAdsByLocation(widget.location),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return widget.showIfEmpty
                  ? _buildPlaceholder()
                  : const SizedBox.shrink();
            }

            if (snapshot.hasError) {
              debugPrint(
                'Error loading ads for ${widget.location.name}: ${snapshot.error}',
              );
              return widget.showIfEmpty
                  ? _buildPlaceholder()
                  : const SizedBox.shrink();
            }

            final ads = snapshot.data ?? [];

            if (ads.isEmpty) {
              if (widget.emptyBuilder != null) {
                return widget.emptyBuilder!(context);
              }
              return widget.showIfEmpty
                  ? _buildPlaceholder()
                  : const SizedBox.shrink();
            }

            // Update cached ads and restart rotation if needed
            if (_cachedAds.length != ads.length) {
              _cachedAds = ads;
              _startRotation(ads);
            }

            // Get the current ad to display
            final safeIndex = _currentAdIndex % ads.length;
            final ad = ads[safeIndex];

            return Container(
              padding: widget.padding ?? const EdgeInsets.all(8.0),
              child: SimpleAdDisplayWidget(
                ad: ad,
                location: widget.location,
                trackAnalytics: widget.trackAnalytics,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(8.0),
      child: Container(
        width: double.infinity,
        height: 50,
        constraints: const BoxConstraints(maxWidth: 400),
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
