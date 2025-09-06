import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/payment_analytics_service.dart';

/// Comprehensive payment analytics dashboard for financial insights and reporting
///
/// Provides visualizations for:
/// - Revenue trends and forecasting
/// - Payment method performance
/// - Customer segmentation and lifetime value
/// - Churn and retention analytics
/// - Financial KPIs and metrics
class PaymentAnalyticsDashboard extends StatefulWidget {
  const PaymentAnalyticsDashboard({Key? key}) : super(key: key);

  @override
  State<PaymentAnalyticsDashboard> createState() =>
      _PaymentAnalyticsDashboardState();
}

class _PaymentAnalyticsDashboardState extends State<PaymentAnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PaymentAnalyticsService _analyticsService = PaymentAnalyticsService();

  // Date range selection
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  // Analytics data
  Map<String, dynamic> _revenueAnalytics = {};
  List<Map<String, dynamic>> _paymentMethodAnalytics = [];
  Map<String, dynamic> _customerAnalytics = {};
  Map<String, dynamic> _forecastData = {};
  Map<String, dynamic> _retentionData = {};

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all analytics in parallel
      final futures = await Future.wait([
        _analyticsService.getRevenueAnalytics(
          startDate: _selectedDateRange.start,
          endDate: _selectedDateRange.end,
        ),
        _analyticsService.getPaymentMethodAnalytics(
          startDate: _selectedDateRange.start,
          endDate: _selectedDateRange.end,
        ),
        _analyticsService.getCustomerAnalytics(
          startDate: _selectedDateRange.start,
          endDate: _selectedDateRange.end,
        ),
        _analyticsService.getRevenueForecast(
          forecastDays: 30,
          historicalDays: 90,
        ),
        _analyticsService.getRetentionAnalytics(analysisMonths: 6),
      ]);

      if (mounted) {
        setState(() {
          _revenueAnalytics = futures[0] as Map<String, dynamic>;
          _paymentMethodAnalytics = futures[1] as List<Map<String, dynamic>>;
          _customerAnalytics = futures[2] as Map<String, dynamic>;
          _forecastData = futures[3] as Map<String, dynamic>;
          _retentionData = futures[4] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load analytics: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      await _loadAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Analytics'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.date_range),
            tooltip: 'Select Date Range',
          ),
          IconButton(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
            Tab(text: 'Revenue', icon: Icon(Icons.trending_up, size: 20)),
            Tab(text: 'Customers', icon: Icon(Icons.people, size: 20)),
            Tab(text: 'Forecast', icon: Icon(Icons.trending_up, size: 20)),
            Tab(text: 'Retention', icon: Icon(Icons.repeat, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : Column(
              children: [
                _buildDateRangeHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildRevenueTab(),
                      _buildCustomersTab(),
                      _buildForecastTab(),
                      _buildRetentionTab(),
                    ],
                  ),
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
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(_error!, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadAnalytics, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildDateRangeHeader() {
    final formatter = DateFormat('MMM dd, yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '${formatter.format(_selectedDateRange.start)} - ${formatter.format(_selectedDateRange.end)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          TextButton(
            onPressed: _selectDateRange,
            child: const Text('Change Period'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_revenueAnalytics.isEmpty) return _buildEmptyState();

    final netRevenue =
        (_revenueAnalytics['netRevenue'] as num?)?.toDouble() ?? 0.0;
    final totalTransactions =
        _revenueAnalytics['totalTransactions'] as int? ?? 0;
    final successRate =
        (_revenueAnalytics['successRate'] as num?)?.toDouble() ?? 0.0;
    final refundRate =
        (_revenueAnalytics['refundRate'] as num?)?.toDouble() ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKPICards(
            netRevenue,
            totalTransactions,
            successRate,
            refundRate,
          ),
          const SizedBox(height: 24),
          _buildPaymentMethodsOverview(),
          const SizedBox(height: 24),
          _buildTopCustomersOverview(),
        ],
      ),
    );
  }

  Widget _buildKPICards(
    double netRevenue,
    int totalTransactions,
    double successRate,
    double refundRate,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildKPICard(
          'Net Revenue',
          '\$${netRevenue.toStringAsFixed(2)}',
          Icons.monetization_on,
          Colors.green,
        ),
        _buildKPICard(
          'Transactions',
          totalTransactions.toString(),
          Icons.receipt,
          Colors.blue,
        ),
        _buildKPICard(
          'Success Rate',
          '${successRate.toStringAsFixed(1)}%',
          Icons.check_circle,
          Colors.teal,
        ),
        _buildKPICard(
          'Refund Rate',
          '${refundRate.toStringAsFixed(1)}%',
          Icons.undo,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
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
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsOverview() {
    if (_paymentMethodAnalytics.isEmpty) return Container();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Methods Performance',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...(_paymentMethodAnalytics
                .take(3)
                .map((method) => _buildPaymentMethodRow(method))),
            if (_paymentMethodAnalytics.length > 3)
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text('View All Methods'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodRow(Map<String, dynamic> method) {
    final methodName = method['method'] as String;
    final successRate = (method['successRate'] as num?)?.toDouble() ?? 0.0;
    final totalAmount = (method['successfulAmount'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildPaymentMethodIcon(methodName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatPaymentMethodName(methodName),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${successRate.toStringAsFixed(1)}% success rate',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '\$${totalAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodIcon(String method) {
    IconData icon;
    Color color;

    switch (method.toLowerCase()) {
      case 'card':
        icon = Icons.credit_card;
        color = Colors.blue;
        break;
      case 'apple_pay':
        icon = Icons.phone_android;
        color = Colors.black;
        break;
      case 'google_pay':
        icon = Icons.account_balance_wallet;
        color = Colors.green;
        break;
      case 'paypal':
        icon = Icons.paypal;
        color = Colors.blue;
        break;
      default:
        icon = Icons.payment;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatPaymentMethodName(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return 'Credit Card';
      case 'apple_pay':
        return 'Apple Pay';
      case 'google_pay':
        return 'Google Pay';
      case 'paypal':
        return 'PayPal';
      default:
        return method
            .split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  Widget _buildTopCustomersOverview() {
    final topCustomers =
        _customerAnalytics['topCustomers'] as List<dynamic>? ?? [];

    if (topCustomers.isEmpty) return Container();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Customers',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...(topCustomers
                .take(5)
                .map(
                  (customer) =>
                      _buildTopCustomerRow(customer as Map<String, dynamic>),
                )),
            if (topCustomers.length > 5)
              TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: const Text('View All Customers'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCustomerRow(Map<String, dynamic> customer) {
    final userId = customer['userId'] as String;
    final netSpent = (customer['netSpent'] as num?)?.toDouble() ?? 0.0;
    final transactionCount = customer['transactionCount'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo[100],
            child: Text(
              userId.substring(0, 2).toUpperCase(),
              style: TextStyle(
                color: Colors.indigo[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer ${userId.substring(0, 8)}...',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  '$transactionCount transactions',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '\$${netSpent.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    // Implementation for detailed revenue analytics
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Breakdown',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRevenueBreakdownCard(),
          const SizedBox(height: 24),
          _buildPaymentMethodAnalytics(),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdownCard() {
    final totalRevenue =
        (_revenueAnalytics['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final completedRevenue =
        (_revenueAnalytics['completedRevenue'] as num?)?.toDouble() ?? 0.0;
    final refundedAmount =
        (_revenueAnalytics['refundedAmount'] as num?)?.toDouble() ?? 0.0;
    final pendingRevenue =
        (_revenueAnalytics['pendingRevenue'] as num?)?.toDouble() ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRevenueItem('Total Revenue', totalRevenue, Colors.blue),
            const Divider(),
            _buildRevenueItem(
              'Completed Revenue',
              completedRevenue,
              Colors.green,
            ),
            const Divider(),
            _buildRevenueItem('Refunded Amount', refundedAmount, Colors.red),
            const Divider(),
            _buildRevenueItem('Pending Revenue', pendingRevenue, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueItem(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodAnalytics() {
    if (_paymentMethodAnalytics.isEmpty) return Container();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._paymentMethodAnalytics.map(
              (method) => _buildDetailedPaymentMethodRow(method),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedPaymentMethodRow(Map<String, dynamic> method) {
    final methodName = method['method'] as String;
    final totalTransactions = method['totalTransactions'] as int? ?? 0;
    final successfulTransactions =
        method['successfulTransactions'] as int? ?? 0;
    final successRate = (method['successRate'] as num?)?.toDouble() ?? 0.0;
    final totalAmount = (method['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final averageAmount = (method['averageAmount'] as num?)?.toDouble() ?? 0.0;

    return ExpansionTile(
      leading: _buildPaymentMethodIcon(methodName),
      title: Text(_formatPaymentMethodName(methodName)),
      subtitle: Text('${successRate.toStringAsFixed(1)}% success rate'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildDetailRow(
                'Total Transactions',
                totalTransactions.toString(),
              ),
              _buildDetailRow(
                'Successful Transactions',
                successfulTransactions.toString(),
              ),
              _buildDetailRow(
                'Total Amount',
                '\$${totalAmount.toStringAsFixed(2)}',
              ),
              _buildDetailRow(
                'Average Amount',
                '\$${averageAmount.toStringAsFixed(2)}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Analytics',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCustomerMetricsCard(),
          const SizedBox(height: 24),
          _buildCustomerSegmentationCard(),
        ],
      ),
    );
  }

  Widget _buildCustomerMetricsCard() {
    final totalCustomers = _customerAnalytics['totalCustomers'] as int? ?? 0;
    final repeatCustomerRate =
        (_customerAnalytics['repeatCustomerRate'] as num?)?.toDouble() ?? 0.0;
    final averageLifetimeValue =
        (_customerAnalytics['averageCustomerLifetimeValue'] as num?)
            ?.toDouble() ??
        0.0;
    final averageOrderValue =
        (_customerAnalytics['averageOrderValue'] as num?)?.toDouble() ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCustomerMetricRow(
              'Total Customers',
              totalCustomers.toString(),
              Icons.people,
            ),
            const Divider(),
            _buildCustomerMetricRow(
              'Repeat Rate',
              '${repeatCustomerRate.toStringAsFixed(1)}%',
              Icons.repeat,
            ),
            const Divider(),
            _buildCustomerMetricRow(
              'Avg. Lifetime Value',
              '\$${averageLifetimeValue.toStringAsFixed(2)}',
              Icons.trending_up,
            ),
            const Divider(),
            _buildCustomerMetricRow(
              'Avg. Order Value',
              '\$${averageOrderValue.toStringAsFixed(2)}',
              Icons.shopping_cart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSegmentationCard() {
    final segments =
        _customerAnalytics['customerSegments'] as Map<String, dynamic>? ?? {};

    if (segments.isEmpty) return Container();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Segments',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...segments.entries.map(
              (entry) => _buildSegmentRow(entry.key, entry.value as List),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentRow(String segmentName, List<dynamic> customers) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatSegmentName(segmentName),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Chip(
            label: Text(customers.length.toString()),
            backgroundColor: _getSegmentColor(segmentName).withOpacity(0.2),
            labelStyle: TextStyle(color: _getSegmentColor(segmentName)),
          ),
        ],
      ),
    );
  }

  String _formatSegmentName(String segmentName) {
    switch (segmentName) {
      case 'highValue':
        return 'High Value';
      case 'mediumValue':
        return 'Medium Value';
      case 'lowValue':
        return 'Low Value';
      case 'atRisk':
        return 'At Risk';
      case 'loyal':
        return 'Loyal';
      default:
        return segmentName;
    }
  }

  Color _getSegmentColor(String segmentName) {
    switch (segmentName) {
      case 'highValue':
        return Colors.green;
      case 'mediumValue':
        return Colors.blue;
      case 'lowValue':
        return Colors.orange;
      case 'atRisk':
        return Colors.red;
      case 'loyal':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildForecastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Forecast',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildForecastSummaryCard(),
          const SizedBox(height: 24),
          _buildForecastChartCard(),
        ],
      ),
    );
  }

  Widget _buildForecastSummaryCard() {
    final totalForecastRevenue =
        (_forecastData['totalForecastRevenue'] as num?)?.toDouble() ?? 0.0;
    final averageDailyRevenue =
        (_forecastData['averageDailyRevenue'] as num?)?.toDouble() ?? 0.0;
    final revenueGrowthTrend =
        (_forecastData['revenueGrowthTrend'] as num?)?.toDouble() ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildForecastMetricRow(
              '30-Day Forecast',
              '\$${totalForecastRevenue.toStringAsFixed(2)}',
            ),
            const Divider(),
            _buildForecastMetricRow(
              'Daily Average',
              '\$${averageDailyRevenue.toStringAsFixed(2)}',
            ),
            const Divider(),
            _buildForecastMetricRow(
              'Growth Trend',
              '${revenueGrowthTrend >= 0 ? '+' : ''}\$${revenueGrowthTrend.toStringAsFixed(2)}/day',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastChartCard() {
    final dailyForecast =
        _forecastData['dailyForecast'] as List<dynamic>? ?? [];

    if (dailyForecast.isEmpty) return Container();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Forecast (Next 30 Days)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Simple list view for now - could be replaced with actual chart
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: dailyForecast.length,
                itemBuilder: (context, index) {
                  final day = dailyForecast[index] as Map<String, dynamic>;
                  final date = day['date'] as String;
                  final revenue =
                      (day['predictedRevenue'] as num?)?.toDouble() ?? 0.0;
                  final confidence =
                      (day['confidence'] as num?)?.toDouble() ?? 0.0;

                  return ListTile(
                    title: Text(date),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${revenue.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${confidence.toStringAsFixed(0)}% confidence',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
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

  Widget _buildRetentionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Retention',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRetentionSummaryCard(),
          const SizedBox(height: 24),
          _buildMonthlyRetentionCard(),
        ],
      ),
    );
  }

  Widget _buildRetentionSummaryCard() {
    final averageRetentionRate =
        (_retentionData['averageRetentionRate'] as num?)?.toDouble() ?? 0.0;
    final averageChurnRate =
        (_retentionData['averageChurnRate'] as num?)?.toDouble() ?? 0.0;
    final retentionTrend =
        _retentionData['retentionTrend'] as String? ?? 'unknown';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRetentionMetricRow(
              'Average Retention',
              '${averageRetentionRate.toStringAsFixed(1)}%',
            ),
            const Divider(),
            _buildRetentionMetricRow(
              'Average Churn',
              '${averageChurnRate.toStringAsFixed(1)}%',
            ),
            const Divider(),
            _buildRetentionMetricRow(
              'Trend',
              _formatRetentionTrend(retentionTrend),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetentionMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRetentionTrend(String trend) {
    switch (trend) {
      case 'improving':
        return 'Improving ↗️';
      case 'declining':
        return 'Declining ↘️';
      case 'stable':
        return 'Stable →';
      default:
        return 'Unknown';
    }
  }

  Widget _buildMonthlyRetentionCard() {
    final monthlyRetention =
        _retentionData['monthlyRetention'] as List<dynamic>? ?? [];

    if (monthlyRetention.isEmpty) return Container();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Retention Rates',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...monthlyRetention.map(
              (month) =>
                  _buildMonthlyRetentionRow(month as Map<String, dynamic>),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyRetentionRow(Map<String, dynamic> month) {
    final monthName = month['month'] as String;
    final retentionRate = (month['retentionRate'] as num?)?.toDouble() ?? 0.0;
    final totalCustomers = month['totalCustomers'] as int? ?? 0;
    final churnedCustomers = month['churnedCustomers'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthName,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                '${retentionRate.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: retentionRate >= 70
                      ? Colors.green
                      : retentionRate >= 50
                      ? Colors.orange
                      : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '$totalCustomers customers, $churnedCustomers churned',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No analytics data available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Analytics will appear here once you have payment data',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
