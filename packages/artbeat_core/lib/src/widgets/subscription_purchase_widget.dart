import 'package:flutter/material.dart';
import '../models/subscription_tier.dart';
import '../services/in_app_purchase_manager.dart';
import '../utils/logger.dart';

/// Widget for displaying and purchasing subscription tiers
class SubscriptionPurchaseWidget extends StatefulWidget {
  final void Function(SubscriptionTier)? onSubscriptionPurchased;
  final void Function(String)? onError;

  const SubscriptionPurchaseWidget({
    super.key,
    this.onSubscriptionPurchased,
    this.onError,
  });

  @override
  State<SubscriptionPurchaseWidget> createState() =>
      _SubscriptionPurchaseWidgetState();
}

class _SubscriptionPurchaseWidgetState
    extends State<SubscriptionPurchaseWidget> {
  final InAppPurchaseManager _purchaseManager = InAppPurchaseManager();
  bool _isLoading = false;
  bool _isYearly = false;
  List<Map<String, dynamic>> _subscriptionPricing = [];

  @override
  void initState() {
    super.initState();
    _loadSubscriptionPricing();
  }

  void _loadSubscriptionPricing() {
    setState(() {
      _subscriptionPricing = _purchaseManager.getAllSubscriptionPricing();
    });
  }

  Future<void> _purchaseSubscription(SubscriptionTier tier) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _purchaseManager.subscribeToTier(
        tier,
        isYearly: _isYearly,
      );

      if (success) {
        widget.onSubscriptionPurchased?.call(tier);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Subscription purchase initiated for ${tier.displayName}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        widget.onError?.call('Failed to initiate subscription purchase');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to initiate subscription purchase'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error purchasing subscription: $e');
      widget.onError?.call(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Billing period toggle
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Monthly',
                  style: TextStyle(
                    fontWeight: _isYearly ? FontWeight.normal : FontWeight.bold,
                    color: _isYearly
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: _isYearly,
                  onChanged: (value) {
                    setState(() {
                      _isYearly = value;
                    });
                  },
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yearly',
                      style: TextStyle(
                        fontWeight: _isYearly
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _isYearly
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                      ),
                    ),
                    if (_isYearly)
                      const Text(
                        '20% OFF',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Subscription tiers
        ...(_subscriptionPricing.map((pricing) {
          final tier = pricing['tier'] as SubscriptionTier;
          final monthlyPrice = pricing['monthlyPrice'] as double;
          final yearlyMonthlyEquivalent =
              pricing['yearlyMonthlyEquivalent'] as double;
          final yearlySavings = pricing['yearlySavings'] as double;
          final features = pricing['features'] as List<String>;

          final displayPrice = _isYearly
              ? yearlyMonthlyEquivalent
              : monthlyPrice;
          final displayPeriod = _isYearly ? 'month (billed yearly)' : 'month';

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Card(
              elevation: tier == SubscriptionTier.creator ? 4 : 2,
              child: Container(
                decoration: tier == SubscriptionTier.creator
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    tier.displayName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (tier == SubscriptionTier.creator)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'POPULAR',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '\$${displayPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '/$displayPeriod',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              if (_isYearly)
                                Text(
                                  'Save \$${yearlySavings.toStringAsFixed(2)} per year',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _purchaseSubscription(tier),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tier == SubscriptionTier.creator
                                  ? Theme.of(context).primaryColor
                                  : null,
                              foregroundColor: tier == SubscriptionTier.creator
                                  ? Colors.white
                                  : null,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Subscribe'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Features
                      const Text(
                        'Features:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...features.map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check,
                                size: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        })),

        // Terms and conditions
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Subscriptions automatically renew unless cancelled. You can cancel anytime in your account settings. Prices may vary by region.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// Simple subscription tier card widget
class SubscriptionTierCard extends StatelessWidget {
  final SubscriptionTier tier;
  final bool isYearly;
  final bool isLoading;
  final VoidCallback? onPurchase;

  const SubscriptionTierCard({
    super.key,
    required this.tier,
    this.isYearly = false,
    this.isLoading = false,
    this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final monthlyPrice = tier.monthlyPrice;
    final yearlyPrice = monthlyPrice * 12 * 0.8; // 20% discount
    final displayPrice = isYearly ? yearlyPrice / 12 : monthlyPrice;
    final displayPeriod = isYearly ? 'month (billed yearly)' : 'month';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tier.displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$${displayPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '/$displayPeriod',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tier.features
                .take(3)
                .map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          size: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (tier.features.length > 3)
              Text(
                '+${tier.features.length - 3} more features',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onPurchase,
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Subscribe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
