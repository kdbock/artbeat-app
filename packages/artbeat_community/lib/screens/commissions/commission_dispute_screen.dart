import 'package:flutter/material.dart';
import '../../models/commission_dispute_model.dart';
import '../../services/commission_dispute_service.dart';

class CommissionDisputeScreen extends StatefulWidget {
  final String commissionId;
  final String otherPartyId;
  final String otherPartyName;

  const CommissionDisputeScreen({
    Key? key,
    required this.commissionId,
    required this.otherPartyId,
    required this.otherPartyName,
  }) : super(key: key);

  @override
  State<CommissionDisputeScreen> createState() =>
      _CommissionDisputeScreenState();
}

class _CommissionDisputeScreenState extends State<CommissionDisputeScreen> {
  late CommissionDisputeService _disputeService;
  late TextEditingController _descriptionController;
  late TextEditingController _messageController;
  DisputeReason _selectedReason = DisputeReason.qualityIssue;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _disputeService = CommissionDisputeService();
    _descriptionController = TextEditingController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _createDispute() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _disputeService.createDispute(
        commissionId: widget.commissionId,
        otherPartyId: widget.otherPartyId,
        otherPartyName: widget.otherPartyName,
        reason: _selectedReason,
        description: _descriptionController.text,
      );

      _descriptionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dispute created. Support team will review soon.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispute Resolution'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Commission Dispute',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our support team will review your dispute and help resolve it fairly. Please provide as much detail as possible.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dispute Reason
            Text(
              'What is the issue?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<DisputeReason>(
                value: _selectedReason,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: DisputeReason.values.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedReason = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              'Detailed Description',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Please describe the issue in detail...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createDispute,
                icon: const Icon(Icons.flag),
                label: const Text('Report Dispute'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tips
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tips for resolving disputes:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...[
                        'Be specific and factual about the issue',
                        'Provide evidence (screenshots, files, messages)',
                        'Respond to the other party\'s messages promptly',
                        'Be professional and respectful',
                      ]
                      .map(
                        (tip) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(tip)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
