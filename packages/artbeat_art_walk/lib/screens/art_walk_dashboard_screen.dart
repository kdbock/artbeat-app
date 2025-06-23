import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:geocoding/geocoding.dart';
import 'package:artbeat_capture/artbeat_capture.dart';

/// Art Walk Dashboard Screen
/// Shows user's art walks, public walks, and map preview. Entry point for creating and exploring art walks.
class ArtWalkDashboardScreen extends StatefulWidget {
  const ArtWalkDashboardScreen({super.key});

  @override
  State<ArtWalkDashboardScreen> createState() => _ArtWalkDashboardScreenState();
}

class _ArtWalkDashboardScreenState extends State<ArtWalkDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showOnboarding = true; // TODO: Replace with persistent check
  GoogleMapController? _mapController;
  CameraPosition? _initialCameraPosition;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserZipAndSetMap();
  }

  Future<void> _loadUserZipAndSetMap() async {
    // TODO: Replace with real user ZIP code lookup and geocoding
    final zip = await _getUserZipCode();
    final latLng = await _getLatLngFromZip(zip);
    setState(() {
      _initialCameraPosition = CameraPosition(target: latLng, zoom: 13);
    });
  }

  Future<String> _getUserZipCode() async {
    final userService = Provider.of<UserService>(context, listen: false);
    final userId = userService.currentUserId;
    if (userId == null) return '10001'; // fallback
    final profile = await userService.getUserProfile(userId);
    if (profile == null) return '10001';
    final zip = profile['zipCode']?.toString();
    final location = profile['location']?.toString();
    if (zip != null && zip.isNotEmpty) return zip;
    if (location != null && location.isNotEmpty) return location;
    return '10001';
  }

  Future<LatLng> _getLatLngFromZip(String zip) async {
    try {
      print('Geocoding for zip: $zip');
      final locations = await locationFromAddress(zip);
      print('Geocoding result: $locations');
      if (locations.isNotEmpty) {
        final loc = locations.first;
        print('Using LatLng: [32m${loc.latitude}, ${loc.longitude}[0m');
        return LatLng(loc.latitude, loc.longitude);
      }
    } catch (e) {
      print('Geocoding failed for zip $zip: $e');
    }
    // Fallback to a default location if geocoding fails
    return const LatLng(37.7749, -122.4194); // San Francisco
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0: // Home - Dashboard
        Navigator.pushNamed(context, '/dashboard');
        break;
      case 1: // Art Walk - Stay here
        break;
      case 2: // Community
        Navigator.pushNamed(context, '/community/dashboard');
        break;
      case 3: // Events
        Navigator.pushNamed(context, '/events/dashboard');
        break;
      case 4: // Capture (Camera button)
        _onCapture();
        break;
    }
  }

  void _onCreateArtWalk() {
    // TODO: Navigate to create art walk screen
  }

  void _onCapture() async {
    // Open the camera screen as a modal and wait for the result
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (context) => const CaptureScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result != null && mounted) {
      // Optionally handle result, e.g., show details or refresh
    }
  }

  Set<Marker> _getMarkers() {
    if (_initialCameraPosition == null) return {};
    return {
      Marker(
        markerId: const MarkerId('center'),
        position: _initialCameraPosition!.target,
        infoWindow: const InfoWindow(title: 'Center'),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Art Walks',
          style: TextStyle(
            color: ArtbeatColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: ArtbeatColors.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: ArtbeatColors.primaryPurple),
            tooltip: 'How Art Walks Work',
            onPressed: () {
              setState(() => _showOnboarding = true);
            },
          ),
        ],
      ),
      drawer: const ArtbeatDrawer(),
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArtbeatColors.primaryPurple.withAlpha(13), // 0.05 opacity
              Colors.white,
              ArtbeatColors.primaryGreen.withAlpha(13), // 0.05 opacity
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (_showOnboarding) _onboardingCard(),

              // Create Art Walk Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  border: Border(
                    bottom: BorderSide(
                      color: ArtbeatColors.border.withAlpha(128),
                      width: 1,
                    ),
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: _onCreateArtWalk,
                  icon: const Icon(Icons.add_road),
                  label: const Text('Create Art Walk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArtbeatColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  border: Border(
                    bottom: BorderSide(
                      color: ArtbeatColors.border.withAlpha(128),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: ArtbeatColors.primaryPurple,
                  unselectedLabelColor: ArtbeatColors.textSecondary,
                  indicatorColor: ArtbeatColors.primaryPurple,
                  tabs: const [
                    Tab(text: 'My Walks'),
                    Tab(text: 'Discover'),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_myWalksTab(), _discoverTab()],
                ),
              ),

              // Map Preview
              _mapPreviewSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onCapture,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Capture Art'),
        backgroundColor: ArtbeatColors.primaryGreen,
        foregroundColor: Colors.white,
        tooltip: 'Capture new art with location',
      ),
      bottomNavigationBar: UniversalBottomNav(
        currentIndex: 1, // Art Walk is index 1
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _onboardingCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtbeatColors.primaryPurple.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArtbeatColors.primaryPurple.withAlpha(77)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.directions_walk,
            size: 40,
            color: ArtbeatColors.primaryPurple,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How Art Walks Work',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Capture art with your camera. Each photo is pinned to its location. Create self-guided art walks by linking your art locations. Share your walks, explore others, and leave reviews!',
                  style: TextStyle(color: ArtbeatColors.textSecondary),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _showOnboarding = false),
                    style: TextButton.styleFrom(
                      foregroundColor: ArtbeatColors.primaryPurple,
                    ),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _myWalksTab() {
    // TODO: Replace with real data
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _artWalkListTile(
          title: 'Downtown Murals',
          subtitle: '5 stops · 1.2 mi · 45 min',
          onTap: () {},
          onEdit: () {},
          onDelete: () {},
        ),
        _artWalkListTile(
          title: 'Riverfront Sculptures',
          subtitle: '3 stops · 0.8 mi · 30 min',
          onTap: () {},
          onEdit: () {},
          onDelete: () {},
        ),
      ],
    );
  }

  Widget _discoverTab() {
    // TODO: Replace with real data
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _artWalkListTile(
          title: 'Historic Art Walk',
          subtitle: '7 stops · 2.0 mi · 1 hr',
          onTap: () {},
          onEdit: null,
          onDelete: null,
          isPublic: true,
        ),
        _artWalkListTile(
          title: 'Gallery Hop',
          subtitle: '4 stops · 1.5 mi · 50 min',
          onTap: () {},
          onEdit: null,
          onDelete: null,
          isPublic: true,
        ),
      ],
    );
  }

  Widget _artWalkListTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    bool isPublic = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          isPublic ? Icons.public : Icons.directions_walk,
          color: isPublic
              ? ArtbeatColors.primaryGreen
              : ArtbeatColors.primaryPurple,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: ArtbeatColors.textSecondary),
        ),
        onTap: onTap,
        trailing: onEdit != null && onDelete != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: ArtbeatColors.primaryPurple),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _mapPreviewSection() {
    if (_initialCameraPosition == null) {
      return Container(
        height: 180,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Container(
      height: 180,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: _initialCameraPosition!,
          onMapCreated: (controller) => _mapController = controller,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: _getMarkers(),
        ),
      ),
    );
  }
}
