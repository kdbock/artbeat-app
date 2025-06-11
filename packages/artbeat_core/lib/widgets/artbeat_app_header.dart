import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/artbeat_colors.dart';
import '../theme/artbeat_typography.dart';

class ArtbeatAppHeader extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;

  const ArtbeatAppHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.onBackPressed,
    this.bottom,
    this.actions,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(bottom == null ? kToolbarHeight : kToolbarHeight + 48);

  @override
  State<ArtbeatAppHeader> createState() => _ArtbeatAppHeaderState();
}

class _ArtbeatAppHeaderState extends State<ArtbeatAppHeader> {
  final _auth = FirebaseAuth.instance;

  void _showUserMenu() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<void>(
      context: context,
      position: position,
      items: <PopupMenuEntry<void>>[
        PopupMenuItem<void>(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('View Profile'),
            onTap: () {
              Navigator.pop(context); // Close menu
              Navigator.pushNamed(context, '/profile/view');
            },
          ),
        ),
        PopupMenuItem<void>(
          child: ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Profile'),
            onTap: () {
              Navigator.pop(context); // Close menu
              Navigator.pushNamed(context, '/profile/edit');
            },
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<void>(
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context); // Close menu
              // Get the current context before async gap
              final navigatorContext = context;
              await _auth.signOut();
              // Use the captured context after checking if widget is mounted
              if (mounted) {
                Navigator.pushReplacementNamed(navigatorContext, '/login');
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: widget.showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBackPressed ?? () => Navigator.pop(context),
            )
          : IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
      title: Text(
        widget.title,
        style: ArtbeatTypography.textTheme.headlineMedium,
      ),
      actions: [
        if (widget.actions != null) ...widget.actions!,
        // Search button
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // TODO: Implement search functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Search coming soon')),
            );
          },
        ),
        // Notifications button
        IconButton(
          icon: const Stack(
            children: [
              Icon(Icons.notifications_outlined),
              Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  Icons.brightness_1,
                  size: 12,
                  color: ArtbeatColors.primaryPurple,
                ),
              ),
            ],
          ),
          onPressed: () {
            // TODO: Implement notifications view
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon')),
            );
          },
        ),
        // User avatar
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: _showUserMenu,
            borderRadius: BorderRadius.circular(20),
            child: StreamBuilder<User?>(
              stream: _auth.userChanges(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                if (user?.photoURL != null) {
                  return CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(user!.photoURL!),
                  );
                }
                return const CircleAvatar(
                  radius: 16,
                  backgroundImage: AssetImage('assets/default_profile.png'),
                );
              },
            ),
          ),
        ),
      ],
      bottom: widget.bottom,
    );
  }
}
