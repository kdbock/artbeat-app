import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class ArtbeatBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final VoidCallback onCapture;

  const ArtbeatBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      clipBehavior: Clip.antiAlias,
      elevation: 8.0,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Left side of bottom bar
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                  _buildNavItem(1, Icons.map_outlined, Icons.map, 'Art Walk'),
                ],
              ),
            ),

            // Center gap for FAB
            const SizedBox(width: 80),

            // Right side of bottom bar
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    2,
                    Icons.people_outline,
                    Icons.people,
                    'Community',
                  ),
                  _buildNavItem(3, Icons.event_outlined, Icons.event, 'Events'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = index == currentIndex;
    final effectiveIndex = index >= 2
        ? index + 1
        : index; // Account for FAB gap

    return InkWell(
      onTap: () => onTap(effectiveIndex),
      child: SizedBox(
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected
                  ? ArtbeatColors.primaryPurple
                  : ArtbeatColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? ArtbeatColors.primaryPurple
                    : ArtbeatColors.textSecondary,
                fontSize: 12,
                fontFamily: 'FallingSky',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
