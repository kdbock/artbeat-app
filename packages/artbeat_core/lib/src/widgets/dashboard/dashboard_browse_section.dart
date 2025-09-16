import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Dashboard section that provides quick access to browse functionality
class DashboardBrowseSection extends StatelessWidget {
  final DashboardViewModel viewModel;

  const DashboardBrowseSection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                        ArtbeatColors.primaryBlue.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.explore_rounded,
                    color: ArtbeatColors.primaryPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore Everything',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Discover all content in one place',
                        style: TextStyle(
                          fontSize: 14,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Browse cards
          SizedBox(
            height: 120, // Reduce height from 140 to 120 to match card height
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: [
                _buildBrowseCard(
                  context,
                  'Browse All',
                  'Everything in one place',
                  Icons.explore_rounded,
                  ArtbeatColors.primaryPurple,
                  () => Navigator.pushNamed(context, '/browse'),
                ),
                const SizedBox(width: 12),
                _buildBrowseCard(
                  context,
                  'Artists',
                  'Discover creators',
                  Icons.people_rounded,
                  ArtbeatColors.primaryBlue,
                  () => Navigator.pushNamed(context, '/artist/browse'),
                ),
                const SizedBox(width: 12),
                _buildBrowseCard(
                  context,
                  'Artwork',
                  'Beautiful creations',
                  Icons.image_rounded,
                  ArtbeatColors.accentOrange,
                  () => Navigator.pushNamed(context, '/artwork/browse'),
                ),
                const SizedBox(width: 12),
                _buildBrowseCard(
                  context,
                  'Captures',
                  'Photo discoveries',
                  Icons.camera_alt_rounded,
                  ArtbeatColors.primaryBlue,
                  () => Navigator.pushNamed(context, '/capture/browse'),
                ),
                const SizedBox(width: 12),
                _buildBrowseCard(
                  context,
                  'Art Walks',
                  'Guided experiences',
                  Icons.map_rounded,
                  ArtbeatColors.primaryGreen,
                  () => Navigator.pushNamed(context, '/art-walk/list'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120, // Add fixed height to prevent overflow
        padding: const EdgeInsets.all(12), // Reduce padding from 16 to 12
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Use min to prevent expansion
          children: [
            Container(
              padding: const EdgeInsets.all(8), // Reduce padding from 12 to 8
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ), // Reduce icon size from 24 to 20
            ),
            const SizedBox(height: 8), // Reduce spacing from 12 to 8
            Flexible(
              // Use Flexible to prevent overflow
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12, // Reduce font size from 14 to 12
                  fontWeight: FontWeight.w600,
                  color: ArtbeatColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2), // Reduce spacing from 4 to 2
            Flexible(
              // Use Flexible to prevent overflow
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10, // Reduce font size from 11 to 10
                  color: ArtbeatColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
