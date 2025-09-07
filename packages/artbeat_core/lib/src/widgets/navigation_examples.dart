import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Example screen showing how to implement enhanced navigation
///
/// This demonstrates the proper way to add comprehensive navigation
/// to any screen in the ARTbeat app
class ExampleScreenWithEnhancedNavigation extends StatelessWidget {
  const ExampleScreenWithEnhancedNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Option 1: Use enhanced app bar with navigation menu access
      appBar: EnhancedAppBar(
        title: 'Example Screen',
        onNavigate: (route) {
          // Handle navigation - could be custom logic or default navigation
          Navigator.of(context).pushNamed(route);
        },
      ),

      // Main content
      body: Stack(
        children: [
          // Your main content here
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Screen Content'),
                const SizedBox(height: 20),

                // Option 2: Button to show navigation menu
                ElevatedButton.icon(
                  onPressed: () => _showEnhancedNavigation(context),
                  icon: const Icon(Icons.explore),
                  label: const Text('Show All Features'),
                ),
              ],
            ),
          ),

          // Option 3: Add floating action button for quick navigation access
          const QuickNavigationFAB(bottom: 20, right: 20),
        ],
      ),

      // Option 4: Traditional drawer (still available)
      drawer: const ArtbeatDrawer(),
    );
  }

  void _showEnhancedNavigation(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedNavigationMenu(
        onNavigate: (route) {
          Navigator.of(context).pop(); // Close the modal
          Navigator.of(context).pushNamed(route); // Navigate to selected route
        },
      ),
    );
  }
}

/// Example of a minimal screen with just FAB navigation
class MinimalScreenWithNavigation extends StatelessWidget {
  const MinimalScreenWithNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minimal Screen')),
      body: const Stack(
        children: [
          // Your content
          Center(child: Text('Minimal Screen Content')),

          // Just add the FAB for comprehensive navigation access
          QuickNavigationFAB(),
        ],
      ),
    );
  }
}

/// Example showing custom navigation handling
class CustomNavigationScreen extends StatelessWidget {
  const CustomNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EnhancedAppBar(
        title: 'Custom Navigation',
        onNavigate: (route) => _handleCustomNavigation(route, context),
      ),
      body: const Center(child: Text('Custom Navigation Example')),
    );
  }

  void _handleCustomNavigation(String route, BuildContext context) {
    // Custom navigation logic
    // For example, you might want to:
    // 1. Log analytics
    // 2. Check permissions
    // 3. Show confirmations for certain routes
    // 4. Handle special navigation patterns

    switch (route) {
      case '/admin/dashboard':
        // Special handling for admin routes
        _navigateToAdminSection(route, context);
        break;
      case '/artist/earnings':
        // Check if user has completed setup
        _navigateWithSetupCheck(route, context);
        break;
      default:
        // Default navigation
        Navigator.of(context).pushNamed(route);
    }
  }

  void _navigateToAdminSection(String route, BuildContext context) {
    // Custom admin navigation logic
    Navigator.of(context).pushNamed(route);
  }

  void _navigateWithSetupCheck(String route, BuildContext context) {
    // Check setup status and navigate accordingly
    Navigator.of(context).pushNamed(route);
  }
}
