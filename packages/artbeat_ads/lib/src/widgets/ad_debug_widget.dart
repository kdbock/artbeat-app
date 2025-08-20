import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/ad_location.dart';
import '../services/ad_debug_service.dart';
import '../services/ad_fix_service.dart';

/// Debug widget to help troubleshoot ad issues
class AdDebugWidget extends StatelessWidget {
  final AdLocation location;
  final String analyticsLocation;

  const AdDebugWidget({
    super.key,
    required this.location,
    required this.analyticsLocation,
  });

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      constraints: const BoxConstraints(maxHeight: 120), // Limit height
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🔍 AD DEBUG: ${location.name}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Loc: ${location.name} (${location.index}) | Analytics: $analyticsLocation',
              style: const TextStyle(fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: [
                _buildCompactButton(
                  'Debug',
                  Colors.blue,
                  () => AdDebugService.debugAdCollections(),
                ),
                _buildCompactButton(
                  'Query',
                  Colors.green,
                  () => AdDebugService.testAdQuery(location),
                ),
                _buildCompactButton(
                  'Fix',
                  Colors.purple,
                  () => AdFixService.fixAdsForTesting(),
                ),
                _buildCompactButton(
                  'Copy',
                  Colors.orange,
                  () => AdFixService.copyAdsToArtistApprovedCollection(),
                ),
                _buildCompactButton(
                  'Test',
                  Colors.teal,
                  () => AdFixService.createTestAd(),
                ),
                _buildCompactButton(
                  'All',
                  Colors.indigo,
                  () => AdFixService.createTestAdsForAllLocations(),
                ),
                _buildCompactButton(
                  'Clean',
                  Colors.red,
                  () => AdFixService.cleanupPlaceholderUrls(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 24,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(text, style: const TextStyle(fontSize: 10)),
      ),
    );
  }
}
