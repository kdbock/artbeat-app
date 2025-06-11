import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/artbeat_app_header.dart';
import '../../widgets/artbeat_drawer.dart';
import '../widgets/art_capture_warning_dialog.dart';
import '../widgets/developer_menu.dart';

/// Main dashboard screen for the application.
class DashboardScreen extends StatefulWidget {
  final List<Widget> screens;
  final VoidCallback onCapturePressed;

  const DashboardScreen({
    super.key,
    required this.screens,
    required this.onCapturePressed,
  }) : assert(screens.length == 4,
            'Dashboard requires exactly 4 screens: Home, Art Walk, Community, and Events');

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: ArtbeatAppHeader(
        title: _getScreenTitle(),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.developer_mode),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: 'Developer Menu',
            ),
          ),
        ],
      ),
      drawer: const ArtbeatDrawer(),
      endDrawer: const DeveloperMenu(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF8C52FF).withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: IndexedStack(
          index: _selectedIndex,
          children: widget.screens,
        ),
      ),
      floatingActionButton: Stack(
        children: [
          // Messaging FAB - positioned on the right side
          Positioned(
            right: 0,
            bottom: 70, // Position it above the bottom nav bar
            child: FloatingActionButton(
              heroTag: 'messagingFab',
              elevation: 4,
              backgroundColor: const Color(0xFF8C52FF),
              onPressed: () => Navigator.pushNamed(context, '/chat'),
              child: const Icon(Icons.message_rounded, color: Colors.white),
            ),
          ),
          // Main capture FAB - centered
          Align(
            alignment: Alignment.bottomCenter,
            child: FloatingActionButton(
              heroTag: 'captureFab',
              elevation: 4,
              onPressed: _handleCapture,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF8C52FF),
                      Color(0xFF00BF63),
                    ],
                  ),
                ),
                child: const Icon(Icons.add_a_photo,
                    size: 32, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Future<Position?> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied'),
          ),
        );
      }
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _handleCapture() async {
    // Show the warning dialog
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) => const ArtCaptureWarningDialog(),
    );

    if (proceed != true || !mounted) return;

    // Get current location
    final location = await _getLocation();

    if (!mounted) return;

    // Navigate to capture screen
    final result = await Navigator.pushNamed(
      context,
      '/capture',
      arguments: {'location': location},
    );

    // If we got a file back, proceed to upload screen
    if (result != null && mounted) {
      await Navigator.pushNamed(
        context,
        '/artwork/upload',
        arguments: {'file': result, 'location': location},
      );
    }
  }

  String _getScreenTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Art Walks';
      case 2:
        return 'Community';
      case 3:
        return 'Events';
      default:
        return 'ARTbeat';
    }
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      clipBehavior: Clip.antiAlias,
      elevation: 8.0,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Left side of bottom bar
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    0,
                    Icons.home_outlined,
                    Icons.home,
                    'Home',
                  ),
                  _buildNavItem(
                    1,
                    Icons.map_outlined,
                    Icons.map,
                    'Art Walk',
                  ),
                ],
              ),
            ),

            // Center gap for FAB
            const SizedBox(width: 80),

            // Right side of bottom bar
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    2,
                    Icons.people_outline,
                    Icons.people,
                    'Community',
                  ),
                  _buildNavItem(
                    3,
                    Icons.event_outlined,
                    Icons.event,
                    'Events',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: SizedBox(
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected
                  ? const Color(0xFF8C52FF)
                  : const Color(0xFF666666),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF8C52FF)
                    : const Color(0xFF666666),
                fontSize: 12,
                fontFamily: 'FallingSky',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
