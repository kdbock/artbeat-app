import 'package:artbeat_community/screens/gifts/gift_modal.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const GiftIntegrationTestApp());
}

class GiftIntegrationTestApp extends StatelessWidget {
  const GiftIntegrationTestApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Gift Integration Test',
    theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
    home: const GiftIntegrationTestScreen(),
  );
}

class GiftIntegrationTestScreen extends StatelessWidget {
  const GiftIntegrationTestScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Gift Integration Test')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Test Gift Order Review Integration',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: () => _testDirectGiftOrderReview(context),
            icon: const Icon(Icons.card_giftcard),
            label: const Text(r'Test Gift Order Review ($5.00)'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () => _testGiftModal(context),
            icon: const Icon(Icons.redeem),
            label: const Text('Test Gift Modal (Updated)'),
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
                  Text('1. Tap "Test Gift Order Review" button'),
                  Text('2. Should open Order Review Screen'),
                  Text('3. Should show coupon code input field'),
                  Text('4. Should show price breakdown'),
                  Text('5. Should allow payment with Stripe'),
                  SizedBox(height: 8),
                  Text(
                    'If this doesn\'t work, the integration needs fixing.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _testDirectGiftOrderReview(BuildContext context) async {
    try {
      AppLogger.info('🧪 Testing direct gift order review...');

      // Test the context extension method directly
      final result = await context.reviewGiftOrder(
        recipientId: 'test_recipient_123',
        recipientName: 'Test Artist',
        amount: 5,
        giftType: 'Brush Pack',
        message: 'Thanks for your amazing art!',
      );

      if (result != null && context.mounted) {
        _showResult(context, 'Gift Order Review Result', result);
      } else {
        AppLogger.error(
          '❌ Gift order review returned null - user cancelled or error occurred',
        );
      }
    } on Exception catch (e) {
      AppLogger.error('❌ Error testing gift order review: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _testGiftModal(BuildContext context) async {
    // Test the updated gift modal
    showDialog<void>(
      context: context,
      builder: (context) => const GiftModal(recipientId: 'test_recipient_123'),
    );
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
                Text(
                  'Code: ${(result['couponApplied'] as Map<String, dynamic>)['code']}',
                ),
                Text(
                  'Original: \$${(result['originalAmount'] as num).toStringAsFixed(2)}',
                ),
                Text(
                  'Discount: \$${(result['discountAmount'] as num).toStringAsFixed(2)}',
                ),
                Text(
                  'Final: \$${(result['finalAmount'] as num).toStringAsFixed(2)}',
                ),
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
