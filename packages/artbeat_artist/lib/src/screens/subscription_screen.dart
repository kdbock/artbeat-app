import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart' as artist_service;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:logger/logger.dart';
import 'package:artbeat_artist/src/screens/refund_request_screen.dart';
import 'package:artbeat_artist/src/screens/subscription_comparison_screen.dart';
import 'package:artbeat_artist/src/screens/payment_screen.dart';
import 'package:artbeat_artist/src/screens/artist_profile_edit_screen.dart';

/// Screen for managing subscription plans
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final artist_service.SubscriptionService _subscriptionService =
      artist_service.SubscriptionService();
  final core.PaymentService _paymentService = core.PaymentService();
  final Logger _logger = Logger();

  bool _isLoading = true;
  SubscriptionModel? _currentSubscription;
  core.SubscriptionTier _selectedTier = core.SubscriptionTier.artistBasic;
  bool _autoRenew = true;
  bool _isProcessing = false;
  bool _prorateChanges = true; // New property for prorated billing
  List<Map<String, dynamic>> _paymentHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  // Helper method to check if a tier is disabled
  bool _isTierDisabled(core.SubscriptionTier tier) {
    return tier == core.SubscriptionTier.artistPro ||
        tier == core.SubscriptionTier.gallery;
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final subscription = await _subscriptionService.getUserSubscription();
      if (subscription != null) {
        _loadPaymentHistory(subscription.userId);
      }
      if (mounted) {
        setState(() {
          _currentSubscription = subscription;
          // Ensure selected tier is not disabled, default to basic if it is
          final tier = subscription?.tier ?? core.SubscriptionTier.artistBasic;
          _selectedTier =
              _isTierDisabled(tier) ? core.SubscriptionTier.artistBasic : tier;
          _autoRenew = subscription?.autoRenew ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subscription: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Load payment history for the current user
  Future<void> _loadPaymentHistory(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      setState(() {
        _paymentHistory = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      _logger.e('Error loading payment history: $e');
    }
  }

  Future<void> _subscribe() async {
    // Prevent subscription to disabled tiers
    if (_isTierDisabled(_selectedTier)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This subscription tier is coming soon!')),
      );
      return;
    }

    if (_selectedTier == core.SubscriptionTier.artistBasic ||
        _selectedTier == core.SubscriptionTier.free) {
      if (_currentSubscription != null) {
        await _cancelSubscription();
      } else {
        // For free basic plan with no existing subscription, proceed to artist profile creation
        _proceedToArtistProfileCreation();
      }
      return;
    }
    setState(() {
      _isProcessing = true;
    });
    try {
      if (_currentSubscription != null &&
          _isSubscriptionActive(_currentSubscription) &&
          _selectedTier != _currentSubscription!.tier) {
        await _changeTier();
      } else {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (context) => PaymentScreen(tier: _selectedTier),
          ),
        );
        if (result == true) {
          await _loadSubscription();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing subscription: $e')),
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

  // Handle subscription tier changes
  Future<void> _changeTier() async {
    if (_currentSubscription == null ||
        !_isSubscriptionActive(_currentSubscription)) {
      // Can't change tier if no active subscription
      return;
    }

    // First confirm the tier change with user
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final bool isUpgrade =
            _selectedTier.index > _currentSubscription!.tier.index;

        return AlertDialog(
          title: Text(
              isUpgrade ? 'Upgrade Subscription' : 'Downgrade Subscription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUpgrade
                    ? 'You are upgrading from ${_getTierName(_currentSubscription!.tier)} to ${_getTierName(_selectedTier)}.'
                    : 'You are downgrading from ${_getTierName(_currentSubscription!.tier)} to ${_getTierName(_selectedTier)}.',
              ),
              const SizedBox(height: 16),
              if (isUpgrade) ...[
                const Text(
                  'You\'ll be charged the difference immediately and your subscription will be upgraded right away.',
                ),
              ] else ...[
                const Text(
                  'Your current plan will continue until the end of your billing cycle, then you\'ll be switched to the new plan.',
                ),
              ],
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Prorate billing for immediate change'),
                subtitle: const Text(
                  'If checked, your current billing cycle will be prorated and the new rate will apply immediately.',
                ),
                value: _prorateChanges,
                onChanged: (value) {
                  setState(() {
                    _prorateChanges = value ?? true;
                  });
                  Navigator.pop(context);
                  _changeTier(); // Reshow dialog with updated value
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isUpgrade ? 'Upgrade Now' : 'Downgrade'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Process the tier change using PaymentService
      await _paymentService.changeSubscriptionTier(
        newTier: core.SubscriptionTier.values[_selectedTier.index],
        subscriptionId: _currentSubscription!.id,
        customerId: _currentSubscription!.stripeCustomerId ?? '',
        prorated: _prorateChanges,
      );

      // Show success dialog
      if (mounted) {
        final isUpgrade =
            _selectedTier.index > _currentSubscription!.tier.index;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title:
                Text(isUpgrade ? 'Upgrade Successful' : 'Downgrade Successful'),
            content: Text(
              isUpgrade
                  ? 'Your subscription has been upgraded to ${_getTierName(_selectedTier)}.'
                  : _prorateChanges
                      ? 'Your subscription has been downgraded to ${_getTierName(_selectedTier)}.'
                      : 'Your subscription will be downgraded to ${_getTierName(_selectedTier)} at the end of the current billing period.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        _loadSubscription(); // Reload subscription data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing subscription tier: $e')),
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

  Future<void> _cancelSubscription() async {
    if (_currentSubscription == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel your subscription? You\'ll lose access to premium features at the end of your billing period.',
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                _showRefundOptions();
              },
              child: const Text('Request a Refund Instead'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Use the PaymentService to cancel in Stripe and update Firestore
      await _paymentService.cancelSubscription(_currentSubscription!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription cancelled successfully')),
        );
        _loadSubscription();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling subscription: $e')),
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

  // Show refund options dialog
  void _showRefundOptions() {
    if (_paymentHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No payment history found')),
      );
      return;
    }

    // Get the most recent payment
    final latestPayment = _paymentHistory.first;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request a Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You can request a refund for your most recent payment. Refunds are typically processed within 5-7 business days.',
            ),
            const SizedBox(height: 16),
            const Text('Most recent payment:'),
            const SizedBox(height: 8),
            ListTile(
              title: Text(
                  '\$${((latestPayment['amount'] as int) / 100).toStringAsFixed(2)}'),
              subtitle: Text(
                  'Date: ${_formatDate((latestPayment['createdAt'] as Timestamp).toDate())}'),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => RefundRequestScreen(
                        subscriptionId: _currentSubscription!.id,
                        paymentId: latestPayment['paymentIntentId'] as String,
                        amount: (latestPayment['amount'] as int) / 100,
                      ),
                    ),
                  );
                },
                child: const Text('Request Refund'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _getTierName(core.SubscriptionTier tier) {
    switch (tier) {
      case core.SubscriptionTier.artistPro:
        return 'Artist Pro Plan';
      case core.SubscriptionTier.gallery:
        return 'Gallery Plan';
      case core.SubscriptionTier.artistBasic:
        return 'Artist Basic Plan';
      case core.SubscriptionTier.free:
        return 'No Plan';
    }
  }

  // Helper to check if subscription is active
  bool _isSubscriptionActive(SubscriptionModel? sub) {
    if (sub == null) return false;
    return sub.status == 'active' || sub.status == 'trialing';
  }

  /// Navigate to artist profile creation for free basic plan users
  void _proceedToArtistProfileCreation() {
    Navigator.push(
      context,
      MaterialPageRoute<ArtistProfileEditScreen>(
        builder: (context) => const ArtistProfileEditScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: core.EnhancedUniversalHeader(
          title: 'Artist Subscriptions',
          showLogo: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.compare),
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => SubscriptionComparisonScreen(
                      currentTier: _currentSubscription?.tier,
                    ),
                  ),
                );
              },
              tooltip: 'Compare Plans',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current subscription info
                    if (_currentSubscription != null)
                      _buildCurrentSubscription(),

                    const SizedBox(height: 24),

                    // Subscription options
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Choose a Subscription Plan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) =>
                                    SubscriptionComparisonScreen(
                                  currentTier: _currentSubscription?.tier,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.compare_arrows),
                          label: const Text('Compare'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Basic plan
                    _buildPlanCard(
                      title: core.SubscriptionTier.artistBasic.displayName,
                      price: core.SubscriptionTier.artistBasic.priceString,
                      features: core.SubscriptionTier.artistBasic.features,
                      tier: core.SubscriptionTier.artistBasic,
                    ),

                    const SizedBox(height: 16),

                    // Pro plan
                    _buildPlanCard(
                      title: core.SubscriptionTier.artistPro.displayName,
                      price: core.SubscriptionTier.artistPro.priceString,
                      features: core.SubscriptionTier.artistPro.features,
                      tier: core.SubscriptionTier.artistPro,
                      isRecommended: true,
                    ),

                    const SizedBox(height: 16),

                    // Gallery plan
                    _buildPlanCard(
                      title: core.SubscriptionTier.gallery.displayName,
                      price: core.SubscriptionTier.gallery.priceString,
                      features: core.SubscriptionTier.gallery.features,
                      tier: core.SubscriptionTier.gallery,
                    ),

                    const SizedBox(height: 24),

                    // Auto-renewal option
                    if (_currentSubscription != null &&
                        _currentSubscription!.isActive)
                      SwitchListTile(
                        title: const Text('Auto-renew subscription'),
                        subtitle: const Text(
                          'Your subscription will automatically renew at the end of the billing period',
                        ),
                        value: _autoRenew,
                        onChanged: (value) {
                          setState(() {
                            _autoRenew = value;
                          });
                        },
                      ),

                    const SizedBox(height: 16),

                    // Subscribe button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _subscribe,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isProcessing
                            ? const CircularProgressIndicator()
                            : Text(
                                _getButtonText(),
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Disclaimer
                    Text(
                      'By subscribing, you agree to our Terms of Service and Privacy Policy. '
                      'You can cancel your subscription at any time.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _getButtonText() {
    if (_currentSubscription != null && _currentSubscription!.isActive) {
      if (_selectedTier != _currentSubscription!.tier) {
        if (_selectedTier == core.SubscriptionTier.artistBasic) {
          return 'Cancel Subscription';
        } else if (_selectedTier.index > _currentSubscription!.tier.index) {
          return 'Upgrade Plan';
        } else {
          return 'Downgrade Plan';
        }
      } else {
        return 'Confirm Selection';
      }
    } else {
      return 'Subscribe Now';
    }
  }

  /// Builds the current subscription information card
  Widget _buildCurrentSubscription() {
    if (_currentSubscription == null) return const SizedBox.shrink();

    // Format dates for display
    final startDate = _currentSubscription!.startDate;
    final endDate = _currentSubscription!.endDate != null
        ? _formatDate(_currentSubscription!.endDate!)
        : 'N/A';

    // Get renewal status
    final renewalStatus = _currentSubscription!.autoRenew
        ? 'Renews automatically on ${_formatDate(_currentSubscription!.endDate!)}'
        : 'Does not renew automatically';

    // Get account status
    final isActive = _isSubscriptionActive(_currentSubscription);
    final statusText = isActive ? 'Active' : 'Inactive';
    final statusColor = isActive ? Colors.green : Colors.red;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withAlpha((0.3 * 255).toInt()),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Subscription',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(statusText),
                  backgroundColor: statusColor.withAlpha((0.1 * 255).toInt()),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Plan details
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _getTierName(_currentSubscription!.tier),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Start date: $startDate'),
                  Text('Current period ends: $endDate'),
                  Text(renewalStatus),
                ],
              ),
              trailing: _currentSubscription!.tier !=
                      core.SubscriptionTier.artistBasic
                  ? TextButton(
                      onPressed: () => _showPaymentHistory(),
                      child: const Text('Payment History'),
                    )
                  : null,
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isSubscriptionActive(_currentSubscription) &&
                    _currentSubscription!.tier !=
                        core.SubscriptionTier.artistBasic)
                  TextButton(
                    onPressed: () => _cancelSubscription(),
                    child: const Text('Cancel Subscription'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Shows payment history in a dialog
  void _showPaymentHistory() {
    if (_paymentHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No payment history available')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),

              // Payment list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _paymentHistory.length,
                  itemBuilder: (context, index) {
                    final payment = _paymentHistory[index];
                    final amount = payment['amount'] != null
                        ? '\$${((payment['amount'] as int) / 100).toStringAsFixed(2)}'
                        : 'N/A';
                    final date = payment['createdAt'] != null
                        ? _formatDate(
                            (payment['createdAt'] as Timestamp).toDate())
                        : 'N/A';
                    final status = payment['status'] as String? ?? 'N/A';

                    return ListTile(
                      title: Text('Payment: $amount'),
                      subtitle: Text('Date: $date\nStatus: $status'),
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
              ),

              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a subscription plan card
  Widget _buildPlanCard({
    required String title,
    required String price,
    required List<String> features,
    required core.SubscriptionTier tier,
    bool isRecommended = false,
  }) {
    final bool isSelected = _selectedTier == tier;
    final bool isCurrentPlan = _currentSubscription != null &&
        _isSubscriptionActive(_currentSubscription) &&
        _currentSubscription!.tier == tier;

    // Disable Pro and Gallery tiers for now
    final bool isDisabled = _isTierDisabled(tier);

    return Tooltip(
      message: isDisabled ? 'Coming Soon' : '',
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: isDisabled
              ? null
              : () {
                  setState(() {
                    _selectedTier = tier;
                  });
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Opacity(
                  opacity: isDisabled ? 0.5 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRecommended && !isDisabled)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ),

                      if (isDisabled)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'COMING SOON',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),

                      if (isCurrentPlan)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CURRENT PLAN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  price,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Radio<core.SubscriptionTier>(
                            value: tier,
                            groupValue: _selectedTier,
                            onChanged: isDisabled
                                ? null
                                : (core.SubscriptionTier? value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedTier = value;
                                      });
                                    }
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Feature list
                      ...features.map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(feature),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
