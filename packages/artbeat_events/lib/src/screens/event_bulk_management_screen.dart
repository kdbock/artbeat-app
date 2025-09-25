import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/artbeat_event.dart';
import '../services/event_bulk_management_service.dart';

/// Screen for bulk event management operations
/// Allows users to perform operations on multiple events at once
class EventBulkManagementScreen extends StatefulWidget {
  const EventBulkManagementScreen({super.key});

  @override
  State<EventBulkManagementScreen> createState() =>
      _EventBulkManagementScreenState();
}

class _EventBulkManagementScreenState extends State<EventBulkManagementScreen> {
  final EventBulkManagementService _bulkService = EventBulkManagementService();

  List<ArtbeatEvent> _events = [];
  final Set<String> _selectedEventIds = <String>{};
  bool _isLoading = true;
  bool _isPerformingBulkOperation = false;
  String? _errorMessage;

  // Filters
  String? _selectedCategory;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final events = await _bulkService.getBulkManageableEvents(
        category: _selectedCategory,
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _events = events;
        _selectedEventIds.clear(); // Clear selections when reloading
        _isLoading = false;
      });
    } on Exception catch (e) {
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
        title: const Text('Bulk Event Management'),
        actions: [
          if (_selectedEventIds.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${_selectedEventIds.length}'),
                child: const Icon(Icons.more_vert),
              ),
              onPressed: _showBulkActionsMenu,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersCard(),
          _buildSelectionHeader(),
          Expanded(
            child: _isLoading || _isPerformingBulkOperation
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorWidget()
                : _buildEventsList(),
          ),
        ],
      ),
      floatingActionButton: _selectedEventIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBulkActionsMenu,
              icon: const Icon(Icons.settings),
              label: Text('${_selectedEventIds.length} Selected'),
            )
          : null,
    );
  }

  Widget _buildFiltersCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedCategory,
                    items: const [
                      DropdownMenuItem(child: Text('All Categories')),
                      DropdownMenuItem(
                        value: 'art-show',
                        child: Text('Art Show'),
                      ),
                      DropdownMenuItem(
                        value: 'workshop',
                        child: Text('Workshop'),
                      ),
                      DropdownMenuItem(
                        value: 'exhibition',
                        child: Text('Exhibition'),
                      ),
                      DropdownMenuItem(value: 'sale', child: Text('Sale')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                      _loadEvents();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedStatus,
                    items: const [
                      DropdownMenuItem(child: Text('All Statuses')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Inactive'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('Cancelled'),
                      ),
                      DropdownMenuItem(
                        value: 'postponed',
                        child: Text('Postponed'),
                      ),
                      DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                      _loadEvents();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _selectStartDate,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _startDate != null
                          ? DateFormat('MMM dd, yyyy').format(_startDate!)
                          : 'Start Date',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _selectEndDate,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _endDate != null
                          ? DateFormat('MMM dd, yyyy').format(_endDate!)
                          : 'End Date',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionHeader() {
    if (_events.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Checkbox(
            value: _selectedEventIds.length == _events.length,
            tristate:
                _selectedEventIds.isNotEmpty &&
                _selectedEventIds.length < _events.length,
            onChanged: _toggleSelectAll,
          ),
          Text(
            _selectedEventIds.isEmpty
                ? 'Select events to perform bulk actions'
                : '${_selectedEventIds.length} of ${_events.length} selected',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_selectedEventIds.isNotEmpty)
            TextButton(
              onPressed: () => setState(_selectedEventIds.clear),
              child: const Text('Clear Selection'),
            ),
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
            'Error loading events',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadEvents, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    if (_events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No events found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Try adjusting your filters or create some events.'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          return _buildEventCard(_events[index]);
        },
      ),
    );
  }

  Widget _buildEventCard(ArtbeatEvent event) {
    final isSelected = _selectedEventIds.contains(event.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (selected) => _toggleEventSelection(event.id),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 2),
                Text(
                  event.location,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, yyyy').format(event.dateTime),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: _buildEventStatusChip(event),
        onTap: () => _toggleEventSelection(event.id),
      ),
    );
  }

  Widget _buildEventStatusChip(ArtbeatEvent event) {
    // Since ArtbeatEvent doesn't have status, use isPublic as indicator
    final status = event.isPublic ? 'active' : 'inactive';
    final color = status == 'active' ? Colors.green : Colors.grey;

    return Chip(
      label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10)),
      backgroundColor: color.withValues(alpha: 0.2),
      side: BorderSide(color: color),
    );
  }

  void _toggleEventSelection(String eventId) {
    setState(() {
      if (_selectedEventIds.contains(eventId)) {
        _selectedEventIds.remove(eventId);
      } else {
        _selectedEventIds.add(eventId);
      }
    });
  }

  void _toggleSelectAll(bool? selectAll) {
    setState(() {
      if (selectAll == true) {
        _selectedEventIds.addAll(_events.map((e) => e.id));
      } else {
        _selectedEventIds.clear();
      }
    });
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
      });
      _loadEvents();
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
      _loadEvents();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedStatus = null;
      _startDate = null;
      _endDate = null;
    });
    _loadEvents();
  }

  void _showBulkActionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildBulkActionsSheet(),
    );
  }

  Widget _buildBulkActionsSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bulk Actions (${_selectedEventIds.length} events)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Update Status'),
            onTap: () {
              Navigator.pop(context);
              _showStatusUpdateDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.green),
            title: const Text('Assign Category'),
            onTap: () {
              Navigator.pop(context);
              _showCategoryAssignDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off, color: Colors.orange),
            title: const Text('Make Private'),
            onTap: () {
              Navigator.pop(context);
              _performBulkUpdate({'isPublic': false});
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility, color: Colors.blue),
            title: const Text('Make Public'),
            onTap: () {
              Navigator.pop(context);
              _performBulkUpdate({'isPublic': true});
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Events'),
            onTap: () {
              Navigator.pop(context);
              _confirmBulkDelete();
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select the new status for selected events:'),
            const SizedBox(height: 16),
            ...['active', 'inactive', 'cancelled', 'postponed', 'draft'].map(
              (status) => ListTile(
                title: Text(status.toUpperCase()),
                onTap: () {
                  Navigator.pop(context);
                  _performBulkStatusChange(status);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryAssignDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a category for selected events:'),
            const SizedBox(height: 16),
            ...['art-show', 'workshop', 'exhibition', 'sale', 'other'].map(
              (category) => ListTile(
                title: Text(category.replaceAll('-', ' ').toUpperCase()),
                onTap: () {
                  Navigator.pop(context);
                  _performBulkCategoryAssign(category);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBulkDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete ${_selectedEventIds.length} events? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performBulkDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkUpdate(Map<String, dynamic> updates) async {
    await _performBulkOperation(
      'Update',
      () => _bulkService.bulkUpdateEvents(_selectedEventIds.toList(), updates),
    );
  }

  Future<void> _performBulkStatusChange(String status) async {
    await _performBulkOperation(
      'Status change',
      () => _bulkService.bulkStatusChange(_selectedEventIds.toList(), status),
    );
  }

  Future<void> _performBulkCategoryAssign(String category) async {
    await _performBulkOperation(
      'Category assignment',
      () =>
          _bulkService.bulkAssignCategory(_selectedEventIds.toList(), category),
    );
  }

  Future<void> _performBulkDelete() async {
    await _performBulkOperation(
      'Deletion',
      () => _bulkService.bulkDeleteEvents(_selectedEventIds.toList()),
      shouldReload: true,
    );
  }

  Future<void> _performBulkOperation(
    String operationName,
    Future<void> Function() operation, {
    bool shouldReload = false,
  }) async {
    setState(() {
      _isPerformingBulkOperation = true;
    });

    try {
      await operation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$operationName completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(_selectedEventIds.clear);

      if (shouldReload) {
        await _loadEvents();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during $operationName: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isPerformingBulkOperation = false;
      });
    }
  }
}
