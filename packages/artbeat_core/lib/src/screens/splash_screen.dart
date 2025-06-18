import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Splash screen that shows full-screen splash image and checks authentication status
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartbeatController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupHeartbeatAnimation();
    _checkAuthAndNavigate();
  }

  void _setupHeartbeatAnimation() {
    _heartbeatController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.2),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.2, end: 1.0),
            weight: 1,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _heartbeatController,
            curve: Curves.easeInOut,
          ),
        );

    _heartbeatController.repeat();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Delay to show splash screen for at least 2 seconds
    await Future<void>.delayed(const Duration(seconds: 2));

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
  void dispose() {
    _heartbeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF8C52FF), // Primary purple
              const Color(0xFF8C52FF).withAlpha(204), // 0.8 opacity
              const Color(0xFF00BF63), // Primary green
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated ARTbeat logo
              ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/images/artbeat_logo.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'ARTbeat',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Discover Local Art',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white.withAlpha(230), // 0.9 opacity
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
