import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_artist/artbeat_artist.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

class ArtistDashboardScreen extends StatefulWidget {
  const ArtistDashboardScreen({super.key});

  @override
  State<ArtistDashboardScreen> createState() => _ArtistDashboardScreenState();
}

class _ArtistDashboardScreenState extends State<ArtistDashboardScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final EventService _eventService = EventService();

  bool _isLoading = true;
  bool _isRefreshing = false;
  core.ArtistProfileModel? _artistProfile;
  SubscriptionModel? _subscription;
  Map<String, dynamic> _quickStats = {};
  List<Map<String, dynamic>> _recentActivities = [];
  List<core.EventModel> _upcomingEvents = [];
  Map<String, dynamic> _commissionSummary = {};

  @override
  void initState() {
    super.initState();
    debugPrint('🎨 ArtistDashboard: initState called');
    _loadArtistData();
  }

  Future<void> _loadArtistData() async {
    debugPrint('🎨 ArtistDashboard: _loadArtistData started');
    if (_isRefreshing) return;

    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });

    try {
      debugPrint('🎨 ArtistDashboard: Loading artist profile...');
      final profileFuture = _subscriptionService.getCurrentArtistProfile();
      final subscriptionFuture = _subscriptionService.getUserSubscription();
      final results = await Future.wait([profileFuture, subscriptionFuture]);

      final artistProfile = results[0] as core.ArtistProfileModel?;
      final subscription = results[1] as SubscriptionModel?;

      debugPrint(
          '🎨 ArtistDashboard: Artist profile: ${artistProfile?.displayName ?? 'null'}');
      debugPrint(
          '🎨 ArtistDashboard: Subscription: ${subscription?.tier ?? 'null'}');

      if (artistProfile != null) {
        debugPrint('🎨 ArtistDashboard: Loading analytics data...');
        final dataFutures = await Future.wait([
          _analyticsService.getQuickStats(artistProfile.userId),
          _analyticsService.getRecentActivities(artistProfile.userId),
          _eventService.getUpcomingEvents(),
          _analyticsService.getCommissionSummary(),
        ]);

        debugPrint('🎨 ArtistDashboard: Analytics data loaded successfully');

        if (mounted) {
          setState(() {
            _artistProfile = artistProfile;
            _subscription = subscription;
            _quickStats = dataFutures[0] as Map<String, dynamic>;
            _recentActivities = dataFutures[1] as List<Map<String, dynamic>>;
            _upcomingEvents = dataFutures[2] as List<core.EventModel>;
            _commissionSummary = dataFutures[3] as Map<String, dynamic>;
            _isLoading = false;
            _isRefreshing = false;
          });
          debugPrint('🎨 ArtistDashboard: UI updated successfully');
        }
      } else {
        debugPrint('🎨 ArtistDashboard: No artist profile found');
        if (mounted) {
          setState(() {
            _artistProfile = artistProfile;
            _subscription = subscription;
            _isLoading = false;
            _isRefreshing = false;
          });
        }
      }
    } catch (e) {
      debugPrint('🎨 ArtistDashboard: Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading artist data: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  String get _tierName {
    if (_subscription == null) return 'Free Plan';

    switch (_subscription!.tier) {
      case core.SubscriptionTier.artistBasic:
        return 'Artist Basic Plan (Free)';
      case core.SubscriptionTier.artistPro:
        return 'Artist Pro Plan (\$9.99/month)';
      case core.SubscriptionTier.gallery:
        return 'Gallery Plan (\$49.99/month)';
      default:
        return 'Free Plan';
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              core.ArtbeatColors.primaryPurple.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      core.ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: core.ArtbeatColors.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: core.ArtbeatColors.textPrimary,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: core.ArtbeatColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

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

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'artwork_view':
        return Icons.visibility;
      case 'profile_view':
        return Icons.person;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.info;
    }
  }

  String _getActivityTitle(Map<String, dynamic> activity) {
    switch (activity['type']) {
      case 'artwork_view':
        return 'Artwork viewed';
      case 'profile_view':
        return 'Profile viewed';
      case 'comment':
        return 'New comment';
      default:
        return 'Activity';
    }
  }

  void _onActivityTap(Map<String, dynamic> activity) {
    switch (activity['type']) {
      case 'artwork_view':
        Navigator.pushNamed(
          context,
          '/artwork/details',
          arguments: {'id': activity['artworkId']},
        );
        break;
      case 'comment':
        Navigator.pushNamed(
          context,
          '/artwork/details',
          arguments: {
            'id': activity['artworkId'],
            'showComments': true,
          },
        );
        break;
    }
  }

  String _formatEventDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _buildCommissionSummary() {
    if (_commissionSummary.isEmpty) return const SizedBox.shrink();

    final activeCommissions = _commissionSummary['activeCommissions'] as int;
    final pendingAmount = _commissionSummary['totalPendingAmount'] as double;
    final paidAmount = _commissionSummary['totalPaidAmount'] as double;
    final activeGalleries = _commissionSummary['activeGalleries'] as int;
    final recentTransactions =
        _commissionSummary['recentTransactions'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Commission Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.info_outline,
                  color: Theme.of(context).primaryColor),
              onPressed: () => _showCommissionInfo(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Active Commissions',
                            style: TextStyle(color: Colors.grey)),
                        Text(activeCommissions.toString(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Active Galleries',
                            style: TextStyle(color: Colors.grey)),
                        Text(activeGalleries.toString(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pending Amount',
                            style: TextStyle(color: Colors.grey)),
                        Text('\$${pendingAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Paid Amount',
                            style: TextStyle(color: Colors.grey)),
                        Text('\$${paidAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (recentTransactions.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...recentTransactions.take(3).map((transaction) => Card(
                child: ListTile(
                  leading: Icon(
                    transaction['status'] == 'paid'
                        ? Icons.check_circle
                        : Icons.pending,
                    color: transaction['status'] == 'paid'
                        ? Colors.green
                        : Colors.orange,
                  ),
                  title: Text(
                      '\$${(transaction['amount'] as num).toStringAsFixed(2)}'),
                  subtitle:
                      Text(_getTimeAgo((transaction['date'] as DateTime))),
                  trailing: Text(
                    transaction['status'] == 'paid' ? 'Paid' : 'Pending',
                    style: TextStyle(
                      color: transaction['status'] == 'paid'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
              )),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/artist/commissions');
              },
              child: const Text('View All Transactions'),
            ),
          ),
        ],
      ],
    );
  }

  void _showCommissionInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Commission Information'),
        content: const SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                  'Active Commissions: Number of ongoing commission agreements with galleries.'),
              SizedBox(height: 8),
              Text(
                  'Active Galleries: Number of galleries you currently work with.'),
              SizedBox(height: 8),
              Text('Pending Amount: Total commission fees yet to be paid.'),
              SizedBox(height: 8),
              Text(
                  'Paid Amount: Total commission fees received in the current period.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Search Artists & Artwork',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: core.ArtbeatColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildSearchOption(
                      'Find Artists',
                      'Search for artists by name or specialty',
                      Icons.person_search,
                      core.ArtbeatColors.primaryPurple,
                      () => Navigator.pushNamed(context, '/artist/search'),
                    ),
                    _buildSearchOption(
                      'Browse Artwork',
                      'Explore art collections and galleries',
                      Icons.palette,
                      core.ArtbeatColors.primaryGreen,
                      () => Navigator.pushNamed(context, '/artwork/browse'),
                    ),
                    _buildSearchOption(
                      'Gallery Search',
                      'Find galleries and exhibition spaces',
                      Icons.business,
                      core.ArtbeatColors.warning,
                      () => Navigator.pushNamed(context, '/gallery/search'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: core.ArtbeatColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: core.ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.palette,
                      color: core.ArtbeatColors.primaryPurple,
                      size: 24,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Artist Tools',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: core.ArtbeatColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Manage your art, profile, and gallery connections',
                            style: TextStyle(
                              fontSize: 14,
                              color: core.ArtbeatColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildProfileMenuTile(
                      icon: Icons.person,
                      title: 'My Profile',
                      subtitle: 'Edit your artist profile and bio',
                      color: core.ArtbeatColors.primaryPurple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artist/profile');
                      },
                    ),
                    _buildProfileMenuTile(
                      icon: Icons.image,
                      title: 'My Artwork',
                      subtitle: 'Manage your art portfolio',
                      color: core.ArtbeatColors.primaryGreen,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artist/artwork');
                      },
                    ),
                    _buildProfileMenuTile(
                      icon: Icons.business,
                      title: 'Gallery Relations',
                      subtitle: 'View partnerships and commissions',
                      color: core.ArtbeatColors.warning,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artist/galleries');
                      },
                    ),
                    _buildProfileMenuTile(
                      icon: Icons.analytics,
                      title: 'Analytics',
                      subtitle: 'Track your art views and engagement',
                      color: core.ArtbeatColors.info,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artist/analytics');
                      },
                    ),
                    _buildProfileMenuTile(
                      icon: Icons.settings,
                      title: 'Settings',
                      subtitle: 'Account and notification settings',
                      color: core.ArtbeatColors.textSecondary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: core.ArtbeatColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: core.ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildArtisticBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFAFAFA),
          Color(0xFFF5F5F5),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return core.MainLayout(
        currentIndex: 0, // Artist dashboard could be index 0 or a custom index
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: _buildArtisticBackground(),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      core.ArtbeatColors.primaryPurple,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: core.ArtbeatColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_artistProfile == null) {
      return core.MainLayout(
        currentIndex: 0,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: const PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight + 4),
            child: core.ArtbeatGradientBackground(
              addShadow: true,
              child: core.EnhancedUniversalHeader(
                title: 'Artist Dashboard',
                showLogo: false,
                showSearch: false,
                showDeveloperTools: false,
                backgroundColor: Colors.transparent,
                foregroundColor: core.ArtbeatColors.textPrimary,
                elevation: 0,
              ),
            ),
          ),
          body: Container(
            decoration: _buildArtisticBackground(),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: core.ArtbeatColors.primaryPurple
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.palette,
                          size: 64,
                          color: core.ArtbeatColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Create Artist Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: core.ArtbeatColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Set up your profile to start sharing artwork and connecting with galleries.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: core.ArtbeatColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/artist/create-profile')
                              .then((_) => _loadArtistData());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: core.ArtbeatColors.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Create Profile'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return core.MainLayout(
      currentIndex: 0,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        drawer: const core.ArtbeatDrawer(),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 4),
          child: core.ArtbeatGradientBackground(
            addShadow: true,
            child: core.EnhancedUniversalHeader(
              title: 'Artist Dashboard',
              showLogo: false,
              showSearch: true,
              showDeveloperTools: false,
              onSearchPressed: () => _showSearchModal(context),
              onProfilePressed: () => _showProfileMenu(context),
              backgroundColor: Colors.transparent,
              foregroundColor: core.ArtbeatColors.textPrimary,
              elevation: 0,
            ),
          ),
        ),
        body: Container(
          decoration: _buildArtisticBackground(),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadArtistData,
              color: core.ArtbeatColors.primaryPurple,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // Profile Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                core.ArtbeatColors.primaryPurple
                                    .withValues(alpha: 0.05),
                                core.ArtbeatColors.primaryGreen
                                    .withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: core
                                      .ArtbeatColors.primaryPurple
                                      .withValues(alpha: 0.1),
                                  backgroundImage:
                                      _artistProfile?.profileImageUrl != null
                                          ? NetworkImage(
                                              _artistProfile!.profileImageUrl!)
                                          : null,
                                  child: _artistProfile?.profileImageUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 40,
                                          color:
                                              core.ArtbeatColors.primaryPurple,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _artistProfile?.displayName ?? '',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: core.ArtbeatColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _tierName,
                                  style: const TextStyle(
                                    color: core.ArtbeatColors.primaryPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Stats Grid
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: [
                          _buildStatCard(
                            'Profile Views',
                            _quickStats['profileViews']?.toString() ?? '0',
                            Icons.visibility,
                          ),
                          _buildStatCard(
                            'Artwork Views',
                            _quickStats['artworkViews']?.toString() ?? '0',
                            Icons.image,
                          ),
                          _buildStatCard(
                            'Total Likes',
                            _quickStats['totalLikes']?.toString() ?? '0',
                            Icons.favorite,
                          ),
                          _buildStatCard(
                            'Comments',
                            _quickStats['totalComments']?.toString() ?? '0',
                            Icons.comment,
                          ),
                          _buildStatCard(
                            'Total Gift Value',
                            '\$${_quickStats['totalGiftValue']?.toString() ?? '0.00'}',
                            Icons.card_giftcard,
                          ),
                          _buildStatCard(
                            'Sponsorships',
                            '\$${_quickStats['sponsorshipsValue']?.toString() ?? '0.00'}',
                            Icons.business_center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Recent Activity
                  if (_recentActivities.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recent Activity',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: core.ArtbeatColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...(_recentActivities.take(5).map((activity) {
                              final timeAgo = _getTimeAgo(
                                  (activity['timestamp'] as Timestamp)
                                      .toDate());
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Icon(
                                    _getActivityIcon(
                                        activity['type'] as String),
                                    color: core.ArtbeatColors.primaryPurple,
                                  ),
                                  title: Text(_getActivityTitle(activity)),
                                  subtitle: Text(timeAgo),
                                  onTap: () => _onActivityTap(activity),
                                ),
                              );
                            })),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, '/artist/activity');
                                },
                                child: const Text('View All Activity'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Commission Summary
                  if (_subscription?.tier == core.SubscriptionTier.artistPro ||
                      _subscription?.tier == core.SubscriptionTier.gallery)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildCommissionSummary(),
                      ),
                    ),

                  // Upcoming Events
                  if (_upcomingEvents.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upcoming Events',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: core.ArtbeatColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...(_upcomingEvents.take(3).map((event) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.event,
                                      color: core.ArtbeatColors.primaryGreen,
                                    ),
                                    title: Text(event.title),
                                    subtitle:
                                        Text(_formatEventDate(event.startDate)),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/event/details',
                                        arguments: {'id': event.id},
                                      );
                                    },
                                  ),
                                ))),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, '/artist/events');
                                },
                                child: const Text('View All Events'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Bottom padding for navigation
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
