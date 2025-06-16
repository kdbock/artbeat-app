import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';

class ArtbeatAppHeader extends StatelessWidget implements PreferredSizeWidget {
  const ArtbeatAppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('ARTbeat'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _handleRefresh(context),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.person),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'profile',
              child: Text('Profile'),
            ),
            const PopupMenuItem<String>(
              value: 'settings',
              child: Text('Settings'),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Text('Logout'),
            ),
          ],
          onSelected: (String value) {
            switch (value) {
              case 'profile':
                Navigator.pushNamed(context, '/profile');
                break;
              case 'settings':
                Navigator.pushNamed(context, '/settings');
                break;
              case 'logout':
                Navigator.pushReplacementNamed(context, '/login');
                break;
            }
          },
        ),
      ],
    );
  }

  Future<void> _handleRefresh(BuildContext context) async {
    if (!context.mounted) return;

    final userService = Provider.of<UserService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Show loading indicator
      final navigator = Navigator.of(context);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Refresh data
      await userService.refreshUserData();

      if (context.mounted) {
        navigator.pop(); // Pop loading dialog
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Refresh complete')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Pop loading dialog
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Refresh failed: $error')),
        );
      }
    }
  }
}
