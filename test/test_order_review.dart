import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const OrderReviewTestApp());
}

class OrderReviewTestApp extends StatelessWidget {
  const OrderReviewTestApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Order Review Test',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const OrderReviewTestScreen(),
    );
}

class OrderReviewTestScreen extends StatelessWidget {
  const OrderReviewTestScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Order Review System Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Order Review with Coupon Support',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Test Gift Payment
            ElevatedButton.icon(
              onPressed: () => _testGiftPayment(context),
              icon: const Icon(Icons.card_giftcard),
              label: const Text(r'Test Gift Payment ($10)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Test Subscription Payment
            ElevatedButton.icon(
              onPressed: () => _testSubscriptionPayment(context),
              icon: const Icon(Icons.star),
              label: const Text(r'Test Subscription ($9.99/month)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Test Commission Payment
            ElevatedButton.icon(
              onPressed: () => _testCommissionPayment(context),
              icon: const Icon(Icons.brush),
              label: const Text(r'Test Commission ($100)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 30),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Instructions:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Tap any payment button above'),
                    Text('2. Try entering a coupon code (e.g., "SAVE10")'),
                    Text('3. See the price breakdown with discount'),
                    Text('4. Complete the payment with Stripe'),
                    SizedBox(height: 8),
                    Text(
                      'Features Tested:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• Order review screen UI'),
                    Text('• Coupon code validation'),
                    Text('• Price calculation with discounts'),
                    Text('• Payment processing integration'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

  Future<void> _testGiftPayment(BuildContext context) async {
    final result = await context.reviewGiftOrder(
      recipientId: 'test_artist_123',
      recipientName: 'Test Artist',
      amount: 10,
      giftType: 'tip',
      message: 'Thanks for your amazing artwork!',
    );

    if (result != null && context.mounted) {
      _showResult(context, 'Gift Payment Result', result);
    }
  }

  Future<void> _testSubscriptionPayment(BuildContext context) async {
    final result = await context.reviewSubscriptionOrder(
      tier: 'premium',
      tierDisplayName: 'Premium',
      priceAmount: 9.99,
      billingCycle: 'monthly',
    );

    if (result != null && context.mounted) {
      _showResult(context, 'Subscription Payment Result', result);
    }
  }

  Future<void> _testCommissionPayment(BuildContext context) async {
    final result = await context.reviewCommissionOrder(
      artistId: 'test_artist_123',
      artistName: 'Test Artist',
      commissionType: 'digital_portrait',
      amount: 100,
      description: 'Custom digital portrait in watercolor style',
      deadline: DateTime.now().add(const Duration(days: 14)),
    );

    if (result != null && context.mounted) {
      _showResult(context, 'Commission Payment Result', result);
    }
  }

  void _showResult(
    BuildContext context,
    String title,
    Map<String, dynamic> result,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${result['status']}'),
              const SizedBox(height: 8),
              if (result['couponApplied'] != null) ...[
                const Text(
                  'Coupon Applied:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text('Code: ${result['couponApplied']['code']}'),
                Text(
                  'Original: \$${result['originalAmount'].toStringAsFixed(2)}',
                ),
                Text(
                  'Discount: \$${result['discountAmount'].toStringAsFixed(2)}',
                ),
                Text('Final: \$${result['finalAmount'].toStringAsFixed(2)}'),
                const SizedBox(height: 8),
              ],
              Text('Message: ${result['message']}'),
              if (result['paymentIntentId'] != null) ...[
                const SizedBox(height: 8),
                Text('Payment ID: ${result['paymentIntentId']}'),
              ],
            ],
          ),
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
