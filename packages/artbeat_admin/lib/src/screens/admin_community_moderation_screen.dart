import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_drawer.dart';

/// Admin screen for community moderation including posts, comments, and reports
class AdminCommunityModerationScreen extends StatefulWidget {
  const AdminCommunityModerationScreen({super.key});

  @override
  State<AdminCommunityModerationScreen> createState() =>
      _AdminCommunityModerationScreenState();
}

class _AdminCommunityModerationScreenState
    extends State<AdminCommunityModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = false;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadModerationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadModerationData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load reported content
      await _loadReportedContent();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading moderation data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadReportedContent() async {
    // This would integrate with actual moderation services
    // For now, we'll use placeholder logic

    // TODO: Implement actual Firebase queries for:
    // - Reported posts
    // - Reported comments
    // - Flagged users
    // - Content moderation queue
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Moderation'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Reported Posts'),
            Tab(text: 'Reported Comments'),
            Tab(text: 'User Reports'),
            Tab(text: 'Moderation Log'),
          ],
        ),
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReportedPostsTab(),
                      _buildReportedCommentsTab(),
                      _buildUserReportsTab(),
                      _buildModerationLogTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search reports...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedFilter,
            items: ['All', 'Pending', 'Reviewed', 'Dismissed']
                .map((filter) => DropdownMenuItem(
                      value: filter,
                      child: Text(filter),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedFilter = value ?? 'All';
              });
            },
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _loadModerationData,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportedPostsTab() {
    return ListView.builder(
      itemCount: 10, // Placeholder count
      itemBuilder: (context, index) {
        return _buildReportedPostCard(index);
      },
    );
  }

  Widget _buildReportedPostCard(int index) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Post #${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reported by: user_${index + 1}@example.com',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reason: Inappropriate content',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: const Text('PENDING'),
                  backgroundColor: Colors.orange[100],
                  labelStyle: const TextStyle(color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                'Sample post content that has been reported for moderation review. This could contain inappropriate material or violate community guidelines.',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showPostDetails(index),
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _dismissReport(index, 'post'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _removeContent(index, 'post'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportedCommentsTab() {
    return ListView.builder(
      itemCount: 8, // Placeholder count
      itemBuilder: (context, index) {
        return _buildReportedCommentCard(index);
      },
    );
  }

  Widget _buildReportedCommentCard(int index) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comment on Post #${index + 10}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Commenter: artist_${index + 1}@example.com',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reported for: Spam/Harassment',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: const Text('PENDING'),
                  backgroundColor: Colors.orange[100],
                  labelStyle: const TextStyle(color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                'This is a sample comment that has been reported. It may contain spam, harassment, or other policy violations.',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showCommentDetails(index),
                  child: const Text('View Context'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _dismissReport(index, 'comment'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _removeContent(index, 'comment'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserReportsTab() {
    return ListView.builder(
      itemCount: 5, // Placeholder count
      itemBuilder: (context, index) {
        return _buildUserReportCard(index);
      },
    );
  }

  Widget _buildUserReportCard(int index) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Report #${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reported User: flagged_user_${index + 1}@example.com',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reports: ${index + 3} reports',
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(index < 2 ? 'HIGH PRIORITY' : 'PENDING'),
                  backgroundColor:
                      index < 2 ? Colors.red[100] : Colors.orange[100],
                  labelStyle: TextStyle(
                    color: index < 2 ? Colors.red : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Recent violations:',
              style: TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            ...List.generate(
                2,
                (i) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.warning,
                              size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                              'Posted inappropriate content on ${DateFormat('MMM dd').format(DateTime.now().subtract(Duration(days: i + 1)))}'),
                        ],
                      ),
                    )),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _viewUserProfile(index),
                  child: const Text('View Profile'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _warnUser(index),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Warn User'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _suspendUser(index),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Suspend'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModerationLogTab() {
    return ListView.builder(
      itemCount: 15, // Placeholder count
      itemBuilder: (context, index) {
        return _buildModerationLogEntry(index);
      },
    );
  }

  Widget _buildModerationLogEntry(int index) {
    final actions = [
      'Content Removed',
      'User Warned',
      'Report Dismissed',
      'User Suspended'
    ];
    final action = actions[index % actions.length];
    final moderator = 'Admin User ${(index % 3) + 1}';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getActionColor(action),
        child: Icon(
          _getActionIcon(action),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(action),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Moderator: $moderator'),
          Text(
            DateFormat('MMM dd, yyyy HH:mm').format(
              DateTime.now().subtract(Duration(hours: index * 2)),
            ),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
      trailing: TextButton(
        onPressed: () => _showLogDetails(index),
        child: const Text('Details'),
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'Content Removed':
      case 'User Suspended':
        return Colors.red;
      case 'User Warned':
        return Colors.orange;
      case 'Report Dismissed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'Content Removed':
        return Icons.delete;
      case 'User Suspended':
        return Icons.block;
      case 'User Warned':
        return Icons.warning;
      case 'Report Dismissed':
        return Icons.check;
      default:
        return Icons.info;
    }
  }

  void _showPostDetails(int index) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Post #${index + 1} Details'),
        content: const SizedBox(
          width: 400,
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Full post content and context would be displayed here.'),
              SizedBox(height: 16),
              Text('Report History:'),
              Text('• Reported 2 hours ago for inappropriate content'),
              Text('• Previous reports: 0'),
              SizedBox(height: 16),
              Text('Author Information:'),
              Text('• Account created: 6 months ago'),
              Text('• Previous violations: 1'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCommentDetails(int index) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comment Details'),
        content: const SizedBox(
          width: 400,
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Full comment thread and context would be displayed here.'),
              SizedBox(height: 16),
              Text('Original Post Context:'),
              Text('• Post about local art exhibition'),
              Text('• 15 comments total'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _dismissReport(int index, String type) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismiss Report'),
        content: Text('Are you sure you want to dismiss this $type report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$type report dismissed')),
              );
              // TODO: Implement actual dismissal logic
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  void _removeContent(int index, String type) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $type'),
        content: Text(
            'Are you sure you want to remove this $type? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$type removed successfully'),
                  backgroundColor: Colors.red,
                ),
              );
              // TODO: Implement actual removal logic
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _viewUserProfile(int index) {
    // TODO: Navigate to user profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening user profile...')),
    );
  }

  void _warnUser(int index) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warn User'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Send warning to user about policy violations?'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Warning Message',
                hintText: 'Enter custom warning message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Warning sent to user')),
              );
              // TODO: Implement actual warning logic
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Send Warning'),
          ),
        ],
      ),
    );
  }

  void _suspendUser(int index) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend User'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How long should this user be suspended?'),
            SizedBox(height: 16),
            // Suspension duration options would go here
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User suspended successfully'),
                  backgroundColor: Colors.red,
                ),
              );
              // TODO: Implement actual suspension logic
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _showLogDetails(int index) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Moderation Log Details'),
        content: const SizedBox(
          width: 400,
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Detailed moderation action information would be displayed here.'),
              SizedBox(height: 16),
              Text('Action Context:'),
              Text('• Rule violated: Community Guidelines Section 3'),
              Text('• Evidence reviewed: Screenshots, reports'),
              Text('• User notified: Yes'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
