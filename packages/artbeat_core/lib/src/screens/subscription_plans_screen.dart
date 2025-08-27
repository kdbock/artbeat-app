import 'package:flutter/material.dart';
import '../models/subscription_tier.dart';
import '../theme/artbeat_colors.dart';
import 'subscription_purchase_screen.dart';

/// Screen showing all available subscription plans for comparison
///
/// This screen allows users to:
/// - View all subscription tiers side by side
/// - Compare features between plans
/// - Select a plan to start the purchase process
class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        backgroundColor: ArtbeatColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ArtbeatColors.primary.withValues(alpha: 0.1),
                        ArtbeatColors.accentOrange.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.palette,
                        size: 48,
                        color: ArtbeatColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Start Your Artistic Journey',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose the perfect plan to showcase and sell your art',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ArtbeatColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Subscription plans
              _buildSubscriptionPlans(context),

              const SizedBox(height: 24),

              // Benefits section
              _buildBenefitsSection(context),

              const SizedBox(height: 24),

              // FAQ section
              _buildFAQSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionPlans(BuildContext context) {
    final plans = [
      SubscriptionTier.free,
      SubscriptionTier.starter,
      SubscriptionTier.creator,
      SubscriptionTier.business,
      SubscriptionTier.enterprise,
    ];

    // For mobile, show as a column
    return Column(
      children: plans
          .map(
            (plan) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: _buildPlanCard(context, plan),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionTier tier) {
    final isRecommended = tier == SubscriptionTier.creator;
    final isFree = tier == SubscriptionTier.free;

    return Card(
      elevation: isRecommended ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isRecommended
              ? ArtbeatColors.primary
              : Colors.grey.withValues(alpha: 0.2),
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recommended badge
            if (isRecommended) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ArtbeatColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'RECOMMENDED',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Plan name and price
            Text(
              tier.displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  isFree ? 'Free' : '\$${tier.monthlyPrice.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.primary,
                  ),
                ),
                if (!isFree)
                  Text(
                    '/month',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ArtbeatColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Features
            Text(
              'Features:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...tier.features
                .map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: ArtbeatColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: ArtbeatColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            const SizedBox(height: 20),

            // CTA button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _selectPlan(context, tier),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFree
                      ? Colors.grey[300]
                      : (isRecommended
                            ? ArtbeatColors.primary
                            : ArtbeatColors.primary.withValues(alpha: 0.8)),
                  foregroundColor: isFree
                      ? ArtbeatColors.textSecondary
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isFree ? 'Get Started' : 'Choose Plan',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why Choose ARTbeat?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildBenefitsList(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBenefitsList(BuildContext context) {
    final benefits = [
      {
        'icon': Icons.storefront,
        'title': 'Professional Storefront',
        'description':
            'Showcase your art with a beautiful, customizable profile',
      },
      {
        'icon': Icons.analytics,
        'title': 'Detailed Analytics',
        'description': 'Track views, engagement, and sales performance',
      },
      {
        'icon': Icons.payment,
        'title': 'Secure Payments',
        'description': 'Built-in payment processing with Stripe integration',
      },
      {
        'icon': Icons.people,
        'title': 'Artist Community',
        'description': 'Connect with other artists and art enthusiasts',
      },
    ];

    return benefits
        .map(
          (benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ArtbeatColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    benefit['icon'] as IconData,
                    color: ArtbeatColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        benefit['title'] as String,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        benefit['description'] as String,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildFAQSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              context,
              'Can I change my plan later?',
              'Yes, you can upgrade or downgrade your plan at any time. Changes will be reflected in your next billing cycle.',
            ),
            _buildFAQItem(
              context,
              'What payment methods do you accept?',
              'We accept all major credit cards and PayPal through our secure Stripe payment processing.',
            ),
            _buildFAQItem(
              context,
              'Is there a free trial?',
              'Yes! Start with our Free plan and upgrade when you\'re ready to unlock more features.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: ArtbeatColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ArtbeatColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _selectPlan(BuildContext context, SubscriptionTier tier) {
    if (tier == SubscriptionTier.free) {
      // For free plan, might navigate to artist onboarding
      Navigator.of(context).pushNamed('/artist/onboarding');
    } else {
      // For paid plans, navigate to purchase screen
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => SubscriptionPurchaseScreen(tier: tier),
        ),
      );
    }
  }
}
