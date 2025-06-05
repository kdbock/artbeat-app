import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Splash screen that shows full-screen splash image and checks authentication status
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Delay to show splash screen for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // Check if user is logged in directly with Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      final route = user != null ? '/dashboard' : '/login';

      debugPrint('🔗 SplashScreen navigating to: $route');
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(route);
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8C52FF), // Purple
              Color(0xFF00BF63), // Green
            ],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Image.asset(
            'assets/images/splash.png',
            fit: BoxFit.fitWidth,
          ),
        ),
      ),
    );
  }
}
