import 'package:flutter/material.dart';
import '../../services/in_app_purchase_manager.dart';
import '../../services/in_app_purchase_setup.dart';
import '../../models/subscription_tier.dart';
import '../../theme/artbeat_colors.dart';

class SubscriptionsScreen extends StatefulWidget {
  final bool showAppBar;
  const SubscriptionsScreen({Key? key, this.showAppBar = true})
    : super(key: key);

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final InAppPurchaseManager _purchaseManager = InAppPurchaseManager();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePurchases();
  }

  Future<void> _initializePurchases() async {
    final setup = InAppPurchaseSetup();
    final initialized = await setup.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = initialized;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Plan',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock features and monetize your art',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ..._buildSubscriptionTiers(),
          const SizedBox(height: 32),
        ],
      ),
    );
    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Artist Subscriptions'),
          backgroundColor: ArtbeatColors.primary,
          foregroundColor: Colors.white,
        ),
        body: content,
      );
    } else {
      return content;
    }
  }

  List<Widget> _buildSubscriptionTiers() {
    final tiers = [
      {
        'name': 'Starter',
        'monthlyProductId': 'artbeat_starter_monthly',
        'yearlyProductId': 'artbeat_starter_yearly',
        'monthlyPrice': '\$4.99',
        'yearlyPrice': '\$49.99',
        'features': [
          'Upload up to 10 artworks',
          'Basic analytics',
          'Standard support',
        ],
      },
      {
        'name': 'Creator',
        'monthlyProductId': 'artbeat_creator_monthly',
        'yearlyProductId': 'artbeat_creator_yearly',
        'monthlyPrice': '\$9.99',
        'yearlyPrice': '\$99.99',
        'features': [
          'Unlimited artwork uploads',
          'Advanced analytics',
          'Priority support',
          'Featured listings',
        ],
        'isPopular': true,
      },
      {
        'name': 'Business',
        'monthlyProductId': 'artbeat_business_monthly',
        'yearlyProductId': 'artbeat_business_yearly',
        'monthlyPrice': '\$19.99',
        'yearlyPrice': '\$199.99',
        'features': [
          'All Creator features',
          'Commission tools',
          'Custom branding',
          'API access',
        ],
      },
      {
        'name': 'Enterprise',
        'monthlyProductId': 'artbeat_enterprise_monthly',
        'yearlyProductId': 'artbeat_enterprise_yearly',
        'monthlyPrice': '\$49.99',
        'yearlyPrice': '\$499.99',
        'features': [
          'All Business features',
          'Dedicated account manager',
          'White-label options',
          '24/7 phone support',
        ],
      },
    ];

    return tiers.map((tier) {
      final isPopular = tier['isPopular'] as bool? ?? false;
      return Column(
        children: [
          Card(
            elevation: isPopular ? 8 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isPopular
                  ? BorderSide(color: ArtbeatColors.primary, width: 2)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tier['name'] as String,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ArtbeatColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Popular',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        tier['monthlyPrice'] as String,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: ArtbeatColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/month',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Text(
                    'or ${tier['yearlyPrice']} /year',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ...(tier['features'] as List<String>)
                      .map(
                        (feature) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: ArtbeatColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(feature),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleSubscription(
                        tier['monthlyProductId'] as String,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPopular
                            ? ArtbeatColors.primary
                            : Colors.grey[300],
                        foregroundColor: isPopular
                            ? Colors.white
                            : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Subscribe Monthly'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _handleSubscription(
                        tier['yearlyProductId'] as String,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isPopular
                              ? ArtbeatColors.primary
                              : Colors.grey[400]!,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Subscribe Yearly'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }).toList();
  }

  Future<void> _handleSubscription(String productId) async {
    if (!_isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('In-app purchases not available. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final tier = _getTierFromProductId(productId);
      final isYearly = productId.contains('yearly');

      final success = await _purchaseManager.subscribeToTier(
        tier,
        isYearly: isYearly,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Subscription initiated!'
                  : 'Failed to complete subscription',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e, _) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  SubscriptionTier _getTierFromProductId(String productId) {
    if (productId.contains('starter')) return SubscriptionTier.starter;
    if (productId.contains('creator')) return SubscriptionTier.creator;
    if (productId.contains('business')) return SubscriptionTier.business;
    if (productId.contains('enterprise')) return SubscriptionTier.enterprise;
    return SubscriptionTier.starter;
  }
}
