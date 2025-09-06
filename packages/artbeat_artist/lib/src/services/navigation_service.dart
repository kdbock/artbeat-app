import 'package:flutter/material.dart';
import '../screens/screens.dart';
import '../screens/earnings/artist_earnings_dashboard.dart';
import '../screens/earnings/payout_request_screen.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

/// Service for handling navigation within the artist module
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  /// Navigate to artist dashboard
  static Future<void> navigateToArtistDashboard(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
          builder: (context) => const ArtistDashboardScreen()),
    );
  }

  /// Navigate to artist profile edit screen
  static Future<void> navigateToProfileEdit(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
          builder: (context) => const ArtistProfileEditScreen()),
    );
  }

  /// Navigate to earnings dashboard
  static Future<void> navigateToEarnings(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
          builder: (context) => const ArtistEarningsDashboard()),
    );
  }

  /// Navigate to analytics dashboard
  static Future<void> navigateToAnalytics(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
          builder: (context) => const AnalyticsDashboardScreen()),
    );
  }

  /// Navigate to subscription analytics
  static Future<void> navigateToSubscriptionAnalytics(
      BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
          builder: (context) => const SubscriptionAnalyticsScreen()),
    );
  }

  /// Navigate to gallery management screen
  static Future<void> navigateToGalleryManagement(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
          builder: (context) => const GalleryArtistsManagementScreen()),
    );
  }

  /// Navigate to event creation screen
  static Future<void> navigateToEventCreation(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
          builder: (context) => const EventCreationScreen()),
    );
  }

  /// Navigate to payment methods screen
  static Future<void> navigateToPaymentMethods(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
          builder: (context) => const PaymentMethodsScreen()),
    );
  }

  /// Navigate to payout request screen
  static Future<void> navigateToPayoutRequest(
    BuildContext context, {
    required double availableBalance,
    VoidCallback? onPayoutRequested,
  }) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => PayoutRequestScreen(
          availableBalance: availableBalance,
          onPayoutRequested: onPayoutRequested ?? () {},
        ),
      ),
    );
  }

  /// Navigate to artist onboarding (requires user for traditional onboarding)
  static Future<void> navigateToOnboarding(
    BuildContext context, {
    required core.UserModel user,
    bool useModern = true,
    VoidCallback? onComplete,
  }) async {
    final screen = useModern
        ? const Modern2025OnboardingScreen()
        : ArtistOnboardingScreen(user: user, onComplete: onComplete);

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (context) => screen),
    );
  }

  /// Navigate with replacement (no back navigation)
  static Future<void> navigateAndReplace(
      BuildContext context, Widget screen) async {
    await Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(builder: (context) => screen),
    );
  }

  /// Navigate and clear stack
  static Future<void> navigateAndClear(
      BuildContext context, Widget screen) async {
    await Navigator.pushAndRemoveUntil<void>(
      context,
      MaterialPageRoute<void>(builder: (context) => screen),
      (route) => false,
    );
  }

  /// Pop with result
  static void popWithResult<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }
}
