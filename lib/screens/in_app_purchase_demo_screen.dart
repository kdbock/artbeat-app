import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../in_app_purchase_setup.dart';

/// Demo screen to test in-app purchase functionality
class InAppPurchaseDemoScreen extends StatefulWidget {
  const InAppPurchaseDemoScreen({super.key});

  @override
  State<InAppPurchaseDemoScreen> createState() =>
      _InAppPurchaseDemoScreenState();
}

class _InAppPurchaseDemoScreenState extends State<InAppPurchaseDemoScreen> {
  final InAppPurchaseManager _purchaseManager = InAppPurchaseManager();
  bool _isInitialized = false;
  String _status = 'Checking initialization...';

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  void _checkInitialization() {
    setState(() {
      _isInitialized = InAppPurchaseSetup().isInitialized;
      _status = _isInitialized
          ? 'In-app purchases ready!'
          : 'In-app purchases not initialized';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('In-App Purchase Demo'),
      backgroundColor: ArtbeatColors.primary,
      foregroundColor: Colors.white,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isInitialized ? Icons.check_circle : Icons.error,
                        color: _isInitialized ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_status),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _checkInitialization,
                    child: const Text('Refresh Status'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Subscription section
          const Text(
            'Subscriptions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Subscription Tiers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...PurchaseHelper.getSubscriptionTiers().map((tier) {
                    final subscriptionTier = tier['tier'] as SubscriptionTier;
                    final monthlyPrice = tier['monthlyPrice'] as double;

                    return ListTile(
                      title: Text(subscriptionTier.displayName),
                      subtitle: Text(
                        '\$${monthlyPrice.toStringAsFixed(2)}/month',
                      ),
                      trailing: ElevatedButton(
                        onPressed: _isInitialized
                            ? () => _showSubscriptionPurchase(subscriptionTier)
                            : null,
                        child: const Text('Subscribe'),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isInitialized
                          ? _showFullSubscriptionWidget
                          : null,
                      child: const Text('View All Subscription Options'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Gifts section
          const Text(
            'Gifts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Gifts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...PurchaseHelper.getAvailableGifts().take(3).map((gift) => ListTile(
                      leading: const Icon(Icons.card_giftcard),
                      title: Text(gift['title'] as String),
                      subtitle: Text(
                        '\$${gift['amount'].toStringAsFixed(2)} - ${gift['credits']} credits',
                      ),
                      trailing: ElevatedButton(
                        onPressed: _isInitialized
                            ? () => _showGiftPurchase(gift)
                            : null,
                        child: const Text('Send'),
                      ),
                    )),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isInitialized ? _showFullGiftWidget : null,
                      child: const Text('Send a Gift'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Ads section
          const Text(
            'Advertisement Packages',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Ad Packages',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...PurchaseHelper.getAvailableAdPackages().take(3).map((
                    package,
                  ) => ListTile(
                      leading: const Icon(Icons.campaign),
                      title: Text(package['title'] as String),
                      subtitle: Text(
                        '\$${package['amount'].toStringAsFixed(2)} - ${package['impressions']} impressions',
                      ),
                      trailing: ElevatedButton(
                        onPressed: _isInitialized
                            ? () => _showAdPurchase(package)
                            : null,
                        child: const Text('Promote'),
                      ),
                    )),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isInitialized ? _showFullAdWidget : null,
                      child: const Text('Promote Artwork'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Debug info
          if (_isInitialized) ...[
            const Text(
              'Debug Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase Manager Available: ${_purchaseManager.isAvailable}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Subscription Tiers: ${PurchaseHelper.getSubscriptionTiers().length}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Available Gifts: ${PurchaseHelper.getAvailableGifts().length}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Available Ad Packages: ${PurchaseHelper.getAvailableAdPackages().length}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  void _showSubscriptionPurchase(SubscriptionTier tier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Subscribe to ${tier.displayName}'),
        content: Text(
          'This would initiate a subscription purchase for ${tier.displayName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await PurchaseHelper.subscribeToTier(tier);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Subscription purchase initiated!'
                          : 'Failed to initiate subscription purchase',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }

  void _showGiftPurchase(Map<String, dynamic> gift) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send ${gift['title']}'),
        content: Text(
          'This would initiate a gift purchase for ${gift['title']}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gift purchase would be initiated here'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Send Gift'),
          ),
        ],
      ),
    );
  }

  void _showAdPurchase(Map<String, dynamic> package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${package['title']}'),
        content: Text(
          'This would initiate an ad campaign purchase for ${package['title']}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ad campaign purchase would be initiated here'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Start Campaign'),
          ),
        ],
      ),
    );
  }

  void _showFullSubscriptionWidget() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Subscription Plans'),
            backgroundColor: ArtbeatColors.primary,
            foregroundColor: Colors.white,
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: SubscriptionPurchaseWidget(),
          ),
        ),
      ),
    );
  }

  void _showFullGiftWidget() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const GiftPurchaseWidget(recipientName: 'Demo User'),
      ),
    );
  }

  void _showFullAdWidget() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const AdPurchaseWidget(artworkTitle: 'Demo Artwork'),
      ),
    );
  }
}
