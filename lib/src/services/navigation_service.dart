import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Enhanced navigation service with error handling and analytics
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Safe navigation with error handling and analytics
  Future<bool> navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
    bool clearStack = false,
  }) async {
    try {
      // Log navigation event
      await _analytics.logEvent(
        name: 'navigation_attempt',
        parameters: {
          'route_name': routeName,
          'has_arguments': arguments != null,
          'replace': replace,
          'clear_stack': clearStack,
        },
      );

      // Perform navigation
      if (clearStack) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          routeName,
          (route) => false,
          arguments: arguments,
        );
      } else if (replace) {
        Navigator.of(
          context,
        ).pushReplacementNamed(routeName, arguments: arguments);
      } else {
        Navigator.of(context).pushNamed(routeName, arguments: arguments);
      }

      // Log successful navigation
      await _analytics.logEvent(
        name: 'navigation_success',
        parameters: {'route_name': routeName},
      );

      return true;
    } catch (error, stackTrace) {
      // Log navigation error
      await _analytics.logEvent(
        name: 'navigation_error',
        parameters: {'route_name': routeName, 'error': error.toString()},
      );

      // Show error to user
      _showNavigationError(context, routeName, error);

      // Log to console for debugging
      debugPrint('Navigation error to $routeName: $error');
      debugPrint('Stack trace: $stackTrace');

      return false;
    }
  }

  /// Show navigation error dialog
  void _showNavigationError(
    BuildContext context,
    String routeName,
    dynamic error,
  ) {
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Navigation Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Failed to navigate to: $routeName'),
            const SizedBox(height: 8),
            Text(
              'Error: ${error.toString()}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
            },
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  /// Check if route exists
  bool doesRouteExist(String routeName) {
    final validRoutes = [
      '/dashboard',
      '/search',
      '/artist/search',
      '/trending',
      '/local',
      '/auth',
      '/art-walk/my-walks',
      '/events',
      '/artist/onboarding',
      '/art-walk/dashboard',
      '/capture/dashboard',
      '/community/dashboard',
      '/artwork/featured',
      '/artist/dashboard',
      '/art-walk/map',
      '/art-walk/create',
      '/art-walk/list',
      '/art-walk/detail',
      '/artist/public-profile',
      '/artist/artwork-detail',
      '/profile',
      '/achievements',
      '/login',
      '/register',
    ];

    return validRoutes.contains(routeName);
  }

  /// Navigate with validation
  Future<bool> safeNavigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
    bool clearStack = false,
  }) async {
    // Pre-flight checks
    if (!context.mounted) {
      debugPrint('Navigation cancelled: context not mounted');
      return false;
    }

    if (!doesRouteExist(routeName)) {
      debugPrint('Navigation cancelled: route $routeName does not exist');
      _showNavigationError(context, routeName, 'Route does not exist');
      return false;
    }

    return navigateTo(
      context,
      routeName,
      arguments: arguments,
      replace: replace,
      clearStack: clearStack,
    );
  }
}

/// Extension to add safe navigation to BuildContext
extension SafeNavigation on BuildContext {
  NavigationService get nav => NavigationService();

  Future<bool> safeNavigate(
    String routeName, {
    Object? arguments,
    bool replace = false,
    bool clearStack = false,
  }) {
    return NavigationService().safeNavigateTo(
      this,
      routeName,
      arguments: arguments,
      replace: replace,
      clearStack: clearStack,
    );
  }
}
