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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    // Add navigation logic if needed
    if (index == 4) {
      Navigator.pushNamed(context, '/chat');
    }
  }

  void _onCapture() {
    // Add capture logic here
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
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                ),
                onPressed: () => _onNavTap(0),
                tooltip: 'Home',
              ),
              IconButton(
                icon: Icon(
                  _selectedIndex == 1 ? Icons.map : Icons.map_outlined,
                ),
                onPressed: () => _onNavTap(1),
                tooltip: 'Art Walk',
              ),
              // Capture camera button in the center
              SizedBox(
                width: 40,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.add_a_photo, size: 28),
                    onPressed: _onCapture,
                    tooltip: 'Capture',
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _selectedIndex == 2 ? Icons.people : Icons.people_outline,
                ),
                onPressed: () => _onNavTap(2),
                tooltip: 'Community',
              ),
              IconButton(
                icon: Icon(
                  _selectedIndex == 4
                      ? Icons.chat_bubble
                      : Icons.chat_bubble_outline,
                ),
                onPressed: () => _onNavTap(4),
                tooltip: 'Chat',
              ),
            ],
          ),
        ),
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
