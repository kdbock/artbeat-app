import 'package:flutter/material.dart';
import 'package:artbeat_artist/artbeat_artist.dart' show CommissionStatus;
import '../../models/commission_model.dart';
import '../../services/commission_service.dart';

class CommissionsScreen extends StatefulWidget {
  const CommissionsScreen({super.key});

  @override
  State<CommissionsScreen> createState() => _CommissionsScreenState();
}

class _CommissionsScreenState extends State<CommissionsScreen>
    with SingleTickerProviderStateMixin {
  final CommissionService _commissionService = CommissionService();
  late final TabController _tabController;
  List<CommissionModel> _commissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCommissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommissions() async {
    setState(() => _isLoading = true);
    try {
      final commissions = await _commissionService.getCommissionsByUser(
        'userId',
      );
      setState(() {
        _commissions = commissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading commissions: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs for filtering commissions
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
        // Commission list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Active commissions
                    _buildCommissionList(
                      _commissions
                          .where((c) => c.status == CommissionStatus.active)
                          .toList(),
                    ),
                    // Pending commissions
                    _buildCommissionList(
                      _commissions
                          .where((c) => c.status == CommissionStatus.pending)
                          .toList(),
                    ),
                    // Completed commissions
                    _buildCommissionList(
                      _commissions
                          .where((c) => c.status == CommissionStatus.completed)
                          .toList(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCommissionList(List<CommissionModel> commissions) {
    if (commissions.isEmpty) {
      return const Center(child: Text('No commissions found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: commissions.length,
      itemBuilder: (context, index) {
        final commission = commissions[index];
        return Card(
          child: ListTile(
            title: Text('Commission Rate: ${commission.commissionRate}%'),
            subtitle: Text('Status: ${commission.status}'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              _showCommissionDetails(commission);
            },
          ),
        );
      },
    );
  }

  void _showCommissionDetails(CommissionModel commission) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Commission Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Commission ID', commission.id),
              _buildDetailRow('Gallery ID', commission.galleryId),
              _buildDetailRow('Artist ID', commission.artistId),
              _buildDetailRow('Artwork ID', commission.artworkId),
              _buildDetailRow(
                'Commission Rate',
                '${commission.commissionRate}%',
              ),
              _buildDetailRow('Status', commission.status),
              _buildDetailRow(
                'Created',
                commission.createdAt.toDate().toString(),
              ),
              _buildDetailRow(
                'Updated',
                commission.updatedAt.toDate().toString(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
