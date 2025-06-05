import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      // Get the stripe customer ID for the current user
      final customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      final String? stripeCustomerId = customerDoc.data()?['stripeCustomerId'];
      final String? defaultPaymentMethodId =
          customerDoc.data()?['defaultPaymentMethodId'];

      if (stripeCustomerId == null || defaultPaymentMethodId == null) {
        throw Exception('Please add a payment method before subscribing');
      }

      // Get the amount based on the subscription tier
      final amount =
          (widget.tier.monthlyPrice * 100).round(); // Convert to cents
      final description = 'Subscription to ${widget.tier.displayName}';

      final success = await _paymentService.processPayment(
        customerId: stripeCustomerId,
        paymentMethodId: defaultPaymentMethodId,
        amount: amount,
        currency: 'usd',
        description: description,
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
      } else {
        throw Exception('Payment processing failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Payment failed: ${e.toString()}';
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

  // Helper methods
  String _getTierName(SubscriptionTier tier) {
    return tier.displayName;
  }

  String _getPriceString(SubscriptionTier tier) {
    double price = tier.monthlyPrice;
    return '\$${price.toStringAsFixed(2)}';
  }

  String _getPlanDescription(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.basic:
        return 'Basic features for artists';
      case SubscriptionTier.standard:
        return 'Pro features for artists';
      case SubscriptionTier.premium:
        return 'Premium features for galleries';
      case SubscriptionTier.none:
        return 'No subscription';
    }
  }

  List<String> _getPlanFeatures(SubscriptionTier tier) {
    return tier.features;
  }
}
