import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_core/src/services/in_app_gift_service.dart';

class GiftModal extends StatefulWidget {
  final String recipientId;

  const GiftModal({super.key, required this.recipientId});

  @override
  State<GiftModal> createState() => _GiftModalState();
}

class _GiftModalState extends State<GiftModal> {
  final UserService _userService = UserService();
  final InAppGiftService _giftService = InAppGiftService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final List<Map<String, dynamic>> _giftOptions = [
    {
      'productId': 'artbeat_gift_small',
      'type': 'Small Gift (50 Credits)',
      'amount': 4.99,
      'credits': 50,
    },
    {
      'productId': 'artbeat_gift_medium',
      'type': 'Medium Gift (100 Credits)',
      'amount': 9.99,
      'credits': 100,
    },
    {
      'productId': 'artbeat_gift_large',
      'type': 'Large Gift (250 Credits)',
      'amount': 24.99,
      'credits': 250,
    },
    {
      'productId': 'artbeat_gift_premium',
      'type': 'Premium Gift (500 Credits)',
      'amount': 49.99,
      'credits': 500,
    },
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

  Future<void> _sendGift(String giftProductId, String giftType) async {
    try {
      final senderId = _auth.currentUser?.uid;
      if (senderId == null) {
        throw Exception('User not authenticated');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Initiating gift purchase...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Use in-app purchase service for gift (Apple compliant)
      final success = await _giftService.purchaseGift(
        recipientId: widget.recipientId,
        giftProductId: giftProductId,
        message: 'A gift from an ArtBeat user',
      );

      // Close the modal
      if (mounted) {
        Navigator.pop(context);
      }

      if (success && mounted) {
        // IAP was initiated successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gift purchase initiated! 🎁 Complete payment to send.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        // Gift purchase failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to initiate gift purchase. Please try again.',
            ),
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
      } else if (e.toString().contains('Recipient not found')) {
        errorMessage = 'The recipient is no longer available.';
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
                            gift['productId'] as String,
                            gift['type'] as String,
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
