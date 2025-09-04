import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_tier.dart';
import '../services/subscription_service.dart';
import '../services/coupon_service.dart';
import '../widgets/coupon_input_widget.dart';

/// Example screen showing how to integrate coupon functionality into subscription purchase
class SubscriptionPurchaseWithCouponScreen extends StatefulWidget {
  final SubscriptionTier selectedTier;

  const SubscriptionPurchaseWithCouponScreen({
    super.key,
    required this.selectedTier,
  });

  @override
  State<SubscriptionPurchaseWithCouponScreen> createState() =>
      _SubscriptionPurchaseWithCouponScreenState();
}

class _SubscriptionPurchaseWithCouponScreenState
    extends State<SubscriptionPurchaseWithCouponScreen> {
  Map<String, dynamic>? _couponResult;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscribe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan selection header
            Text(
              'Selected Plan',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Plan details card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.selectedTier.displayName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getPlanDescription(widget.selectedTier),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PricingDisplayWidget(
                          tier: widget.selectedTier,
                          couponResult: _couponResult,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Plan features
                    ...widget.selectedTier.features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: theme.textTheme.bodyMedium,
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

            const SizedBox(height: 32),

            // Coupon input section
            CouponInputWidget(
              selectedTier: widget.selectedTier,
              onCouponApplied: (result) {
                setState(() {
                  _couponResult = result;
                });
              },
              onCouponRemoved: () {
                setState(() {
                  _couponResult = null;
                });
              },
            ),

            const SizedBox(height: 32),

            // Subscribe button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processSubscription,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _couponResult?['isFree'] == true
                            ? 'Get Free Access'
                            : 'Subscribe Now',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Terms and conditions
            Text(
              'By subscribing, you agree to our Terms of Service and Privacy Policy.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getPlanDescription(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Perfect for getting started';
      case SubscriptionTier.starter:
        return 'Great for individual creators';
      case SubscriptionTier.creator:
        return 'Most popular choice for professionals';
      case SubscriptionTier.business:
        return 'Ideal for small teams and galleries';
      case SubscriptionTier.enterprise:
        return 'Complete solution for institutions';
    }
  }

  Future<void> _processSubscription() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final subscriptionService = context.read<SubscriptionService>();
      final result = await subscriptionService.createSubscriptionWithCoupon(
        tier: widget.selectedTier,
        couponCode: _couponResult?['coupon']?.code as String?,
      );

      if (result['success'] == true) {
        if (mounted) {
          final theme = Theme.of(context);
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] as String),
              backgroundColor: theme.colorScheme.primary,
            ),
          );

          // Navigate back or to success screen
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          final theme = Theme.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] as String),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process subscription: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

/// Example of how to create a full access coupon for beta testing
class CreateBetaAccessCouponExample {
  static Future<String> createBetaAccessCoupon() async {
    final couponService = CouponService();

    return couponService.createFullAccessCoupon(
      title: 'Beta Tester Access',
      description:
          'Full access to all features for beta testers. No payment required.',
      maxUses: 1000, // Limited to 1000 beta users
      expiresAt: DateTime.now().add(
        const Duration(days: 90),
      ), // 90 days beta period
    );
  }

  static Future<String> createReferralCoupon() async {
    final couponService = CouponService();

    return couponService.createFullAccessCoupon(
      title: 'Referral Bonus',
      description:
          'Free access for successful referrals. Thank you for spreading the word!',
      maxUses: null, // Unlimited uses
      expiresAt: null, // No expiration
    );
  }

  static Future<String> createLimitedTimeOffer() async {
    final couponService = CouponService();

    return couponService.createPercentageDiscountCoupon(
      title: 'Launch Special',
      description: '50% off your first year! Limited time offer.',
      discountPercentage: 50,
      maxUses: 500,
      expiresAt: DateTime.now().add(const Duration(days: 30)), // 30 days
    );
  }
}
