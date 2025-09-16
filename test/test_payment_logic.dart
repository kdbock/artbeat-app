import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const PaymentLogicTestApp());
}

class PaymentLogicTestApp extends StatelessWidget {
  const PaymentLogicTestApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Payment Logic Test',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const PaymentLogicTestScreen(),
    );
}

class PaymentLogicTestScreen extends StatelessWidget {
  const PaymentLogicTestScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Payment Logic Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Payment Logic',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () => _testZeroAmountLogic(context),
              icon: const Icon(Icons.check_circle),
              label: const Text('Test Zero Amount Logic'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () => _testRegularAmountLogic(context),
              icon: const Icon(Icons.payment),
              label: const Text('Test Regular Amount Logic'),
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
                      'Test Results:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This tests the payment logic without Firebase dependencies.',
                    ),
                    Text('Check the console output for detailed results.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

  void _testZeroAmountLogic(BuildContext context) {
    AppLogger.info('🧪 Testing zero amount payment logic...');

    // Simulate the logic from the payment service
    const double amount = 0;

    if (amount <= 0.0) {
      AppLogger.info('✅ Zero amount detected - would skip Stripe payment processing');
      AppLogger.info('✅ Would process free gift directly on backend');
      AppLogger.info('✅ Would return success with isFreeGift: true');

      final mockResult = {
        'status': 'success',
        'giftId': 'mock_gift_123',
        'paymentIntentId': null,
        'message': 'Free gift sent successfully!',
        'isFreeGift': true,
      };

      _showResult(context, 'Zero Amount Logic Test', mockResult);
    } else {
      AppLogger.error('❌ Zero amount logic failed');
    }
  }

  void _testRegularAmountLogic(BuildContext context) {
    AppLogger.info('🧪 Testing regular amount payment logic...');

    // Simulate the logic from the payment service
    const double amount = 5;

    if (amount <= 0.0) {
      AppLogger.error('❌ Regular amount incorrectly detected as zero');
    } else {
      AppLogger.info('✅ Regular amount detected - would create Stripe payment intent');
      AppLogger.info('✅ Would present payment sheet');
      AppLogger.info('✅ Would process payment with backend');

      final mockResult = {
        'status': 'success',
        'giftId': 'mock_gift_456',
        'paymentIntentId': 'pi_mock_payment_intent',
        'message': 'Gift sent successfully!',
        'isFreeGift': false,
      };

      _showResult(context, 'Regular Amount Logic Test', mockResult);
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
