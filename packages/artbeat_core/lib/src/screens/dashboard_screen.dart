import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart' show ArtWalkMapScreen;
import 'package:artbeat_community/screens/feed/community_feed_screen.dart'
    show CommunityFeedScreen;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork
    show ArtworkBrowseScreen;
import 'package:artbeat_capture/artbeat_capture.dart' show CaptureScreen;

/// Main dashboard screen for the application.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // List of screens for bottom navigation
  final List<Widget> _screens = [
    const HomeTab(),
    const ArtWalkMapScreen(),
    const CaptureScreen(),
    const CommunityFeedScreen(),
    const artwork.ArtworkBrowseScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('ARTbeat'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8C52FF),
        onPressed: () => setState(() => _selectedIndex = 2),
        child: const Icon(Icons.add_a_photo, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Left side items
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.home, 'Home'),
                  _buildNavItem(1, Icons.map, 'Art Walk'),
                ],
              ),
            ),
            // Space for FAB
            const SizedBox(width: 80),
            // Right side items
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(3, Icons.forum, 'Community'),
                  _buildNavItem(4, Icons.palette, 'Artwork'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Theme.of(context).primaryColor : Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: CircleAvatar(
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : const AssetImage('assets/default_profile.png')
                      as ImageProvider,
            ),
            accountName: Text(user?.displayName ?? 'User'),
            accountEmail: Text(user?.email ?? ''),
          ),
          _buildDrawerSection(
            'Profile',
            [
              _buildDrawerItem('View Profile', Icons.person, () {}),
              _buildDrawerItem('Edit Profile', Icons.edit, () {}),
              _buildDrawerItem('Favorites', Icons.favorite, () {}),
              _buildDrawerItem('Achievements', Icons.stars, () {}),
            ],
          ),
          _buildDrawerSection(
            'Artist',
            [
              _buildDrawerItem('Dashboard', Icons.dashboard, () {}),
              _buildDrawerItem('Analytics', Icons.analytics, () {}),
              _buildDrawerItem('Subscriptions', Icons.subscriptions, () {}),
            ],
          ),
          _buildDrawerSection(
            'Settings',
            [
              _buildDrawerItem('Account', Icons.settings, () {}),
              _buildDrawerItem('Notifications', Icons.notifications, () {}),
              _buildDrawerItem('Privacy & Security', Icons.security, () {}),
            ],
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8C52FF),
            Color(0xFF00BF63),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          _buildDisabledSection('Featured Artwork'),
          const SizedBox(height: 24),
          _buildDisabledSection('Local Artists'),
          const SizedBox(height: 24),
          _buildDisabledSection('Upcoming Events'),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to ARTbeat!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Discover local art, connect with artists, and explore your creative community.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Start Exploring'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
