import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/analytics_model.dart';
import '../services/enhanced_analytics_service.dart';
import '../widgets/admin_drawer.dart';

/// Admin Financial Analytics Screen
///
/// Provides comprehensive financial analytics and insights including:
/// - Revenue tracking and forecasting
/// - Subscription analytics
/// - Commission tracking
/// - Financial KPIs and trends
class AdminFinancialAnalyticsScreen extends StatefulWidget {
  const AdminFinancialAnalyticsScreen({super.key});

  @override
  State<AdminFinancialAnalyticsScreen> createState() =>
      _AdminFinancialAnalyticsScreenState();
}

class _AdminFinancialAnalyticsScreenState
    extends State<AdminFinancialAnalyticsScreen> {
  final EnhancedAnalyticsService _analyticsService = EnhancedAnalyticsService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  AnalyticsModel? _analytics;
  bool _isLoading = true;
  String? _error;
  DateRange _selectedDateRange = DateRange.last30Days;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final analytics = await _analyticsService.getEnhancedAnalytics(
        dateRange: _selectedDateRange,
      );

      if (mounted) {
        setState(() {
          _analytics = analytics;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AdminDrawer(),
      appBar: const EnhancedUniversalHeader(
        title: 'Financial Analytics',
        showBackButton: true,
        showSearch: true,
        showDeveloperTools: true,
      ),
      body: Container(
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
              _buildDateRangeSelector(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorWidget()
                        : _buildFinancialContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('Time Period: '),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<DateRange>(
              value: _selectedDateRange,
              isExpanded: true,
              items: DateRange.values
                  .map((range) => DropdownMenuItem(
                        value: range,
                        child: Text(range.displayName),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedDateRange = value;
                  });
                  _loadAnalytics();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh),
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
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading financial analytics',
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
            onPressed: _loadAnalytics,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialContent() {
    if (_analytics == null) {
      return const Center(child: Text('No financial data available'));
    }

    final financial = _analytics!.financialMetrics;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRevenueOverview(financial),
          const SizedBox(height: 24),
          _buildRevenueBreakdown(financial),
          const SizedBox(height: 24),
          _buildFinancialKPIs(financial),
          const SizedBox(height: 24),
          _buildRevenueChart(financial),
          const SizedBox(height: 24),
          _buildTransactionMetrics(financial),
        ],
      ),
    );
  }

  Widget _buildRevenueOverview(FinancialMetrics financial) {
    return _buildSection(
      title: 'Revenue Overview',
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildFinancialCard(
              'Total Revenue',
              _formatCurrency(financial.totalRevenue),
              Icons.attach_money,
              Colors.green,
              changeValue: financial.revenueGrowth,
            ),
            _buildFinancialCard(
              'Monthly Recurring Revenue',
              _formatCurrency(financial.monthlyRecurringRevenue),
              Icons.repeat,
              Colors.blue,
              changeValue: financial.subscriptionGrowth,
            ),
            _buildFinancialCard(
              'Average Revenue Per User',
              _formatCurrency(financial.averageRevenuePerUser),
              Icons.person_outline,
              Colors.orange,
            ),
            _buildFinancialCard(
              'Customer Lifetime Value',
              _formatCurrency(financial.lifetimeValue),
              Icons.trending_up,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueBreakdown(FinancialMetrics financial) {
    return _buildSection(
      title: 'Revenue Breakdown',
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildFinancialCard(
              'Subscription Revenue',
              _formatCurrency(financial.subscriptionRevenue),
              Icons.subscriptions,
              Colors.indigo,
              changeValue: financial.subscriptionGrowth,
            ),
            _buildFinancialCard(
              'Event Revenue',
              _formatCurrency(financial.eventRevenue),
              Icons.event,
              Colors.teal,
            ),
            _buildFinancialCard(
              'Commission Revenue',
              _formatCurrency(financial.commissionRevenue),
              Icons.percent,
              Colors.amber,
              changeValue: financial.commissionGrowth,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialKPIs(FinancialMetrics financial) {
    return _buildSection(
      title: 'Key Performance Indicators',
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildFinancialCard(
              'Churn Rate',
              '${financial.churnRate.toStringAsFixed(1)}%',
              Icons.trending_down,
              Colors.red,
            ),
            _buildFinancialCard(
              'Total Transactions',
              financial.totalTransactions.toString(),
              Icons.receipt,
              Colors.cyan,
            ),
            _buildFinancialCard(
              'Revenue Growth',
              '${financial.revenueGrowth.toStringAsFixed(1)}%',
              Icons.show_chart,
              financial.revenueGrowth >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueChart(FinancialMetrics financial) {
    return _buildSection(
      title: 'Revenue Trends',
      children: [
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: financial.revenueTimeSeries.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No revenue data available for chart'),
                    ],
                  ),
                )
              : _buildSimpleChart(financial.revenueTimeSeries),
        ),
      ],
    );
  }

  Widget _buildSimpleChart(List<RevenueDataPoint> data) {
    // Simple chart representation - in a real app, use a charting library like fl_chart
    return Column(
      children: [
        const Text('Revenue Over Time',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final point = data[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${point.date.month}/${point.date.day}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(point.category),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            _formatCurrency(point.amount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionMetrics(FinancialMetrics financial) {
    return _buildSection(
      title: 'Transaction Analysis',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenue by Category',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ...financial.revenueByCategory.entries.map((entry) {
                  final percentage = financial.totalRevenue > 0
                      ? (entry.value / financial.totalRevenue) * 100
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(entry.key),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          _formatCurrency(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildFinancialCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    double? changeValue,
  }) {
    return Card(
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              textAlign: TextAlign.center,
            ),
            if (changeValue != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    changeValue >= 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 16,
                    color: changeValue >= 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${changeValue.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: changeValue >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'subscriptions':
        return Colors.indigo;
      case 'events':
        return Colors.teal;
      case 'commissions':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(2)}';
    }
  }
}
