import 'package:flutter/material.dart';
import '../services/in_app_subscription_service.dart';
import '../models/subscription_tier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

/// Screen for purchasing artist or gallery subscriptions via in-app purchase
class SubscriptionPurchaseScreen extends StatefulWidget {
  final SubscriptionTier tier;
  final bool isUpgrade;

  const SubscriptionPurchaseScreen({
    super.key,
    required this.tier,
    this.isUpgrade = false,
  });

  @override
  State<SubscriptionPurchaseScreen> createState() =>
      _SubscriptionPurchaseScreenState();
}

class _SubscriptionPurchaseScreenState
    extends State<SubscriptionPurchaseScreen> {
  final InAppSubscriptionService _subscriptionService =
      InAppSubscriptionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.isUpgrade ? 'Upgrade to' : 'Subscribe to'} ${_getTierName(widget.tier)}',
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubscriptionSummary(),
                  const SizedBox(height: 24),
                  _buildFeaturesList(),
                  const SizedBox(height: 24),
                  _buildPricingInfo(),
                  const SizedBox(height: 24),
                  _buildPaymentInfo(),
                  const SizedBox(height: 32),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSubscription,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        '${widget.isUpgrade ? 'Upgrade' : 'Subscribe'} - ${_formatPrice(_getTierPrice(widget.tier))}/month',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('core_subscription_cancel'.tr()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSubscriptionSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTierIcon(widget.tier),
                    color: Theme.of(context).primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTierName(widget.tier),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getTierDescription(widget.tier),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isUpgrade
                          ? 'Upgrade your account to unlock premium features'
                          : 'Join thousands of artists and galleries on ARTbeat',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = _getTierFeatures(widget.tier);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What\'s Included',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
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
    );
  }

  Widget _buildPricingInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Subscription',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  _formatPrice(_getTierPrice(widget.tier)),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Billing Cycle',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'Monthly',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Today',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatPrice(_getTierPrice(widget.tier)),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your subscription will automatically renew each month. You can cancel anytime from your account settings.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Payment will be processed securely through the App Store. You can manage your subscription in your device settings.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'By subscribing, you agree to our Terms of Service and Privacy Policy.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          // Navigate to Terms of Service
                          Navigator.pushNamed(context, '/terms-of-service');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Terms of Service',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                      const Text(' • ', style: TextStyle(fontSize: 12)),
                      TextButton(
                        onPressed: () {
                          // Navigate to Privacy Policy
                          Navigator.pushNamed(context, '/privacy-policy');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Privacy Policy',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubscription() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'User not authenticated. Please log in.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Purchase the subscription through IAP
      final success = await _subscriptionService.subscribeToTier(
        widget.tier,
        isYearly: false,
      );

      if (success) {
        if (mounted) {
          // Show success dialog
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                '${widget.isUpgrade ? 'Upgrade' : 'Subscription'} Successful!',
              ),
              content: Text(
                widget.isUpgrade
                    ? 'Your account has been upgraded to ${_getTierName(widget.tier)}. Enjoy your new features!'
                    : 'Welcome to ${_getTierName(widget.tier)}! Your subscription is now active.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );

          // Return to previous screen with success result
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        throw Exception('Failed to initiate subscription purchase');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Subscription failed: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getTierName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return 'Starter';
      case SubscriptionTier.creator:
        return 'Creator';
      case SubscriptionTier.business:
        return 'Business';
      case SubscriptionTier.enterprise:
        return 'Enterprise';
      case SubscriptionTier.free:
        return 'Free';
    }
  }

  String _getTierDescription(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return 'Perfect for entry-level creators';
      case SubscriptionTier.creator:
        return 'Professional tools for serious artists';
      case SubscriptionTier.business:
        return 'Complete solution for growing businesses';
      case SubscriptionTier.enterprise:
        return 'Enterprise-grade features and support';
      case SubscriptionTier.free:
        return 'Basic features to get started';
    }
  }

  IconData _getTierIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return Icons.palette;
      case SubscriptionTier.creator:
        return Icons.star;
      case SubscriptionTier.business:
        return Icons.business;
      case SubscriptionTier.enterprise:
        return Icons.business_center;
      case SubscriptionTier.free:
        return Icons.person;
    }
  }

  double _getTierPrice(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return 4.99;
      case SubscriptionTier.creator:
        return 12.99;
      case SubscriptionTier.business:
        return 29.99;
      case SubscriptionTier.enterprise:
        return 79.99;
      case SubscriptionTier.free:
        return 0.0;
    }
  }

  String _formatPrice(double price) {
    if (price == 0.0) return '\$0';
    return '\$${price.toStringAsFixed(2)}';
  }

  List<String> _getTierFeatures(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return [
          'Up to 25 artworks',
          '5GB storage',
          '50 AI credits/month',
          'Basic analytics',
          'Community features',
          'Email support',
        ];
      case SubscriptionTier.creator:
        return [
          'Up to 100 artworks',
          '25GB storage',
          '200 AI credits/month',
          'Advanced analytics',
          'Featured placement',
          'Event creation',
          'Priority support',
        ];
      case SubscriptionTier.business:
        return [
          'Unlimited artworks',
          '100GB storage',
          '500 AI credits/month',
          'Custom branding',
          'Team collaboration (5 members)',
          'API access',
          'Advanced insights',
        ];
      case SubscriptionTier.enterprise:
        return [
          'Unlimited everything',
          'Custom integrations',
          'Dedicated account manager',
          'SLA guarantees',
          'Advanced security',
          '24/7 phone support',
        ];
      case SubscriptionTier.free:
        return [
          'Up to 3 artworks',
          '0.5GB storage',
          '5 AI credits/month',
          'Basic community access',
        ];
    }
  }
}
