import 'package:flutter/material.dart';

/// Widget to display the status of an ad (pending, approved, rejected, running, expired)
enum AdStatus { pending, approved, rejected, running, expired }

class AdStatusWidget extends StatelessWidget {
  final AdStatus status;
  final String? reason;

  const AdStatusWidget({super.key, required this.status, this.reason});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case AdStatus.pending:
        color = Colors.orange;
        label = 'Pending Approval';
        break;
      case AdStatus.approved:
        color = Colors.green;
        label = 'Approved';
        break;
      case AdStatus.rejected:
        color = Colors.red;
        label = 'Rejected';
        break;
      case AdStatus.running:
        color = Colors.blue;
        label = 'Running';
        break;
      case AdStatus.expired:
        color = Colors.grey;
        label = 'Expired';
        break;
    }
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 16),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color)),
        if (status == AdStatus.rejected && reason != null) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: reason!,
            child: const Icon(Icons.info_outline, color: Colors.red, size: 16),
          ),
        ],
      ],
    );
  }
}
