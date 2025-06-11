import 'package:flutter/material.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import '../app.dart';
import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_profile/artbeat_profile.dart';
import 'package:artbeat_settings/artbeat_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeveloperMenu extends StatelessWidget {
  const DeveloperMenu({super.key});

  void _navigateToScreen(BuildContext context, Widget screen) {
    // Close the developer menu first
    Navigator.pop(context);

    // Then navigate to the new screen
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppShell(child: screen),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Developer Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Screen Navigation',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            _buildModuleSection(
              context,
              'Art Walk Screens',
              {
                'Art Walk Map': const ArtWalkMapScreen(),
                'Create Art Walk': const CreateArtWalkScreen(),
                'Art Walk Details': const ArtWalkDetailScreen(walkId: 'test-walk'),
              },
            ),
            _buildModuleSection(
              context,
              'Artist Screens',
              {
                'Artist Browse': const artist.ArtistBrowseScreen(),
                'Artist Dashboard': const artist.ArtistDashboardScreen(),
                'Artist Profile': const artist.ArtistPublicProfileScreen(
                    artistProfileId: 'test-profile'),
                'Artist Profile Edit': const artist.ArtistProfileEditScreen(),
              },
            ),
            _buildModuleSection(
              context,
              'Artwork Screens',
              {
                'Artwork Browse': const artwork.ArtworkBrowseScreen(),
                'Artwork Detail':
                    const artwork.ArtworkDetailScreen(artworkId: 'test-artwork'),
                'Artwork Upload': const artwork.ArtworkUploadScreen(),
              },
            ),
            _buildModuleSection(
              context,
              'Auth Screens',
              {
                'Login': const LoginScreen(),
                'Register': const RegisterScreen(),
                'Forgot Password': const ForgotPasswordScreen(),
              },
            ),
            _buildModuleSection(
              context,
              'Capture Screens',
              {
                'Camera': const CaptureScreen(),
                'Capture List': const CaptureListScreen(),
                'Capture Detail': CaptureDetailScreen(
                  capture: CaptureModel(
                    id: 'test-capture',
                    userId: 'test-user',
                    imageUrl: 'https://placeholder.co/400',
                    createdAt: DateTime.now(),
                    isProcessed: false,
                    isPublic: false,
                  ),
                ),
              },
            ),
            _buildModuleSection(
              context,
              'Community Screens',
              {
                'Feed': const CommunityFeedScreen(),
              },
            ),
            _buildModuleSection(
              context,
              'Profile Screens',
              {
                'Profile View': ProfileViewScreen(
                    userId:
                        FirebaseAuth.instance.currentUser?.uid ?? 'test-user'),
                'Edit Profile': EditProfileScreen(
                    userId:
                        FirebaseAuth.instance.currentUser?.uid ?? 'test-user'),
                'Followers': FollowersListScreen(
                    userId:
                        FirebaseAuth.instance.currentUser?.uid ?? 'test-user'),
                'Following': FollowingListScreen(
                    userId:
                        FirebaseAuth.instance.currentUser?.uid ?? 'test-user'),
                'Favorites': FavoritesScreen(
                    userId:
                        FirebaseAuth.instance.currentUser?.uid ?? 'test-user'),
              },
            ),
            _buildModuleSection(
              context,
              'Settings Screens',
              {
                'Settings': const SettingsScreen(),
                'Account Settings': const AccountSettingsScreen(),
                'Privacy Settings': const PrivacySettingsScreen(),
                'Notification Settings': const NotificationSettingsScreen(),
                'Security Settings': const SecuritySettingsScreen(),
                'Blocked Users': const BlockedUsersScreen(),
              },
            ),
            const Divider(),
            _buildDatabaseSection(context),
            _buildBackupSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleSection(
    BuildContext context,
    String title,
    Map<String, Widget> screens,
  ) {
    return ExpansionTile(
      title: Text(title),
      children: screens.entries.map((entry) {
        return ListTile(
          title: Text(entry.key),
          onTap: () => _navigateToScreen(context, entry.value),
        );
      }).toList(),
    );
  }

  Widget _buildDatabaseSection(BuildContext context) {
    return ExpansionTile(
      title: const Text('Database Management'),
      children: [
        ListTile(
          title: const Text('View Records'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Database viewer coming soon')),
            );
          },
        ),
        ListTile(
          title: const Text('User Management'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User management coming soon')),
            );
          },
        ),
        ListTile(
          title: const Text('Analytics'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Analytics dashboard coming soon')),
            );
          },
        ),
        ListTile(
          title: const Text('System Settings'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('System settings coming soon')),
            );
          },
        ),
        ListTile(
          title: const Text('View Logs'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Log viewer coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBackupSection(BuildContext context) {
    return ExpansionTile(
      title: const Text('Backup Management'),
      children: [
        ListTile(
          title: const Text('View Backups'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup viewer coming soon')),
            );
          },
        ),
        ListTile(
          title: const Text('Create Backup'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup creation coming soon')),
            );
          },
        ),
        ListTile(
          title: const Text('Restore Backup'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup restoration coming soon')),
            );
          },
        ),
      ],
    );
  }
}
