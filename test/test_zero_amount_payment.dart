import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ZeroAmountTestApp());
}

class ZeroAmountTestApp extends StatelessWidget {
  const ZeroAmountTestApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Zero Amount Payment Test',
    theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
    home: const ZeroAmountTestScreen(),
  );
}

class ZeroAmountTestScreen extends StatelessWidget {
  const ZeroAmountTestScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Zero Amount Payment Test')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Test Zero Amount Payment Handling',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: () => _testZeroAmountOrderReview(context),
            icon: const Icon(Icons.card_giftcard),
            label: const Text(r'Test Zero Amount Gift Order ($0.00)'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () => _testRegularAmountOrderReview(context),
            icon: const Icon(Icons.payment),
            label: const Text(r'Test Regular Gift Order ($5.00)'),
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
                    'Expected Behavior:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Zero amount order should show "Complete Order (Free)" button',
                  ),
                  Text(
                    r'2. Regular amount order should show "Pay $5.00" button',
                  ),
                  Text('3. Zero amount should skip Stripe payment processing'),
                  Text('4. Both should handle the flow correctly'),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _testZeroAmountOrderReview(BuildContext context) async {
    try {
      AppLogger.info('🧪 Testing zero amount gift order review...');

      // Create order details with zero amount (simulating 100% off coupon)
      final orderDetails = OrderDetails(
        type: TransactionType.gift,
        title: 'Free Gift - Brush Pack',
        description: 'Free gift with 100% off coupon for Test Artist',
        originalAmount: 0, // Zero amount to test free gift handling
        metadata: {
          'recipientId': 'test_recipient_123',
          'recipientName': 'Test Artist',
          'giftType': 'Brush Pack',
          'message': 'Free gift with 100% off coupon!',
        },
      );

      // Navigate to Order Review Screen
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => OrderReviewScreen(
            orderDetails: orderDetails,
            onPaymentComplete: (result) {
              AppLogger.info('🎉 Payment completed: $result');
            },
            onCancel: () {
              AppLogger.error('❌ Payment cancelled');
            },
          ),
        ),
      );

      if (result != null && context.mounted) {
        _showResult(context, 'Zero Amount Gift Result', result);
      } else {
        AppLogger.error(
          '❌ Zero amount gift order returned null - user cancelled or error occurred',
        );
      }
    } on Exception catch (e) {
      AppLogger.error('❌ Error testing zero amount gift order: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _testRegularAmountOrderReview(BuildContext context) async {
    try {
      AppLogger.info('🧪 Testing regular amount gift order review...');

      // Create order details with regular amount
      final orderDetails = OrderDetails(
        type: TransactionType.gift,
        title: 'Paid Gift - Brush Pack',
        description: 'Regular paid gift for Test Artist',
        originalAmount: 5, // Regular amount
        metadata: {
          'recipientId': 'test_recipient_123',
          'recipientName': 'Test Artist',
          'giftType': 'Brush Pack',
          'message': 'Regular paid gift!',
        },
      );

      // Navigate to Order Review Screen
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => OrderReviewScreen(
            orderDetails: orderDetails,
            onPaymentComplete: (result) {
              AppLogger.info('🎉 Payment completed: $result');
            },
            onCancel: () {
              AppLogger.error('❌ Payment cancelled');
            },
          ),
        ),
      );

      if (result != null && context.mounted) {
        _showResult(context, 'Regular Amount Gift Result', result);
      } else {
        AppLogger.error(
          '❌ Regular amount gift order returned null - user cancelled or error occurred',
        );
      }
    } on Exception catch (e) {
      AppLogger.error('❌ Error testing regular amount gift order: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
              Text('Message: ${result['message']}'),
              if (result['paymentIntentId'] != null) ...[
                const SizedBox(height: 8),
                Text('Payment ID: ${result['paymentIntentId']}'),
              ] else ...[
                const SizedBox(height: 8),
                const Text(
                  'No Payment ID (Free Transaction)',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (result['isFreeGift'] == true) ...[
                const SizedBox(height: 8),
                const Text(
                  'Free Gift: YES',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
