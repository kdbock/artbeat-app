import 'package:artbeat_core/artbeat_core.dart' show CaptureModel;
import 'package:artbeat_core/widgets/artbeat_bottom_nav_bar.dart';
import 'package:flutter/material.dart';

/// Main dashboard screen for the application.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Force keyboard to close on dashboard load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      Navigator.pushNamed(context, '/art_walk/dashboard');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/community/social');
    } else if (index == 4) {
      Navigator.pushNamed(context, '/chat');
    }
  }

  void _onCapture() async {
    // Open the camera screen and wait for the result
    final result = await Navigator.pushNamed(context, '/capture');
    if (result != null && mounted) {
      // result should be a CaptureModel or a map with image/location
      final capture = result as CaptureModel;
      final detailResult = await Navigator.pushNamed(
        context,
        '/capture/detail',
        arguments: {'capture': capture},
      );
      if (detailResult == true && mounted) {
        // After successful upload, go back to dashboard
        Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.developer_mode),
            onPressed: () {},
            tooltip: 'Developer Menu',
          ),
          // Profile dropdown (generic icon, right of dev icon)
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, size: 28),
            onSelected: (value) {
              switch (value) {
                case 'public_profile':
                  Navigator.pushNamed(context, '/profile/public');
                  break;
                case 'edit_profile':
                  Navigator.pushNamed(context, '/profile/edit');
                  break;
                case 'favorites':
                  Navigator.pushNamed(context, '/favorites');
                  break;
                case 'captures':
                  Navigator.pushNamed(context, '/captures');
                  break;
                case 'achievements':
                  Navigator.pushNamed(context, '/achievements');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'public_profile',
                child: Text('Public Profile'),
              ),
              const PopupMenuItem(
                value: 'edit_profile',
                child: Text('Edit Profile'),
              ),
              const PopupMenuItem(
                value: 'favorites',
                child: Text('Fan Of (Favorites)'),
              ),
              const PopupMenuItem(value: 'captures', child: Text('Captures')),
              const PopupMenuItem(
                value: 'achievements',
                child: Text('Achievements'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Art',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor:
                    theme.inputDecorationTheme.fillColor ?? Colors.grey[100],
              ),
              enabled: false,
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.primaryColor,
            tabs: const [
              Tab(text: 'Artists'),
              Tab(text: 'Artwork'),
              Tab(text: 'Events'),
              Tab(text: 'Artwalks'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(4, (index) => _comingSoon()),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ArtbeatBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        onCapture: _onCapture,
      ),
    );
  }

  Widget _comingSoon() {
    return const Center(
      child: Text(
        'Coming Soon',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
