import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/enhanced_gift_service.dart';
import '../services/payment_service.dart';
import '../models/gift_campaign_model.dart';
import '../models/gift_subscription_model.dart';

/// Enhanced screen for purchasing gifts with custom amounts, campaigns, and subscriptions
class EnhancedGiftPurchaseScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final GiftCampaignModel? campaign; // Optional campaign context

  const EnhancedGiftPurchaseScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.campaign,
  });

  @override
  State<EnhancedGiftPurchaseScreen> createState() =>
      _EnhancedGiftPurchaseScreenState();
}

class _EnhancedGiftPurchaseScreenState extends State<EnhancedGiftPurchaseScreen>
    with SingleTickerProviderStateMixin {
  final EnhancedGiftService _giftService = EnhancedGiftService();
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _customAmountController = TextEditingController();

  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;

  // Gift Type Selection
  String _giftMode = 'preset'; // preset, custom, subscription
  String? _selectedPresetGift;
  double _selectedAmount = 0.0;

  // Subscription Settings
  SubscriptionFrequency _subscriptionFrequency = SubscriptionFrequency.monthly;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // If opened from a campaign, default to custom mode
    if (widget.campaign != null) {
      _giftMode = 'custom';
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Send Gift to ${widget.recipientName}'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            onTap: (index) {
              setState(() {
                switch (index) {
                  case 0:
                    _giftMode = 'preset';
                    break;
                  case 1:
                    _giftMode = 'custom';
                    break;
                  case 2:
                    _giftMode = 'subscription';
                    break;
                }
                _selectedAmount = 0.0;
                _selectedPresetGift = null;
                _customAmountController.clear();
              });
            },
            tabs: const [
              Tab(text: 'Preset Gifts'),
              Tab(text: 'Custom Amount'),
              Tab(text: 'Subscription'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPresetGiftsTab(),
                          _buildCustomAmountTab(),
                          _buildSubscriptionTab(),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        child: _buildBottomSection(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPresetGiftsTab() {
    final presetGifts = _giftService.getPresetGiftTypes();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecipientInfo(),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose a Preset Gift',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...presetGifts.entries.map(
                    (entry) => _buildPresetGiftOption(entry.key, entry.value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildMessageSection(),
        ],
      ),
    );
  }

  Widget _buildCustomAmountTab() {
    final suggestions = _giftService.getCustomGiftSuggestions();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecipientInfo(),
          const SizedBox(height: 24),

          // Campaign info if applicable
          if (widget.campaign != null) _buildCampaignInfo(),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Custom Gift Amount',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Custom amount input
                  TextField(
                    controller: _customAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Enter Amount (\$1.00 - \$1,000.00)',
                      prefixText: '\$',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedAmount = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Quick amount suggestions
                  const Text(
                    'Quick Amounts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestions
                        .map((amount) => _buildQuickAmountChip(amount))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildMessageSection(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecipientInfo(),
          const SizedBox(height: 24),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recurring Gift Subscription',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Support this artist with regular gifts. Different from sponsorships, these are simple recurring donations.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Amount input
                  TextField(
                    controller: _customAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Amount per payment',
                      prefixText: '\$',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedAmount = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Frequency selection
                  const Text(
                    'Payment Frequency',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<SubscriptionFrequency>(
                    segments: SubscriptionFrequency.values
                        .map(
                          (frequency) => ButtonSegment<SubscriptionFrequency>(
                            value: frequency,
                            label: Text(
                              frequency.name.toUpperCase(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                    selected: {_subscriptionFrequency},
                    onSelectionChanged: (selected) {
                      setState(() {
                        _subscriptionFrequency = selected.first;
                      });
                    },
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      minimumSize: WidgetStateProperty.all(const Size(0, 36)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildMessageSection(),
        ],
      ),
    );
  }

  Widget _buildRecipientInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sending Gift To',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    widget.recipientName.isNotEmpty
                        ? widget.recipientName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recipientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Artist',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignInfo() {
    final campaign = widget.campaign!;

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
                Icon(Icons.campaign, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Supporting Campaign',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              campaign.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              campaign.description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Progress bar
            LinearProgressIndicator(
              value: campaign.progressPercentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${campaign.currentAmount.toStringAsFixed(2)} raised',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Goal: \$${campaign.goalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetGiftOption(String giftType, double price) {
    final isSelected = _selectedPresetGift == giftType;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPresetGift = giftType;
            _selectedAmount = price;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getGiftIcon(giftType),
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
                      giftType,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.black,
                      ),
                    ),
                    Text(
                      _getGiftDescription(giftType),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black,
                ),
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(double amount) {
    return ActionChip(
      label: Text(
        '\$${amount.toStringAsFixed(amount == amount.toInt() ? 0 : 2)}',
      ),
      onPressed: () {
        setState(() {
          _selectedAmount = amount;
          _customAmountController.text = amount.toStringAsFixed(2);
        });
      },
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: Theme.of(context).primaryColor),
    );
  }

  Widget _buildMessageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Message (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText:
                    'Write a personal message to ${widget.recipientName}...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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

          // Order summary
          if (_selectedAmount > 0) _buildOrderSummary(),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedAmount > 0 ? _handlePurchase : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: Text(
                _getButtonText(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_getGiftTypeDisplay()),
                Text(
                  '\$${_selectedAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (_giftMode == 'subscription')
              Text(
                _subscriptionFrequency.name.toUpperCase(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  String _getButtonText() {
    if (_selectedAmount <= 0) return 'Select Amount';

    switch (_giftMode) {
      case 'subscription':
        return 'Start Subscription - \$${_selectedAmount.toStringAsFixed(2)}/${_subscriptionFrequency.name}';
      default:
        return 'Send Gift - \$${_selectedAmount.toStringAsFixed(2)}';
    }
  }

  String _getGiftTypeDisplay() {
    switch (_giftMode) {
      case 'preset':
        return _selectedPresetGift ?? 'Preset Gift';
      case 'custom':
        return 'Custom Gift';
      case 'subscription':
        return 'Gift Subscription';
      default:
        return 'Gift';
    }
  }

  Future<void> _handlePurchase() async {
    if (_selectedAmount <= 0) {
      setState(() {
        _errorMessage = 'Please select or enter a valid amount.';
      });
      return;
    }

    // Validate custom amounts
    if (_giftMode == 'custom' &&
        (_selectedAmount < 1.0 || _selectedAmount > 1000.0)) {
      setState(() {
        _errorMessage =
            'Custom gift amount must be between \$1.00 and \$1,000.00';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user's default payment method
      final paymentMethodId = await _paymentService.getDefaultPaymentMethodId();

      if (paymentMethodId == null) {
        setState(() {
          _errorMessage =
              'No payment method found. Please add a payment method first.';
        });
        return;
      }

      final message = _messageController.text.trim().isNotEmpty
          ? _messageController.text.trim()
          : null;

      Map<String, dynamic> result;

      switch (_giftMode) {
        case 'preset':
          // Use existing enhanced gift payment
          result = await _paymentService.processEnhancedGiftPayment(
            recipientId: widget.recipientId,
            paymentMethodId: paymentMethodId,
            giftType: _selectedPresetGift!,
            amount: _selectedAmount,
            message: message,
          );
          break;

        case 'custom':
          // Use custom gift payment
          result = await _giftService.sendCustomGift(
            recipientId: widget.recipientId,
            amount: _selectedAmount,
            paymentMethodId: paymentMethodId,
            message: message,
            campaignId: widget.campaign?.id,
          );
          break;

        case 'subscription':
          // Create gift subscription
          await _giftService.createGiftSubscription(
            recipientId: widget.recipientId,
            amount: _selectedAmount,
            frequency: _subscriptionFrequency,
            message: message,
            paymentMethodId: paymentMethodId,
          );
          result = {'status': 'succeeded'};
          break;

        default:
          throw Exception('Invalid gift mode');
      }

      if (result['status'] == 'succeeded') {
        if (mounted) {
          // Show success dialog
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(_getSuccessTitle()),
              content: Text(_getSuccessMessage()),
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
        throw Exception('Payment failed with status: ${result['status']}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gift purchase failed: ${e.toString()}';
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

  String _getSuccessTitle() {
    switch (_giftMode) {
      case 'subscription':
        return 'Gift Subscription Created!';
      default:
        return 'Gift Sent Successfully!';
    }
  }

  String _getSuccessMessage() {
    switch (_giftMode) {
      case 'subscription':
        return 'Your ${_subscriptionFrequency.name} gift subscription of \$${_selectedAmount.toStringAsFixed(2)} has been set up for ${widget.recipientName}. They will receive regular gifts and notifications!';
      case 'custom':
        if (widget.campaign != null) {
          return 'Your custom gift of \$${_selectedAmount.toStringAsFixed(2)} has been sent to ${widget.recipientName} and contributed to their campaign "${widget.campaign!.title}". They will receive a notification about your generous support!';
        }
        return 'Your custom gift of \$${_selectedAmount.toStringAsFixed(2)} has been sent to ${widget.recipientName}. They will receive a notification about your thoughtful gift!';
      default:
        return 'Your ${_selectedPresetGift} gift has been sent to ${widget.recipientName}. They will receive a notification about your thoughtful gift!';
    }
  }

  String _getGiftDescription(String giftType) {
    switch (giftType) {
      case 'Mini Palette':
        return 'A small token of appreciation';
      case 'Brush Pack':
        return 'Essential tools for creativity';
      case 'Canvas Set':
        return 'Perfect for new artworks';
      case 'Art Supplies':
        return 'Complete set of art materials';
      case 'Studio Time':
        return 'Support for dedicated art time';
      case 'Premium Support':
        return 'Comprehensive artist support';
      default:
        return 'A thoughtful gift for artists';
    }
  }

  IconData _getGiftIcon(String giftType) {
    switch (giftType) {
      case 'Mini Palette':
        return Icons.palette;
      case 'Brush Pack':
        return Icons.brush;
      case 'Canvas Set':
        return Icons.crop_original;
      case 'Art Supplies':
        return Icons.art_track;
      case 'Studio Time':
        return Icons.access_time;
      case 'Premium Support':
        return Icons.star;
      default:
        return Icons.card_giftcard;
    }
  }
}
