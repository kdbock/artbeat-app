import 'package:flutter/material.dart';
import '../../models/commission_model.dart';
import '../../services/commission_service.dart';

class CommissionDetailsSheet extends StatelessWidget {
  final CommissionModel commission;

  const CommissionDetailsSheet({
    super.key,
    required this.commission,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Commission Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatusIndicator(commission.status),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('Gallery ID', commission.galleryId),
                  _buildDetailRow('Artist ID', commission.artistId),
                  _buildDetailRow(
                      'Commission Rate', '${commission.commissionRate}%'),
                  _buildDetailRow('Created', _formatDate(commission.createdAt)),
                  if (commission.artworkIds != null)
                    _buildDetailRow('Artwork Count',
                        commission.artworkIds!.length.toString()),
                  if (commission.terms != null)
                    ExpansionTile(
                      title: const Text('Additional Terms'),
                      children: commission.terms!.entries
                          .map((e) => ListTile(
                                title: Text(e.key as String? ?? ''),
                                subtitle: Text(
                                    (e.value as String?)?.toString() ?? ''),
                              ))
                          .toList(),
                    ),
                  if (commission.transactions != null) ...[
                    const SizedBox(height: 16),
                    // Transaction history section
                    _buildTransactionHistory(commission.transactions!),
                  ],
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(CommissionStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatStatus(status),
        style: TextStyle(color: _getStatusColor(status)),
      ),
    );
  }

  Color _getStatusColor(CommissionStatus status) {
    return switch (status) {
      CommissionStatus.pending => Colors.orange,
      CommissionStatus.active => Colors.green,
      CommissionStatus.completed => Colors.blue,
      CommissionStatus.paid => Colors.green,
      CommissionStatus.cancelled => Colors.red,
    };
  }

  Widget _buildTransactionHistory(List<CommissionTransaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...transactions.map((transaction) => Card(
              child: ListTile(
                title: Text(transaction.artworkTitle),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sale Amount: \$${transaction.saleAmount}'),
                    Text('Commission: \$${transaction.commissionAmount}'),
                    Text('Date: ${_formatDate(transaction.transactionDate)}'),
                  ],
                ),
                trailing: Text(
                  transaction.status,
                  style: TextStyle(
                    color: transaction.status == 'paid'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (commission.status == CommissionStatus.pending)
          ElevatedButton(
            onPressed: () => _handleAcceptCommission(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          )
        else if (commission.status == CommissionStatus.active)
          ElevatedButton(
            onPressed: () => _handleMarkComplete(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Complete'),
          ),
      ],
    );
  }

  void _handleAcceptCommission(BuildContext context) async {
    final commissionService = CommissionService();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Commission?'),
        content: const Text(
            'Are you sure you want to accept this commission agreement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Update commission status to active
                await commissionService.updateStatus(
                  commission.id,
                  CommissionStatus.active,
                );

                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close details sheet

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Commission accepted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error accepting commission: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _handleMarkComplete(BuildContext context) async {
    final commissionService = CommissionService();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Complete?'),
        content: const Text('Are you sure this commission is complete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Update commission status to completed
                await commissionService.updateStatus(
                  commission.id,
                  CommissionStatus.completed,
                );

                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close details sheet

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Commission marked as complete'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error marking commission as complete: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatStatus(CommissionStatus status) {
    return switch (status) {
      CommissionStatus.pending => 'Pending',
      CommissionStatus.active => 'Active',
      CommissionStatus.completed => 'Completed',
      CommissionStatus.paid => 'Paid',
      CommissionStatus.cancelled => 'Cancelled',
    };
  }
}
