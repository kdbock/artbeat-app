import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

/// Screen to compare different subscription tiers
class SubscriptionComparisonScreen extends StatelessWidget {
  final core.SubscriptionTier? currentTier;

  const SubscriptionComparisonScreen({
    super.key,
    this.currentTier,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Plans'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildComparisonColumn(
                  context: context,
                  tier: core.SubscriptionTier.artistBasic,
                  title: 'Artist Basic',
                  price: 'Free',
                  isCurrent: currentTier == core.SubscriptionTier.artistBasic,
                ),
                _buildComparisonColumn(
                  context: context,
                  tier: core.SubscriptionTier.artistPro,
                  title: 'Artist Pro',
                  price: '\$9.99/month',
                  isRecommended: true,
                  isCurrent: currentTier == core.SubscriptionTier.artistPro,
                ),
                _buildComparisonColumn(
                  context: context,
                  tier: core.SubscriptionTier.gallery,
                  title: 'Gallery',
                  price: '\$49.99/month',
                  isCurrent: currentTier == core.SubscriptionTier.gallery,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'All plans include community features, profile customization, and basic analytics.',
            style: TextStyle(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonColumn({
    required BuildContext context,
    required core.SubscriptionTier tier,
    required String title,
    required String price,
    bool isRecommended = false,
    bool isCurrent = false,
  }) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCurrent
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          width: isCurrent ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              color: Colors.amber.shade100,
              child: const Text(
                'RECOMMENDED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const Text(
                'CURRENT PLAN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Features',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ..._getFeatures(tier).map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(feature)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Limitations',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ..._getLimitations(tier).map(
                  (limitation) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Icon(
                          limitation.startsWith('❌')
                              ? Icons.cancel
                              : Icons.info_outline,
                          color: limitation.startsWith('❌')
                              ? Colors.red
                              : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(limitation.startsWith('❌')
                                ? limitation.substring(2)
                                : limitation)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getFeatures(core.SubscriptionTier tier) {
    switch (tier) {
      case core.SubscriptionTier.artistBasic:
        return [
          'Artist profile page',
          'Up to 5 artwork listings',
          'Basic analytics',
          'Community features',
        ];
      case core.SubscriptionTier.artistPro:
        return [
          'Unlimited artwork listings',
          'Featured in discover section',
          'Advanced analytics',
          'Priority support',
          'Event creation and promotion',
          'Commission handling tools',
        ];
      case core.SubscriptionTier.gallery:
        return [
          'Multiple artist management',
          'Business profile for galleries',
          'Advanced analytics dashboard',
          'Dedicated support',
          'Event ticketing and sales',
          'Commission management',
          'Marketing tools',
          'Bulk uploads',
        ];
      case core.SubscriptionTier.free:
        return [
          'Basic profile access',
          'Community features',
        ];
    }
  }

  List<String> _getLimitations(core.SubscriptionTier tier) {
    switch (tier) {
      case core.SubscriptionTier.artistBasic:
        return [
          'Limited to 5 artworks',
          '❌ No advanced analytics',
          '❌ No featured placement',
          '❌ No event creation',
        ];
      case core.SubscriptionTier.artistPro:
        return [
          '❌ No gallery management tools',
          '❌ No bulk artwork uploads',
          'Standard support only',
        ];
      case core.SubscriptionTier.gallery:
        return [
          'Higher monthly cost',
        ];
      case core.SubscriptionTier.free:
        return [
          '❌ No artwork uploads',
          '❌ No analytics',
          '❌ Limited features',
        ];
    }
  }
}
