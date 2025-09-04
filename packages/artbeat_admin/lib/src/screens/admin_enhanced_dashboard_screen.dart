import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/analytics_model.dart';
import '../models/recent_activity_model.dart';
import '../services/recent_activity_service.dart';
import '../services/enhanced_analytics_service.dart';
import '../widgets/admin_drawer.dart';

/// Enhanced Admin Dashboard with comprehensive analytics and real-time metrics
///
/// Features:
/// - Real-time financial metrics
/// - User engagement analytics
/// - Content performance tracking
/// - Advanced KPIs and forecasting
/// - Industry-standard analytics dashboard
class AdminEnhancedDashboardScreen extends StatefulWidget {
  const AdminEnhancedDashboardScreen({super.key});

  @override
  State<AdminEnhancedDashboardScreen> createState() =>
      _AdminEnhancedDashboardScreenState();
}

class _AdminEnhancedDashboardScreenState
    extends State<AdminEnhancedDashboardScreen> with TickerProviderStateMixin {
  final RecentActivityService _activityService = RecentActivityService();
  final EnhancedAnalyticsService _analyticsService = EnhancedAnalyticsService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TabController _tabController;

  AnalyticsModel? _analytics;
  List<RecentActivityModel> _recentActivities = [];
  bool _isLoading = true;
  bool _isLoadingActivities = true;
  bool _isLoadingAnalytics = true;
  bool _isUsingFallbackData = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null; // Clear any previous errors
      });
    }

    try {
      await Future.wait([
        _loadRecentActivities(),
        _loadAnalytics(),
      ]).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (mounted) {
            setState(() {
              _error = 'Loading timed out. Please try again.';
            });
          }
          return <void>[];
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load dashboard data: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      setState(() {
        _isLoadingActivities = true;
      });

      final activities = await _activityService.getRecentActivities(limit: 10);

      if (mounted) {
        setState(() {
          _recentActivities = activities;
          _isLoadingActivities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingActivities = false;
          _error = 'Failed to load recent activities: $e';
        });
      }
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() {
        _isLoadingAnalytics = true;
      });

      final analytics = await _analyticsService.getEnhancedAnalytics(
        dateRange: DateRange.last30Days,
      );

      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoadingAnalytics = false;
          // Check if we're using fallback data (simplified metrics)
          _isUsingFallbackData = analytics.userGrowth == 0.0 &&
              analytics.artworkGrowth == 0.0 &&
              analytics.newUsers == 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAnalytics = false;
          _error = 'Failed to load analytics: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // Admin screens don't use bottom navigation
      scaffoldKey: _scaffoldKey,
      appBar: const EnhancedUniversalHeader(
        title: 'Enhanced Dashboard',
        showBackButton: false,
        showSearch: true,
        showDeveloperTools: true,
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
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildFinancialTab(),
                    _buildUserAnalyticsTab(),
                    _buildContentAnalyticsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
          Tab(text: 'Financial', icon: Icon(Icons.attach_money, size: 20)),
          Tab(text: 'Users', icon: Icon(Icons.people, size: 20)),
          Tab(text: 'Content', icon: Icon(Icons.content_copy, size: 20)),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isUsingFallbackData) _buildFallbackBanner(),
            _buildKPIOverview(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
            const SizedBox(height: 24),
            _buildSystemHealth(),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialTab() {
    if (_isLoadingAnalytics) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_analytics == null) {
      return const Center(child: Text('No financial data available'));
    }

    final financial = _analytics!.financialMetrics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFinancialOverview(financial),
          const SizedBox(height: 24),
          _buildRevenueBreakdown(financial),
          const SizedBox(height: 24),
          _buildFinancialTrends(financial),
        ],
      ),
    );
  }

  Widget _buildUserAnalyticsTab() {
    if (_isLoadingAnalytics) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_analytics == null) {
      return const Center(child: Text('No user analytics available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserMetrics(),
          const SizedBox(height: 24),
          _buildUserGeography(),
          const SizedBox(height: 24),
          _buildUserJourneys(),
          const SizedBox(height: 24),
          _buildConversionFunnels(),
        ],
      ),
    );
  }

  Widget _buildContentAnalyticsTab() {
    if (_isLoadingAnalytics) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_analytics == null) {
      return const Center(child: Text('No content analytics available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentMetrics(),
          const SizedBox(height: 24),
          _buildTopContent(),
          const SizedBox(height: 24),
          _buildEngagementMetrics(),
        ],
      ),
    );
  }

  Widget _buildKPIOverview() {
    return _buildSection(
      title: 'Key Performance Indicators',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildKPICard(
                  'Total Revenue',
                  _analytics?.financialMetrics != null
                      ? _formatCurrency(
                          _analytics!.financialMetrics.totalRevenue)
                      : '\$0',
                  Icons.attach_money,
                  Colors.green,
                  changeValue: _analytics != null
                      ? _analytics!.financialMetrics.revenueGrowth
                      : null,
                ),
                _buildKPICard(
                  'Active Users',
                  _analytics?.activeUsers.toString() ?? '0',
                  Icons.people,
                  Colors.blue,
                  changeValue: _analytics?.activeUserGrowth,
                ),
                _buildKPICard(
                  'Total Content',
                  (_analytics != null
                          ? (_analytics!.totalArtworks +
                              _analytics!.totalPosts +
                              _analytics!.totalEvents)
                          : 0)
                      .toString(),
                  Icons.content_copy,
                  Colors.orange,
                ),
                _buildKPICard(
                  'Engagement Rate',
                  _analytics != null
                      ? '${(100 - _analytics!.bounceRate).toStringAsFixed(1)}%'
                      : '0%',
                  Icons.favorite,
                  Colors.pink,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFinancialOverview(FinancialMetrics financial) {
    return _buildSection(
      title: 'Financial Overview',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildKPICard(
                  'Monthly Recurring Revenue',
                  _formatCurrency(financial.monthlyRecurringRevenue),
                  Icons.repeat,
                  Colors.indigo,
                  changeValue: financial.subscriptionGrowth,
                ),
                _buildKPICard(
                  'Average Revenue Per User',
                  _formatCurrency(financial.averageRevenuePerUser),
                  Icons.person_outline,
                  Colors.teal,
                ),
                _buildKPICard(
                  'Customer Lifetime Value',
                  _formatCurrency(financial.lifetimeValue),
                  Icons.trending_up,
                  Colors.purple,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRevenueBreakdown(FinancialMetrics financial) {
    return _buildSection(
      title: 'Revenue Sources',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: financial.revenueByCategory.entries.map((entry) {
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialTrends(FinancialMetrics financial) {
    return _buildSection(
      title: 'Financial Trends',
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Churn Rate',
                '${financial.churnRate.toStringAsFixed(1)}%',
                Icons.trending_down,
                Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                'Total Transactions',
                financial.totalTransactions.toString(),
                Icons.receipt,
                Colors.cyan,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserMetrics() {
    return _buildSection(
      title: 'User Analytics',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildKPICard(
                  'Total Users',
                  _analytics?.totalUsers.toString() ?? '0',
                  Icons.people,
                  Colors.blue,
                  changeValue: _analytics?.userGrowth,
                ),
                _buildKPICard(
                  'New Users',
                  _analytics?.newUsers.toString() ?? '0',
                  Icons.person_add,
                  Colors.green,
                  changeValue: _analytics?.newUserGrowth,
                ),
                _buildKPICard(
                  'Retention Rate',
                  _analytics != null
                      ? '${_analytics!.retentionRate.toStringAsFixed(1)}%'
                      : '0%',
                  Icons.loyalty,
                  Colors.purple,
                  changeValue: _analytics?.retentionChange,
                ),
                _buildKPICard(
                  'Avg Session Time',
                  _analytics != null
                      ? _formatDuration(_analytics!.avgSessionDuration)
                      : '0s',
                  Icons.access_time,
                  Colors.orange,
                  changeValue: _analytics?.sessionDurationChange,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildUserGeography() {
    if (_analytics == null || _analytics!.usersByCountry.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Users by Country',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _analytics!.usersByCountry.entries
                  .take(5)
                  .map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(entry.key)),
                            Text(
                              entry.value.toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserJourneys() {
    if (_analytics == null || _analytics!.topUserJourneys.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Top User Journeys',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _analytics!.topUserJourneys
                  .take(5)
                  .map((journey) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(journey.stepName)),
                            Text('${journey.userCount} users'),
                            const SizedBox(width: 16),
                            Text(
                              '${journey.conversionRate.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: journey.conversionRate > 50
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversionFunnels() {
    if (_analytics == null || _analytics!.conversionFunnels.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Conversion Funnels',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _analytics!.conversionFunnels.entries
                  .map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(entry.key)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: entry.value > 50
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${entry.value.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: entry.value > 50
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentMetrics() {
    return _buildSection(
      title: 'Content Analytics',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildKPICard(
                  'Total Artworks',
                  _analytics?.totalArtworks.toString() ?? '0',
                  Icons.image,
                  Colors.red,
                  changeValue: _analytics?.artworkGrowth,
                ),
                _buildKPICard(
                  'Total Posts',
                  _analytics?.totalPosts.toString() ?? '0',
                  Icons.post_add,
                  Colors.teal,
                  changeValue: _analytics?.postGrowth,
                ),
                _buildKPICard(
                  'Total Comments',
                  _analytics?.totalComments.toString() ?? '0',
                  Icons.comment,
                  Colors.indigo,
                  changeValue: _analytics?.commentGrowth,
                ),
                _buildKPICard(
                  'Total Events',
                  _analytics?.totalEvents.toString() ?? '0',
                  Icons.event,
                  Colors.pink,
                  changeValue: _analytics?.eventGrowth,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopContent() {
    if (_analytics == null || _analytics!.topContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Top Performing Content',
      children: [
        Card(
          child: Column(
            children: _analytics!.topContent
                .take(5)
                .map((content) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getContentTypeColor(content.type),
                        child: Icon(
                          _getContentTypeIcon(content.type),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        content.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                          '${content.views} views • ${content.likes} likes'),
                      trailing: Text(
                        content.type.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementMetrics() {
    return _buildSection(
      title: 'Engagement Metrics',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildKPICard(
                  'Page Views',
                  _analytics?.pageViews.toString() ?? '0',
                  Icons.visibility,
                  Colors.amber,
                  changeValue: _analytics?.pageViewGrowth,
                ),
                _buildKPICard(
                  'Bounce Rate',
                  _analytics != null
                      ? '${_analytics!.bounceRate.toStringAsFixed(1)}%'
                      : '0%',
                  Icons.exit_to_app,
                  Colors.red,
                  changeValue: _analytics?.bounceRateChange,
                ),
                _buildKPICard(
                  'Total Likes',
                  _analytics?.totalLikes.toString() ?? '0',
                  Icons.favorite,
                  Colors.pink,
                  changeValue: _analytics?.likeGrowth,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return _buildSection(
      title: 'Quick Actions',
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionButton(
              'Manage Users',
              Icons.manage_accounts,
              () => Navigator.pushNamed(context, '/admin/user-management'),
            ),
            _buildActionButton(
              'Review Content',
              Icons.rate_review,
              () => Navigator.pushNamed(context, '/admin/content-review'),
            ),
            _buildActionButton(
              'Coupon Management',
              Icons.local_offer,
              () => Navigator.pushNamed(context, '/admin/coupon-management'),
            ),
            _buildActionButton(
              'Financial Analytics',
              Icons.analytics,
              () => Navigator.pushNamed(context, '/admin/financial-analytics'),
            ),
            _buildActionButton(
              'Full Analytics',
              Icons.show_chart,
              () => Navigator.pushNamed(context, '/admin/analytics'),
            ),
            _buildActionButton(
              'Settings',
              Icons.settings,
              () => Navigator.pushNamed(context, '/admin/settings'),
            ),
            _buildActionButton(
              'Ad Management',
              Icons.ad_units,
              () => Navigator.pushNamed(context, '/admin/ad-management'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return _buildSection(
      title: 'Recent Activity',
      children: [
        Card(
          child: _isLoadingActivities
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _recentActivities.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text('No recent activity'),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: _recentActivities
                          .take(5)
                          .map((activity) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _getActivityColor(activity.type.name),
                                  child: Icon(
                                    _getActivityIcon(activity.type.name),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(activity.description),
                                subtitle:
                                    Text(activity.userName ?? 'Unknown User'),
                                trailing: Text(
                                  _formatTimeAgo(activity.timestamp),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ))
                          .toList(),
                    ),
        ),
      ],
    );
  }

  Widget _buildSystemHealth() {
    return _buildSection(
      title: 'System Health',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildKPICard(
                  'Error Rate',
                  _analytics != null
                      ? '${_analytics!.errorRate.toStringAsFixed(2)}%'
                      : '0%',
                  Icons.error_outline,
                  Colors.red,
                  changeValue: _analytics?.errorRateChange,
                ),
                _buildKPICard(
                  'Response Time',
                  _analytics != null
                      ? '${_analytics!.avgResponseTime.toStringAsFixed(0)}ms'
                      : '0ms',
                  Icons.speed,
                  Colors.green,
                  changeValue: _analytics?.responseTimeChange,
                ),
                _buildKPICard(
                  'Storage Used',
                  _analytics != null
                      ? _formatBytes(_analytics!.storageUsed)
                      : '0B',
                  Icons.storage,
                  Colors.orange,
                  changeValue: _analytics?.storageGrowth,
                ),
                _buildKPICard(
                  'Bandwidth',
                  _analytics != null
                      ? _formatBytes(_analytics!.bandwidthUsed)
                      : '0B',
                  Icons.network_check,
                  Colors.purple,
                  changeValue: _analytics?.bandwidthChange,
                ),
              ],
            );
          },
        ),
      ],
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
            'Error loading dashboard',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDashboardData,
            child: const Text('Retry'),
          ),
        ],
      ),
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

  Widget _buildFallbackBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Analytics are loading with basic data. Full analytics will be available once database indexes are ready.',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(
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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color
                          ?.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (changeValue != null) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    changeValue >= 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 14,
                    color: changeValue >= 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      '${changeValue.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: changeValue >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 160,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          textStyle: Theme.of(context).textTheme.labelLarge,
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

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'user_registered':
        return Colors.green;
      case 'artwork_uploaded':
        return Colors.blue;
      case 'event_created':
        return Colors.orange;
      case 'subscription_created':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'user_registered':
        return Icons.person_add;
      case 'artwork_uploaded':
        return Icons.image;
      case 'event_created':
        return Icons.event;
      case 'subscription_created':
        return Icons.subscriptions;
      default:
        return Icons.notifications;
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
