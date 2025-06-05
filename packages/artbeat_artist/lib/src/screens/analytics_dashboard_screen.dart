import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Import the models and services from our packages
import 'package:artbeat_artist/src/services/analytics_service.dart';
import 'package:artbeat_artist/src/services/subscription_service.dart'
    as artist_subscription;
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_core/artbeat_core.dart' hide SubscriptionService;

/// Analytics Dashboard Screen for Artists with Pro and Gallery plans
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final artist_subscription.SubscriptionService _subscriptionService =
      artist_subscription.SubscriptionService();
  final ArtworkService _artworkService = ArtworkService();
  final AnalyticsService _analyticsService = AnalyticsService();

  bool _isLoading = true;
  bool _hasProAccess = false;
  List<ArtworkModel> _artworks = [];
  Map<String, dynamic> _analytics = {};

  // Date range for analytics
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedRange = '30d'; // 7d, 30d, 90d, 1y

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user's subscription
      final subscription = await _subscriptionService.getUserSubscription();

      setState(() {
        // Added null check for subscription before accessing tier
        _hasProAccess = subscription != null &&
            (subscription.tier == SubscriptionTier.standard ||
                subscription.tier == SubscriptionTier.premium);
      });

      if (!_hasProAccess) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get user's artwork
      final artworks = await _artworkService.getArtworkByArtistProfileId(
        _auth.currentUser!.uid,
      );

      // Get analytics data
      final analytics = await _analyticsService.getProfileAnalytics(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _artworks = artworks;
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateDateRange(String range) {
    setState(() {
      _selectedRange = range;

      switch (range) {
        case '7d':
          _startDate = DateTime.now().subtract(const Duration(days: 7));
          break;
        case '30d':
          _startDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        case '90d':
          _startDate = DateTime.now().subtract(const Duration(days: 90));
          break;
        case '1y':
          _startDate = DateTime.now().subtract(const Duration(days: 365));
          break;
      }

      _endDate = DateTime.now();
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

    if (!_hasProAccess) {
      return _buildUpgradePrompt();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showDateRangePicker(),
            tooltip: 'Select Date Range',
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
              _buildDateRangeSelector(),
              const SizedBox(height: 16),
              _buildOverviewMetrics(),
              const SizedBox(height: 24),
              _buildVisitorsChart(),
              const SizedBox(height: 24),
              _buildTopArtworks(),
              const SizedBox(height: 24),
              _buildLocationBreakdown(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dateRangeButton('7d', '7 Days'),
        _dateRangeButton('30d', '30 Days'),
        _dateRangeButton('90d', '90 Days'),
        _dateRangeButton('1y', '1 Year'),
      ],
    );
  }

  Widget _dateRangeButton(String value, String label) {
    final isSelected = _selectedRange == value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _updateDateRange(value),
      ),
    );
  }

  void _showDateRangePicker() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
        _selectedRange = 'custom';
      });

      _loadData();
    }
  }

  Widget _buildUpgradePrompt() {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Dashboard')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.analytics_outlined,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Pro Analytics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upgrade to Artist Pro or Gallery plan to access detailed analytics about your artwork, audience, and sales.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/artist/subscription'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: const Text('Upgrade Subscription'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewMetrics() {
    final profileViews = _analytics['profileViews'] ?? 0;
    final artworkViews = _analytics['artworkViews'] ?? 0;
    final favorites = _analytics['favorites'] ?? 0;
    final leadClicks = _analytics['leadClicks'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildMetricCard('Profile Views', profileViews, Icons.visibility),
            _buildMetricCard('Artwork Views', artworkViews, Icons.image),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildMetricCard('Favorites', favorites, Icons.favorite),
            _buildMetricCard('Lead Clicks', leadClicks, Icons.link),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, int value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                NumberFormat.compact().format(value),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorsChart() {
    final visitorsData = _analytics['visitorsOverTime'] as List<dynamic>? ?? [];

    if (visitorsData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No visitor data available'),
          ),
        ),
      );
    }

    final spots = visitorsData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value['value'].toDouble());
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Visitors',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                // Corrected from SafeSafeSafeSafeSafeLineChart
                LineChartData(
                  gridData: const FlGridData(show: false), // Removed const
                  titlesData: const FlTitlesData(show: false), // Removed const
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2,
                      color: Theme.of(context).primaryColor,
                      dotData: const FlDotData(show: false), // Removed const
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withAlpha(
                            (255 * 0.2).round()), // Corrected withAlpha
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopArtworks() {
    final topArtworkIds = _analytics['topArtworks'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Performing Artwork',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (topArtworkIds.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('No artwork data available'),
              ),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: topArtworkIds.length > 5 ? 5 : topArtworkIds.length,
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
                    price: 0,
                    medium: '',
                    isForSale: false,
                    styles: [], // Updated from style to styles (List)
                    tags: [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(), // Added required field
                  ),
                );

                final views = _analytics['artworkViews_$artworkId'] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 160,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                          child: artwork.imageUrl.isNotEmpty
                              ? Image.network(
                                  artwork.imageUrl,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 120,
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 40),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                artwork.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.visibility, size: 16),
                                  const SizedBox(width: 4),
                                  Text('$views views'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLocationBreakdown() {
    final locationData =
        _analytics['locationBreakdown'] as Map<dynamic, dynamic>? ?? {};

    if (locationData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Convert to list of entries and sort by count
    final entries = locationData.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    // Take top 5
    final topLocations = entries.take(5).toList();

    // Calculate total for percentages
    final total = entries.fold<int>(
        0,
        (currentSum, entry) =>
            currentSum + (entry.value as int)); // Renamed sum to currentSum

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Audience Location',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: topLocations.map((entry) {
                final location = entry.key as String;
                final count = entry.value as int;
                final percentage = total > 0 ? (count / total * 100) : 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(location),
                          Text('${percentage.toStringAsFixed(1)}%'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
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
}
