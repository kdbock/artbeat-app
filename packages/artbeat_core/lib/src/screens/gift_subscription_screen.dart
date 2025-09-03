import 'package:flutter/material.dart';
import '../services/enhanced_gift_service.dart';
import '../models/gift_subscription_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Screen for managing gift subscriptions
class GiftSubscriptionScreen extends StatefulWidget {
  const GiftSubscriptionScreen({super.key});

  @override
  State<GiftSubscriptionScreen> createState() => _GiftSubscriptionScreenState();
}

class _GiftSubscriptionScreenState extends State<GiftSubscriptionScreen>
    with SingleTickerProviderStateMixin {
  final EnhancedGiftService _giftService = EnhancedGiftService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Subscriptions'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sending'),
            Tab(text: 'Receiving'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSendingTab(), _buildReceivingTab()],
      ),
    );
  }

  Widget _buildSendingTab() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Please log in to view your subscriptions'),
      );
    }

    return StreamBuilder<List<GiftSubscriptionModel>>(
      stream: _giftService.getUserGiftSubscriptions(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading subscriptions: ${snapshot.error}'),
          );
        }

        final subscriptions = snapshot.data ?? [];

        if (subscriptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.card_giftcard_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No gift subscriptions',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start supporting artists with recurring gifts',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subscriptions.length,
          itemBuilder: (context, index) {
            final subscription = subscriptions[index];
            return _buildSubscriptionCard(subscription, isSender: true);
          },
        );
      },
    );
  }

  Widget _buildReceivingTab() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Please log in to view your subscriptions'),
      );
    }

    return StreamBuilder<List<GiftSubscriptionModel>>(
      stream: _giftService.getReceivedGiftSubscriptions(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading subscriptions: ${snapshot.error}'),
          );
        }

        final subscriptions = snapshot.data ?? [];

        if (subscriptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No gift subscriptions received',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'When supporters set up recurring gifts, they\'ll appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subscriptions.length,
          itemBuilder: (context, index) {
            final subscription = subscriptions[index];
            return _buildSubscriptionCard(subscription, isSender: false);
          },
        );
      },
    );
  }

  Widget _buildSubscriptionCard(
    GiftSubscriptionModel subscription, {
    required bool isSender,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSender ? 'Gift to Artist' : 'Gift from Supporter',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatusChip(subscription.status),
                          const SizedBox(width: 8),
                          Text(
                            subscription.frequencyDisplayName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSender) _buildSubscriptionMenu(subscription),
              ],
            ),

            const SizedBox(height: 16),

            // Amount and frequency
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${subscription.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'per ${subscription.frequency.name}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${subscription.averageMonthlyAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'per month',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Statistics
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${subscription.totalPayments}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Payments',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${subscription.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Total Sent',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (subscription.nextPaymentDateTime != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDate(subscription.nextPaymentDateTime!),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            'Next Payment',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Message
            if (subscription.message != null &&
                subscription.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.message,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subscription.message!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Actions
            if (isSender) _buildSenderActions(subscription),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(SubscriptionStatus status) {
    MaterialColor color;
    String label;

    switch (status) {
      case SubscriptionStatus.active:
        color = Colors.green;
        label = 'Active';
        break;
      case SubscriptionStatus.paused:
        color = Colors.orange;
        label = 'Paused';
        break;
      case SubscriptionStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
      case SubscriptionStatus.expired:
        color = Colors.grey;
        label = 'Expired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color.shade700,
        ),
      ),
    );
  }

  Widget _buildSubscriptionMenu(GiftSubscriptionModel subscription) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'pause':
            _pauseSubscription(subscription.id);
            break;
          case 'resume':
            _resumeSubscription(subscription.id);
            break;
          case 'cancel':
            _cancelSubscription(subscription.id);
            break;
        }
      },
      itemBuilder: (context) => [
        if (subscription.isActive)
          const PopupMenuItem(
            value: 'pause',
            child: ListTile(
              leading: Icon(Icons.pause),
              title: Text('Pause'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (subscription.isPaused)
          const PopupMenuItem(
            value: 'resume',
            child: ListTile(
              leading: Icon(Icons.play_arrow),
              title: Text('Resume'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (subscription.isActive || subscription.isPaused)
          const PopupMenuItem(
            value: 'cancel',
            child: ListTile(
              leading: Icon(Icons.cancel),
              title: Text('Cancel'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  Widget _buildSenderActions(GiftSubscriptionModel subscription) {
    return Row(
      children: [
        if (subscription.isActive)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pauseSubscription(subscription.id),
              icon: const Icon(Icons.pause, size: 16),
              label: const Text('Pause'),
            ),
          ),
        if (subscription.isPaused) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _resumeSubscription(subscription.id),
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Resume'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _cancelSubscription(subscription.id),
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
        if (subscription.isActive) ...[
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _cancelSubscription(subscription.id),
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return '${difference}d';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  void _pauseSubscription(String subscriptionId) async {
    try {
      await _giftService.pauseGiftSubscription(subscriptionId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Subscription paused')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error pausing subscription: $e')),
        );
      }
    }
  }

  void _resumeSubscription(String subscriptionId) async {
    try {
      await _giftService.resumeGiftSubscription(subscriptionId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Subscription resumed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resuming subscription: $e')),
        );
      }
    }
  }

  void _cancelSubscription(String subscriptionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel this gift subscription? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _giftService.cancelGiftSubscription(subscriptionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription cancelled')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling subscription: $e')),
          );
        }
      }
    }
  }
}
