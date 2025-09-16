import 'package:flutter/material.dart';
import '../utils/order_review_helpers.dart';
import '../utils/logger.dart';

/// Example widget showing how to integrate order review screen
class OrderReviewExample extends StatelessWidget {
  const OrderReviewExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Review Examples')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Order Review Integration Examples',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Gift Example
            ElevatedButton.icon(
              onPressed: () => _showGiftOrderReview(context),
              icon: const Icon(Icons.card_giftcard),
              label: const Text('Send Gift (\$10)'),
            ),
            const SizedBox(height: 12),

            // Subscription Example
            ElevatedButton.icon(
              onPressed: () => _showSubscriptionOrderReview(context),
              icon: const Icon(Icons.star),
              label: const Text('Premium Subscription (\$9.99/month)'),
            ),
            const SizedBox(height: 12),

            // Advertisement Example
            ElevatedButton.icon(
              onPressed: () => _showAdOrderReview(context),
              icon: const Icon(Icons.campaign),
              label: const Text('Promote Content (\$25)'),
            ),
            const SizedBox(height: 12),

            // Sponsorship Example
            ElevatedButton.icon(
              onPressed: () => _showSponsorshipOrderReview(context),
              icon: const Icon(Icons.handshake),
              label: const Text('Sponsor Artist (\$50)'),
            ),
            const SizedBox(height: 12),

            // Commission Example
            ElevatedButton.icon(
              onPressed: () => _showCommissionOrderReview(context),
              icon: const Icon(Icons.brush),
              label: const Text('Request Commission (\$100)'),
            ),

            const SizedBox(height: 30),
            const Text(
              'Features:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('• Apply coupon codes for discounts'),
            const Text('• See price breakdown with discounts'),
            const Text('• Secure payment with Stripe'),
            const Text('• Support for all transaction types'),
            const Text('• Automatic coupon validation'),
            const Text('• Free orders when 100% discount applied'),
          ],
        ),
      ),
    );
  }

  /// Example: Gift order review
  Future<void> _showGiftOrderReview(BuildContext context) async {
    final result = await context.reviewGiftOrder(
      recipientId: 'example_artist_id',
      recipientName: 'Amazing Artist',
      amount: 10.0,
      giftType: 'tip',
      message: 'Great work on your latest piece!',
    );

    if (result != null && context.mounted) {
      _showResultDialog(context, 'Gift Sent!', result);
    }
  }

  /// Example: Subscription order review
  Future<void> _showSubscriptionOrderReview(BuildContext context) async {
    final result = await context.reviewSubscriptionOrder(
      tier: 'premium',
      tierDisplayName: 'Premium',
      priceAmount: 9.99,
      billingCycle: 'monthly',
    );

    if (result != null && context.mounted) {
      _showResultDialog(context, 'Subscription Activated!', result);
    }
  }

  /// Example: Advertisement order review
  Future<void> _showAdOrderReview(BuildContext context) async {
    final result = await context.reviewAdOrder(
      adType: 'featured_post',
      amount: 25.0,
      duration: 7,
      targetAudience: {
        'interests': ['art', 'painting', 'landscape'],
        'demographics': 'art_enthusiasts',
      },
      adContent: {
        'title': 'Check out my latest artwork!',
        'description': 'A beautiful landscape painting',
        'imageUrl': 'https://example.com/artwork.jpg',
      },
    );

    if (result != null && context.mounted) {
      _showResultDialog(context, 'Advertisement Created!', result);
    }
  }

  /// Example: Sponsorship order review
  Future<void> _showSponsorshipOrderReview(BuildContext context) async {
    final result = await context.reviewSponsorshipOrder(
      artistId: 'example_artist_id',
      artistName: 'Talented Artist',
      sponsorshipType: 'monthly_support',
      amount: 50.0,
      duration: 30,
      benefits: [
        'Early access to new artwork',
        'Monthly behind-the-scenes content',
        'Sponsor recognition on profile',
      ],
    );

    if (result != null && context.mounted) {
      _showResultDialog(context, 'Sponsorship Started!', result);
    }
  }

  /// Example: Commission order review
  Future<void> _showCommissionOrderReview(BuildContext context) async {
    final result = await context.reviewCommissionOrder(
      artistId: 'example_artist_id',
      artistName: 'Skilled Artist',
      commissionType: 'custom_portrait',
      amount: 100.0,
      description: 'Digital portrait of my pet cat in watercolor style',
      deadline: DateTime.now().add(const Duration(days: 14)),
      requirements: {
        'style': 'watercolor',
        'size': '12x16 inches',
        'format': 'digital',
        'revisions': 2,
      },
    );

    if (result != null && context.mounted) {
      _showResultDialog(context, 'Commission Requested!', result);
    }
  }

  /// Show result dialog
  void _showResultDialog(
    BuildContext context,
    String title,
    Map<String, dynamic> result,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${result['status']}'),
            if (result['couponApplied'] != null) ...[
              const SizedBox(height: 8),
              Text('Coupon Applied: ${result['couponApplied']['code']}'),
              Text(
                'Original Amount: \$${result['originalAmount'].toStringAsFixed(2)}',
              ),
              Text(
                'Discount: \$${result['discountAmount'].toStringAsFixed(2)}',
              ),
              Text(
                'Final Amount: \$${result['finalAmount'].toStringAsFixed(2)}',
              ),
            ],
            const SizedBox(height: 8),
            Text('Message: ${result['message']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Example of how to replace direct payment calls with order review
class PaymentIntegrationExample {
  /// OLD WAY: Direct payment without coupon support
  static Future<void> oldDirectPayment(BuildContext context) async {
    // This is how you might have called payments before
    /*
    final paymentService = PaymentService();
    final result = await paymentService.processDirectGiftPayment(
      recipientId: 'artist_id',
      amount: 10.0,
      giftType: 'tip',
      message: 'Great work!',
    );
    */
  }

  /// NEW WAY: Using order review screen with coupon support
  static Future<void> newOrderReviewPayment(BuildContext context) async {
    // Now you can use the order review screen which includes coupon support
    final result = await context.reviewGiftOrder(
      recipientId: 'artist_id',
      recipientName: 'Artist Name',
      amount: 10.0,
      giftType: 'tip',
      message: 'Great work!',
    );

    if (result != null) {
      // Payment completed successfully
      // The result includes coupon information if applied
      AppLogger.info('Payment completed: ${result['status']}');
      if (result['couponApplied'] != null) {
        AppLogger.info('Coupon used: ${result['couponApplied']['code']}');
        AppLogger.info('Saved: \$${result['discountAmount']}');
      }
    }
  }

  /// Example of integrating with existing UI buttons
  static Widget buildGiftButton(
    BuildContext context,
    String artistId,
    String artistName,
  ) {
    return ElevatedButton.icon(
      onPressed: () async {
        final result = await context.reviewGiftOrder(
          recipientId: artistId,
          recipientName: artistName,
          amount: 5.0,
          giftType: 'tip',
          message: 'Thanks for sharing your art!',
        );

        if (result != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] as String),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      icon: const Icon(Icons.card_giftcard),
      label: const Text('Send \$5 Tip'),
    );
  }
}
