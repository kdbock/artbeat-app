import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../../models/commission_model.dart';
import '../../services/commission_service.dart';
import 'commission_details_sheet.dart';

class CommissionsScreen extends StatefulWidget {
  const CommissionsScreen({super.key});

  @override
  State<CommissionsScreen> createState() => _CommissionsScreenState();
}

class _CommissionsScreenState extends State<CommissionsScreen> {
  final _commissionService = CommissionService();
  List<CommissionModel> _commissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommissions();
  }

  Future<void> _loadCommissions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Get current user ID
      final userId = UserService().currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      _commissions = await _commissionService.getCommissionsByUser(userId);
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      // debugPrint('Error loading commissions: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _commissions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pendingCommissions = _commissions
        .where((c) => c.status == CommissionStatus.pending)
        .toList();
    final activeCommissions =
        _commissions.where((c) => c.status == CommissionStatus.active).toList();
    final completedCommissions = _commissions
        .where((c) => c.status == CommissionStatus.completed)
        .toList();
    final paidCommissions =
        _commissions.where((c) => c.status == CommissionStatus.paid).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Commission Agreements'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
              Tab(text: 'Paid'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCommissionList(pendingCommissions),
            _buildCommissionList(activeCommissions),
            _buildCommissionList(completedCommissions),
            _buildCommissionList(paidCommissions),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionList(List<CommissionModel> commissions) {
    if (commissions.isEmpty) {
      return const Center(
        child: Text('No commissions in this category'),
      );
    }

    return ListView.builder(
      itemCount: commissions.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final commission = commissions[index];
        return Card(
          child: ListTile(
            title: Text(
              'Gallery: ${commission.galleryId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Commission Rate: ${commission.commissionRate}%'),
                Text('Created: ${_formatDate(commission.createdAt)}'),
                if (commission.status == CommissionStatus.completed ||
                    commission.status == CommissionStatus.paid)
                  Text('Completed: ${_formatDate(commission.completedAt!)}'),
              ],
            ),
            trailing: _buildStatusIndicator(commission.status),
            onTap: () => _showCommissionDetails(commission),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(CommissionStatus status) {
    final color = switch (status) {
      CommissionStatus.pending => Colors.orange,
      CommissionStatus.active => Colors.green,
      CommissionStatus.completed => Colors.blue,
      CommissionStatus.paid => Colors.green,
      CommissionStatus.cancelled => Colors.red,
    };

    final icon = switch (status) {
      CommissionStatus.pending => Icons.pending,
      CommissionStatus.active => Icons.check_circle,
      CommissionStatus.completed => Icons.done_all,
      CommissionStatus.paid => Icons.attach_money,
      CommissionStatus.cancelled => Icons.cancel,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        Text(
          _formatStatus(status),
          style: TextStyle(color: color),
        ),
      ],
    );
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showCommissionDetails(CommissionModel commission) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => CommissionDetailsSheet(commission: commission),
      isScrollControlled: true,
    );
  }
}
