import 'package:flutter/material.dart';
import '../models/ad_status.dart' as model;

class AdStatusWidget extends StatelessWidget {
  final model.AdStatus status;
  final String? reason;

  const AdStatusWidget({super.key, required this.status, this.reason});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case model.AdStatus.pending:
        color = Colors.orange;
        label = 'Pending Approval';
        break;
      case model.AdStatus.approved:
        color = Colors.green;
        label = 'Approved';
        break;
      case model.AdStatus.rejected:
        color = Colors.red;
        label = 'Rejected';
        break;
      case model.AdStatus.running:
        color = Colors.blue;
        label = 'Running';
        break;
      case model.AdStatus.expired:
        color = Colors.grey;
        label = 'Expired';
        break;
    }
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label),
        if (status == model.AdStatus.rejected && reason != null) ...[
          const SizedBox(width: 8),
          Text('($reason)', style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }
}
