import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/artbeat_event.dart';
import '../services/event_moderation_service.dart';

/// Screen for event moderation dashboard
/// Allows moderators to review and manage flagged events
class EventModerationDashboardScreen extends StatefulWidget {
  const EventModerationDashboardScreen({super.key});

  @override
  State<EventModerationDashboardScreen> createState() =>
      _EventModerationDashboardScreenState();
}

class _EventModerationDashboardScreenState
    extends State<EventModerationDashboardScreen>
    with SingleTickerProviderStateMixin {
  final EventModerationService _moderationService = EventModerationService();

  late TabController _tabController;
  List<Map<String, dynamic>> _flaggedEvents = [];
  List<ArtbeatEvent> _pendingEvents = [];
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        _moderationService.getFlaggedEventsWithDetails(),
        _moderationService.getPendingEvents(),
        _moderationService.getModerationAnalytics(),
      ]);

      setState(() {
        _flaggedEvents = futures[0] as List<Map<String, dynamic>>;
        _pendingEvents = futures[1] as List<ArtbeatEvent>;
        _analytics = futures[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Moderation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Flagged Events', icon: Icon(Icons.flag)),
            Tab(text: 'Pending Review', icon: Icon(Icons.pending)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFlaggedEventsTab(),
                _buildPendingEventsTab(),
                _buildAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Error loading moderation data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildFlaggedEventsTab() {
    if (_flaggedEvents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No flagged events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('All events are currently clear of flags.'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _flaggedEvents.length,
        itemBuilder: (context, index) {
          return _buildFlaggedEventCard(_flaggedEvents[index]);
        },
      ),
    );
  }

  Widget _buildFlaggedEventCard(Map<String, dynamic> flaggedEventData) {
    final flag = flaggedEventData['flag'] as Map<String, dynamic>;
    final event = flaggedEventData['event'] as ArtbeatEvent;
    final flagId = flaggedEventData['flagId'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildFlagTypeChip(flag['flagType'] as String? ?? 'other'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reason: ${flag['reason']}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Flagged: ${_formatTimestamp(flag['timestamp'])}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _dismissFlag(flagId),
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _viewEventDetails(event),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Review'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingEventsTab() {
    if (_pendingEvents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No pending events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('All events have been reviewed.'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingEvents.length,
        itemBuilder: (context, index) {
          return _buildPendingEventCard(_pendingEvents[index]);
        },
      ),
    );
  }

  Widget _buildPendingEventCard(ArtbeatEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  event.location,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                _buildStatusChip('pending'), // Default to pending for now
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _reviewEvent(event.id, false),
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _reviewEvent(event.id, true),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_analytics == null) {
      return const Center(child: Text('Analytics data not available'));
    }

    final flags = _analytics!['flags'] as Map<String, dynamic>;
    final events = _analytics!['events'] as Map<String, dynamic>;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Moderation Overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsCard(
                    'Total Flags',
                    '${flags['total']}',
                    Icons.flag,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsCard(
                    'Pending Flags',
                    '${flags['pending']}',
                    Icons.pending,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsCard(
                    'Total Events',
                    '${events['total']}',
                    Icons.event,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsCard(
                    'Flagged Events',
                    '${events['flagged']}',
                    Icons.warning,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildProgressIndicator(
              'Flag Resolution Rate',
              flags['reviewed'] as int,
              flags['total'] as int,
            ),
            const SizedBox(height: 16),
            _buildProgressIndicator(
              'Content Quality',
              (events['total'] as int) - (events['flagged'] as int),
              events['total'] as int,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(String title, int current, int total) {
    final percentage = total > 0 ? (current / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('$current / $total (${(percentage * 100).toInt()}%)'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildFlagTypeChip(String flagType) {
    final colors = {
      'spam': Colors.red,
      'inappropriate_content': Colors.orange,
      'misinformation': Colors.purple,
      'intellectual_property': Colors.blue,
      'other': Colors.grey,
    };

    return Chip(
      label: Text(
        flagType.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 10),
      ),
      backgroundColor: colors[flagType]?.withValues(alpha: 0.2),
      side: BorderSide(color: colors[flagType] ?? Colors.grey),
    );
  }

  Widget _buildStatusChip(String status) {
    final colors = {
      'pending': Colors.orange,
      'under_review': Colors.blue,
      'flagged': Colors.red,
      'approved': Colors.green,
      'rejected': Colors.red,
    };

    return Chip(
      label: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 10),
      ),
      backgroundColor: colors[status]?.withValues(alpha: 0.2),
      side: BorderSide(color: colors[status] ?? Colors.grey),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      final date = timestamp is DateTime
          ? timestamp
          : (timestamp as Timestamp).toDate();
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _reviewEvent(String eventId, bool approved) async {
    try {
      await _moderationService.reviewEvent(eventId, approved);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Event ${approved ? 'approved' : 'rejected'} successfully',
            ),
            backgroundColor: approved ? Colors.green : Colors.red,
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _dismissFlag(String flagId) async {
    final reason = await _showDismissalReasonDialog();
    if (reason == null) return;

    try {
      await _moderationService.dismissFlag(flagId, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flag dismissed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error dismissing flag: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showDismissalReasonDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismiss Flag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for dismissing this flag:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Dismissal reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  void _viewEventDetails(ArtbeatEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${event.description}'),
              const SizedBox(height: 8),
              Text('Location: ${event.location}'),
              const SizedBox(height: 8),
              Text(
                'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(event.dateTime)}',
              ),
              const SizedBox(height: 8),
              const Text('Status: pending'), // Default status for now
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _reviewEvent(event.id, false);
            },
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _reviewEvent(event.id, true);
            },
            icon: const Icon(Icons.check),
            label: const Text('Approve'),
          ),
        ],
      ),
    );
  }
}
