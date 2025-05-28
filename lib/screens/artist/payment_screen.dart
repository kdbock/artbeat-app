import 'package:flutter/material.dart';
import 'package:artbeat/models/subscription_model.dart';
import 'package:artbeat/services/payment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Screen for handling subscription payments
class PaymentScreen extends StatefulWidget {
  final SubscriptionTier tier;

  const PaymentScreen({
    super.key,
    required this.tier,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscribe to ${_getTierName(widget.tier)}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlanDetails(),
                  const SizedBox(height: 24),
                  _buildFeaturesList(),
                  const SizedBox(height: 32),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
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
                      onPressed: _handlePayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                          'Subscribe Now - ${_getPriceString(widget.tier)}'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTierName(widget.tier),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getPriceString(widget.tier),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getPlanDescription(widget.tier),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Plan Features',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._getPlanFeatures(widget.tier).map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePayment() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      setState(() {
        _errorMessage =
            'User email not available. Please update your profile email.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _paymentService.processPayment(
        tier: widget.tier,
        email: user.email!,
      );

      if (success) {
        if (mounted) {
          // Show success dialog
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Subscription Successful'),
              content: Text(
                  'You\'ve successfully subscribed to the ${_getTierName(widget.tier)}!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );

          // Return to artist dashboard with refresh
          if (mounted) {
            Navigator.pop(context, true); // Return true to trigger refresh
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper methods
  String _getTierName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.standard:
        return 'Artist Pro Plan';
      case SubscriptionTier.premium:
        return 'Gallery Plan';
      default:
        return 'Artist Basic Plan';
    }
  }

  String _getPriceString(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.standard:
        return '\$9.99/month';
      case SubscriptionTier.premium:
        return '\$49.99/month';
      default:
        return 'Free';
    }
  }

  String _getPlanDescription(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.standard:
        return 'For artists who want to showcase their work and connect with art enthusiasts.';
      case SubscriptionTier.premium:
        return 'For galleries and art businesses managing multiple artists and exhibitions.';
      default:
        return 'Basic features for artists getting started on the platform.';
    }
  }

  List<String> _getPlanFeatures(SubscriptionTier tier) {
    final List<String> baseFeatures = [
      'Artist profile page',
      'Community features',
      'Basic analytics',
    ];

    switch (tier) {
      case SubscriptionTier.standard:
        return [
          'Unlimited artwork listings',
          'Featured in discover section',
          'Advanced analytics',
          'Priority support',
          'Event creation and promotion',
          ...baseFeatures,
        ];
      case SubscriptionTier.premium:
        return [
          'Multiple artist management',
          'Business profile for galleries',
          'Advanced analytics dashboard',
          'Dedicated support',
          'Event management and ticketing',
          'Promotional tools and marketing',
          ...baseFeatures,
        ];
      default:
        return [
          'Up to 5 artwork listings',
          ...baseFeatures,
        ];
    }
  }
}
