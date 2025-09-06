import 'package:flutter/material.dart';
import '../theme/artbeat_colors.dart';
import 'enhanced_navigation_menu.dart';

/// Quick access navigation floating action button
///
/// Provides easy access to all app features through a floating button
/// that opens the enhanced navigation menu
class QuickNavigationFAB extends StatelessWidget {
  /// Custom navigation handler
  final void Function(String)? onNavigate;

  /// Custom position from bottom
  final double? bottom;

  /// Custom position from right
  final double? right;

  /// Whether to show as mini FAB
  final bool mini;

  const QuickNavigationFAB({
    super.key,
    this.onNavigate,
    this.bottom,
    this.right,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom ?? 100,
      right: right ?? 20,
      child: FloatingActionButton(
        onPressed: () => _showNavigationMenu(context),
        backgroundColor: ArtbeatColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 8,
        mini: mini,
        heroTag: "navigation_fab",
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ArtbeatColors.primaryPurple, ArtbeatColors.primaryGreen],
            ),
          ),
          child: const Icon(Icons.explore_outlined, size: 28),
        ),
      ),
    );
  }

  void _showNavigationMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedNavigationMenu(
        onNavigate: (route) {
          Navigator.of(context).pop(); // Close the bottom sheet
          if (onNavigate != null) {
            onNavigate!(route);
          } else {
            Navigator.of(context).pushNamed(route);
          }
        },
      ),
    );
  }
}

/// Enhanced app bar with navigation menu access
///
/// Provides consistent app bar design with quick navigation access
class EnhancedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showNavigationMenu;
  final void Function(String)? onNavigate;

  const EnhancedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showNavigationMenu = true,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> appBarActions = [
      if (showNavigationMenu)
        IconButton(
          icon: const Icon(Icons.explore_outlined),
          onPressed: () => _showNavigationMenu(context),
          tooltip: 'Navigation Menu',
        ),
      ...?actions,
    ];

    return AppBar(
      title: Text(title),
      leading: leading,
      actions: appBarActions.isNotEmpty ? appBarActions : null,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: ArtbeatColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
    );
  }

  void _showNavigationMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedNavigationMenu(
        onNavigate: (route) {
          Navigator.of(context).pop(); // Close the bottom sheet
          if (onNavigate != null) {
            onNavigate!(route);
          } else {
            Navigator.of(context).pushNamed(route);
          }
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
