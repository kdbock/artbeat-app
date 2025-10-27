import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart'
    hide
        PaymentResult; // Use the main package export but hide PaymentResult to avoid conflict
import 'package:artbeat_core/src/services/enhanced_payment_service_working.dart'
    show
        EnhancedPaymentService,
        PaymentResult; // Import both EnhancedPaymentService and PaymentResult

class GiftModal extends StatefulWidget {
  final String recipientId;

  const GiftModal({super.key, required this.recipientId});

  @override
  State<GiftModal> createState() => _GiftModalState();
}

class _GiftModalState extends State<GiftModal> {
  final UserService _userService = UserService();
  final EnhancedPaymentService _paymentService = EnhancedPaymentService();
  final List<Map<String, dynamic>> _giftOptions = [
    {'type': 'Mini Palette', 'amount': 1.0},
    {'type': 'Brush Pack', 'amount': 5.0},
    {'type': 'Gallery Frame', 'amount': 20.0},
    {'type': 'Golden Canvas', 'amount': 50.0},
  ];

  String? _recipientName;

  @override
  void initState() {
    super.initState();
    _loadRecipientName();
  }

  Future<void> _loadRecipientName() async {
    try {
      final user = await _userService.getUserById(widget.recipientId);
      if (mounted) {
        setState(() {
          _recipientName = user?.fullName ?? user?.username ?? 'Unknown User';
        });
      }
    } catch (e) {
      AppLogger.error('Error loading recipient name: $e');
      if (mounted) {
        setState(() {
          _recipientName = 'Unknown User';
        });
      }
    }
  }

  Future<void> _sendGift(String giftType, double amount) async {
    try {
      final senderId = _userService.currentUserId;
      if (senderId == null) {
        throw Exception('User not authenticated');
      }

      // Close the current modal first
      Navigator.pop(context);

      // Use enhanced payment service for gift processing
      final paymentResult = await _processGiftPayment(
        recipientId: widget.recipientId,
        recipientName: _recipientName ?? 'Unknown User',
        amount: amount,
        giftType: giftType,
      );

      if (paymentResult.success && mounted) {
        // Payment was successful
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gift sent successfully! 🎁'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        // Payment failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send gift'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Failed to send gift: $e';

      // Provide more user-friendly error messages
      if (e.toString().contains('User not authenticated')) {
        errorMessage = 'Please log in to send gifts.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Process gift payment using enhanced payment service
  Future<PaymentResult> _processGiftPayment({
    required String recipientId,
    required String recipientName,
    required double amount,
    required String giftType,
  }) async {
    try {
      // Create payment intent for gift
      final paymentIntentData = await _createGiftPaymentIntent(
        recipientId: recipientId,
        recipientName: recipientName,
        amount: amount,
        giftType: giftType,
      );

      final clientSecret = paymentIntentData['clientSecret'] as String;

      // Process payment with enhanced service
      final result = await _paymentService.processPaymentWithRiskAssessment(
        paymentIntentClientSecret: clientSecret,
        amount: amount,
        currency: 'USD',
        metadata: {
          'gift_type': giftType,
          'recipient_id': recipientId,
          'recipient_name': recipientName,
        },
      );

      if (result.success) {
        // Log successful gift transaction
        await _logGiftTransaction(
          recipientId: recipientId,
          recipientName: recipientName,
          amount: amount,
          giftType: giftType,
          paymentIntentId: result.paymentIntentId,
        );
      }

      return result;
    } catch (e) {
      AppLogger.error('Error processing gift payment: $e');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  /// Create payment intent for gift using enhanced service
  Future<Map<String, dynamic>> _createGiftPaymentIntent({
    required String recipientId,
    required String recipientName,
    required double amount,
    required String giftType,
  }) async {
    final body = {
      'amount': (amount * 100).toInt(), // Convert to cents
      'currency': 'usd',
      'recipientId': recipientId,
      'recipientName': recipientName,
      'giftType': giftType,
      'type': 'gift',
      'platform': 'ARTbeat',
      'deviceFingerprint': await _paymentService.getDeviceFingerprint(),
      'metadata': {
        'gift_type': giftType,
        'recipient_id': recipientId,
        'platform': 'ARTbeat',
      },
    };

    // Use the enhanced payment service's authenticated request method
    final response = await _paymentService.makeAuthenticatedRequest(
      functionKey: 'processGiftPayment',
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create gift payment intent: ${response.body}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Log successful gift transaction
  Future<void> _logGiftTransaction({
    required String recipientId,
    required String recipientName,
    required double amount,
    required String giftType,
    String? paymentIntentId,
  }) async {
    try {
      final senderId = _userService.currentUserId;
      if (senderId == null) return;

      await FirebaseFirestore.instance.collection('gift_transactions').add({
        'senderId': senderId,
        'recipientId': recipientId,
        'recipientName': recipientName,
        'amount': amount,
        'currency': 'USD',
        'giftType': giftType,
        'paymentIntentId': paymentIntentId,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'ARTbeat',
        'status': 'completed',
      });

      AppLogger.info('✅ Gift transaction logged: $giftType to $recipientName');
    } catch (e) {
      AppLogger.error('❌ Error logging gift transaction: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _recipientName != null
                        ? 'Send Gift to $_recipientName'
                        : 'Send a Gift',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose a gift amount. You can apply coupon codes in the next step!',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ..._giftOptions.map((gift) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.redeem, color: Colors.green),
                  title: Text(
                    gift['type'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '\$${(gift['amount'] as num).toStringAsFixed(2)}',
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: _recipientName != null
                        ? () => _sendGift(
                            gift['type'] as String,
                            (gift['amount'] as num).toDouble(),
                          )
                        : null,
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Send'),
                  ),
                ),
              );
            }),
            if (_recipientName == null) ...[
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Loading...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
