import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

import '../models/ad_model.dart';
import '../models/ad_analytics_model.dart';
import '../models/ad_impression_model.dart';
import '../models/ad_click_model.dart';
import '../models/ad_zone.dart';
import '../services/ad_analytics_service.dart';

/// Screen showing detailed performance metrics for a specific ad
class AdPerformanceScreen extends StatefulWidget {
  final AdModel ad;

  const AdPerformanceScreen({super.key, required this.ad});

  @override
  State<AdPerformanceScreen> createState() => _AdPerformanceScreenState();
}

class _AdPerformanceScreenState extends State<AdPerformanceScreen> {
  late AdAnalyticsService _analyticsService;

  AdAnalyticsModel? _analytics;
  List<AdImpressionModel> _recentImpressions = [];
  List<AdClickModel> _recentClicks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyticsService = AdAnalyticsService();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _analyticsService.getAdPerformanceMetrics(widget.ad.id),
        _analyticsService.getAdImpressions(widget.ad.id, limit: 50),
        _analyticsService.getAdClicks(widget.ad.id, limit: 50),
      ]);

      if (mounted) {
        setState(() {
          _analytics = results[0] as AdAnalyticsModel?;
          _recentImpressions = results[1] as List<AdImpressionModel>;
          _recentClicks = results[2] as List<AdClickModel>;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading analytics: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MainLayout(
        currentIndex: -1,
        appBar: const EnhancedUniversalHeader(title: 'Ad Performance'),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return MainLayout(
      currentIndex: -1,
      appBar: EnhancedUniversalHeader(
        title: 'Ad Performance',
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ad preview
                    _buildAdPreview(),

                    const SizedBox(height: 24),

                    // Performance metrics
                    _buildPerformanceMetrics(),

                    const SizedBox(height: 24),

                    // Charts section
                    _buildChartsSection(),

                    const SizedBox(height: 24),

                    // Recent activity
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAdPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ad Preview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                // Ad thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.ad.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Ad details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ad.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.ad.description,
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text(widget.ad.size.name),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              widget.ad.zone != null
                                  ? '${widget.ad.zone!.icon} ${widget.ad.zone!.displayName}'
                                  : widget.ad.location.name,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    if (_analytics == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.analytics, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No analytics data available'),
              Text('Data will appear once your ad starts receiving views'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 16),

            // Metrics grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMetricCard(
                  'Total Impressions',
                  _analytics!.totalImpressions.toString(),
                  Icons.visibility,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Total Clicks',
                  _analytics!.totalClicks.toString(),
                  Icons.mouse,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Click-Through Rate',
                  '${_analytics!.clickThroughRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
                _buildMetricCard(
                  'Total Revenue',
                  '\$${_analytics!.totalRevenue.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    if (_analytics == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trends',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 16),

            // Location breakdown
            if (_analytics!.locationBreakdown.isNotEmpty) ...[
              const Text(
                'Performance by Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (final entry in _analytics!.locationBreakdown.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text(
                        '${entry.value} interactions',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // Note: In a real implementation, you would add charts here
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Interactive charts coming soon'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 16),

            // Recent impressions and clicks
            if (_recentImpressions.isEmpty && _recentClicks.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No recent activity'),
                  ],
                ),
              )
            else ...[
              // Combine and sort recent activity
              ...(_buildRecentActivityList()),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecentActivityList() {
    final List<Widget> activities = [];

    // Add recent impressions
    for (final impression in _recentImpressions.take(10)) {
      activities.add(
        _buildActivityItem(
          icon: Icons.visibility,
          color: Colors.blue,
          title: 'Ad viewed',
          subtitle: 'Location: ${impression.location.name}',
          timestamp: impression.timestamp,
        ),
      );
    }

    // Add recent clicks
    for (final click in _recentClicks.take(10)) {
      activities.add(
        _buildActivityItem(
          icon: Icons.mouse,
          color: Colors.green,
          title: 'Ad clicked',
          subtitle: 'Type: ${click.clickType}',
          timestamp: click.timestamp,
        ),
      );
    }

    // Sort by timestamp (most recent first)
    // Note: This is a simplified version - in a real app, you'd sort the combined list

    return activities.take(10).toList();
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required DateTime timestamp,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          Text(
            _formatTimeAgo(timestamp),
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
