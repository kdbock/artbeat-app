import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class GiftCardWidget extends StatelessWidget {
  final GiftModel gift;
  final VoidCallback? onSendGift;

  const GiftCardWidget({
    super.key,
    required this.gift,
    this.onSendGift,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gift.giftType,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: \$${gift.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            if (onSendGift != null)
              ElevatedButton(
                onPressed: onSendGift,
                child: const Text('Send Gift'),
              ),
          ],
        ),
      ),
    );
  }
}
