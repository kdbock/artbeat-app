import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

class AuthGuard {
  /// Check if user is currently authenticated
  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  /// Checks if the user is authenticated and returns appropriate route
  static Route<dynamic>? guardRoute({
    required RouteSettings settings,
    required Widget Function() authenticatedBuilder,
    required Widget Function()? unauthenticatedBuilder,
    String? redirectRoute,
  }) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is authenticated, return the requested route
      return MaterialPageRoute(
        builder: (_) => authenticatedBuilder(),
        settings: settings,
      );
    } else {
      // User is not authenticated
      if (unauthenticatedBuilder != null) {
        return MaterialPageRoute(
          builder: (_) => unauthenticatedBuilder(),
          settings: settings,
        );
      } else {
        // Redirect to login or specified route
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
          settings: RouteSettings(name: redirectRoute ?? '/auth'),
        );
      }
    }
  }

  /// Check if user has specific role/permission
  static bool hasRole(String role) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // This would typically check custom claims or user document
    // For now, return basic authentication status
    return user.emailVerified;
  }

  /// Check if user is an artist
  static bool isArtist() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // This would check if user has artist role in Firestore
    // For now, return true if user is authenticated
    return true;
  }
}

/// Widget to show when authentication is required
class AuthRequiredScreen extends StatelessWidget {
  const AuthRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const core.EnhancedUniversalHeader(
        title: 'Authentication Required',
        showLogo: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Authentication Required',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please sign in to access this feature',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/auth');
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
