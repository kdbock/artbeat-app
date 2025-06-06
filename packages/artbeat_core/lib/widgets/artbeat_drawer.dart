import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/artbeat_colors.dart';
import '../theme/artbeat_typography.dart';
import 'artbeat_drawer_items.dart';

class ArtbeatDrawer extends StatelessWidget {
  const ArtbeatDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ArtbeatColors.primaryPurple.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ArtbeatColors.primaryPurple,
                    ArtbeatColors.primaryGreen,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.userChanges(),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      return CircleAvatar(
                        radius: 30,
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : const AssetImage('assets/default_profile.png')
                                as ImageProvider,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.userChanges(),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Guest User',
                            style: ArtbeatTypography.textTheme.titleMedium
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: ArtbeatTypography.textTheme.bodyMedium
                                ?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            ...ArtbeatDrawerItems.mainItems.map((item) => ListTile(
                  leading: Icon(item.icon, color: ArtbeatColors.primaryPurple),
                  title: Text(
                    item.title,
                    style: ArtbeatTypography.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    if (item.route != ModalRoute.of(context)?.settings.name) {
                      Navigator.pushNamed(context, item.route);
                    }
                  },
                )),
            const Divider(),
            ...ArtbeatDrawerItems.settingsItems.map((item) => ListTile(
                  leading: Icon(item.icon, color: ArtbeatColors.primaryPurple),
                  title: Text(
                    item.title,
                    style: ArtbeatTypography.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.pushNamed(context, item.route);
                  },
                )),
            const Divider(),
            ListTile(
              leading: Icon(
                ArtbeatDrawerItems.signOut.icon,
                color: ArtbeatDrawerItems.signOut.color,
              ),
              title: Text(
                ArtbeatDrawerItems.signOut.title,
                style: ArtbeatTypography.textTheme.bodyMedium?.copyWith(
                  color: ArtbeatDrawerItems.signOut.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(
                      context, ArtbeatDrawerItems.signOut.route);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
