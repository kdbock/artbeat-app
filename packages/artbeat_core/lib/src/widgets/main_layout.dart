import 'package:flutter/material.dart';
import 'universal_bottom_nav.dart';
import 'package:artbeat_capture/artbeat_capture.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final void Function(int)? onNavigationChanged;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    this.onNavigationChanged,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  void _handleNavigation(int index) {
    if (widget.onNavigationChanged != null) {
      widget.onNavigationChanged!(index);
    } else {
      // Default navigation logic
      switch (index) {
        case 0:
          Navigator.of(context).pushReplacementNamed('/dashboard');
          break;
        case 1:
          Navigator.of(context).pushReplacementNamed('/art-walk/dashboard');
          break;
        case 2:
          Navigator.of(context).pushReplacementNamed('/community/dashboard');
          break;
        case 3:
          Navigator.of(context).pushReplacementNamed('/events/dashboard');
          break;
        case 4:
          // Open capture as a modal instead of navigation
          _openCaptureModal();
          break;
      }
    }
  }

  void _openCaptureModal() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const CaptureScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: UniversalBottomNav(
        currentIndex: widget.currentIndex,
        onTap: _handleNavigation,
      ),
    );
  }
}
