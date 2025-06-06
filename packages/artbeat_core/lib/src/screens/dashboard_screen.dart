import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/artbeat_app_header.dart';
import '../../widgets/artbeat_drawer.dart';
import '../widgets/art_capture_warning_dialog.dart';

/// Main dashboard screen for the application.
class DashboardScreen extends StatefulWidget {
  final List<Widget> screens;
  final VoidCallback onCapturePressed;

  const DashboardScreen({
    super.key,
    required this.screens,
    required this.onCapturePressed,
  }) : assert(screens.length == 5, 'Dashboard requires exactly 5 screens');

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
        return 'Capture';
      case 3:
        return 'Community';
      case 4:
        return 'Artwork';
      default:
        return 'ARTbeat';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: ArtbeatAppHeader(title: _getScreenTitle()),
      drawer: const ArtbeatDrawer(),
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
      floatingActionButton: FloatingActionButton(
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
          child: const Icon(Icons.add_a_photo, size: 32, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                  _buildNavItem(1, Icons.map_outlined, Icons.map, 'Art Walk'),
                ],
              ),
            ),
            const SizedBox(width: 80),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                      2, Icons.people_outline, Icons.people, 'Community'),
                  _buildNavItem(
                      3, Icons.person_outline, Icons.person, 'Profile'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? selectedIcon : unselectedIcon,
            color: isSelected ? const Color(0xFF8C52FF) : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected ? const Color(0xFF8C52FF) : Colors.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}
