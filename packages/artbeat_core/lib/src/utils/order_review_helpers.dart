import 'package:flutter/material.dart';
import '../screens/order_review_screen.dart';
import 'logger.dart';

/// Helper functions to launch order review screen for different transaction types
class OrderReviewHelpers {
  /// Launch order review for gift payment
  static Future<Map<String, dynamic>?> reviewGiftOrder({
    required BuildContext context,
    required String recipientId,
    required String recipientName,
    required double amount,
    required String giftType,
    String? message,
  }) {
    debugPrint(
      '🎁 OrderReviewHelpers.reviewGiftOrder called with amount: \$${amount.toStringAsFixed(2)}',
    );
    AppLogger.info('🎁 Gift type: $giftType');
    AppLogger.info('🎁 Recipient: $recipientName');

    final orderDetails = OrderDetails(
      type: TransactionType.gift,
      title: 'Send Gift to $recipientName',
      description: 'Send a \$${amount.toStringAsFixed(2)} $giftType gift',
      originalAmount: amount,
      metadata: {
        'recipientId': recipientId,
        'giftType': giftType,
        'message': message,
      },
    );

    return Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => OrderReviewScreen(orderDetails: orderDetails),
      ),
    );
  }

  /// Launch order review for subscription payment
  static Future<Map<String, dynamic>?> reviewSubscriptionOrder({
    required BuildContext context,
    required String tier,
    required String tierDisplayName,
    required double priceAmount,
    required String billingCycle,
  }) {
    final orderDetails = OrderDetails(
      type: TransactionType.subscription,
      title: '$tierDisplayName Subscription',
      description: 'Subscribe to $tierDisplayName tier - $billingCycle billing',
      originalAmount: priceAmount,
      metadata: {'tier': tier, 'billingCycle': billingCycle},
    );

    return Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => OrderReviewScreen(orderDetails: orderDetails),
      ),
    );
  }

  /// Launch order review for advertisement payment
  static Future<Map<String, dynamic>?> reviewAdOrder({
    required BuildContext context,
    required String adType,
    required double amount,
    required int duration,
    Map<String, dynamic>? targetAudience,
    Map<String, dynamic>? adContent,
  }) {
    final orderDetails = OrderDetails(
      type: TransactionType.advertisement,
      title: 'Promote Your Content',
      description: '$adType advertisement for $duration days',
      originalAmount: amount,
      metadata: {
        'adType': adType,
        'duration': duration,
        'targetAudience': targetAudience,
        'adContent': adContent,
      },
    );

    return Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => OrderReviewScreen(orderDetails: orderDetails),
      ),
    );
  }

  /// Launch order review for sponsorship payment
  static Future<Map<String, dynamic>?> reviewSponsorshipOrder({
    required BuildContext context,
    required String artistId,
    required String artistName,
    required String sponsorshipType,
    required double amount,
    required int duration,
    required List<String> benefits,
  }) {
    final orderDetails = OrderDetails(
      type: TransactionType.sponsorship,
      title: 'Sponsor $artistName',
      description: '$sponsorshipType sponsorship for $duration days',
      originalAmount: amount,
      metadata: {
        'artistId': artistId,
        'sponsorshipType': sponsorshipType,
        'duration': duration,
        'benefits': benefits,
      },
    );

    return Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => OrderReviewScreen(orderDetails: orderDetails),
      ),
    );
  }

  /// Launch order review for commission payment
  static Future<Map<String, dynamic>?> reviewCommissionOrder({
    required BuildContext context,
    required String artistId,
    required String artistName,
    required String commissionType,
    required double amount,
    required String description,
    DateTime? deadline,
    Map<String, dynamic>? requirements,
  }) {
    final orderDetails = OrderDetails(
      type: TransactionType.commission,
      title: 'Commission from $artistName',
      description: '$commissionType commission - $description',
      originalAmount: amount,
      metadata: {
        'artistId': artistId,
        'commissionType': commissionType,
        'description': description,
        'deadline': deadline,
        'requirements': requirements,
      },
    );

    return Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => OrderReviewScreen(orderDetails: orderDetails),
      ),
    );
  }

  /// Show order review as a modal bottom sheet (alternative presentation)
  static Future<Map<String, dynamic>?> showOrderReviewModal({
    required BuildContext context,
    required OrderDetails orderDetails,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: OrderReviewScreen(orderDetails: orderDetails),
      ),
    );
  }
}

/// Extension methods for easier access
extension OrderReviewExtensions on BuildContext {
  /// Quick access to gift order review
  Future<Map<String, dynamic>?> reviewGiftOrder({
    required String recipientId,
    required String recipientName,
    required double amount,
    required String giftType,
    String? message,
  }) => OrderReviewHelpers.reviewGiftOrder(
    context: this,
    recipientId: recipientId,
    recipientName: recipientName,
    amount: amount,
    giftType: giftType,
    message: message,
  );

  /// Quick access to subscription order review
  Future<Map<String, dynamic>?> reviewSubscriptionOrder({
    required String tier,
    required String tierDisplayName,
    required double priceAmount,
    required String billingCycle,
  }) => OrderReviewHelpers.reviewSubscriptionOrder(
    context: this,
    tier: tier,
    tierDisplayName: tierDisplayName,
    priceAmount: priceAmount,
    billingCycle: billingCycle,
  );

  /// Quick access to ad order review
  Future<Map<String, dynamic>?> reviewAdOrder({
    required String adType,
    required double amount,
    required int duration,
    Map<String, dynamic>? targetAudience,
    Map<String, dynamic>? adContent,
  }) => OrderReviewHelpers.reviewAdOrder(
    context: this,
    adType: adType,
    amount: amount,
    duration: duration,
    targetAudience: targetAudience,
    adContent: adContent,
  );

  /// Quick access to sponsorship order review
  Future<Map<String, dynamic>?> reviewSponsorshipOrder({
    required String artistId,
    required String artistName,
    required String sponsorshipType,
    required double amount,
    required int duration,
    required List<String> benefits,
  }) => OrderReviewHelpers.reviewSponsorshipOrder(
    context: this,
    artistId: artistId,
    artistName: artistName,
    sponsorshipType: sponsorshipType,
    amount: amount,
    duration: duration,
    benefits: benefits,
  );

  /// Quick access to commission order review
  Future<Map<String, dynamic>?> reviewCommissionOrder({
    required String artistId,
    required String artistName,
    required String commissionType,
    required double amount,
    required String description,
    DateTime? deadline,
    Map<String, dynamic>? requirements,
  }) => OrderReviewHelpers.reviewCommissionOrder(
    context: this,
    artistId: artistId,
    artistName: artistName,
    commissionType: commissionType,
    amount: amount,
    description: description,
    deadline: deadline,
    requirements: requirements,
  );
}
