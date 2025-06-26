import 'package:flutter/material.dart';

/// Widget to display ad payment summary and trigger payment action
class AdPaymentWidget extends StatelessWidget {
  final int days;
  final double pricePerDay;
  final VoidCallback onPay;
  final bool isProcessing;

  const AdPaymentWidget({
    super.key,
    required this.days,
    required this.pricePerDay,
    required this.onPay,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final total = days * pricePerDay;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ad Duration: $days day${days == 1 ? '' : 's'}'),
            Text('Price per day: \$${pricePerDay.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            const Text('Total: ', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : onPay,
                child: isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Pay & Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
