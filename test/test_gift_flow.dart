import 'package:artbeat_community/screens/gifts/gift_modal.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const GiftFlowTestApp());
}

class GiftFlowTestApp extends StatelessWidget {
  const GiftFlowTestApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Gift Flow Test',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: const GiftFlowTestScreen(),
  );
}

class GiftFlowTestScreen extends StatelessWidget {
  const GiftFlowTestScreen({super.key});

  static const String testRecipientId = 'test_recipient_123';
  static const String testRecipientName = 'Test Artist';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Gift Flow Test')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Test Gift Payment Flows',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Test Gift Modal (Community Package)
          ElevatedButton.icon(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => const GiftModal(
                  recipientId: GiftFlowTestScreen.testRecipientId,
                ),
              );
            },
            icon: const Icon(Icons.card_giftcard),
            label: const Text('Test Gift Modal (Community)'),
          ),
          const SizedBox(height: 16),

          // Test Enhanced Gift Purchase Screen (Core Package)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<Widget>(
                  builder: (context) => const EnhancedGiftPurchaseScreen(
                    recipientId: GiftFlowTestScreen.testRecipientId,
                    recipientName: GiftFlowTestScreen.testRecipientName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.redeem),
            label: const Text('Test Enhanced Gift Screen (Core)'),
          ),
          const SizedBox(height: 16),

          // Test Direct Order Review
          ElevatedButton.icon(
            onPressed: () async {
              final result = await context.reviewGiftOrder(
                recipientId: GiftFlowTestScreen.testRecipientId,
                recipientName: GiftFlowTestScreen.testRecipientName,
                amount: 10,
                giftType: 'Test Gift',
                message: 'Test message from direct order review',
              );

              if (result != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Result: ${result['status']}'),
                    backgroundColor: result['status'] == 'success'
                        ? Colors.green
                        : Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.receipt_long),
            label: const Text('Test Direct Order Review'),
          ),
          const SizedBox(height: 32),

          Text(
            'Expected Flow:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '1. Tap any button above\n'
            '2. Order Review Screen should open\n'
            '3. Coupon code input should be visible\n'
            '4. Price breakdown should show\n'
            '5. Payment should process with Stripe',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debug Info:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('Check console for debug messages starting with 🎁'),
                Text('Look for amount values in the logs'),
                Text('Verify order review screen opens (not direct payment)'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
