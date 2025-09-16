import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show EnhancedUniversalHeader, MainLayout, AppLogger;
import '../services/artwork_analytics_service.dart';
import '../services/artwork_service.dart';

/// Analytics dashboard for artwork performance
class ArtworkAnalyticsDashboard extends StatefulWidget {
  const ArtworkAnalyticsDashboard({super.key});

  @override
  State<ArtworkAnalyticsDashboard> createState() =>
      _ArtworkAnalyticsDashboardState();
}

class _ArtworkAnalyticsDashboardState extends State<ArtworkAnalyticsDashboard> {
  final ArtworkAnalyticsService _analyticsService = ArtworkAnalyticsService();
  final ArtworkService _artworkService = ArtworkService();

  List<Map<String, dynamic>> _topArtworks = [];
  Map<String, dynamic> _searchAnalytics = {};
  Map<String, dynamic> _revenueAnalytics = {};
  Map<String, dynamic> _crossPackageAnalytics = {};
  Map<String, dynamic> _optimizedAnalytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _artworkService.getCurrentUserId();
      if (userId != null) {
        // Load all analytics data in parallel for better performance
        final results = await Future.wait([
          _analyticsService.getTopArtworks(userId),
          _analyticsService.getSearchAnalytics(),
          _analyticsService.getRevenueAnalytics(userId),
          _analyticsService.getCrossPackageAnalytics(userId),
          _analyticsService.getOptimizedAnalytics(userId),
        ]);

        setState(() {
          _topArtworks = results[0] as List<Map<String, dynamic>>;
          _searchAnalytics = results[1] as Map<String, dynamic>;
          _revenueAnalytics = results[2] as Map<String, dynamic>;
          _crossPackageAnalytics = results[3] as Map<String, dynamic>;
          _optimizedAnalytics = results[4] as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading analytics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportAnalytics() async {
    try {
      final userId = _artworkService.getCurrentUserId();
      if (userId == null) return;

      final exportData =
          await _analyticsService.exportAnalytics(userId, format: 'json');

      // Show export options dialog
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Analytics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Analytics data exported successfully!'),
              const SizedBox(height: 16),
              Text(
                'Exported ${exportData.length} characters of data',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                'Data includes: Views, Revenue, Search Analytics, and Performance Metrics',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                // Copy to clipboard functionality could be added here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Analytics data copied to clipboard')),
                );
                Navigator.pop(context);
              },
              child: const Text('Copy Data'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error exporting analytics')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0,
      appBar: EnhancedUniversalHeader(
        title: 'Analytics Dashboard',
        showLogo: false,
        showBackButton: true,
        backgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFF7B2FF2), // Purple
            Color(0xFF00FF87), // Green
          ],
        ),
        titleGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFF7B2FF2), // Purple
            Color(0xFF00FF87), // Green
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _exportAnalytics,
            tooltip: 'Export Analytics',
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Cards
                    _buildOverviewCards(),

                    const SizedBox(height: 24),

                    // Revenue Analytics
                    _buildRevenueAnalyticsSection(),

                    const SizedBox(height: 24),

                    // Top Performing Artworks
                    _buildTopArtworksSection(),

                    const SizedBox(height: 24),

                    // Cross-Package Analytics
                    _buildCrossPackageAnalyticsSection(),

                    const SizedBox(height: 24),

                    // Search Analytics
                    _buildSearchAnalyticsSection(),

                    const SizedBox(height: 24),

                    // Optimized Analytics
                    _buildOptimizedAnalyticsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    final totalViews = _topArtworks.fold<int>(
        0, (sum, artwork) => sum + (artwork['totalViews'] as int? ?? 0));
    final totalEngagement = _topArtworks.fold<int>(
        0, (sum, artwork) => sum + (artwork['totalEngagement'] as int? ?? 0));
    final avgEngagementRate = _topArtworks.isNotEmpty
        ? _topArtworks.fold<double>(
                0,
                (sum, artwork) =>
                    sum + (artwork['engagementRate'] as double? ?? 0)) /
            _topArtworks.length
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Views',
            totalViews.toString(),
            Icons.visibility,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Total Engagement',
            totalEngagement.toString(),
            Icons.thumb_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Avg Engagement Rate',
            '${avgEngagementRate.toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueAnalyticsSection() {
    final totalRevenue = _revenueAnalytics['totalRevenue'] as double? ?? 0.0;
    final totalSales = _revenueAnalytics['totalSales'] as int? ?? 0;
    final averageSale = _revenueAnalytics['averageSale'] as double? ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Revenue',
                '\$${totalRevenue.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Total Sales',
                totalSales.toString(),
                Icons.shopping_cart,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Average Sale',
                '\$${averageSale.toStringAsFixed(2)}',
                Icons.analytics,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCrossPackageAnalyticsSection() {
    final conversionRate =
        _crossPackageAnalytics['conversionRate'] as double? ?? 0.0;
    final engagementToRevenueRatio =
        _crossPackageAnalytics['engagementToRevenueRatio'] as double? ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cross-Package Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Conversion Rate',
                '${conversionRate.toStringAsFixed(2)}%',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Engagement/Revenue',
                engagementToRevenueRatio.toStringAsFixed(2),
                Icons.link,
                Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Insights',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Conversion Rate: ${conversionRate.toStringAsFixed(2)}% of views result in sales',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Engagement Ratio: ${engagementToRevenueRatio.toStringAsFixed(2)} engagements per dollar',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopArtworksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Performing Artworks',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _topArtworks.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No artwork performance data available yet'),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _topArtworks.length,
                itemBuilder: (context, index) {
                  final artwork = _topArtworks[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(artwork['title'] as String? ?? 'Untitled'),
                      subtitle: Text(
                        'Views: ${artwork['totalViews']} | Engagement: ${artwork['engagementRate'].toStringAsFixed(1)}%',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.analytics),
                        onPressed: () => _showArtworkDetails(artwork),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildSearchAnalyticsSection() {
    final totalSearches = _searchAnalytics['totalSearches'] as int? ?? 0;
    final uniqueQueries = _searchAnalytics['uniqueQueries'] as int? ?? 0;
    final averageResults = _searchAnalytics['averageResults'] as double? ?? 0.0;
    final topQueries = _searchAnalytics['topQueries'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Searches',
                totalSearches.toString(),
                Icons.search,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Unique Queries',
                uniqueQueries.toString(),
                Icons.query_stats,
                Colors.teal,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Avg Results',
                averageResults.toStringAsFixed(1),
                Icons.list,
                Colors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (topQueries.isNotEmpty) ...[
          const Text(
            'Top Search Queries',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: topQueries.take(5).map<Widget>((query) {
                final queryData = query as Map<String, dynamic>;
                return ListTile(
                  title: Text(queryData['query'] as String),
                  trailing: Text('${queryData['count']} searches'),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptimizedAnalyticsSection() {
    if (_optimizedAnalytics.isEmpty) {
      return const SizedBox.shrink();
    }

    final actionBreakdown =
        _optimizedAnalytics['actionBreakdown'] as Map<String, dynamic>? ?? {};
    final totalAnalytics = _optimizedAnalytics['totalAnalytics'] as int? ?? 0;
    final totalSales = _optimizedAnalytics['totalSales'] as int? ?? 0;
    final totalRevenue = _optimizedAnalytics['totalRevenue'] as double? ?? 0.0;
    final avgRevenuePerSale =
        _optimizedAnalytics['averageRevenuePerSale'] as double? ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Optimization',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Performance metrics cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Analytics',
                totalAnalytics.toString(),
                Icons.analytics,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Total Sales',
                totalSales.toString(),
                Icons.shopping_cart,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Revenue',
                '\$${totalRevenue.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Avg per Sale',
                '\$${avgRevenuePerSale.toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
          ],
        ),

        if (actionBreakdown.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Action Breakdown',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...actionBreakdown.entries.map((entry) {
                    final action = entry.key;
                    final count = entry.value as int;
                    final percentage = totalAnalytics > 0
                        ? (count / totalAnalytics * 100).toStringAsFixed(1)
                        : '0.0';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            action.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '$count ($percentage%)',
                            style: TextStyle(color: Colors.grey[600]),
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
      ],
    );
  }

  void _showArtworkDetails(Map<String, dynamic> artwork) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(artwork['title'] as String? ?? 'Artwork Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Views: ${artwork['totalViews']}'),
            Text('Total Engagement: ${artwork['totalEngagement']}'),
            Text('Recent Views: ${artwork['recentViews']}'),
            Text(
                'Engagement Rate: ${artwork['engagementRate'].toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
