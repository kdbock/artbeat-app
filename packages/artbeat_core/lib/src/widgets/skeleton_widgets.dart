import 'package:flutter/material.dart';

/// Skeleton loading widgets for progressive loading UI
class SkeletonWidgets {
  /// Creates a shimmer effect animation controller
  static AnimationController createShimmerController(TickerProvider vsync) {
    return AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: vsync,
    )..repeat();
  }

  /// Base skeleton container with shimmer effect
  static Widget skeleton({
    required double width,
    required double height,
    BorderRadius? borderRadius,
    required Animation<double> animation,
    bool flexible = false,
  }) {
    final skeletonWidget = AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: flexible ? null : width,
          height: height,
          constraints: flexible ? BoxConstraints(maxWidth: width) : null,
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + animation.value * 2, 0.0),
              end: Alignment(1.0 + animation.value * 2, 0.0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );

    return flexible ? Flexible(child: skeletonWidget) : skeletonWidget;
  }

  /// Skeleton for artist cards
  static Widget artistCardSkeleton(Animation<double> animation) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Artist image skeleton
          skeleton(
            width: 160,
            height: 120,
            borderRadius: BorderRadius.circular(12),
            animation: animation,
          ),
          const SizedBox(height: 8),
          // Artist name skeleton
          skeleton(
            width: 120,
            height: 16,
            borderRadius: BorderRadius.circular(4),
            animation: animation,
            flexible: true,
          ),
          const SizedBox(height: 4),
          // Artist subtitle skeleton
          skeleton(
            width: 80,
            height: 12,
            borderRadius: BorderRadius.circular(4),
            animation: animation,
            flexible: true,
          ),
        ],
      ),
    );
  }

  /// Skeleton for artwork cards
  static Widget artworkCardSkeleton(Animation<double> animation) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Artwork image skeleton
          skeleton(
            width: 200,
            height: 150,
            borderRadius: BorderRadius.circular(12),
            animation: animation,
          ),
          const SizedBox(height: 8),
          // Artwork title skeleton
          skeleton(
            width: 150,
            height: 16,
            borderRadius: BorderRadius.circular(4),
            animation: animation,
            flexible: true,
          ),
          const SizedBox(height: 4),
          // Artist name skeleton
          skeleton(
            width: 100,
            height: 12,
            borderRadius: BorderRadius.circular(4),
            animation: animation,
            flexible: true,
          ),
        ],
      ),
    );
  }

  /// Skeleton for capture cards
  static Widget captureCardSkeleton(Animation<double> animation) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Capture image skeleton
          skeleton(
            width: 140,
            height: 140,
            borderRadius: BorderRadius.circular(8),
            animation: animation,
          ),
          const SizedBox(height: 6),
          // Location skeleton
          skeleton(
            width: 100,
            height: 12,
            borderRadius: BorderRadius.circular(4),
            animation: animation,
            flexible: true,
          ),
        ],
      ),
    );
  }

  /// Skeleton for community post cards
  static Widget communityPostSkeleton(Animation<double> animation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Profile picture skeleton
              skeleton(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.circular(20),
                animation: animation,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Username skeleton
                  skeleton(
                    width: 120,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                    animation: animation,
                    flexible: true,
                  ),
                  const SizedBox(height: 4),
                  // Time skeleton
                  skeleton(
                    width: 60,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                    animation: animation,
                    flexible: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Post content skeleton
          skeleton(
            width: double.infinity,
            height: 16,
            borderRadius: BorderRadius.circular(4),
            animation: animation,
            flexible: true,
          ),
          const SizedBox(height: 8),
          skeleton(
            width: 200,
            height: 16,
            borderRadius: BorderRadius.circular(4),
            animation: animation,
            flexible: true,
          ),
        ],
      ),
    );
  }

  /// Skeleton for event cards
  static Widget eventCardSkeleton(Animation<double> animation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Date skeleton
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade100,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                skeleton(
                  width: 30,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                  animation: animation,
                  flexible: true,
                ),
                const SizedBox(height: 4),
                skeleton(
                  width: 20,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                  animation: animation,
                  flexible: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Event title skeleton
                skeleton(
                  width: 180,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                  animation: animation,
                  flexible: true,
                ),
                const SizedBox(height: 8),
                // Event location skeleton
                skeleton(
                  width: 120,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                  animation: animation,
                  flexible: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section header skeleton
  static Widget sectionHeaderSkeleton(Animation<double> animation) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          skeleton(
            width: 150,
            height: 20,
            borderRadius: BorderRadius.circular(4),
            animation: animation,
            flexible: true,
          ),
          skeleton(
            width: 60,
            height: 16,
            borderRadius: BorderRadius.circular(4),
            animation: animation,
            flexible: true,
          ),
        ],
      ),
    );
  }
}
