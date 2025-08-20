import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../services/capture_service.dart';

/// Admin screen for moderating pending captures
class AdminContentModerationScreen extends StatefulWidget {
  const AdminContentModerationScreen({Key? key}) : super(key: key);

  @override
  State<AdminContentModerationScreen> createState() =>
      _AdminContentModerationScreenState();
}

class _AdminContentModerationScreenState
    extends State<AdminContentModerationScreen> {
  final CaptureService _captureService = CaptureService();
  List<core.CaptureModel> _pendingCaptures = [];
  bool _loading = true;
  String _selectedTab = 'pending';

  @override
  void initState() {
    super.initState();
    _loadPendingCaptures();
  }

  Future<void> _loadPendingCaptures() async {
    setState(() => _loading = true);

    try {
      final captures = await _captureService.getPendingCaptures(limit: 50);
      if (mounted) {
        setState(() {
          _pendingCaptures = captures;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading captures: $e')));
      }
    }
  }

  Future<void> _loadCapturesByStatus(String status) async {
    setState(() => _loading = true);

    try {
      List<core.CaptureModel> captures;
      if (status == 'pending') {
        captures = await _captureService.getPendingCaptures(limit: 50);
      } else {
        captures = await _captureService.getCapturesByStatus(status, limit: 50);
      }

      if (mounted) {
        setState(() {
          _pendingCaptures = captures;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading captures: $e')));
      }
    }
  }

  Future<void> _approveCapture(core.CaptureModel capture) async {
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Approve Capture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Are you sure you want to approve this capture?'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Moderation Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await _captureService.approveCapture(
        capture.id,
        moderationNotes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Capture approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCapturesByStatus(_selectedTab);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to approve capture'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectCapture(core.CaptureModel capture) async {
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Capture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Are you sure you want to reject this capture?'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Reason for rejection (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await _captureService.rejectCapture(
        capture.id,
        moderationNotes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Capture rejected'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadCapturesByStatus(_selectedTab);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reject capture'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteCapture(core.CaptureModel capture) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Capture'),
          content: const Text(
            'Are you sure you want to permanently delete this capture? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await _captureService.adminDeleteCapture(capture.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Capture deleted permanently'),
              backgroundColor: Colors.red,
            ),
          );
          _loadCapturesByStatus(_selectedTab);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete capture'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _viewCaptureDetails(core.CaptureModel capture) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'Capture Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              capture.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.error, size: 48),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Details
                        _buildDetailRow('Title', capture.title ?? 'No title'),
                        _buildDetailRow('Status', capture.status.displayName),
                        if (capture.artistName != null)
                          _buildDetailRow('Artist', capture.artistName!),
                        if (capture.artType != null)
                          _buildDetailRow('Art Type', capture.artType!),
                        if (capture.artMedium != null)
                          _buildDetailRow('Medium', capture.artMedium!),
                        if (capture.description != null)
                          _buildDetailRow('Description', capture.description!),
                        if (capture.locationName != null)
                          _buildDetailRow('Location', capture.locationName!),
                        _buildDetailRow(
                          'Created',
                          capture.createdAt.toString(),
                        ),
                        if (capture.moderationNotes != null)
                          _buildDetailRow(
                            'Moderation Notes',
                            capture.moderationNotes!,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: core.EnhancedUniversalHeader(
        title: 'Content Moderation',
        showLogo: false,
        showBackButton: true,
        onMenuPressed: () {
          // Open the drawer if available
          if (Scaffold.of(context).hasDrawer) {
            Scaffold.of(context).openDrawer();
          }
        },
        onBackPressed: () {
          Navigator.of(context).pop();
        },
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'pending',
                        label: Text('Pending'),
                        icon: Icon(Icons.schedule),
                      ),
                      ButtonSegment(
                        value: 'approved',
                        label: Text('Approved'),
                        icon: Icon(Icons.check_circle),
                      ),
                      ButtonSegment(
                        value: 'rejected',
                        label: Text('Rejected'),
                        icon: Icon(Icons.cancel),
                      ),
                    ],
                    selected: {_selectedTab},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedTab = newSelection.first;
                      });
                      _loadCapturesByStatus(_selectedTab);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => _loadCapturesByStatus(_selectedTab),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _pendingCaptures.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedTab == 'pending'
                              ? Icons.schedule
                              : _selectedTab == 'approved'
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${_selectedTab} captures found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'All caught up!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingCaptures.length,
                    itemBuilder: (context, index) {
                      final capture = _pendingCaptures[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Image thumbnail
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    capture.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.error),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      capture.title ?? 'Untitled',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (capture.artistName != null)
                                      Text('Artist: ${capture.artistName!}'),
                                    if (capture.artType != null)
                                      Text('Type: ${capture.artType!}'),
                                    Text(
                                      'Created: ${capture.createdAt.toLocal().toString().split(' ')[0]}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            capture.status ==
                                                core.CaptureStatus.pending
                                            ? Colors.orange.shade100
                                            : capture.status ==
                                                  core.CaptureStatus.approved
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        capture.status.displayName,
                                        style: TextStyle(
                                          color:
                                              capture.status ==
                                                  core.CaptureStatus.pending
                                              ? Colors.orange.shade800
                                              : capture.status ==
                                                    core.CaptureStatus.approved
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Actions
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _viewCaptureDetails(capture),
                                    icon: const Icon(Icons.visibility),
                                    tooltip: 'View Details',
                                  ),
                                  if (_selectedTab == 'pending') ...[
                                    IconButton(
                                      onPressed: () => _approveCapture(capture),
                                      icon: const Icon(Icons.check_circle),
                                      color: Colors.green,
                                      tooltip: 'Approve',
                                    ),
                                    IconButton(
                                      onPressed: () => _rejectCapture(capture),
                                      icon: const Icon(Icons.cancel),
                                      color: Colors.orange,
                                      tooltip: 'Reject',
                                    ),
                                  ],
                                  IconButton(
                                    onPressed: () => _deleteCapture(capture),
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
