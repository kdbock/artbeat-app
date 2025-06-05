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
      final commissions =
          await _commissionService.getCommissionsByUser('userId');
      setState(() {
        _commissions = commissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading commissions: $e')),
      );
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
                    _buildCommissionList(_commissions
                        .where((c) => c.status == CommissionStatus.active)
                        .toList()),
                    // Pending commissions
                    _buildCommissionList(_commissions
                        .where((c) => c.status == CommissionStatus.pending)
                        .toList()),
                    // Completed commissions
                    _buildCommissionList(_commissions
                        .where((c) => c.status == CommissionStatus.completed)
                        .toList()),
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
              // TODO: Navigate to commission details
            },
          ),
        );
      },
    );
  }
}
