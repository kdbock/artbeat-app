import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../widgets/admin_drawer.dart';

/// Admin Events Management Screen
///
/// Centralized event administration interface with comprehensive event management
/// capabilities including approval workflows, bulk operations, and analytics.
class AdminEventsManagementScreen extends StatefulWidget {
  const AdminEventsManagementScreen({super.key});

  @override
  State<AdminEventsManagementScreen> createState() =>
      _AdminEventsManagementScreenState();
}

class _AdminEventsManagementScreenState
    extends State<AdminEventsManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State management
  final List<EventModel> _pendingEvents = [];
  final List<EventModel> _allEvents = [];
  final Map<String, bool> _selectedEvents = {};
  bool _isLoading = true;
  bool _isSelectionMode = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Integrate with artbeat_events services
      // final events = await EventService().getAllEventsForAdmin();
      // setState(() {
      //   _allEvents = events;
      //   _pendingEvents = events.where((e) => e.status == 'pending').toList();
      //   _isLoading = false;
      // });

      // Placeholder for now
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
  }

  Future<void> _approveEvent(String eventId) async {
    try {
      // TODO: Implement event approval
      // await EventModerationService().approveEvent(eventId);
      await _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving event: $e')),
        );
      }
    }
  }

  Future<void> _rejectEvent(String eventId, String reason) async {
    try {
      // TODO: Implement event rejection
      // await EventModerationService().rejectEvent(eventId, reason);
      await _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting event: $e')),
        );
      }
    }
  }

  Future<void> _bulkApproveEvents() async {
    final selectedEventIds = _selectedEvents.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedEventIds.isEmpty) return;

    try {
      // TODO: Implement bulk approval
      // await EventModerationService().bulkApproveEvents(selectedEventIds);
      await _loadEvents();
      _clearSelection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedEventIds.length} events approved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error bulk approving events: $e')),
        );
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedEvents.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AdminDrawer(),
      appBar: const EnhancedUniversalHeader(
        title: 'Events Management',
        showBackButton: true,
        showSearch: true,
        showDeveloperTools: true,
      ),
      body: Column(
        children: [
          // Admin header with purple branding
          Material(
            color: const Color(0xFF8C52FF),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF00BF63),
              unselectedLabelColor:
                  const Color(0xFF00BF63).withValues(alpha: 0.7),
              indicatorColor: const Color(0xFF00BF63),
              tabs: const [
                Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
                Tab(text: 'All Events', icon: Icon(Icons.event)),
                Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
                Tab(text: 'Settings', icon: Icon(Icons.settings)),
              ],
            ),
          ),

          // Action bar for bulk operations
          if (_isSelectionMode) _buildActionBar(),

          // Search and filter bar
          _buildSearchAndFilterBar(),

          // Main content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingEventsTab(),
                _buildAllEventsTab(),
                _buildAnalyticsTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    final selectedCount =
        _selectedEvents.values.where((selected) => selected).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF8C52FF).withValues(alpha: 0.1),
      child: Row(
        children: [
          Text('$selectedCount selected'),
          const Spacer(),
          TextButton.icon(
            onPressed: _bulkApproveEvents,
            icon: const Icon(Icons.check, color: Colors.green),
            label: const Text('Approve'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _showBulkRejectDialog(),
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text('Reject'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _clearSelection,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search events...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedFilter,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'approved', child: Text('Approved')),
              DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              DropdownMenuItem(value: 'flagged', child: Text('Flagged')),
            ],
            onChanged: (value) {
              setState(() => _selectedFilter = value ?? 'all');
              _loadEvents();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingEventsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingEvents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No pending events',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'All events have been reviewed',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _pendingEvents.length,
      itemBuilder: (context, index) {
        final event = _pendingEvents[index];
        return _buildEventCard(event, isPending: true);
      },
    );
  }

  Widget _buildAllEventsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Selection toggle
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() => _isSelectionMode = !_isSelectionMode);
                  if (!_isSelectionMode) _clearSelection();
                },
                icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist),
                label: Text(
                    _isSelectionMode ? 'Cancel Selection' : 'Select Multiple'),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: _allEvents.length,
            itemBuilder: (context, index) {
              final event = _allEvents[index];
              return _buildEventCard(event);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(EventModel event, {bool isPending = false}) {
    final isSelected = _selectedEvents[event.id] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    _selectedEvents[event.id] = value ?? false;
                  });
                },
              )
            : const CircleAvatar(
                backgroundColor: Colors.blue, // Default color
                child: Icon(
                  Icons.event,
                  color: Colors.white,
                  size: 16,
                ),
              ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Organizer: ${event.artistId}'),
            Text('Date: ${event.startDate.toString().substring(0, 16)}'),
            Text('Location: ${event.location}'),
          ],
        ),
        trailing: isPending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _approveEvent(event.id),
                    icon: const Icon(Icons.check, color: Colors.green),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    onPressed: () => _showRejectDialog(event.id),
                    icon: const Icon(Icons.close, color: Colors.red),
                    tooltip: 'Reject',
                  ),
                ],
              )
            : IconButton(
                onPressed: () => _showEventDetails(event),
                icon: const Icon(Icons.more_vert),
              ),
        onTap: _isSelectionMode
            ? () {
                setState(() {
                  _selectedEvents[event.id] = !isSelected;
                });
              }
            : () => _showEventDetails(event),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Event Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Analytics dashboard coming soon',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Event Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Event management settings coming soon',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(EventModel event) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Organizer: ${event.artistId}'),
            const SizedBox(height: 8),
            Text('Date: ${event.startDate}'),
            const SizedBox(height: 8),
            Text('Location: ${event.location}'),
            const SizedBox(height: 8),
            if (event.description.isNotEmpty)
              Text('Description: ${event.description}'),
            const SizedBox(height: 8),
            Text('Public Event: ${event.isPublic ? "Yes" : "No"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          // Note: Status-based actions removed since EventModel doesn't have status
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _approveEvent(event.id);
            },
            child: const Text('Approve', style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showRejectDialog(event.id);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String eventId) {
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Rejection reason...',
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
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectEvent(eventId, reasonController.text);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showBulkRejectDialog() {
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Reject Events'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Please provide a reason for rejecting selected events:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Rejection reason...',
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
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _bulkRejectEvents(reasonController.text);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject Selected'),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkRejectEvents(String reason) async {
    final selectedEventIds = _selectedEvents.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedEventIds.isEmpty) return;

    try {
      // TODO: Implement bulk rejection
      // await EventModerationService().bulkRejectEvents(selectedEventIds, reason);
      await _loadEvents();
      _clearSelection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedEventIds.length} events rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error bulk rejecting events: $e')),
        );
      }
    }
  }
}
