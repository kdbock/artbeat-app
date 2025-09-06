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
      print('✅ Successfully upgraded to Creator tier');
    } catch (e) {
      print('❌ Upgrade failed: $e');
    }
  }

  /// Example: Check user's feature limits
  Future<void> checkUserLimits() async {
    try {
      final limits = await _subscriptionService.getFeatureLimits();

      print('📊 Current Feature Limits:');
      print('  • Artworks: ${limits.artworks}');
      print('  • Storage: ${limits.storageGB} GB');
      print('  • AI Credits: ${limits.aiCredits}');
      print('  • Team Members: ${limits.teamMembers}');
      print('  • Advanced Analytics: ${limits.hasAdvancedAnalytics}');
      print('  • Featured Placement: ${limits.hasFeaturedPlacement}');
      print('  • Custom Branding: ${limits.hasCustomBranding}');
    } catch (e) {
      print('❌ Failed to get limits: $e');
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

      print('🔐 Feature Access Check:');
      for (final feature in features) {
        final hasAccess = await _subscriptionService.checkFeatureAccess(
          feature,
        );
        final status = hasAccess ? '✅' : '❌';
        print('  $status $feature');
      }
    } catch (e) {
      print('❌ Failed to check feature access: $e');
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
      print('✅ Notification preferences updated successfully');

      // Verify the update
      final currentPrefs = await _notificationService
          .getNotificationPreferences();
      print('📱 Current notification settings:');
      currentPrefs.forEach((key, value) {
        final status = value ? '🔔' : '🔕';
        print('  $status $key');
      });
    } catch (e) {
      print('❌ Failed to update notification preferences: $e');
    }
  }

  /// Example: Complete workflow demonstrating all new methods
  Future<void> completeWorkflow() async {
    print('🚀 Starting complete service methods workflow...\n');

    // 1. Check current limits
    print('1️⃣ Checking current feature limits...');
    await checkUserLimits();
    print('');

    // 2. Check feature access
    print('2️⃣ Checking feature access...');
    await checkFeatureAccess();
    print('');

    // 3. Update notification preferences
    print('3️⃣ Updating notification preferences...');
    await updateNotificationSettings();
    print('');

    // 4. Upgrade subscription (commented out to avoid charges)
    print('4️⃣ Subscription upgrade (demo - not executed)');
    print('   Call upgradeUserSubscription() to upgrade to a paid tier');
    print('');

    print('✅ Workflow completed! All 4 new service methods demonstrated.');
  }
}

/// Usage example
void main() async {
  final example = ServiceMethodsExample();

  // Run the complete workflow
  await example.completeWorkflow();
}
