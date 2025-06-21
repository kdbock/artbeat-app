import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart'; // or the correct import for UserService
import 'package:geocoding/geocoding.dart';

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
  int _selectedIndex = 1; // Art Walk tab index
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

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushNamed(context, '/dashboard');
    } else if (index == 1) {
      // Already on Art Walk dashboard
    } else if (index == 2) {
      Navigator.pushNamed(context, '/community/social');
    } else if (index == 4) {
      Navigator.pushNamed(context, '/chat');
    }
  }

  void _onCreateArtWalk() {
    // TODO: Navigate to create art walk screen
  }

  void _onCapture() async {
    // Open the camera screen and wait for the result
    final result = await Navigator.pushNamed(context, '/capture');
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
    final theme = Theme.of(context);
    return MainLayout(
      currentIndex: 1, // Art Walk index
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Art Walks'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'How Art Walks Work',
              onPressed: () {
                setState(() => _showOnboarding = true);
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _onCapture,
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Capture Art'),
          tooltip: 'Capture new art with location',
        ),
        body: Column(
          children: [
            if (_showOnboarding) _onboardingCard(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onCreateArtWalk,
                  icon: const Icon(Icons.add_road),
                  label: const Text('Create Art Walk'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: theme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: theme.primaryColor,
              tabs: const [
                Tab(text: 'My Walks'),
                Tab(text: 'Discover'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_myWalksTab(), _discoverTab()],
              ),
            ),
            _mapPreviewSection(),
          ],
        ),
      ),
    );
  }

  Widget _onboardingCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.directions_walk, size: 40, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How Art Walks Work',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Capture art with your camera. Each photo is pinned to its location. Create self-guided art walks by linking your art locations. Share your walks, explore others, and leave reviews!',
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _showOnboarding = false),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          isPublic ? Icons.public : Icons.directions_walk,
          color: isPublic ? Colors.green : Colors.blue,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: onEdit != null && onDelete != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
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
