import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../utils/user_sync_helper.dart';
import '../theme/artbeat_colors.dart';
import '../utils/color_extensions.dart';

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
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    try {
      if (Firebase.apps.isEmpty) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _syncUserInBackground();
      }

      FocusScope.of(context).unfocus();
      final route = user != null ? '/dashboard' : '/login';

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

  // Sync user data in background without blocking navigation
  void _syncUserInBackground() {
    Future.delayed(Duration.zero, () async {
      try {
        await UserSyncHelper.ensureUserDocumentExists().timeout(
          const Duration(seconds: 5),
        );
      } on TimeoutException {
        // Ignore timeout
      } catch (syncError) {
        // Ignore sync errors in background
      }
    });
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
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArtbeatColors.primaryPurple.withAlphaValue(0.05),
              Colors.white,
              ArtbeatColors.primaryGreen.withAlphaValue(0.05),
            ],
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              'assets/images/splashTRANS_logo.png',
              width: 300,
              height: 300,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image not found
                return Icon(
                  Icons.image_not_supported,
                  size: 100,
                  color: ArtbeatColors.primaryPurple.withAlpha(120),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
