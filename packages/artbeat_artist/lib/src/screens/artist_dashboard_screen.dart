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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    if (_artistProfile == null) {
      return Scaffold(
        appBar: const core.UniversalHeader(
          title: 'Artist Dashboard',
          showLogo: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Create Artist Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set up your profile to start sharing artwork and connecting with galleries.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/artist/create-profile')
                        .then((_) => _loadArtistData());
                  },
                  child: const Text('Create Profile'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadArtistData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _artistProfile?.profileImageUrl != null
                          ? NetworkImage(_artistProfile!.profileImageUrl!)
                          : null,
                      child: _artistProfile?.profileImageUrl == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _artistProfile?.displayName ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _tierName,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats Grid
            GridView.count(
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
              ],
            ),

            // Recent Activity
            if (_recentActivities.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...(_recentActivities.take(5).map((activity) {
                final timeAgo =
                    _getTimeAgo((activity['timestamp'] as Timestamp).toDate());
                return Card(
                  child: ListTile(
                    leading: Icon(
                      _getActivityIcon(activity['type'] as String),
                      color: Theme.of(context).primaryColor,
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
                    Navigator.pushNamed(context, '/artist/activity');
                  },
                  child: const Text('View All Activity'),
                ),
              ),
            ],

            // Commission Summary
            if (_subscription?.tier == core.SubscriptionTier.artistPro ||
                _subscription?.tier == core.SubscriptionTier.gallery)
              _buildCommissionSummary(),

            // Upcoming Events
            if (_upcomingEvents.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Upcoming Events',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...(_upcomingEvents.take(3).map((event) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.event),
                      title: Text(event.title),
                      subtitle: Text(_formatEventDate(event.startDate)),
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
                    Navigator.pushNamed(context, '/artist/events');
                  },
                  child: const Text('View All Events'),
                ),
              ),
            ],

            // Commission Summary
            if (_subscription?.tier == core.SubscriptionTier.artistPro ||
                _subscription?.tier == core.SubscriptionTier.gallery)
              _buildCommissionSummary(),
          ],
        ),
      ),
    );
  }
}
