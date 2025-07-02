import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart'; // Use the main package export for all core classes

class GiftModal extends StatefulWidget {
  final String recipientId;

  const GiftModal({super.key, required this.recipientId});

  @override
  State<GiftModal> createState() => _GiftModalState();
}

class _GiftModalState extends State<GiftModal> {
  final PaymentService _paymentService = PaymentService();
  final UserService _userService = UserService();
  final List<Map<String, dynamic>> _giftOptions = [
    {'type': 'Mini Palette', 'amount': 1.0},
    {'type': 'Brush Pack', 'amount': 5.0},
    {'type': 'Gallery Frame', 'amount': 20.0},
    {'type': 'Golden Canvas', 'amount': 50.0},
  ];

  Future<void> _sendGift(String giftType, double amount) async {
    try {
      final senderId = _userService.currentUserId;
      if (senderId == null) {
        throw Exception('User not authenticated');
      }

      final gift = GiftModel(
        id: '', // ID will be set by Firestore
        senderId: senderId,
        recipientId: widget.recipientId,
        giftType: giftType,
        amount: amount,
        createdAt: Timestamp.now(),
      );

      await _paymentService.processGiftPayment(gift);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gift sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send gift: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Send a Gift',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ..._giftOptions.map((gift) {
            return ListTile(
              title: Text(gift['type'] as String),
              subtitle: Text('Amount: \$${gift['amount']}'),
              trailing: ElevatedButton(
                onPressed: () => _sendGift(
                  gift['type'] as String,
                  (gift['amount'] as num).toDouble(),
                ),
                child: const Text('Send'),
              ),
            );
          }),
        ],
      ),
    );
  }
}
