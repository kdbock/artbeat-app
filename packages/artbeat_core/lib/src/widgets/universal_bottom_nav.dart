import 'package:flutter/material.dart';
import 'package:artbeat_core/src/theme/artbeat_colors.dart';

class UniversalBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const UniversalBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Beautiful gradient background that matches the app's artistic theme
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.backgroundPrimary,
            ArtbeatColors.primaryPurple.withValues(alpha: 0.02),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                label: 'Art Walk',
              ),
              _buildCaptureButton(context),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.people_outline_rounded,
                activeIcon: Icons.people_rounded,
                label: 'Community',
              ),
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.event_outlined,
                activeIcon: Icons.event_rounded,
                label: 'Events',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (index != currentIndex) onTap(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Beautiful gradient background for active state
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ArtbeatColors.primaryPurple.withValues(alpha: 0.15),
                    ArtbeatColors.primaryGreen.withValues(alpha: 0.15),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          // Subtle shadow for active state
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                // Gradient border effect for active icons
                gradient: isActive
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                          ArtbeatColors.primaryGreen.withValues(alpha: 0.3),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? ArtbeatColors.primaryPurple
                    : ArtbeatColors.textSecondary,
                size: isActive ? 26 : 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? ArtbeatColors.primaryPurple
                    : ArtbeatColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton(BuildContext context) {
    final isActive = currentIndex == 4;

    return GestureDetector(
      onTap: () {
        if (4 != currentIndex) onTap(4);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: isActive ? 64 : 58,
        height: isActive ? 64 : 58,
        decoration: BoxDecoration(
          // Beautiful artistic gradient
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArtbeatColors.primaryPurple,
              ArtbeatColors.primaryGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          // Enhanced shadow for depth
          boxShadow: [
            BoxShadow(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: ArtbeatColors.primaryGreen.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            // Inner glow effect
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.transparent,
              ],
              stops: const [0.3, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: isActive ? 32 : 28,
          ),
        ),
      ),
    );
  }
}
