import 'package:flutter/material.dart';

/// Universal header widget that provides consistent app bar across all screens
/// 
/// Features:
/// - Hamburger menu icon (opens drawer or shows placeholder)
/// - ARTbeat logo (with fallback to text)
/// - Search icon (optional)
/// - Customizable title, colors, and actions
/// 
/// Example usage:
/// ```dart
/// UniversalHeader(
///   onSearchPressed: () => Navigator.pushNamed(context, '/search'),
///   title: 'Custom Title', // Optional, will show logo by default
///   showLogo: false, // Set to false to show title instead of logo
/// )
/// ```
class UniversalHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onSearchPressed;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;

  const UniversalHeader({
    super.key,
    this.title,
    this.showLogo = true,
    this.onMenuPressed,
    this.onSearchPressed,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? Colors.black87,
      elevation: elevation ?? 0,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed ?? () => _openDrawer(context),
      ),
      title: _buildTitle(),
      centerTitle: true,
      actions: _buildActions(),
    );
  }

  Widget _buildTitle() {
    if (showLogo) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Try to load the logo image, fallback to text if not found
          Image.asset(
            'assets/images/artbeat_header.png',
            height: 32,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to text logo if image not found
              return Text(
                title ?? 'ARTbeat',
                style: TextStyle(
                  color: foregroundColor ?? Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              );
            },
          ),
        ],
      );
    } else if (title != null) {
      return Text(
        title!,
        style: TextStyle(
          color: foregroundColor ?? Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  List<Widget> _buildActions() {
    final actionsList = <Widget>[];
    
    // Add search icon if callback provided
    if (onSearchPressed != null) {
      actionsList.add(
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: onSearchPressed,
        ),
      );
    }
    
    // Add any additional actions
    if (actions != null) {
      actionsList.addAll(actions!);
    }
    
    return actionsList;
  }

  void _openDrawer(BuildContext context) {
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.hasDrawer) {
      scaffoldState.openDrawer();
    } else {
      // If no drawer, show a placeholder action
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menu functionality coming soon!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
