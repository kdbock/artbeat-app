import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/content_review_model.dart';
import '../services/content_review_service.dart';
import '../widgets/admin_drawer.dart';

/// Enhanced Admin Content Review Screen with bulk operations and advanced filtering
///
/// Features:
/// - Support for all content types (ads, captures, posts, comments, artwork)
/// - Bulk selection and operations (approve, reject, delete)
/// - Advanced filtering and search
/// - Enhanced content preview
/// - Real-time updates
class EnhancedAdminContentReviewScreen extends StatefulWidget {
  const EnhancedAdminContentReviewScreen({super.key});

  @override
  State<EnhancedAdminContentReviewScreen> createState() =>
      _EnhancedAdminContentReviewScreenState();
}

class _EnhancedAdminContentReviewScreenState
    extends State<EnhancedAdminContentReviewScreen> {
  final ContentReviewService _contentReviewService = ContentReviewService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<ContentReviewModel> _pendingReviews = [];
  List<ContentReviewModel> _selectedReviews = [];
  bool _isLoading = true;
  bool _isBulkOperationInProgress = false;
  String? _error;

  // Filters
  ModerationFilters _filters = const ModerationFilters();
  bool _showAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    _loadPendingReviews();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == _filters.searchQuery) return;

      setState(() {
        _filters = _filters.copyWith(searchQuery: _searchController.text);
      });
      _loadPendingReviews();
    });
  }

  Future<void> _loadPendingReviews() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final reviews = await _contentReviewService.getPendingReviews(
        contentType: _filters.contentType,
        filters: _filters,
      );

      if (mounted) {
        setState(() {
          _pendingReviews = reviews;
          _selectedReviews.clear(); // Clear selection when reloading
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSelection(ContentReviewModel review) {
    setState(() {
      if (_selectedReviews.contains(review)) {
        _selectedReviews.remove(review);
      } else {
        _selectedReviews.add(review);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedReviews.length == _pendingReviews.length) {
        _selectedReviews.clear();
      } else {
        _selectedReviews = List.from(_pendingReviews);
      }
    });
  }

  Future<void> _approveContent(
      String contentId, ContentType contentType) async {
    try {
      await _contentReviewService.approveContent(contentId, contentType);
      await _loadPendingReviews();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve content: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectContent(
      String contentId, ContentType contentType, String reason) async {
    try {
      await _contentReviewService.rejectContent(contentId, contentType, reason);
      await _loadPendingReviews();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content rejected successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject content: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bulkApprove() async {
    if (_selectedReviews.isEmpty) return;

    final confirmed = await _showBulkConfirmationDialog(
      'Approve Selected Content',
      'Are you sure you want to approve ${_selectedReviews.length} selected items?',
      Colors.green,
    );

    if (confirmed == true) {
      setState(() => _isBulkOperationInProgress = true);

      try {
        await _contentReviewService.bulkApproveContent(_selectedReviews);
        await _loadPendingReviews();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${_selectedReviews.length} items approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to approve content: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isBulkOperationInProgress = false);
      }
    }
  }

  Future<void> _bulkReject() async {
    if (_selectedReviews.isEmpty) return;

    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Reject Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rejecting ${_selectedReviews.length} selected items.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
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
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                Navigator.of(context).pop(reason);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject All'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      setState(() => _isBulkOperationInProgress = true);

      try {
        await _contentReviewService.bulkRejectContent(_selectedReviews, reason);
        await _loadPendingReviews();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${_selectedReviews.length} items rejected successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject content: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isBulkOperationInProgress = false);
      }
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedReviews.isEmpty) return;

    final confirmed = await _showBulkConfirmationDialog(
      'Delete Selected Content',
      'Are you sure you want to permanently delete ${_selectedReviews.length} selected items? This action cannot be undone.',
      Colors.red,
    );

    if (confirmed == true) {
      setState(() => _isBulkOperationInProgress = true);

      try {
        await _contentReviewService.bulkDeleteContent(_selectedReviews);
        await _loadPendingReviews();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('${_selectedReviews.length} items deleted successfully'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete content: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isBulkOperationInProgress = false);
      }
    }
  }

  Future<bool?> _showBulkConfirmationDialog(
    String title,
    String message,
    Color color,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String contentId, ContentType contentType) {
    final TextEditingController reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
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
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                Navigator.of(context).pop();
                _rejectContent(contentId, contentType, reason);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showContentDetails(ContentReviewModel review) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
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
                    _buildContentTypeChip(review.contentType),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Content Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                      _buildDetailRow('Title', review.title),
                      _buildDetailRow('Description', review.description),
                      _buildDetailRow('Author', review.authorName),
                      _buildDetailRow('Status', review.status.displayName),
                      _buildDetailRow('Created', _formatDate(review.createdAt)),

                      // Content-specific metadata
                      if (review.metadata != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Additional Information:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...review.metadata!.entries.map((entry) {
                          if (entry.value != null) {
                            return _buildDetailRow(
                              _formatMetadataKey(entry.key),
                              entry.value.toString(),
                            );
                          }
                          return const SizedBox.shrink();
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showRejectDialog(review.contentId, review.contentType);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _approveContent(review.contentId, review.contentType);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                  ],
                ),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatMetadataKey(String key) {
    // Convert camelCase to Title Case
    return key
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        )
        .split(' ')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // Admin screens don't use bottom navigation
      scaffoldKey: _scaffoldKey,
      appBar: EnhancedUniversalHeader(
        title: 'Enhanced Content Review',
        showBackButton: true,
        showSearch: false, // We have our own search
        showDeveloperTools: true,
        actions: [
          if (_selectedReviews.isNotEmpty)
            IconButton(
              onPressed: () => setState(() => _selectedReviews.clear()),
              icon: const Icon(Icons.clear),
              tooltip: 'Clear Selection',
            ),
        ],
      ),
      drawer: const AdminDrawer(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchAndFilterBar(),
              if (_selectedReviews.isNotEmpty) _buildBulkActionBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorWidget()
                        : _buildContentList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search content, authors, or descriptions...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _filters = _filters.copyWith(searchQuery: '');
                        });
                        _loadPendingReviews();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          // Filter row
          Row(
            children: [
              // Content type filter
              Expanded(
                child: DropdownButtonFormField<ContentType>(
                  initialValue: _filters.contentType,
                  decoration: const InputDecoration(
                    labelText: 'Content Type',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<ContentType>(
                      value: null,
                      child: Text(
                        'All',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                    ),
                    ...ContentType.values
                        .where((type) => type != ContentType.all)
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[800]),
                              ),
                            ))
                        .toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filters = _filters.copyWith(contentType: value);
                    });
                    _loadPendingReviews();
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Status filter
              Expanded(
                child: DropdownButtonFormField<ReviewStatus>(
                  initialValue: _filters.status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<ReviewStatus>(
                      value: null,
                      child: Text(
                        'All',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                    ),
                    ...ReviewStatus.values
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[800]),
                              ),
                            ))
                        .toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filters = _filters.copyWith(status: value);
                    });
                    _loadPendingReviews();
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Advanced filters toggle
              IconButton(
                onPressed: () {
                  setState(() {
                    _showAdvancedFilters = !_showAdvancedFilters;
                  });
                },
                icon: Icon(
                  _showAdvancedFilters
                      ? Icons.filter_list
                      : Icons.filter_list_off,
                ),
                tooltip: 'Advanced Filters',
              ),

              // Refresh button
              IconButton(
                onPressed: _loadPendingReviews,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),

          // Advanced filters (collapsible)
          if (_showAdvancedFilters) ...[
            const SizedBox(height: 12),
            _buildAdvancedFilters(),
          ],

          // Active filters indicator
          if (_filters.hasActiveFilters) ...[
            const SizedBox(height: 8),
            _buildActiveFiltersChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Advanced Filters',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Date from
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'From Date',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filters.dateFrom ??
                          DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _filters = _filters.copyWith(dateFrom: date);
                      });
                      _loadPendingReviews();
                    }
                  },
                  controller: TextEditingController(
                    text: _filters.dateFrom?.toString().split(' ')[0] ?? '',
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Date to
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'To Date',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filters.dateTo ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _filters = _filters.copyWith(dateTo: date);
                      });
                      _loadPendingReviews();
                    }
                  },
                  controller: TextEditingController(
                    text: _filters.dateTo?.toString().split(' ')[0] ?? '',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Clear filters button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _filters = const ModerationFilters();
                  _searchController.clear();
                });
                _loadPendingReviews();
              },
              child: const Text('Clear All Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    final chips = <Widget>[];

    if (_filters.contentType != null) {
      chips.add(_buildFilterChip(
        'Type: ${_filters.contentType!.displayName}',
        () {
          setState(() {
            _filters = _filters.copyWith(contentType: null);
          });
          _loadPendingReviews();
        },
      ));
    }

    if (_filters.status != null) {
      chips.add(_buildFilterChip(
        'Status: ${_filters.status!.displayName}',
        () {
          setState(() {
            _filters = _filters.copyWith(status: null);
          });
          _loadPendingReviews();
        },
      ));
    }

    if (_filters.searchQuery != null && _filters.searchQuery!.isNotEmpty) {
      chips.add(_buildFilterChip(
        'Search: "${_filters.searchQuery}"',
        () {
          _searchController.clear();
          setState(() {
            _filters = _filters.copyWith(searchQuery: '');
          });
          _loadPendingReviews();
        },
      ));
    }

    if (_filters.dateFrom != null) {
      chips.add(_buildFilterChip(
        'From: ${_filters.dateFrom!.toString().split(' ')[0]}',
        () {
          setState(() {
            _filters = _filters.copyWith(dateFrom: null);
          });
          _loadPendingReviews();
        },
      ));
    }

    if (_filters.dateTo != null) {
      chips.add(_buildFilterChip(
        'To: ${_filters.dateTo!.toString().split(' ')[0]}',
        () {
          setState(() {
            _filters = _filters.copyWith(dateTo: null);
          });
          _loadPendingReviews();
        },
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          'Active Filters (${_filters.activeFilterCount}):',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        ...chips,
      ],
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildBulkActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedReviews.length} selected',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          if (_isBulkOperationInProgress)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            TextButton.icon(
              onPressed: _bulkApprove,
              icon: const Icon(Icons.check, color: Colors.green),
              label: const Text('Approve All'),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _bulkReject,
              icon: const Icon(Icons.close, color: Colors.orange),
              label: const Text('Reject All'),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _bulkDelete,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Delete All'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading content',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPendingReviews,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    if (_pendingReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No pending reviews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              _filters.hasActiveFilters
                  ? 'No content matches your current filters'
                  : 'All content has been reviewed',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (_filters.hasActiveFilters) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _filters = const ModerationFilters();
                    _searchController.clear();
                  });
                  _loadPendingReviews();
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        // Select all header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: _selectedReviews.length == _pendingReviews.length &&
                    _pendingReviews.isNotEmpty,
                tristate: true,
                onChanged: (_) => _selectAll(),
              ),
              Text(
                'Select All (${_pendingReviews.length} items)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                '${_selectedReviews.length} selected',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Content list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _pendingReviews.length,
            itemBuilder: (context, index) {
              final review = _pendingReviews[index];
              final isSelected = _selectedReviews.contains(review);
              return _buildEnhancedContentCard(review, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedContentCard(ContentReviewModel review, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
          : null,
      child: InkWell(
        onTap: () => _showContentDetails(review),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(review),
                  ),
                  const SizedBox(width: 8),
                  _buildContentTypeChip(review.contentType),
                  const Spacer(),
                  Text(
                    _formatDate(review.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Content preview
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content image (if available)
                  if (review.metadata?['imageUrl'] != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        review.metadata!['imageUrl'] as String,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.error),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Content details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          review.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'By ${review.authorName}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 16),
                            _buildStatusChip(review.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: TextButton.icon(
                      onPressed: () => _showContentDetails(review),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: TextButton(
                      onPressed: () => _showRejectDialog(
                        review.contentId,
                        review.contentType,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () => _approveContent(
                        review.contentId,
                        review.contentType,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentTypeChip(ContentType type) {
    Color color;
    IconData icon;

    switch (type) {
      case ContentType.ads:
        color = Colors.purple;
        icon = Icons.campaign;
        break;
      case ContentType.captures:
        color = Colors.blue;
        icon = Icons.camera_alt;
        break;
      case ContentType.posts:
        color = Colors.green;
        icon = Icons.article;
        break;
      case ContentType.comments:
        color = Colors.orange;
        icon = Icons.comment;
        break;
      case ContentType.artwork:
        color = Colors.red;
        icon = Icons.palette;
        break;
      case ContentType.all:
        color = Colors.grey;
        icon = Icons.all_inclusive;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            type.displayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ReviewStatus status) {
    Color color;
    switch (status) {
      case ReviewStatus.pending:
        color = Colors.orange;
        break;
      case ReviewStatus.approved:
        color = Colors.green;
        break;
      case ReviewStatus.rejected:
        color = Colors.red;
        break;
      case ReviewStatus.flagged:
        color = Colors.purple;
        break;
      case ReviewStatus.underReview:
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
