import 'package:flutter/material.dart';
import 'package:artbeat/utils/nc_location_helper.dart';

/// A widget that displays a region marker on maps or in lists
/// with the appropriate styling based on the region
class NCRegionMarkerWidget extends StatelessWidget {
  /// The region name to display
  final String regionName;

  /// Whether to show the region icon
  final bool showIcon;

  /// Whether to use a smaller size for the marker
  final bool isSmall;

  /// Callback when the marker is tapped
  final VoidCallback? onTap;

  const NCRegionMarkerWidget({
    super.key,
    required this.regionName,
    this.showIcon = true,
    this.isSmall = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final helper = NCLocationHelper();
    final color = helper.getColorForRegion(regionName);
    final icon = showIcon ? helper.getIconForRegion(regionName) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 8.0 : 12.0,
          vertical: isSmall ? 4.0 : 6.0,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon && icon != null) ...[
              Icon(
                icon,
                color: Colors.white,
                size: isSmall ? 14 : 18,
              ),
              SizedBox(width: isSmall ? 4 : 6),
            ],
            Text(
              regionName,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
