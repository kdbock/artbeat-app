import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';
import '../models/admin_stats_model.dart';
import '../models/recent_activity_model.dart';
import '../services/admin_service.dart';
import '../services/recent_activity_service.dart';
import 'admin_user_management_screen.dart';
import 'admin_content_review_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_settings_screen.dart';

/// Enhanced Admin Dashboard screen with fluid design and better UX
///
/// Features:
/// - Fluid, continuous scrolling layout
/// - Enhanced visual hierarchy
/// - Intuitive navigation
/// - Real-time statistics
/// - Modern, clean design
/// - Optimized performance
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  final RecentActivityService _activityService = RecentActivityService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  AdminStatsModel? _stats;
  List<RecentActivityModel> _recentActivities = [];
  bool _isLoading = true;
  bool _isLoadingActivities = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadRecentActivities();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final stats = await _adminService.getAdminStats();

      if (mounted) {
        setState(() {
          _stats = stats;
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

  Future<void> _loadRecentActivities() async {
    try {
      setState(() {
        _isLoadingActivities = true;
      });

      final activities = await _activityService.getRecentActivities(limit: 5);

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
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0, // Admin is usually index 0 in admin section
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
              title: 'Admin Dashboard',
              showLogo: false,
              showSearch: false,
              showDeveloperTools: true,
              onProfilePressed: () =>
                  Navigator.pushNamed(context, '/admin/profile'),
              onMenuPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
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
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                if (_isLoading) ...[
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ] else if (_error != null) ...[
                  SliverFillRemaining(
                    child: Center(
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
                            onPressed: _loadStats,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildStatsOverview(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildRecentActivity(),
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              'Total Users',
              _stats?.totalUsers.toString() ?? '0',
              Icons.people_outline,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Artists',
              _stats?.totalArtists.toString() ?? '0',
              Icons.palette_outlined,
              Colors.green,
            ),
            _buildStatCard(
              'Total Artworks',
              _stats?.totalArtworks.toString() ?? '0',
              Icons.image_outlined,
              Colors.orange,
            ),
            _buildStatCard(
              'Total Events',
              _stats?.totalEvents.toString() ?? '0',
              Icons.event_outlined,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionButton(
              'Manage Users',
              Icons.manage_accounts,
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const AdminUserManagementScreen(),
                ),
              ),
            ),
            _buildActionButton(
              'Review Content',
              Icons.rate_review,
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const AdminContentReviewScreen(),
                ),
              ),
            ),
            _buildActionButton(
              'Analytics',
              Icons.analytics,
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const AdminAnalyticsScreen(),
                ),
              ),
            ),
            _buildActionButton(
              'Settings',
              Icons.settings,
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const AdminSettingsScreen(),
                ),
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            IconButton(
              onPressed: _loadRecentActivities,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh activities',
            ),
          ],
        ),
        const SizedBox(height: 16),
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
                            Text(
                              'No recent activity',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentActivities.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final activity = _recentActivities[index];
                        return _buildActivityTile(activity);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildActivityTile(RecentActivityModel activity) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getActivityColor(activity.type),
        child: Icon(
          _getActivityIcon(activity.type),
          color: Colors.white,
        ),
      ),
      title: Text(
        activity.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        activity.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        activity.timeAgo,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.userRegistered:
      case ActivityType.artworkApproved:
      case ActivityType.userVerified:
        return Colors.green;
      case ActivityType.userLogin:
      case ActivityType.postCreated:
        return Colors.blue;
      case ActivityType.artworkUploaded:
      case ActivityType.adminAction:
        return Colors.purple;
      case ActivityType.commentAdded:
      case ActivityType.contentReported:
        return Colors.orange;
      case ActivityType.eventCreated:
        return Colors.indigo;
      case ActivityType.artworkRejected:
      case ActivityType.userSuspended:
      case ActivityType.systemError:
        return Colors.red;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.userRegistered:
        return Icons.person_add;
      case ActivityType.userLogin:
        return Icons.login;
      case ActivityType.artworkUploaded:
        return Icons.image;
      case ActivityType.artworkApproved:
        return Icons.check_circle;
      case ActivityType.artworkRejected:
        return Icons.cancel;
      case ActivityType.postCreated:
        return Icons.post_add;
      case ActivityType.commentAdded:
        return Icons.comment;
      case ActivityType.eventCreated:
        return Icons.event;
      case ActivityType.userSuspended:
        return Icons.block;
      case ActivityType.userVerified:
        return Icons.verified;
      case ActivityType.contentReported:
        return Icons.report;
      case ActivityType.systemError:
        return Icons.error;
      case ActivityType.adminAction:
        return Icons.admin_panel_settings;
    }
  }
}
