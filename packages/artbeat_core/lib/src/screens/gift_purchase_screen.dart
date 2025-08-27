import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Screen for purchasing gifts for other users
class GiftPurchaseScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const GiftPurchaseScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  State<GiftPurchaseScreen> createState() => _GiftPurchaseScreenState();
}

class _GiftPurchaseScreenState extends State<GiftPurchaseScreen> {
  final PaymentService _paymentService = PaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedGiftType;
  double _selectedAmount = 0.0;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Gift to ${widget.recipientName}'),
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
                  _buildRecipientInfo(),
                  const SizedBox(height: 24),
                  _buildGiftSelection(),
                  const SizedBox(height: 24),
                  _buildMessageSection(),
                  const SizedBox(height: 24),
                  _buildPricingSummary(),
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
                      onPressed: _selectedGiftType != null
                          ? _handlePurchase
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: Text(
                        _selectedGiftType != null
                            ? 'Send Gift - \$${_selectedAmount.toStringAsFixed(2)}'
                            : 'Select a Gift',
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
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
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

  Widget _buildGiftSelection() {
    final giftTypes = _paymentService.getGiftTypes();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a Gift',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...giftTypes.entries.map(
              (entry) => _buildGiftOption(
                entry.key,
                entry.value,
                _getGiftDescription(entry.key),
                _getGiftIcon(entry.key),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftOption(
    String giftType,
    double price,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedGiftType == giftType;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedGiftType = giftType;
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
                  icon,
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
                      description,
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

  Widget _buildPricingSummary() {
    if (_selectedGiftType == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedGiftType!, style: const TextStyle(fontSize: 16)),
                Text(
                  '\$${_selectedAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${_selectedAmount.toStringAsFixed(2)}',
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

  Future<void> _handlePurchase() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'User not authenticated. Please log in.';
      });
      return;
    }

    if (_selectedGiftType == null) {
      setState(() {
        _errorMessage = 'Please select a gift type.';
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

      // Process the gift payment
      final result = await _paymentService.processEnhancedGiftPayment(
        recipientId: widget.recipientId,
        paymentMethodId: paymentMethodId,
        giftType: _selectedGiftType!,
        amount: _selectedAmount,
        message: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
      );

      if (result['status'] == 'succeeded') {
        if (mounted) {
          // Show success dialog
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Gift Sent Successfully!'),
              content: Text(
                'Your ${_selectedGiftType!} gift has been sent to ${widget.recipientName}. They will receive a notification about your thoughtful gift!',
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
