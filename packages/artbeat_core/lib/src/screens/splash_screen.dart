import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../utils/user_sync_helper.dart';
import '../utils/performance_monitor.dart';
import '../theme/artbeat_colors.dart';

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
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Reset UserSyncHelper state in debug mode to handle hot reload
    if (kDebugMode) {
      UserSyncHelper.resetState();
    }
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
    // Prevent multiple navigation calls
    if (_hasNavigated) {
      debugPrint('🔄 Splash: Already navigated, skipping...');
      return;
    }

    if (kDebugMode) debugPrint('🔄 Splash: Starting auth check...');
    // Reduced delay for faster startup - just enough for smooth animation
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted || _hasNavigated) return;

    try {
      if (kDebugMode) debugPrint('🔥 Splash: Checking Firebase apps...');
      if (Firebase.apps.isEmpty) {
        if (kDebugMode)
          debugPrint('❌ Splash: No Firebase apps found, going to login');
        if (!mounted || _hasNavigated) return;
        _hasNavigated = true;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
        return;
      }

      debugPrint('✅ Splash: Firebase apps available (${Firebase.apps.length})');
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('👤 Splash: Current user: ${user?.uid ?? 'None'}');

      if (user != null) {
        debugPrint('🔄 Splash: Starting user sync...');
        _syncUserInBackground();
      }

      FocusScope.of(context).unfocus();
      final route = user != null ? '/dashboard' : '/login';
      if (kDebugMode) debugPrint('🧭 Splash: Navigating to $route');

      // Start dashboard navigation timing
      if (route == '/dashboard') {
        PerformanceMonitor.startTimer('dashboard_navigation');
      }

      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      // Use pushNamedAndRemoveUntil to ensure clean navigation
      Navigator.of(context).pushNamedAndRemoveUntil(
        route,
        (Route<dynamic> route) => false, // Remove all previous routes
      );
      debugPrint('✅ Splash: Navigation command sent');
    } catch (e) {
      debugPrint('❌ Splash: Error checking auth status: $e');
      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      // Dismiss keyboard before navigating
      FocusScope.of(context).unfocus();
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
      debugPrint('🔄 Splash: Fallback navigation to login sent');
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
              Colors.white,
              ArtbeatColors.primaryPurple.withValues(alpha: 0.15),
              const Color(0xFF4A90E2).withValues(alpha: 0.2), // Blue accent
              Colors.white.withValues(alpha: 0.95),
              ArtbeatColors.primaryGreen.withValues(alpha: 0.12),
              Colors.white,
            ],
            stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.8),
              blurRadius: 4,
              offset: const Offset(-1, -1),
            ),
            BoxShadow(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(1, 1),
            ),
          ],
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
