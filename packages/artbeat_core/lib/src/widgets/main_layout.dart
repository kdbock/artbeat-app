import 'package:flutter/material.dart';
import 'enhanced_bottom_nav.dart';

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
          Navigator.of(context).pushReplacementNamed('/capture/dashboard');
          break;
        case 3:
          Navigator.of(context).pushReplacementNamed('/community/dashboard');
          break;
        case 4:
          Navigator.of(context).pushReplacementNamed('/events/dashboard');
          break;
        default:
          // Handle any other indices gracefully
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: EnhancedBottomNav(
        currentIndex: widget.currentIndex,
        onTap: _handleNavigation,
      ),
    );
  }
}
