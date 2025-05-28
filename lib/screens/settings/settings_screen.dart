import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          // User info header
          if (user != null)
            ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    user.photoURL != null && user.photoURL!.isNotEmpty
                        ? NetworkImage(user.photoURL!) as ImageProvider
                        : const AssetImage('assets/default_profile.png'),
                radius: 25,
              ),
              title: Text(
                user.displayName ?? 'WordNerd User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(user.email ?? ''),
              onTap: () {
                // Navigate to profile
                Navigator.pushNamed(
                  context,
                  '/profile/view',
                  arguments: {'userId': user.uid, 'isCurrentUser': true},
                );
              },
            ),

          const Divider(),

          // Account settings
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Account Settings'),
            subtitle: const Text('Manage username, email, password, and phone'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/settings/account');
            },
          ),

          // Privacy settings
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Privacy Settings'),
            subtitle: const Text('Control who can see and interact with you'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/settings/privacy');
            },
          ),

          // Notification settings
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notification Settings'),
            subtitle: const Text('Manage how you receive notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/settings/notifications');
            },
          ),

          // Security settings
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security Settings'),
            subtitle: const Text(
              'Protect your account with additional security',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/settings/security');
            },
          ),

          // Artist Subscription
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Artist Subscription'),
            subtitle: const Text('Manage your artist profile and subscription'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/artist/dashboard');
            },
          ),

          // Favorites
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('My Favorites'),
            subtitle: const Text('View and manage your favorite items'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                Navigator.pushNamed(
                  context,
                  '/profile/favorites',
                  arguments: {'userId': user.uid},
                );
              }
            },
          ),

          // Blocked users
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked Users'),
            subtitle: const Text('Manage users you have blocked'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/settings/blocked-users');
            },
          ),

          const Divider(),

          // Help & Support
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              // Future implementation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support coming soon')),
              );
            },
          ),

          // About
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About WordNerd'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'WordNerd',
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(size: 32),
                children: const [
                  Text(
                    'WordNerd is a vocabulary learning app that helps you expand your word knowledge.',
                  ),
                ],
              );
            },
          ),

          // Logout button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('LOG OUT'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                try {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error signing out: ${e.toString()}'),
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
