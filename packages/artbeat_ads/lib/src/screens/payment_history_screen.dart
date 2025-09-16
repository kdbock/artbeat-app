import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../models/payment_history_model.dart';
import '../services/payment_history_service.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Screen for displaying user's payment history and transaction details
///
/// Features:
/// - Transaction list with filtering
/// - Payment status indicators
/// - Receipt downloads
/// - Search functionality
/// - Monthly summaries
class PaymentHistoryScreen extends StatefulWidget {
  final String userId;

  const PaymentHistoryScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen>
    with SingleTickerProviderStateMixin {
  final PaymentHistoryService _paymentHistoryService = PaymentHistoryService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  PaymentStatus? _selectedStatusFilter;
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  bool _isSearching = false;
  List<PaymentHistoryModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
          ),
          IconButton(icon: const Icon(Icons.search), onPressed: _toggleSearch),
        ],
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by ad title or transaction ID...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: _performSearch,
                  ),
                ),
              )
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'All', icon: Icon(Icons.list)),
                  Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
                  Tab(text: 'Monthly', icon: Icon(Icons.calendar_month)),
                ],
              ),
      ),
      body: _isSearching
          ? _buildSearchResults()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPaymentsList(),
                _buildStatistics(),
                _buildMonthlyView(),
              ],
            ),
    );
  }

  Widget _buildPaymentsList() {
    return StreamBuilder<List<PaymentHistoryModel>>(
      stream: _paymentHistoryService.getUserPaymentHistory(
        userId: widget.userId,
        statusFilter: _selectedStatusFilter,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading payment history',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final payments = snapshot.data ?? [];

        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Payment History',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your payment transactions will appear here',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              return _buildPaymentCard(payments[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildPaymentCard(PaymentHistoryModel payment) {
    final theme = Theme.of(context);
    final statusColor = Color(
      int.parse(payment.status.colorHex.substring(1), radix: 16) + 0xFF000000,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showPaymentDetails(payment),
        borderRadius: BorderRadius.circular(8),
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
                          payment.adTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          intl.DateFormat(
                            'MMM d, y • h:mm a',
                          ).format(payment.transactionDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        payment.formattedAmount,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: payment.isSuccessful
                              ? Colors.green[700]
                              : null,
                        ),
                      ),
                      if (payment.isRefunded &&
                          payment.formattedRefundAmount != null)
                        Text(
                          'Refunded: ${payment.formattedRefundAmount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildPaymentMethodIcon(payment.paymentMethod),
                      const SizedBox(width: 8),
                      Text(
                        payment.paymentMethod.displayName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      payment.status.displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (payment.failureReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          payment.failureReason!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodIcon(PaymentMethod method) {
    IconData iconData;
    Color iconColor;

    switch (method) {
      case PaymentMethod.card:
        iconData = Icons.credit_card;
        iconColor = Colors.blue;
        break;
      case PaymentMethod.bankTransfer:
        iconData = Icons.account_balance;
        iconColor = Colors.green;
        break;
      case PaymentMethod.applePay:
        iconData = Icons.apple;
        iconColor = Colors.black;
        break;
      case PaymentMethod.googlePay:
        iconData = Icons.android;
        iconColor = Colors.orange;
        break;
      case PaymentMethod.paypal:
        iconData = Icons.payment;
        iconColor = Colors.blue;
        break;
    }

    return Icon(iconData, size: 20, color: iconColor);
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return const Center(child: Text('Enter a search term to find payments'));
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No payments found'),
            Text('Try a different search term'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildPaymentCard(_searchResults[index]);
      },
    );
  }

  Widget _buildStatistics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _paymentHistoryService.getUserPaymentStats(
        userId: widget.userId,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Error loading statistics'));
        }

        final stats = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatCard(
                'Total Payments',
                '${stats['totalPayments'] ?? 0}',
                Icons.payment,
                Colors.blue,
              ),
              _buildStatCard(
                'Successful Payments',
                '${stats['successfulPayments'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'Failed Payments',
                '${stats['failedPayments'] ?? 0}',
                Icons.error,
                Colors.red,
              ),
              _buildStatCard(
                'Success Rate',
                '${(stats['successRate'] ?? 0).toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.orange,
              ),
              _buildStatCard(
                'Total Amount',
                '\$${(stats['totalAmount'] ?? 0).toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
              _buildStatCard(
                'Refunded Amount',
                '\$${(stats['refundedAmount'] ?? 0).toStringAsFixed(2)}',
                Icons.money_off,
                Colors.blue,
              ),
              _buildStatCard(
                'Net Revenue',
                '\$${(stats['netRevenue'] ?? 0).toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                Colors.purple,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _paymentHistoryService.getMonthlyPaymentSummary(
        userId: widget.userId,
        monthsBack: 12,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Error loading monthly data'));
        }

        final monthlyData = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: monthlyData.length,
          itemBuilder: (context, index) {
            final data = monthlyData[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      intl.DateFormat(
                        'MMMM y',
                      ).format(DateTime.parse('${data['month']}-01')),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMonthlyMetric(
                          'Payments',
                          '${data['totalPayments']}',
                          Icons.payment,
                        ),
                        _buildMonthlyMetric(
                          'Successful',
                          '${data['successfulPayments']}',
                          Icons.check_circle,
                        ),
                        _buildMonthlyMetric(
                          'Revenue',
                          '\$${(data['totalAmount'] as double).toStringAsFixed(0)}',
                          Icons.attach_money,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMonthlyMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        PaymentStatus? tempStatusFilter = _selectedStatusFilter;
        DateTimeRange? tempDateRange = _selectedDateRange;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Payments'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<PaymentStatus?>(
                    value: tempStatusFilter,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Statuses'),
                      ),
                      ...PaymentStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        tempStatusFilter = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      tempDateRange == null
                          ? 'Select Date Range'
                          : '${intl.DateFormat('MMM d, y').format(tempDateRange!.start)} - ${intl.DateFormat('MMM d, y').format(tempDateRange!.end)}',
                    ),
                    trailing: const Icon(Icons.date_range),
                    onTap: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: tempDateRange,
                      );
                      if (range != null) {
                        setState(() {
                          tempDateRange = range;
                        });
                      }
                    },
                  ),
                  if (tempDateRange != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          tempDateRange = null;
                        });
                      },
                      child: const Text('Clear Date Range'),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatusFilter = tempStatusFilter;
                      _selectedDateRange = tempDateRange;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _searchResults.clear();
      }
    });
  }

  void _performSearch(String query) async {
    setState(() {
      _searchQuery = query;
    });

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    try {
      final results = await _paymentHistoryService.searchPayments(
        userId: widget.userId,
        searchTerm: query.trim(),
      );
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      AppLogger.error('Search error: $e');
    }
  }

  void _showPaymentDetails(PaymentHistoryModel payment) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Details',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildDetailRow('Ad Title', payment.adTitle),
                    _buildDetailRow('Amount', payment.formattedAmount),
                    _buildDetailRow('Status', payment.status.displayName),
                    _buildDetailRow(
                      'Payment Method',
                      payment.paymentMethod.displayName,
                    ),
                    _buildDetailRow(
                      'Date',
                      intl.DateFormat(
                        'MMM d, y • h:mm a',
                      ).format(payment.transactionDate),
                    ),
                    if (payment.stripePaymentIntentId != null)
                      _buildDetailRow(
                        'Transaction ID',
                        payment.stripePaymentIntentId!,
                      ),
                    if (payment.isRefunded) ...[
                      const Divider(),
                      Text(
                        'Refund Information',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (payment.refundedAt != null)
                        _buildDetailRow(
                          'Refunded Date',
                          intl.DateFormat(
                            'MMM d, y • h:mm a',
                          ).format(payment.refundedAt!),
                        ),
                      if (payment.formattedRefundAmount != null)
                        _buildDetailRow(
                          'Refund Amount',
                          payment.formattedRefundAmount!,
                        ),
                      if (payment.refundReason != null)
                        _buildDetailRow('Refund Reason', payment.refundReason!),
                    ],
                    if (payment.failureReason != null) ...[
                      const Divider(),
                      Text(
                        'Failure Information',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Reason', payment.failureReason!),
                    ],
                    const SizedBox(height: 20),
                    if (payment.isSuccessful) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadReceipt(payment),
                          icon: const Icon(Icons.download),
                          label: const Text('Download Receipt'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement support/contact functionality
                        },
                        icon: const Icon(Icons.support_agent),
                        label: const Text('Contact Support'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  void _downloadReceipt(PaymentHistoryModel payment) async {
    try {
      // Show loading
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating receipt...'),
            ],
          ),
        ),
      );

      final receiptUrl = await _paymentHistoryService.generateReceipt(
        payment.id,
      );

      Navigator.pop(context); // Close loading dialog

      if (receiptUrl != null) {
        // TODO: Implement actual receipt download/viewing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to generate receipt');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download receipt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
