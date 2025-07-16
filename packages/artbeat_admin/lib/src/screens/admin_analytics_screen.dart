import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';
import '../models/analytics_model.dart';
import '../services/analytics_service.dart';

/// Admin Analytics Screen
///
/// Provides comprehensive analytics and insights for administrators
/// including user engagement, content performance, and system metrics.
class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
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

      final analytics = await _analyticsService.getAnalytics(
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
    return MainLayout(
      currentIndex: 0,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        drawer: const ArtbeatDrawer(),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 4),
          child: ArtbeatGradientBackground(
            addShadow: true,
            child: EnhancedUniversalHeader(
              title: 'Analytics',
              showLogo: false,
              showSearch: false,
              showDeveloperTools: true,
              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              backgroundColor: Colors.transparent,
              foregroundColor: ArtbeatColors.textPrimary,
              elevation: 0,
            ),
          ),
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
                          : _buildAnalyticsContent(),
                ),
              ],
            ),
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
            'Error loading analytics',
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

  Widget _buildAnalyticsContent() {
    if (_analytics == null) {
      return const Center(child: Text('No analytics data available'));
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserMetrics(),
          const SizedBox(height: 24),
          _buildContentMetrics(),
          const SizedBox(height: 24),
          _buildEngagementMetrics(),
          const SizedBox(height: 24),
          _buildTechnicalMetrics(),
          const SizedBox(height: 24),
          _buildTopContent(),
        ],
      ),
    );
  }

  Widget _buildUserMetrics() {
    return _buildSection(
      title: 'User Metrics',
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildMetricCard(
              'Total Users',
              _analytics!.totalUsers.toString(),
              Icons.people,
              Colors.blue,
              changeValue: _analytics!.userGrowth,
            ),
            _buildMetricCard(
              'Active Users',
              _analytics!.activeUsers.toString(),
              Icons.person,
              Colors.green,
              changeValue: _analytics!.activeUserGrowth,
            ),
            _buildMetricCard(
              'New Users',
              _analytics!.newUsers.toString(),
              Icons.person_add,
              Colors.orange,
              changeValue: _analytics!.newUserGrowth,
            ),
            _buildMetricCard(
              'Retention Rate',
              '${_analytics!.retentionRate.toStringAsFixed(1)}%',
              Icons.loyalty,
              Colors.purple,
              changeValue: _analytics!.retentionChange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentMetrics() {
    return _buildSection(
      title: 'Content Metrics',
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildMetricCard(
              'Total Artworks',
              _analytics!.totalArtworks.toString(),
              Icons.image,
              Colors.red,
              changeValue: _analytics!.artworkGrowth,
            ),
            _buildMetricCard(
              'Total Posts',
              _analytics!.totalPosts.toString(),
              Icons.post_add,
              Colors.teal,
              changeValue: _analytics!.postGrowth,
            ),
            _buildMetricCard(
              'Total Comments',
              _analytics!.totalComments.toString(),
              Icons.comment,
              Colors.indigo,
              changeValue: _analytics!.commentGrowth,
            ),
            _buildMetricCard(
              'Total Events',
              _analytics!.totalEvents.toString(),
              Icons.event,
              Colors.pink,
              changeValue: _analytics!.eventGrowth,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEngagementMetrics() {
    return _buildSection(
      title: 'Engagement Metrics',
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildMetricCard(
              'Avg. Session Time',
              _formatDuration(_analytics!.avgSessionDuration),
              Icons.access_time,
              Colors.cyan,
              changeValue: _analytics!.sessionDurationChange,
            ),
            _buildMetricCard(
              'Page Views',
              _analytics!.pageViews.toString(),
              Icons.visibility,
              Colors.amber,
              changeValue: _analytics!.pageViewGrowth,
            ),
            _buildMetricCard(
              'Bounce Rate',
              '${_analytics!.bounceRate.toStringAsFixed(1)}%',
              Icons.exit_to_app,
              Colors.red,
              changeValue: _analytics!.bounceRateChange,
            ),
            _buildMetricCard(
              'Likes',
              _analytics!.totalLikes.toString(),
              Icons.favorite,
              Colors.pink,
              changeValue: _analytics!.likeGrowth,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTechnicalMetrics() {
    return _buildSection(
      title: 'Technical Metrics',
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildMetricCard(
              'Error Rate',
              '${_analytics!.errorRate.toStringAsFixed(2)}%',
              Icons.error_outline,
              Colors.red,
              changeValue: _analytics!.errorRateChange,
            ),
            _buildMetricCard(
              'API Response Time',
              '${_analytics!.avgResponseTime.toStringAsFixed(0)}ms',
              Icons.speed,
              Colors.green,
              changeValue: _analytics!.responseTimeChange,
            ),
            _buildMetricCard(
              'Storage Used',
              _formatBytes(_analytics!.storageUsed),
              Icons.storage,
              Colors.orange,
              changeValue: _analytics!.storageGrowth,
            ),
            _buildMetricCard(
              'Bandwidth',
              _formatBytes(_analytics!.bandwidthUsed),
              Icons.network_check,
              Colors.purple,
              changeValue: _analytics!.bandwidthChange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopContent() {
    return _buildSection(
      title: 'Top Content',
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _analytics!.topContent.length,
          itemBuilder: (context, index) {
            final content = _analytics!.topContent[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getContentTypeColor(content.type),
                  child: Icon(
                    _getContentTypeIcon(content.type),
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  content.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle:
                    Text('${content.views} views • ${content.likes} likes'),
                trailing: Text(
                  content.type.charAt(0).toUpperCase() +
                      content.type.substring(1),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            );
          },
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

  Widget _buildMetricCard(
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

  Color _getContentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'artwork':
        return Colors.blue;
      case 'post':
        return Colors.green;
      case 'event':
        return Colors.orange;
      case 'comment':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getContentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'artwork':
        return Icons.image;
      case 'post':
        return Icons.post_add;
      case 'event':
        return Icons.event;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDuration(double seconds) {
    if (seconds < 60) {
      return '${seconds.toInt()}s';
    } else if (seconds < 3600) {
      return '${(seconds / 60).toStringAsFixed(1)}m';
    } else {
      return '${(seconds / 3600).toStringAsFixed(1)}h';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }
}

extension StringExtension on String {
  String charAt(int index) => this[index];
}
