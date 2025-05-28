import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat/screens/discover_screen.dart';
import 'package:artbeat/screens/capture/camera_screen.dart';
import 'package:artbeat/screens/calendar/calendar_screen.dart';

// Import all the widget components for our new dashboard
import 'package:artbeat/widgets/local_artists_row_widget.dart';
import 'package:artbeat/widgets/local_artwork_row_widget.dart';
import 'package:artbeat/widgets/local_art_walk_preview_widget.dart';
import 'package:artbeat/widgets/artist_subscription_cta_widget.dart';
import 'package:artbeat/widgets/upcoming_events_row_widget.dart';
import 'package:artbeat/widgets/featured_content_row_widget.dart';
import 'package:artbeat/widgets/local_galleries_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int _currentIndex = 0;
  String _userZipCode = '10001'; // Default to New York

  @override
  void initState() {
    super.initState();
    _getUserZipCode();
  }

  Future<void> _getUserZipCode() async {
    if (currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        if (userDoc.exists && userDoc.data()?['location'] != null) {
          setState(() {
            _userZipCode = userDoc.data()?['location'];
          });
        }
      } catch (e) {
        debugPrint('Error getting user zip code: $e');
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  void _navigateToProfile() {
    if (currentUser != null) {
      Navigator.pushNamed(
        context,
        '/profile/view',
        arguments: {'userId': currentUser!.uid, 'isCurrentUser': true},
      );
    }
  }

  void _navigateToCommunity() {
    Navigator.pushNamed(context, '/community/feed');
  }

  Future<void> _openCamera() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentIndex) {
      case 0: // Home
        return _buildHomeView();
      case 1: // Discover
        return _buildDiscoverView();
      case 2: // Events
        return const CalendarScreen();
      case 3: // Community - This should not occur as we navigate directly
        return _buildCommunityView(); // Show community feed when staying in dashboard
      default:
        return _buildHomeView();
    }
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome header section with profile
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (currentUser != null) ...[
                  GestureDetector(
                    onTap: _navigateToProfile,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: currentUser?.photoURL != null &&
                              currentUser!.photoURL!.isNotEmpty
                          ? NetworkImage(currentUser!.photoURL!)
                              as ImageProvider
                          : null,
                      child: currentUser?.photoURL == null ||
                              currentUser!.photoURL!.isEmpty
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${currentUser?.displayName ?? 'Art Lover'}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'New York, $_userZipCode',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    // Navigate to notifications page
                  },
                ),
              ],
            ),
          ),

          // Local Artists Section
          LocalArtistsRowWidget(
            zipCode: _userZipCode,
            onSeeAllPressed: () =>
                Navigator.pushNamed(context, '/artist/browse'),
          ),

          const SizedBox(height: 16),

          // Local Artwork Section
          LocalArtworkRowWidget(
            zipCode: _userZipCode,
            onSeeAllPressed: () =>
                Navigator.pushNamed(context, '/artwork/browse'),
          ),

          const SizedBox(height: 16),

          // Local Art Walk Preview
          LocalArtWalkPreviewWidget(
            zipCode: _userZipCode,
            onSeeAllPressed: () =>
                Navigator.pushNamed(context, '/art-walk/list'),
          ),

          const SizedBox(height: 24),

          // Artist Subscription Call to Action
          ArtistSubscriptionCTAWidget(
            onSubscribePressed: () =>
                Navigator.pushNamed(context, '/artist/subscription'),
          ),

          const SizedBox(height: 24),

          // Upcoming Events Section
          UpcomingEventsRowWidget(
            zipCode: _userZipCode,
            onSeeAllPressed: () => Navigator.pushNamed(context, '/calendar'),
          ),

          const SizedBox(height: 24),

          // Featured Content Section
          FeaturedContentRowWidget(
            zipCode: _userZipCode,
            onSeeAllPressed: () =>
                Navigator.pushNamed(context, '/content/featured'),
          ),

          const SizedBox(height: 24),

          // Local Galleries and Museums
          LocalGalleriesWidget(
            zipCode: _userZipCode,
            onSeeAllPressed: () =>
                Navigator.pushNamed(context, '/galleries/browse'),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDiscoverView() {
    return const DiscoverScreen();
  }

  Widget _buildCommunityView() {
    // This is a placeholder that will be replaced by a real community feed
    return const Center(
      child: Text('Community feed will be displayed here'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARTbeat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: _navigateToProfile,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _signOut,
          ),
        ],
      ),
      body: _buildCurrentView(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dashboard_fab',
        onPressed: _openCamera,
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 3) {
              // Community tab
              _navigateToCommunity();
            }
          });
        },
      ),
    );
  }
}
