import 'package:flutter/material.dart';
import '../models/subscription_tier.dart';
import '../screens/subscription_purchase_screen.dart';
// Note: PaymentMethodsScreen is now available in artbeat_artist package

/// Example demonstrating how to integrate all Stripe payment features
class PaymentIntegrationExample extends StatefulWidget {
  const PaymentIntegrationExample({super.key});

  @override
  State<PaymentIntegrationExample> createState() =>
      _PaymentIntegrationExampleState();
}

class _PaymentIntegrationExampleState extends State<PaymentIntegrationExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Integration Examples'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Payment Management'),
            _buildPaymentManagementSection(),
            const SizedBox(height: 32),

            _buildSectionHeader('Subscription Purchases'),
            _buildSubscriptionSection(),
            const SizedBox(height: 32),

            _buildSectionHeader('Gift Purchases'),
            _buildGiftSection(),
            const SizedBox(height: 32),

            _buildSectionHeader('Ad Purchases'),
            _buildAdSection(),
            const SizedBox(height: 32),

            _buildSectionHeader('Integration Guide'),
            _buildIntegrationGuide(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPaymentManagementSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Payment Methods',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Allow users to add, view, and remove payment methods securely.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // PaymentMethodsScreen is now in artbeat_artist package
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Payment methods management moved to artbeat_artist package',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.credit_card),
              label: const Text('Manage Payment Methods (See artbeat_artist)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subscription Tiers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Offer different subscription tiers for artists and galleries.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSubscriptionButton(
                  'Artist Pro - \$29/month',
                  SubscriptionTier.creator,
                  Icons.star,
                ),
                _buildSubscriptionButton(
                  'Gallery - \$99/month',
                  SubscriptionTier.business,
                  Icons.business,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionButton(
    String title,
    SubscriptionTier tier,
    IconData icon,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => SubscriptionPurchaseScreen(tier: tier),
          ),
        );
      },
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildGiftSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Gifts to Artists',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Gifts are now sent via quick purchase flow (InAppGiftService).',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAdSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Promote with Ads',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Purchase ad placements to promote artwork and events.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Example: Navigate to ad creation with payment
                _showAdPurchaseExample();
              },
              icon: const Icon(Icons.campaign),
              label: const Text('Create Ad'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ad Pricing Structure:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('• Banner Ads: \$10 base price'),
            const Text('• Featured Placement: \$25 base price'),
            const Text('• Sponsored Content: \$50 base price'),
            const Text('• Premium Placement: \$100 base price'),
            const SizedBox(height: 8),
            const Text(
              'Pricing varies by location and duration.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationGuide() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Integration Guide',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildIntegrationStep(
              '1. Setup Stripe',
              'Configure Stripe keys in Firebase Functions and Flutter app.',
            ),
            _buildIntegrationStep(
              '2. Payment Methods',
              'Use PaymentMethodsScreen from artbeat_artist package to let users manage cards.',
            ),
            _buildIntegrationStep(
              '3. Subscriptions',
              'Use SubscriptionPurchaseScreen for recurring payments.',
            ),
            _buildIntegrationStep(
              '4. One-time Payments',
              'Use AdPaymentScreen for ad purchases. Use InAppGiftService.purchaseQuickGift() for gifts.',
            ),
            _buildIntegrationStep(
              '5. Webhooks',
              'Configure Stripe webhooks to handle payment events.',
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
                    'Code Example:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '''
// Initialize payment service
final paymentService = PaymentService();

// Process a gift payment
final result = await paymentService.processEnhancedGiftPayment(
  recipientId: 'user_id',
  paymentMethodId: 'pm_123',
  giftType: 'Small Gift (50 Credits)',
  amount: 4.99,
  message: 'Keep creating!',
);

// Create a subscription
final subscription = await paymentService.createSubscription(
  tier: SubscriptionTier.creator,
  paymentMethodId: 'pm_123',
);
                    ''',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationStep(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAdPurchaseExample() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ad Purchase Example'),
        content: const Text(
          'In a real implementation, you would:\n\n'
          '1. Create an AdModel with your ad content\n'
          '2. Select location and duration\n'
          '3. Navigate to AdPaymentScreen\n'
          '4. Process payment through Stripe\n'
          '5. Submit ad for approval',
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
