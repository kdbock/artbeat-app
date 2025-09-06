import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/refund_request_model.dart';
import '../services/refund_service.dart';

/// Administrative interface for managing refund requests
///
/// Provides comprehensive refund management including:
/// - View and filter refund requests by status and priority
/// - Process refund approvals and rejections
/// - Add administrative notes and tracking
/// - View refund history and statistics
/// - Export refund data for accounting
class RefundManagementScreen extends StatefulWidget {
  const RefundManagementScreen({Key? key}) : super(key: key);

  @override
  State<RefundManagementScreen> createState() => _RefundManagementScreenState();
}

class _RefundManagementScreenState extends State<RefundManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RefundService _refundService = RefundService();

  // Filters
  RefundStatus? _selectedStatus;
  RefundPriority? _selectedPriority;
  String _searchQuery = '';

  // Data
  List<RefundRequestModel> _allRefunds = [];
  List<RefundRequestModel> _filteredRefunds = [];
  Map<String, dynamic> _statistics = {};

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRefunds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRefunds() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final refundsStream = _refundService.getAllRefundRequests();
      final stats = await _refundService.getRefundStatistics();

      // Get the first batch of refunds from stream
      final refunds = await refundsStream.first;

      if (mounted) {
        setState(() {
          _allRefunds = refunds;
          _statistics = stats;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load refunds: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    _filteredRefunds = _allRefunds.where((refund) {
      final bool matchesStatus =
          _selectedStatus == null || refund.status == _selectedStatus;
      final bool matchesPriority =
          _selectedPriority == null || refund.priority == _selectedPriority;
      final bool matchesSearch =
          _searchQuery.isEmpty ||
          refund.paymentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          refund.reason.toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          refund.description.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesStatus && matchesPriority && matchesSearch;
    }).toList();

    // Sort by priority and creation date
    _filteredRefunds.sort((a, b) {
      final int priorityComparison =
          _getPriorityWeight(b.priority) - _getPriorityWeight(a.priority);
      if (priorityComparison != 0) return priorityComparison;
      return b.requestedAt.compareTo(a.requestedAt);
    });
  }

  int _getPriorityWeight(RefundPriority priority) {
    switch (priority) {
      case RefundPriority.urgent:
        return 4;
      case RefundPriority.high:
        return 3;
      case RefundPriority.normal:
        return 2;
      case RefundPriority.low:
        return 1;
    }
  }

  Future<void> _processRefund(RefundRequestModel refund, bool approve) async {
    try {
      if (approve) {
        await _refundService.approveRefundRequest(
          refundId: refund.id,
          adminId: 'admin_user',
          approvedAmount: refund.requestedAmount,
        );
      } else {
        final reason = await _showRejectionDialog();
        if (reason != null) {
          await _refundService.rejectRefundRequest(
            refundId: refund.id,
            adminId: 'admin_user',
            adminNotes: reason,
          );
        }
      }

      await _loadRefunds();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? 'Refund approved successfully'
                  : 'Refund rejected successfully',
            ),
            backgroundColor: approve ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing refund: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showRejectionDialog() async {
    String rejectionReason = '';

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Refund'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejecting this refund:'),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => rejectionReason = value,
                decoration: const InputDecoration(
                  hintText: 'Enter rejection reason...',
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
              onPressed: () =>
                  Navigator.of(context).pop(rejectionReason.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refund Management'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadRefunds,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Requests', icon: Icon(Icons.list, size: 20)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : TabBarView(
              controller: _tabController,
              children: [_buildRequestsTab(), _buildStatisticsTab()],
            ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(_error!, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadRefunds, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    return Column(
      children: [
        _buildFiltersSection(),
        Expanded(
          child: _filteredRefunds.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredRefunds.length,
                  itemBuilder: (context, index) {
                    return _buildRefundCard(_filteredRefunds[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by payment ID, reason, or notes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          Row(
            children: [
              Expanded(child: _buildStatusFilter()),
              const SizedBox(width: 12),
              Expanded(child: _buildPriorityFilter()),
            ],
          ),
          const SizedBox(height: 8),
          // Results count
          Row(
            children: [
              Text(
                'Showing ${_filteredRefunds.length} of ${_allRefunds.length} requests',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const Spacer(),
              if (_selectedStatus != null ||
                  _selectedPriority != null ||
                  _searchQuery.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = null;
                      _selectedPriority = null;
                      _searchQuery = '';
                      _applyFilters();
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<RefundStatus?>(
      value: _selectedStatus,
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<RefundStatus?>(
          value: null,
          child: Text('All Statuses'),
        ),
        ...RefundStatus.values.map(
          (status) => DropdownMenuItem<RefundStatus?>(
            value: status,
            child: Text(_formatStatus(status)),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedStatus = value;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildPriorityFilter() {
    return DropdownButtonFormField<RefundPriority?>(
      value: _selectedPriority,
      decoration: const InputDecoration(
        labelText: 'Priority',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<RefundPriority?>(
          value: null,
          child: Text('All Priorities'),
        ),
        ...RefundPriority.values.map(
          (priority) => DropdownMenuItem<RefundPriority?>(
            value: priority,
            child: Text(_formatPriority(priority)),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedPriority = value;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildRefundCard(RefundRequestModel refund) {
    final isActionable =
        refund.status == RefundStatus.pending ||
        refund.status == RefundStatus.underReview;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and priority
            Row(
              children: [
                _buildStatusChip(refund.status),
                const SizedBox(width: 8),
                _buildPriorityChip(refund.priority),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(refund.requestedAt),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Payment and amount info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment ID',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        refund.paymentId,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Refund Amount',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                    Text(
                      '\$${refund.requestedAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Reason
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatReason(refund.reason),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

            // Customer note
            if (refund.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Note',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      refund.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],

            // Admin notes
            if (refund.adminNotes?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Notes',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      refund.adminNotes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],

            // Action buttons
            if (isActionable) ...[
              const SizedBox(height: 16),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _processRefund(refund, false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange[700],
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _processRefund(refund, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(RefundStatus status) {
    Color color;
    final String label = _formatStatus(status);

    switch (status) {
      case RefundStatus.pending:
        color = Colors.orange;
        break;
      case RefundStatus.underReview:
        color = Colors.blue;
        break;
      case RefundStatus.approved:
        color = Colors.green;
        break;
      case RefundStatus.rejected:
        color = Colors.red;
        break;
      case RefundStatus.completed:
        color = Colors.teal;
        break;
      case RefundStatus.processing:
        color = Colors.blue;
        break;
      case RefundStatus.failed:
        color = Colors.red;
        break;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: Color.fromRGBO(color.red, color.green, color.blue, 1.0),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPriorityChip(RefundPriority priority) {
    Color color;
    final String label = _formatPriority(priority);

    switch (priority) {
      case RefundPriority.low:
        color = Colors.grey;
        break;
      case RefundPriority.normal:
        color = Colors.orange;
        break;
      case RefundPriority.high:
        color = Colors.red;
        break;
      case RefundPriority.urgent:
        color = Colors.red;
        break;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: Color.fromRGBO(color.red, color.green, color.blue, 1.0),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_statistics.isEmpty) return _buildEmptyState();

    final totalRequests = _statistics['totalRequests'] as int? ?? 0;
    final totalRefundAmount =
        (_statistics['totalRefundAmount'] as num?)?.toDouble() ?? 0.0;
    final averageRefundAmount =
        (_statistics['averageRefundAmount'] as num?)?.toDouble() ?? 0.0;
    final statusBreakdown =
        _statistics['statusBreakdown'] as Map<String, dynamic>? ?? {};
    final monthlyStats =
        _statistics['monthlyRefundSummary'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Refund Statistics',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Overview cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Total Requests',
                totalRequests.toString(),
                Icons.list,
              ),
              _buildStatCard(
                'Total Amount',
                '\$${totalRefundAmount.toStringAsFixed(2)}',
                Icons.monetization_on,
              ),
              _buildStatCard(
                'Average Amount',
                '\$${averageRefundAmount.toStringAsFixed(2)}',
                Icons.calculate,
              ),
              _buildStatCard(
                'Processing Rate',
                _calculateProcessingRate(),
                Icons.trending_up,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Status breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requests by Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...statusBreakdown.entries.map(
                    (entry) =>
                        _buildStatusBreakdownRow(entry.key, entry.value as int),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Monthly summary
          if (monthlyStats.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Refund Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...monthlyStats.map(
                      (monthData) => _buildMonthlyStatsRow(
                        monthData as Map<String, dynamic>,
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

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.indigo, size: 24),
                const Spacer(),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBreakdownRow(String status, int count) {
    final total = _statistics['totalRequests'] as int? ?? 1;
    final percentage = (count / total) * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatStatus(
                RefundStatus.values.firstWhere(
                  (s) => s.toString().split('.').last == status,
                  orElse: () => RefundStatus.pending,
                ),
              ),
            ),
          ),
          Text('$count (${percentage.toStringAsFixed(1)}%)'),
        ],
      ),
    );
  }

  Widget _buildMonthlyStatsRow(Map<String, dynamic> monthData) {
    final month = monthData['month'] as String;
    final requestCount = monthData['requestCount'] as int;
    final totalAmount = (monthData['totalAmount'] as num).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(month)),
          Text('$requestCount requests'),
          const SizedBox(width: 16),
          Text('\$${totalAmount.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  String _calculateProcessingRate() {
    final total = _statistics['totalRequests'] as int? ?? 0;
    final statusBreakdown =
        _statistics['statusBreakdown'] as Map<String, dynamic>? ?? {};

    final processed =
        (statusBreakdown['approved'] as int? ?? 0) +
        (statusBreakdown['rejected'] as int? ?? 0) +
        (statusBreakdown['processed'] as int? ?? 0);

    final rate = total > 0 ? (processed / total) * 100 : 0.0;
    return '${rate.toStringAsFixed(1)}%';
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No refund requests found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Refund requests will appear here when customers submit them',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatStatus(RefundStatus status) {
    switch (status) {
      case RefundStatus.pending:
        return 'Pending';
      case RefundStatus.underReview:
        return 'Under Review';
      case RefundStatus.approved:
        return 'Approved';
      case RefundStatus.rejected:
        return 'Rejected';
      case RefundStatus.processing:
        return 'Processing';
      case RefundStatus.completed:
        return 'Completed';
      case RefundStatus.failed:
        return 'Failed';
    }
  }

  String _formatPriority(RefundPriority priority) {
    switch (priority) {
      case RefundPriority.low:
        return 'Low';
      case RefundPriority.normal:
        return 'Normal';
      case RefundPriority.high:
        return 'High';
      case RefundPriority.urgent:
        return 'Urgent';
    }
  }

  String _formatReason(RefundReason reason) {
    switch (reason) {
      case RefundReason.adNotDisplayed:
        return 'Ad Not Displayed';
      case RefundReason.technicalIssue:
        return 'Technical Issue';
      case RefundReason.unauthorizedCharge:
        return 'Unauthorized Charge';
      case RefundReason.serviceNotProvided:
        return 'Service Not Provided';
      case RefundReason.qualityIssue:
        return 'Quality Issue';
      case RefundReason.changeOfMind:
        return 'Change of Mind';
      case RefundReason.duplicate:
        return 'Duplicate Charge';
      case RefundReason.fraudulent:
        return 'Fraudulent Transaction';
      case RefundReason.other:
        return 'Other';
    }
  }
}
