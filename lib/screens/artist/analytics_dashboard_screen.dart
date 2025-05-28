import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat/models/subscription_model.dart';
import 'package:artbeat/models/artwork_model.dart';
import 'package:artbeat/services/subscription_service.dart';
import 'package:artbeat/services/artwork_service.dart';
import 'package:artbeat/services/analytics_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Analytics Dashboard Screen for Artists with Pro and Gallery plans
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SubscriptionService _subscriptionService = SubscriptionService();
  final ArtworkService _artworkService = ArtworkService();
  final AnalyticsService _analyticsService = AnalyticsService();

  bool _isLoading = true;
  bool _hasProAccess = false;
  SubscriptionModel? _subscription;
  List<ArtworkModel> _artworks = [];
  Map<String, dynamic> _analytics = {};

  // Date range for analytics
  String _selectedRange = 'last_30_days';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load data for the analytics dashboard
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user's subscription
      final subscription = await _subscriptionService.getUserSubscription();
      final hasProAccess = subscription != null &&
          (subscription.tier == SubscriptionTier.standard ||
              subscription.tier == SubscriptionTier.premium);

      // Get user's artwork
      final artworks = await _artworkService.getUserArtwork();

      // Calculate analytics data
      final analytics = await _calculateAnalytics();

      if (mounted) {
        setState(() {
          _subscription = subscription;
          _hasProAccess = hasProAccess;
          _artworks = artworks;
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
        setState(() {
          _isLoading = false;
          _hasProAccess = false;
        });
      }
    }
  }

  /// Calculate analytics data based on selected date range
  Future<Map<String, dynamic>> _calculateAnalytics() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return {};
    }

    final analytics = <String, dynamic>{};

    try {
      // Use AnalyticsService to get data
      final profileAnalytics = await _analyticsService.getProfileAnalytics(
        startDate: _startDate,
        endDate: _endDate,
      );

      final artworkAnalytics = await _analyticsService.getArtworkAnalytics(
        startDate: _startDate,
        endDate: _endDate,
      );

      final followerAnalytics = await _analyticsService.getFollowerAnalytics(
        startDate: _startDate,
        endDate: _endDate,
      );

      // Merge all analytics data
      analytics.addAll(profileAnalytics);
      analytics.addAll(artworkAnalytics);
      analytics.addAll(followerAnalytics);

      // Convert date formats for chart display if needed
      if (analytics.containsKey('profileViewsByDay')) {
        final profileViewsByDate = <String, int>{};
        (analytics['profileViewsByDay'] as Map<String, int>)
            .forEach((key, value) {
          final dateParts = key.split('-');
          if (dateParts.length >= 3) {
            final dateString = '${dateParts[1]}/${dateParts[2]}';
            profileViewsByDate[dateString] = value;
          }
        });
        analytics['profileViewsByDate'] = profileViewsByDate;
      }

      // Get total artwork count
      final artworkSnapshot = await _firestore
          .collection('artwork')
          .where('userId', isEqualTo: userId)
          .get();

      analytics['totalArtworks'] = artworkSnapshot.size;
    } catch (e) {
      print('Error calculating analytics: $e');
    }

    return analytics;
  }

  /// Update the date range and reload data
  void _updateDateRange(String range) {
    DateTime now = DateTime.now();
    DateTime start;

    switch (range) {
      case 'last_7_days':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'last_30_days':
        start = now.subtract(const Duration(days: 30));
        break;
      case 'last_90_days':
        start = now.subtract(const Duration(days: 90));
        break;
      default:
        start = now.subtract(const Duration(days: 30));
    }

    setState(() {
      _selectedRange = range;
      _startDate = start;
      _endDate = now;
    });

    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show upgrade prompt for users without Pro access
    if (!_hasProAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bar_chart, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Advanced Analytics',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Get detailed insights about your artwork and followers',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              const Text(
                'Available with Artist Pro Plan',
                style: TextStyle(fontSize: 18, color: Colors.deepPurple),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/artist/subscription');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Upgrade to Pro'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _updateDateRange,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'last_7_days',
                child: Text('Last 7 Days'),
              ),
              const PopupMenuItem(
                value: 'last_30_days',
                child: Text('Last 30 Days'),
              ),
              const PopupMenuItem(
                value: 'last_90_days',
                child: Text('Last 90 Days'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateRangeHeader(),
              const SizedBox(height: 24),
              _buildStatCards(),
              const SizedBox(height: 32),
              _buildProfileViewsChart(),
              const SizedBox(height: 32),
              _buildTopArtworkList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeHeader() {
    final DateFormat formatter = DateFormat('MMM d, yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Analytics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            '${formatter.format(_startDate)} - ${formatter.format(_endDate)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Profile Views',
          _analytics['totalProfileViews']?.toString() ?? '0',
          Icons.visibility,
          Colors.blue,
        ),
        _buildStatCard(
          'Artwork Views',
          _analytics['totalArtworkViews']?.toString() ?? '0',
          Icons.image,
          Colors.green,
        ),
        _buildStatCard(
          'Total Followers',
          _analytics['totalFollowers']?.toString() ?? '0',
          Icons.people,
          Colors.purple,
        ),
        _buildStatCard(
          'New Followers',
          _analytics['newFollowers']?.toString() ?? '0',
          Icons.person_add,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
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
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileViewsChart() {
    final viewsByDate =
        _analytics['profileViewsByDate'] as Map<String, int>? ?? {};

    if (viewsByDate.isEmpty) {
      return const Center(
        child: Text('No profile views data available for this period'),
      );
    }

    // Sort dates
    final sortedDates = viewsByDate.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('MM/dd').parse(a);
        final dateB = DateFormat('MM/dd').parse(b);
        return dateA.compareTo(dateB);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Views',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < sortedDates.length) {
                        return Text(
                          sortedDates[value.toInt()],
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 30,
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: sortedDates.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      viewsByDate[entry.value]!.toDouble(),
                    );
                  }).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopArtworkList() {
    final viewsByArtwork =
        _analytics['viewsByArtwork'] as Map<String, int>? ?? {};

    if (viewsByArtwork.isEmpty) {
      return const Center(
        child: Text('No artwork view data available for this period'),
      );
    }

    // Sort artworks by views
    final sortedArtworkIds = viewsByArtwork.keys.toList()
      ..sort((a, b) => viewsByArtwork[b]!.compareTo(viewsByArtwork[a]!));

    // Get top 5 artworks
    final topArtworkIds = sortedArtworkIds.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Viewed Artwork',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: topArtworkIds.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final artworkId = topArtworkIds[index];
            final artwork = _artworks.firstWhere(
              (a) => a.id == artworkId,
              orElse: () => ArtworkModel(
                id: artworkId,
                userId: '',
                artistProfileId: '',
                title: 'Unknown Artwork',
                description: '',
                imageUrl: '',
                medium: '',
                style: '',
                tags: [],
                isForSale: false,
                createdAt: Timestamp.now(),
              ),
            );

            return ListTile(
              leading: artwork.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        artwork.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
              title: Text(artwork.title),
              subtitle: Text('${artwork.medium} • ${artwork.style}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    viewsByArtwork[artworkId].toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('views'),
                ],
              ),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/artist/artwork-detail',
                  arguments: {'artworkId': artworkId},
                );
              },
            );
          },
        ),
      ],
    );
  }
}
