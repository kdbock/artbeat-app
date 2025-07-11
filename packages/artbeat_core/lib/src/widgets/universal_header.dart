import 'package:flutter/material.dart';
import 'developer_feedback_admin_screen.dart';
import 'feedback_system_info_screen.dart';

/// Universal header widget that provides consistent app bar across all screens
///
/// Features:
/// - Hamburger menu icon (opens drawer or shows placeholder)
/// - ARTbeat logo (with fallback to text)
/// - Search icon (optional)
/// - Developer tools icon (provides access to feedback system)
/// - Customizable title, colors, and actions
///
/// Example usage:
/// ```dart
/// EnhancedUniversalHeader(
///   onSearchPressed: () => Navigator.pushNamed(context, '/search'),
///   title: 'Custom Title', // Optional, will show logo by default
///   showLogo: false, // Set to false to show title instead of logo
///   showDeveloperTools: true, // Show developer icon
/// )
/// ```
class EnhancedUniversalHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final bool showDeveloperTools;
  final bool showBackButton;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onDeveloperPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;

  const EnhancedUniversalHeader({
    super.key,
    this.title,
    this.showLogo = true,
    this.showDeveloperTools = false,
    this.onMenuPressed,
    this.onSearchPressed,
    this.onDeveloperPressed,
    this.onProfilePressed,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? Colors.black87,
      elevation: elevation ?? 0,
      leading: _buildLeadingIcon(context),
      title: _buildTitle(),
      centerTitle: true,
      actions: _buildActions(context),
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    if (showBackButton) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed ?? () => Navigator.maybePop(context),
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed ?? () => _openDrawer(context),
      );
    }
  }

  Widget _buildTitle() {
    if (showLogo) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 32),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Image.asset(
                  'assets/images/artbeat_header.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to text logo if image not found
                    return Text(
                      title ?? 'ARTbeat',
                      style: TextStyle(
                        color: foregroundColor ?? Colors.black87,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } else if (title != null) {
      return Text(
        title!,
        style: TextStyle(
          color: foregroundColor ?? Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    final actionsList = <Widget>[];

    // Always add search icon, use provided callback or fallback to search modal
    actionsList.add(
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: onSearchPressed ?? () => _showSearchModal(context),
      ),
    );

    // Add developer tools icon if enabled
    if (showDeveloperTools) {
      actionsList.add(
        IconButton(
          icon: const Icon(Icons.developer_mode),
          tooltip: 'Developer Tools',
          onPressed: onDeveloperPressed ?? () => _showDeveloperTools(context),
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

  void _showDeveloperTools(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Developer Tools',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.feedback, color: Colors.blue),
              title: const Text('Submit Feedback'),
              subtitle: const Text(
                'Report bugs, request features, or suggest improvements',
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/feedback');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings,
                color: Colors.orange,
              ),
              title: const Text('Admin Panel'),
              subtitle: const Text('View and manage feedback submissions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const DeveloperFeedbackAdminScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.green),
              title: const Text('System Info'),
              subtitle: const Text('Learn about the feedback system'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const FeedbackSystemInfoScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Add default search modal
  void _showSearchModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search ARTbeat',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (query) {
                  // TODO: implement search logic
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
