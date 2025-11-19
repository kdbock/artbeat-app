import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../models/commission_analytics_model.dart'
    show ArtistCommissionAnalytics;
import '../../services/commission_analytics_service.dart';
import 'package:artbeat_core/artbeat_core.dart' hide NumberFormat;

class CommissionAnalyticsDashboard extends StatefulWidget {
  final String artistId;

  const CommissionAnalyticsDashboard({Key? key, required this.artistId})
    : super(key: key);

  @override
  State<CommissionAnalyticsDashboard> createState() =>
      _CommissionAnalyticsDashboardState();
}

class _CommissionAnalyticsDashboardState
    extends State<CommissionAnalyticsDashboard> {
  late CommissionAnalyticsService _analyticsService;
  ArtistCommissionAnalytics? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _analyticsService = CommissionAnalyticsService();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await _analyticsService.getArtistAnalytics(
        widget.artistId,
      );
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_analytics == null) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 48 + 4),
          child: Container(
            decoration: const BoxDecoration(
              gradient: ArtbeatColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: AppBar(title: const Text('Commission Analytics')),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No analytics data available yet'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAnalytics,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    final formatter = intl.NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48 + 4),
        child: Container(
          decoration: const BoxDecoration(
            gradient: ArtbeatColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            title: const Text('Commission Analytics'),
            elevation: 0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStatCard(
                  title: 'Total Commissions',
                  value: '${_analytics!.totalCommissions}',
                  icon: Icons.work,
                  color: Colors.blue,
                ),
                _buildStatCard(
                  title: 'Completed',
                  value: '${_analytics!.completedCommissions}',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _buildStatCard(
                  title: 'Active',
                  value: '${_analytics!.activeCommissions}',
                  icon: Icons.hourglass_top,
                  color: Colors.orange,
                ),
                _buildStatCard(
                  title: 'Total Earnings',
                  value: formatter.format(_analytics!.totalEarnings),
                  icon: Icons.attach_money,
                  color: Colors.deepPurple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Key Metrics
            _buildSection(
              title: 'Key Metrics',
              children: [
                _buildMetricRow(
                  label: 'Average Rating',
                  value: '${_analytics!.averageRating.toStringAsFixed(1)} ⭐',
                ),
                _buildMetricRow(
                  label: 'Completion Rate',
                  value:
                      '${(_analytics!.completionRate * 100).toStringAsFixed(1)}%',
                ),
                _buildMetricRow(
                  label: 'Acceptance Rate',
                  value:
                      '${(_analytics!.acceptanceRate * 100).toStringAsFixed(1)}%',
                ),
                _buildMetricRow(
                  label: 'Avg Turnaround',
                  value:
                      '${_analytics!.averageTurnaroundDays.toStringAsFixed(1)} days',
                ),
                _buildMetricRow(
                  label: 'Repeat Clients',
                  value: '${_analytics!.returningClients}',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Commission Types
            if (_analytics!.commissionsByType.isNotEmpty)
              _buildSection(
                title: 'Commissions by Type',
                children: [
                  ..._analytics!.commissionsByType.entries.map((e) {
                    final earnings = _analytics!.earningsByType[e.key] ?? 0.0;
                    return Column(
                      children: [
                        _buildMetricRow(
                          label: e.key.toUpperCase(),
                          value: '${e.value} (${formatter.format(earnings)})',
                        ),
                        const Divider(height: 16),
                      ],
                    );
                  }).toList(),
                ],
              ),
            const SizedBox(height: 24),

            // Financial Summary
            _buildSection(
              title: 'Financial Summary',
              children: [
                _buildMetricRow(
                  label: 'Average Commission Value',
                  value: formatter.format(_analytics!.averageCommissionValue),
                ),
                _buildMetricRow(
                  label: 'Estimated Earnings',
                  value: formatter.format(_analytics!.estimatedEarnings),
                ),
                _buildMetricRow(
                  label: 'Total Refunded',
                  value: formatter.format(_analytics!.totalRefunded),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Client Metrics
            _buildSection(
              title: 'Client Metrics',
              children: [
                _buildMetricRow(
                  label: 'Unique Clients',
                  value: '${_analytics!.uniqueClients}',
                ),
                _buildMetricRow(
                  label: 'Returning Clients',
                  value: '${_analytics!.returningClients}',
                ),
                if (_analytics!.returningClients > 0)
                  _buildMetricRow(
                    label: 'Repeat Client Rate',
                    value:
                        '${((_analytics!.returningClients / _analytics!.uniqueClients) * 100).toStringAsFixed(1)}%',
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Quality Metrics
            _buildSection(
              title: 'Quality Metrics',
              children: [
                _buildMetricRow(
                  label: 'On-Time Deliveries',
                  value: '${_analytics!.onTimeDeliveryCount}',
                ),
                _buildMetricRow(
                  label: 'Late Deliveries',
                  value: '${_analytics!.lateDeliveryCount}',
                ),
                _buildMetricRow(
                  label: 'Ratings Received',
                  value: '${_analytics!.ratingsCount}',
                ),
                _buildMetricRow(
                  label: 'Disputes',
                  value: '${_analytics!.disputesCount}',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Refresh Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadAnalytics,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Analytics'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMetricRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
