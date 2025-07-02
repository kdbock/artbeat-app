import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';
import '../theme/artbeat_colors.dart';
import '../theme/artbeat_typography.dart';

class DeveloperFeedbackAdminScreen extends StatefulWidget {
  const DeveloperFeedbackAdminScreen({super.key});

  @override
  State<DeveloperFeedbackAdminScreen> createState() =>
      _DeveloperFeedbackAdminScreenState();
}

class _DeveloperFeedbackAdminScreenState
    extends State<DeveloperFeedbackAdminScreen>
    with TickerProviderStateMixin {
  final FeedbackService _feedbackService = FeedbackService();
  late TabController _tabController;
  FeedbackStatus? _statusFilter;
  String? _packageFilter;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _feedbackService.getFeedbackStats();
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (e) {
      // Handle error silently or show snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Feedback Admin'),
        backgroundColor: ArtbeatColors.primaryPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Feedback', icon: Icon(Icons.list)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
            Tab(text: 'Management', icon: Icon(Icons.admin_panel_settings)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadStats();
              setState(() {}); // Refresh the streams
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedbackList(),
          _buildStatistics(),
          _buildManagement(),
        ],
      ),
    );
  }

  Widget _buildFeedbackList() {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: StreamBuilder<List<FeedbackModel>>(
            stream: _statusFilter != null
                ? _feedbackService.getFeedbackByStatus(_statusFilter!)
                : _feedbackService.getAllFeedback(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text('Error loading feedback: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final feedbacks = snapshot.data ?? [];

              // Apply package filter if set
              final filteredFeedbacks = _packageFilter != null
                  ? feedbacks
                        .where((f) => f.packageModules.contains(_packageFilter))
                        .toList()
                  : feedbacks;

              if (filteredFeedbacks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.feedback, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No feedback found',
                        style: ArtbeatTypography.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Feedback will appear here when users submit it',
                        style: ArtbeatTypography.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredFeedbacks.length,
                itemBuilder: (context, index) {
                  return _buildFeedbackCard(filteredFeedbacks[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use column layout for narrow screens
          if (constraints.maxWidth < 500) {
            return Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<FeedbackStatus?>(
                    value: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<FeedbackStatus?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ...FeedbackStatus.values.map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<String?>(
                    value: _packageFilter,
                    decoration: const InputDecoration(
                      labelText: 'Package',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    isExpanded: true, // This helps prevent overflow
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ...FeedbackService.getAvailablePackages().map(
                        (package) => DropdownMenuItem(
                          value: package,
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              _getPackageDisplayName(package),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _packageFilter = value;
                      });
                    },
                  ),
                ),
              ],
            );
          }

          // Use row layout for wider screens
          return Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<FeedbackStatus?>(
                  value: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<FeedbackStatus?>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...FeedbackStatus.values.map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.displayName),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _packageFilter,
                  decoration: const InputDecoration(
                    labelText: 'Package',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  isExpanded: true, // This helps prevent overflow
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...FeedbackService.getAvailablePackages().map(
                      (package) => DropdownMenuItem(
                        value: package,
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            _getPackageDisplayName(package),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _packageFilter = value;
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeedbackCard(FeedbackModel feedback) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        leading: _getTypeIcon(feedback.type),
        title: Text(
          feedback.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(feedback.status),
                const SizedBox(width: 8),
                _buildPriorityChip(feedback.priority),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${feedback.userName} • ${feedback.packageModules.map(_getPackageDisplayName).join(', ')} • ${DateFormat('MMM dd, yyyy').format(feedback.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Description', feedback.description),
                const SizedBox(height: 12),
                _buildDetailRow('User Email', feedback.userEmail),
                const SizedBox(height: 12),
                _buildDetailRow('Device Info', feedback.deviceInfo),
                const SizedBox(height: 12),
                _buildDetailRow('App Version', feedback.appVersion),
                if (feedback.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildImagesSection(feedback.imageUrls),
                ],
                if (feedback.developerResponse != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Developer Response',
                    feedback.developerResponse!,
                  ),
                ],
                const SizedBox(height: 16),
                _buildActionButtons(feedback),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }

  Widget _buildImagesSection(List<String> imageUrls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Screenshots',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _showImageDialog(imageUrls[index]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrls[index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.error),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(FeedbackModel feedback) {
    return Wrap(
      spacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showResponseDialog(feedback),
          icon: const Icon(Icons.reply, size: 16),
          label: const Text('Respond'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ArtbeatColors.primaryPurple,
            foregroundColor: Colors.white,
          ),
        ),
        OutlinedButton.icon(
          onPressed: () =>
              _updateStatus(feedback.id, FeedbackStatus.inProgress),
          icon: const Icon(Icons.play_arrow, size: 16),
          label: const Text('In Progress'),
        ),
        OutlinedButton.icon(
          onPressed: () => _updateStatus(feedback.id, FeedbackStatus.resolved),
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Resolve'),
        ),
        OutlinedButton.icon(
          onPressed: () => _confirmDelete(feedback.id),
          icon: const Icon(Icons.delete, size: 16),
          label: const Text('Delete'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    );
  }

  Widget _buildStatusChip(FeedbackStatus status) {
    Color color;
    switch (status) {
      case FeedbackStatus.open:
        color = Colors.blue;
        break;
      case FeedbackStatus.inProgress:
        color = Colors.orange;
        break;
      case FeedbackStatus.resolved:
        color = Colors.green;
        break;
      case FeedbackStatus.closed:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(FeedbackPriority priority) {
    Color color;
    switch (priority) {
      case FeedbackPriority.low:
        color = Colors.green;
        break;
      case FeedbackPriority.medium:
        color = Colors.orange;
        break;
      case FeedbackPriority.high:
        color = Colors.red;
        break;
      case FeedbackPriority.critical:
        color = Colors.red[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        priority.displayName,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    if (_stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCard('Overall Statistics', {
            'Total Feedback': _stats!['total'].toString(),
            'Open': _stats!['open'].toString(),
            'In Progress': _stats!['inProgress'].toString(),
            'Resolved': _stats!['resolved'].toString(),
            'Closed': _stats!['closed'].toString(),
          }),
          const SizedBox(height: 16),
          _buildStatsCard(
            'By Type',
            Map<String, String>.from(
              (_stats!['byType'] as Map).map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatsCard(
            'By Priority',
            Map<String, String>.from(
              (_stats!['byPriority'] as Map).map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatsCard(
            'By Package',
            Map<String, String>.from(
              (_stats!['byPackage'] as Map).map(
                (k, v) => MapEntry(
                  _getPackageDisplayName(k.toString()),
                  v.toString(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, Map<String, String> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: ArtbeatTypography.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...stats.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      entry.value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagement() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bulk Actions',
            style: ArtbeatTypography.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dangerous Actions'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _confirmBulkAction('Mark all open as closed'),
                    icon: const Icon(Icons.close_fullscreen),
                    label: const Text('Close All Open Feedback'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _confirmBulkAction('Delete all resolved feedback'),
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Delete All Resolved'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Icon _getTypeIcon(FeedbackType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case FeedbackType.bug:
        iconData = Icons.bug_report;
        color = Colors.red;
        break;
      case FeedbackType.feature:
        iconData = Icons.lightbulb;
        color = Colors.blue;
        break;
      case FeedbackType.improvement:
        iconData = Icons.trending_up;
        color = Colors.green;
        break;
      case FeedbackType.usability:
        iconData = Icons.accessibility;
        color = Colors.purple;
        break;
      case FeedbackType.performance:
        iconData = Icons.speed;
        color = Colors.orange;
        break;
      case FeedbackType.other:
        iconData = Icons.help;
        color = Colors.grey;
        break;
    }

    return Icon(iconData, color: color);
  }

  String _getPackageDisplayName(String packageName) {
    final displayNames = {
      'artbeat_core': 'Core System',
      'artbeat_auth': 'Authentication',
      'artbeat_profile': 'User Profile',
      'artbeat_artist': 'Artist Features',
      'artbeat_artwork': 'Artwork Management',
      'artbeat_art_walk': 'Art Walks',
      'artbeat_community': 'Community Features',
      'artbeat_capture': 'Photo Capture',
      'artbeat_messaging': 'Messaging',
      'artbeat_settings': 'Settings',
      'artbeat_admin': 'Admin Features',
      'artbeat_ads': 'Advertisements',
      'main_app': 'Main App',
      'general': 'General/Other',
    };
    return displayNames[packageName] ?? packageName;
  }

  Future<void> _updateStatus(
    String feedbackId,
    FeedbackStatus newStatus,
  ) async {
    try {
      await _feedbackService.updateFeedbackStatus(feedbackId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showResponseDialog(FeedbackModel feedback) async {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Responding to: ${feedback.title}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Your response',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await _feedbackService.addDeveloperResponse(
                    feedback.id,
                    controller.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Response added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add response: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Send Response'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String feedbackId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text(
          'Are you sure you want to delete this feedback? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _feedbackService.deleteFeedback(feedbackId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Feedback deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete feedback: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmBulkAction(String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Action'),
        content: Text(
          'Are you sure you want to $action? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bulk action functionality coming soon'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Screenshot'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Flexible(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64),
                        Text('Failed to load image'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
