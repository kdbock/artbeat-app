// ignore_for_file: avoid_print

/// Example demonstrating the newly implemented service methods
///
/// This file shows how to use the 4 core service methods that were just implemented:
/// - SubscriptionService.upgradeSubscription()
/// - SubscriptionService.getFeatureLimits()
/// - SubscriptionService.checkFeatureAccess()
/// - NotificationService.updateNotificationPreferences()

import 'package:artbeat_core/artbeat_core.dart';

class ServiceMethodsExample {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final NotificationService _notificationService = NotificationService();

  /// Example: Upgrade user subscription
  Future<void> upgradeUserSubscription() async {
    try {
      // Upgrade to Creator tier
      await _subscriptionService.upgradeSubscription(SubscriptionTier.creator);
      AppLogger.info('✅ Successfully upgraded to Creator tier');
    } catch (e) {
      AppLogger.error('❌ Upgrade failed: $e');
    }
  }

  /// Example: Check user's feature limits
  Future<void> checkUserLimits() async {
    try {
      final limits = await _subscriptionService.getFeatureLimits();

      AppLogger.analytics('📊 Current Feature Limits:');
      AppLogger.info('  • Artworks: ${limits.artworks}');
      AppLogger.info('  • Storage: ${limits.storageGB} GB');
      AppLogger.info('  • AI Credits: ${limits.aiCredits}');
      AppLogger.info('  • Team Members: ${limits.teamMembers}');
      AppLogger.analytics(
        '  • Advanced Analytics: ${limits.hasAdvancedAnalytics}',
      );
      AppLogger.info('  • Featured Placement: ${limits.hasFeaturedPlacement}');
      AppLogger.info('  • Custom Branding: ${limits.hasCustomBranding}');
    } catch (e) {
      AppLogger.error('❌ Failed to get limits: $e');
    }
  }

  /// Example: Check specific feature access
  Future<void> checkFeatureAccess() async {
    try {
      final features = [
        'advanced_analytics',
        'featured_placement',
        'custom_branding',
        'api_access',
        'unlimited_support',
        'team_members',
        'ai_credits',
      ];

      AppLogger.auth('🔐 Feature Access Check:');
      for (final feature in features) {
        final hasAccess = await _subscriptionService.checkFeatureAccess(
          feature,
        );
        final status = hasAccess ? '✅' : '❌';
        AppLogger.info('  $status $feature');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to check feature access: $e');
    }
  }

  /// Example: Update notification preferences
  Future<void> updateNotificationSettings() async {
    try {
      final preferences = {
        'likes': true,
        'comments': true,
        'follows': true,
        'messages': true,
        'mentions': true,
        'artworkPurchases': true,
        'subscriptions': true,
        'subscriptionExpirations': true,
        'galleryInvitations': false, // User doesn't want gallery invites
        'invitationResponses': true,
        'achievements': true,
        'emailNotifications': true,
        'pushNotifications': true,
        'marketingEmails': false, // User opted out of marketing
      };

      await _notificationService.updateNotificationPreferences(preferences);
      AppLogger.info('✅ Notification preferences updated successfully');

      // Verify the update
      final currentPrefs = await _notificationService
          .getNotificationPreferences();
      AppLogger.info('📱 Current notification settings:');
      currentPrefs.forEach((key, value) {
        final status = value ? '🔔' : '🔕';
        AppLogger.info('  $status $key');
      });
    } catch (e) {
      AppLogger.error('❌ Failed to update notification preferences: $e');
    }
  }

  /// Example: Complete workflow demonstrating all new methods
  Future<void> completeWorkflow() async {
    AppLogger.info('🚀 Starting complete service methods workflow...\n');

    // 1. Check current limits
    AppLogger.info('1️⃣ Checking current feature limits...');
    await checkUserLimits();
    AppLogger.info('');

    // 2. Check feature access
    AppLogger.info('2️⃣ Checking feature access...');
    await checkFeatureAccess();
    AppLogger.info('');

    // 3. Update notification preferences
    AppLogger.info('3️⃣ Updating notification preferences...');
    await updateNotificationSettings();
    AppLogger.info('');

    // 4. Upgrade subscription (commented out to avoid charges)
    AppLogger.info('4️⃣ Subscription upgrade (demo - not executed)');
    AppLogger.info(
      '   Call upgradeUserSubscription() to upgrade to a paid tier',
    );
    AppLogger.info('');

    AppLogger.info(
      '✅ Workflow completed! All 4 new service methods demonstrated.',
    );
  }
}

/// Usage example
void main() async {
  final example = ServiceMethodsExample();

  // Run the complete workflow
  await example.completeWorkflow();
}
