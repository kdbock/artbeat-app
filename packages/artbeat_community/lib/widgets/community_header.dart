import 'package:flutter/material.dart';

class CommunityHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showSearchIcon;
  final bool showMessagingIcon;
  final bool showDeveloperIcon;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onMessagingPressed;
  final VoidCallback? onDeveloperPressed;
  final VoidCallback? onBackPressed;

  const CommunityHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.showSearchIcon = true,
    this.showMessagingIcon = true,
    this.showDeveloperIcon = true,
    this.onSearchPressed,
    this.onMessagingPressed,
    this.onDeveloperPressed,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black87,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF9C27B0), // Purple
              Color(0xFF4CAF50), // Green
            ],
          ),
        ),
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      actions: [
        if (showSearchIcon)
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: onSearchPressed ?? () => _navigateToSearch(context),
          ),
        if (showMessagingIcon)
          IconButton(
            icon: const Icon(Icons.message, color: Colors.black87),
            onPressed:
                onMessagingPressed ?? () => _navigateToMessaging(context),
          ),
        if (showDeveloperIcon)
          IconButton(
            icon: const Icon(Icons.developer_mode, color: Colors.black87),
            onPressed: onDeveloperPressed ?? () => _openDeveloperTools(context),
          ),
        const SizedBox(width: 8), // Small padding from right edge
      ],
    );
  }

  void _navigateToSearch(BuildContext context) {
    Navigator.pushNamed(context, '/community/search');
  }

  void _navigateToMessaging(BuildContext context) {
    Navigator.pushNamed(context, '/community/messaging');
  }

  void _openDeveloperTools(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer Tools'),
        content: const Text(
          'Developer tools will be available in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
