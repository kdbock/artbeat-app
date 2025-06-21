import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/user_sync_helper.dart';

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
      debugPrint('SplashScreen: currentUser = ' + (user?.uid ?? 'null'));

      // If user is authenticated, ensure their Firestore document exists
      if (user != null) {
        debugPrint('🔄 SplashScreen: Ensuring user document sync...');
        await UserSyncHelper.ensureUserDocumentExists();
      }

      // Dismiss keyboard before navigating
      FocusScope.of(context).unfocus();
      final route = user != null ? '/dashboard' : '/login';

      debugPrint('🔗 SplashScreen navigating to: $route');
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(route);
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      if (!mounted) return;
      // Dismiss keyboard before navigating
      FocusScope.of(context).unfocus();
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'packages/artbeat_core/assets/images/artbeat_splash_bg.png',
            fit: BoxFit.cover,
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child:
                  SizedBox.shrink(), // Remove logo for pure background, or add logo if desired
            ),
          ),
        ],
      ),
    );
  }
}
