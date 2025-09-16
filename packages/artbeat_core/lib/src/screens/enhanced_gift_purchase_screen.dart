import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/enhanced_gift_service.dart';
import '../models/gift_campaign_model.dart';
import '../models/gift_subscription_model.dart';
import '../models/artist_profile_model.dart';
import '../utils/order_review_helpers.dart';
import '../utils/logger.dart';
import '../widgets/main_layout.dart';
import '../theme/artbeat_colors.dart';

/// Enhanced screen for purchasing gifts with custom amounts, campaigns, and subscriptions
/// Modern themed design with glassmorphism and gradient backgrounds
class EnhancedGiftPurchaseScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final GiftCampaignModel? campaign; // Optional campaign context
  final int initialTab; // 0: preset, 1: custom, 2: subscription

  const EnhancedGiftPurchaseScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.campaign,
    this.initialTab = 0, // Default to preset tab
  });

  @override
  State<EnhancedGiftPurchaseScreen> createState() =>
      _EnhancedGiftPurchaseScreenState();
}

class _EnhancedGiftPurchaseScreenState extends State<EnhancedGiftPurchaseScreen>
    with TickerProviderStateMixin {
  final EnhancedGiftService _giftService = EnhancedGiftService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _customAmountController = TextEditingController();

  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;

  // Artist Profile
  ArtistProfileModel? _recipientProfile;

  // Gift Type Selection
  String _giftMode = 'preset'; // preset, custom, subscription
  String? _selectedPresetGift;
  double _selectedAmount = 0.0;

  // Subscription Settings
  SubscriptionFrequency _subscriptionFrequency = SubscriptionFrequency.monthly;

  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );

    // Initialize fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();

    debugPrint(
      '🎁 EnhancedGiftPurchaseScreen initialized with recipient: ${widget.recipientName}',
    );
    debugPrint('🎁 Initial tab index: ${widget.initialTab}');
    debugPrint(
      '🎁 Initial selected amount: \$${_selectedAmount.toStringAsFixed(2)}',
    );

    // Set initial mode based on tab
    switch (widget.initialTab) {
      case 0:
        _giftMode = 'preset';
        // Set a default amount for preset mode to prevent $0.00 payments
        _selectedAmount = 5.0; // Default to "Brush Pack" amount
        _selectedPresetGift = 'Brush Pack';
        debugPrint(
          '🎁 Set default amount: \$${_selectedAmount.toStringAsFixed(2)}',
        );
        break;
      case 1:
        _giftMode = 'custom';
        break;
      case 2:
        _giftMode = 'subscription';
        break;
    }

    // If opened from a campaign, override to custom mode
    if (widget.campaign != null) {
      _giftMode = 'custom';
      _tabController.index = 1;
    }

    // Load recipient profile
    _loadRecipientProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _customAmountController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipientProfile() async {
    try {
      debugPrint(
        '🎁 Loading recipient profile for user: ${widget.recipientId}',
      );
      final snapshot = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .where('userId', isEqualTo: widget.recipientId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _recipientProfile = ArtistProfileModel.fromFirestore(
          snapshot.docs.first,
        );
        debugPrint(
          '🎁 Loaded recipient profile: ${_recipientProfile!.displayName}',
        );
        if (mounted) setState(() {});
      } else {
        debugPrint(
          '🎁 No artist profile found for recipient: ${widget.recipientId}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading recipient profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // Not in main navigation
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.topRight,
                colors: [
                  ArtbeatColors.secondaryTeal, // Light Teal
                  ArtbeatColors.accentOrange, // Light Orange/Peach
                ],
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Send Gift to ${widget.recipientName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                // TODO: Implement search functionality
              },
            ),
            IconButton(
              icon: const Icon(Icons.message, color: Colors.white),
              onPressed: () {
                // TODO: Implement messaging functionality
              },
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () {
                // TODO: Implement profile functionality
              },
            ),
          ],
        ),
        body: Container(
          decoration: _buildBackgroundDecoration(),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SafeArea(
                    child: Column(
                      children: [
                        _buildModernTabBar(),
                        Expanded(child: _buildUnifiedScrollableContent()),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildUnifiedScrollableContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPresetGiftsContent(),
        _buildCustomAmountContent(),
        _buildSubscriptionContent(),
      ],
    );
  }

  Widget _buildPresetGiftsContent() {
    final presetGifts = _giftService.getPresetGiftTypes();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecipientInfo(),
          const SizedBox(height: 24),
          Container(
            decoration: _buildGlassDecoration(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a Preset Gift',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...presetGifts.entries.map(
                    (entry) => _buildPresetGiftOption(entry.key, entry.value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildMessageSection(),
          const SizedBox(height: 24),
          _buildOrderSummarySection(),
          const SizedBox(height: 24),
          _buildPurchaseButtonSection(),
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildCustomAmountContent() {
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

          Container(
            decoration: _buildGlassDecoration(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom Gift Amount',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 20),

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
          const SizedBox(height: 24),
          _buildOrderSummarySection(),
          const SizedBox(height: 24),
          _buildPurchaseButtonSection(),
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildSubscriptionContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecipientInfo(),
          const SizedBox(height: 24),

          Container(
            decoration: _buildGlassDecoration(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recurring Gift Subscription',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Support this artist with regular gifts. Different from sponsorships, these are simple recurring donations.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),

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
          const SizedBox(height: 24),
          _buildOrderSummarySection(),
          const SizedBox(height: 24),
          _buildPurchaseButtonSection(),
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildOrderSummarySection() {
    // Show order summary if a gift is selected, even if amount is $0.00 (coupon case)
    bool hasValidSelection = false;
    switch (_giftMode) {
      case 'preset':
        hasValidSelection =
            _selectedPresetGift != null && _selectedPresetGift!.isNotEmpty;
        break;
      case 'custom':
        hasValidSelection = _customAmountController.text.isNotEmpty;
        break;
      case 'subscription':
        hasValidSelection = _customAmountController.text.isNotEmpty;
        break;
    }

    if (!hasValidSelection) return const SizedBox.shrink();

    return Container(
      decoration: _buildGlassDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getGiftTypeDisplay(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _selectedAmount == 0.0
                          ? 'FREE'
                          : '\$${_selectedAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _selectedAmount == 0.0
                            ? Colors.greenAccent
                            : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    if (_selectedAmount == 0.0)
                      Text(
                        '(100% coupon)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.greenAccent.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (_giftMode == 'subscription')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _subscriptionFrequency.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButtonSection() {
    return Column(
      children: [
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.only(bottom: 20.0),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.withValues(alpha: 0.8),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

        AnimatedScale(
          scale: _selectedAmount > 0 ? 1.0 : 0.95,
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedAmount > 0 ? _handlePurchase : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: _selectedAmount > 0
                    ? ArtbeatColors.surface
                    : ArtbeatColors.buttonDisabled,
                foregroundColor: ArtbeatColors.secondaryTeal,
                disabledBackgroundColor: ArtbeatColors.buttonDisabled,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _getButtonText(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _selectedAmount > 0
                      ? ArtbeatColors.secondaryTeal
                      : ArtbeatColors.textDisabled,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.7),
          ),
          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ArtbeatColors.secondaryTeal, // Light Teal
          ArtbeatColors.secondaryTeal.withValues(alpha: 0.8), // Darker Teal
          ArtbeatColors.accentOrange, // Light Orange/Peach
          ArtbeatColors.accentOrange.withValues(alpha: 0.8), // Darker Orange
        ],
        stops: const [0.0, 0.4, 0.6, 1.0],
      ),
    );
  }

  BoxDecoration _buildGlassDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      boxShadow: [
        BoxShadow(
          color: ArtbeatColors.secondaryTeal.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: _buildGlassDecoration(),
      child: TabBar(
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
        indicator: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(15),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
        tabs: const [
          Tab(
            child: Text(
              'Preset Gifts',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Tab(
            child: Text(
              'Custom Amount',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Tab(
            child: Text(
              'Subscription',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientInfo() {
    return Container(
      decoration: _buildGlassDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sending Gift To',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: _recipientProfile?.profileImageUrl != null
                      ? NetworkImage(_recipientProfile!.profileImageUrl!)
                      : null,
                  child: _recipientProfile?.profileImageUrl == null
                      ? Text(
                          widget.recipientName.isNotEmpty
                              ? widget.recipientName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _recipientProfile?.displayName ?? widget.recipientName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        'Artist',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
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
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPresetGift = giftType;
            _selectedAmount = price;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4FB3BE).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getGiftIcon(giftType),
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      giftType,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getGiftDescription(giftType),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                    ),
                ],
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
    return Container(
      decoration: _buildGlassDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Message (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 3,
              maxLength: 200,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText:
                    'Write a personal message to ${widget.recipientName}...',
                hintStyle: const TextStyle(color: Colors.black45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                counterStyle: const TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getButtonText() {
    if (_selectedAmount < 0) return 'Select Amount';
    if (_selectedAmount == 0.0) return 'Send Free Gift';

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
    debugPrint(
      '🎁 _handlePurchase called with amount: \$${_selectedAmount.toStringAsFixed(2)}',
    );
    AppLogger.info('🎁 Gift mode: $_giftMode');
    AppLogger.info('🎁 Selected preset gift: $_selectedPresetGift');

    // Check if a valid gift selection has been made
    bool hasValidSelection = false;
    switch (_giftMode) {
      case 'preset':
        hasValidSelection =
            _selectedPresetGift != null && _selectedPresetGift!.isNotEmpty;
        break;
      case 'custom':
        hasValidSelection = _customAmountController.text.isNotEmpty;
        break;
      case 'subscription':
        hasValidSelection = _customAmountController.text.isNotEmpty;
        break;
    }

    if (!hasValidSelection) {
      AppLogger.error('❌ No gift selection made');
      setState(() {
        _errorMessage = 'Please select a gift type or enter an amount.';
      });
      return;
    }

    // Allow $0.00 amounts for 100% coupon scenarios, but validate reasonable bounds for non-coupon cases
    if (_selectedAmount < 0) {
      AppLogger.error(
        '❌ Invalid amount: \$${_selectedAmount.toStringAsFixed(2)}',
      );
      setState(() {
        _errorMessage = 'Amount cannot be negative.';
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
      final message = _messageController.text.trim().isNotEmpty
          ? _messageController.text.trim()
          : null;

      // Use order review system with coupon support
      debugPrint(
        '🎁 Calling reviewGiftOrder with amount: \$${_selectedAmount.toStringAsFixed(2)}',
      );
      final result = await context.reviewGiftOrder(
        recipientId: widget.recipientId,
        recipientName: widget.recipientName,
        amount: _selectedAmount,
        giftType: _giftMode == 'preset' ? _selectedPresetGift! : 'Custom Gift',
        message: message,
      );

      if (result != null && result['status'] == 'success') {
        // Payment successful
        if (mounted) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => AlertDialog(
              title: Text(_getSuccessTitle()),
              content: Text(_getSuccessMessage()),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pop(context, true);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else if (result != null) {
        // Payment failed
        throw Exception(result['message'] ?? 'Payment failed');
      } else {
        // User cancelled - just reset loading state and return
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
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
