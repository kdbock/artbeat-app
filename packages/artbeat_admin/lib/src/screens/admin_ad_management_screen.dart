import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';

/// Admin Ad Management Screen
/// Handles advertising content management and sponsored content moderation
class AdminAdManagementScreen extends StatefulWidget {
  const AdminAdManagementScreen({super.key});

  @override
  State<AdminAdManagementScreen> createState() =>
      _AdminAdManagementScreenState();
}

class _AdminAdManagementScreenState extends State<AdminAdManagementScreen> {
  final List<String> _tabs = [
    'Active Ads',
    'Pending Review',
    'Archived',
    'Analytics'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ad Management',
          style: TextStyle(
            fontFamily: 'Limelight',
            color: Color(0xFF8C52FF),
          ),
        ),
        bottom: TabBar(
          isScrollable: false,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          labelColor: const Color(0xFF8C52FF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF8C52FF),
        ),
      ),
      drawer: const AdminDrawer(),
      body: TabBarView(
        children: [
          _buildActiveAdsTab(),
          _buildPendingReviewTab(),
          _buildArchivedTab(),
          _buildAnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAdDialog(),
        backgroundColor: const Color(0xFF8C52FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildActiveAdsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, color: Colors.grey),
            ),
            title: Text('Advertisement ${index + 1}'),
            subtitle: Text(
                'Advertiser: Company ${index + 1}\nImpressions: ${(index + 1) * 1000}'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'pause',
                  child: Row(
                    children: [
                      Icon(Icons.pause, size: 16),
                      SizedBox(width: 8),
                      Text('Pause'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive, size: 16),
                      SizedBox(width: 8),
                      Text('Archive'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _handleAdAction(value, index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingReviewTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.pending, color: Colors.orange),
            ),
            title: Text('Pending Ad ${index + 1}'),
            subtitle: Text(
                'Submitted: 2024-12-${(index + 1).toString().padLeft(2, '0')}\nAdvertiser: New Company ${index + 1}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _approveAd(index),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _rejectAd(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArchivedTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 15,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.archive, color: Colors.grey),
            ),
            title: Text('Archived Ad ${index + 1}'),
            subtitle: Text(
                'Ended: 2024-11-${(index + 1).toString().padLeft(2, '0')}\nTotal Impressions: ${(index + 1) * 5000}'),
            trailing: IconButton(
              icon: const Icon(Icons.restore),
              onPressed: () => _restoreAd(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Total Ads', '45', Icons.campaign),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard('Active Ads', '23', Icons.play_arrow),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child:
                    _buildMetricCard('Revenue', '\$12,500', Icons.attach_money),
              ),
              const SizedBox(width: 16),
              Expanded(
                child:
                    _buildMetricCard('Impressions', '2.5M', Icons.visibility),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Performance Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Performance Chart\n(Integration with analytics service required)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF8C52FF)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8C52FF),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAdDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Advertisement'),
        content:
            const Text('This feature will integrate with ad creation tools.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Ad creation feature coming soon')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _handleAdAction(String action, int index) {
    String message;
    switch (action) {
      case 'edit':
        message = 'Edit ad ${index + 1}';
        break;
      case 'pause':
        message = 'Paused ad ${index + 1}';
        break;
      case 'archive':
        message = 'Archived ad ${index + 1}';
        break;
      default:
        message = 'Unknown action';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _approveAd(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Approved pending ad ${index + 1}')),
    );
  }

  void _rejectAd(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rejected pending ad ${index + 1}')),
    );
  }

  void _restoreAd(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Restored archived ad ${index + 1}')),
    );
  }
}
