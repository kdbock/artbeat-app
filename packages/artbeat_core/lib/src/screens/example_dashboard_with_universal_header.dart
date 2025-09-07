import 'package:flutter/material.dart';
import 'package:artbeat_core/src/widgets/universal_artbeat_header.dart';

/// Example Dashboard Screen with Universal Header
///
/// This demonstrates the proper implementation of the universal header
/// system across all ARTbeat modules.
class ExampleDashboardWithUniversalHeader extends StatefulWidget {
  const ExampleDashboardWithUniversalHeader({super.key});

  @override
  State<ExampleDashboardWithUniversalHeader> createState() =>
      _ExampleDashboardWithUniversalHeaderState();
}

class _ExampleDashboardWithUniversalHeaderState
    extends State<ExampleDashboardWithUniversalHeader> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Universal Header - Core Module
          UniversalArtbeatHeader(
            moduleName: 'artbeat_core',
            title: 'ARTbeat Dashboard',
            subtitle: 'Welcome back! Discover amazing art',
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _handleSearch(),
                tooltip: 'Search',
              ),
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => _handleNotifications(),
                tooltip: 'Notifications',
              ),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () => _handleProfile(),
                tooltip: 'Profile',
              ),
            ],
          ),

          // Main Content
          Expanded(child: _buildDashboardContent()),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh dashboard data
        await Future<void>.delayed(const Duration(seconds: 1));
      },
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 16),
          _buildQuickActions(),
          const SizedBox(height: 16),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to ARTbeat!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Discover amazing artwork, connect with artists, and explore your creative side.',
              style: TextStyle(fontSize: 16, color: Colors.white, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildActionCard(
              'Browse Art',
              Icons.palette,
              'artbeat_artwork',
              () => _navigateToModule('artwork'),
            ),
            const SizedBox(width: 12),
            _buildActionCard(
              'Find Artists',
              Icons.brush,
              'artbeat_artist',
              () => _navigateToModule('artist'),
            ),
            const SizedBox(width: 12),
            _buildActionCard(
              'Community',
              Icons.people,
              'artbeat_community',
              () => _navigateToModule('community'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    String moduleName,
    VoidCallback onTap,
  ) {
    final colorScheme = _getModuleColorScheme(moduleName);

    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.secondary.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, size: 32, color: colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          'New artwork added to your favorites',
          '2 hours ago',
          Icons.favorite,
          Colors.red,
        ),
        _buildActivityItem(
          'Artist John Doe followed you',
          '5 hours ago',
          Icons.person_add,
          Colors.blue,
        ),
        _buildActivityItem(
          'Your comment received 5 likes',
          '1 day ago',
          Icons.thumb_up,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(time),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Handle activity tap
        },
      ),
    );
  }

  ModuleColorScheme _getModuleColorScheme(String moduleName) {
    // Import the color schemes from the universal header
    return moduleColorSchemes[moduleName] ??
        moduleColorSchemes['artbeat_core']!;
  }

  void _handleSearch() {
    // Navigate to search screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search functionality coming soon!')),
    );
  }

  void _handleNotifications() {
    // Navigate to notifications screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications screen coming soon!')),
    );
  }

  void _handleProfile() {
    // Navigate to profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile screen coming soon!')),
    );
  }

  void _navigateToModule(String moduleName) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navigating to $moduleName module')));
  }
}
