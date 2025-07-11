import 'package:flutter/material.dart';
import 'enhanced_bottom_nav.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final void Function(int)? onNavigationChanged;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    this.onNavigationChanged,
    this.appBar,
    this.drawer,
    this.endDrawer,
    this.scaffoldKey,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  void _handleNavigation(int index) {
    if (widget.onNavigationChanged != null) {
      widget.onNavigationChanged!(index);
    } else {
      // Default navigation logic - use pushNamedAndRemoveUntil to prevent app reloads
      // and ensure proper navigation stack management
      switch (index) {
        case 0:
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
          break;
        case 1:
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/art-walk/dashboard', (route) => false);
          break;
        case 2:
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/capture/dashboard', (route) => false);
          break;
        case 3:
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/community/dashboard', (route) => false);
          break;
        case 4:
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/events/dashboard', (route) => false);
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
      key: widget.scaffoldKey,
      appBar: widget.appBar,
      drawer: widget.drawer,
      endDrawer: widget.endDrawer,
      body: widget.child,
      bottomNavigationBar: EnhancedBottomNav(
        currentIndex: widget.currentIndex,
        onTap: _handleNavigation,
      ),
    );
  }
}
