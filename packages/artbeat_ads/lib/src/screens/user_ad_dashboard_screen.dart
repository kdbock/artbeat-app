import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';

import '../models/ad_model.dart';
import '../models/ad_status.dart';
import '../models/ad_analytics_model.dart';
import '../models/ad_type.dart';
import '../models/ad_size.dart';
import '../models/ad_location.dart';
import '../models/ad_duration.dart';
import '../services/simple_ad_service.dart';
import '../services/ad_analytics_service.dart';
import 'simple_ad_create_screen.dart';
import 'ad_performance_screen.dart';

/// User-facing ad management dashboard
class UserAdDashboardScreen extends StatefulWidget {
  const UserAdDashboardScreen({super.key});

  @override
  State<UserAdDashboardScreen> createState() => _UserAdDashboardScreenState();
}

class _UserAdDashboardScreenState extends State<UserAdDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SimpleAdService _adService;
  late AdAnalyticsService _analyticsService;

  String? _currentUserId;
  List<AdModel> _userAds = [];
  List<AdAnalyticsModel> _userAnalytics = [];
  bool _isLoading = true;
  String? _error;

  // Filter state
  AdStatus? _statusFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _adService = SimpleAdService();
    _analyticsService = AdAnalyticsService();
    _getCurrentUserId();
    _loadUserAds();
    _loadUserAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid;

    if (_currentUserId == null) {
      setState(() {
        _error = 'User not authenticated';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserAds() async {
    if (_currentUserId == null) return;

    try {
      _adService.getAdsByOwner(_currentUserId!).listen((ads) {
        if (mounted) {
          setState(() {
            _userAds = ads;
            _isLoading = false;
            _error = null;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading ads: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserAnalytics() async {
    if (_currentUserId == null) return;

    try {
      final analytics = await _analyticsService.getUserAdAnalytics(
        _currentUserId!,
      );
      if (mounted) {
        setState(() {
          _userAnalytics = analytics;
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadUserAnalytics(),
      // _loadUserAds is stream-based and will update automatically
    ]);
    setState(() => _isLoading = false);
  }

  List<AdModel> get _filteredAds {
    var filtered = _userAds;

    // Apply status filter
    if (_statusFilter != null) {
      filtered = filtered.where((ad) => ad.status == _statusFilter).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (ad) =>
                ad.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                ad.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.startDate.compareTo(a.startDate));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MainLayout(
        currentIndex: -1,
        appBar: const EnhancedUniversalHeader(title: 'My Ads'),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return MainLayout(
      currentIndex: -1,
      appBar: EnhancedUniversalHeader(
        title: 'My Ads',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateAd(),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      child: Column(
        children: [
          // Quick stats overview
          _buildQuickStats(),

          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'All Ads (${_userAds.length})'),
              const Tab(text: 'Active'),
              const Tab(text: 'Analytics'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllAdsTab(),
                _buildActiveAdsTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final activeAds = _userAds
        .where((ad) => ad.status == AdStatus.approved)
        .length;
    final pendingAds = _userAds
        .where((ad) => ad.status == AdStatus.pending)
        .length;
    final totalImpressions = _userAnalytics.fold<int>(
      0,
      (sum, analytics) => sum + analytics.totalImpressions,
    );
    final totalClicks = _userAnalytics.fold<int>(
      0,
      (sum, analytics) => sum + analytics.totalClicks,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total Ads',
            _userAds.length.toString(),
            Icons.ads_click,
          ),
          _buildStatItem(
            'Active',
            activeAds.toString(),
            Icons.check_circle,
            color: Colors.green,
          ),
          _buildStatItem(
            'Pending',
            pendingAds.toString(),
            Icons.pending,
            color: Colors.orange,
          ),
          _buildStatItem(
            'Impressions',
            _formatNumber(totalImpressions),
            Icons.visibility,
          ),
          _buildStatItem('Clicks', _formatNumber(totalClicks), Icons.mouse),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color ?? Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).textTheme.headlineSmall?.color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildAllAdsTab() {
    return Column(
      children: [
        // Search and filter bar
        _buildSearchAndFilter(),

        // Ads list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredAds.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredAds.length,
                    itemBuilder: (context, index) {
                      final ad = _filteredAds[index];
                      final analytics = _userAnalytics.firstWhere(
                        (a) => a.adId == ad.id,
                        orElse: () => AdAnalyticsModel(
                          adId: ad.id,
                          ownerId: ad.ownerId,
                          totalImpressions: 0,
                          totalClicks: 0,
                          clickThroughRate: 0.0,
                          totalRevenue: 0.0,
                          averageViewDuration: 0.0,
                          firstImpressionDate: DateTime.now(),
                          lastImpressionDate: DateTime.now(),
                          locationBreakdown: {},
                          dailyImpressions: {},
                          dailyClicks: {},
                          lastUpdated: DateTime.now(),
                        ),
                      );
                      return _buildAdCard(ad, analytics);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildActiveAdsTab() {
    final activeAds = _userAds
        .where((ad) => ad.status == AdStatus.approved)
        .toList();

    if (activeAds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No active ads', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              'Create your first ad to start advertising',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToCreateAd,
              icon: const Icon(Icons.add),
              label: const Text('Create Ad'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeAds.length,
        itemBuilder: (context, index) {
          final ad = activeAds[index];
          final analytics = _userAnalytics.firstWhere(
            (a) => a.adId == ad.id,
            orElse: () => AdAnalyticsModel(
              adId: ad.id,
              ownerId: ad.ownerId,
              totalImpressions: 0,
              totalClicks: 0,
              clickThroughRate: 0.0,
              totalRevenue: 0.0,
              averageViewDuration: 0.0,
              firstImpressionDate: DateTime.now(),
              lastImpressionDate: DateTime.now(),
              locationBreakdown: {},
              dailyImpressions: {},
              dailyClicks: {},
              lastUpdated: DateTime.now(),
            ),
          );
          return _buildAdCard(ad, analytics);
        },
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_userAnalytics.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No analytics data', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text(
              'Analytics will appear once your ads start receiving views',
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Analytics cards
          for (final analytics in _userAnalytics) ...[
            () {
              final ad = _userAds.firstWhere(
                (a) => a.id == analytics.adId,
                orElse: () => AdModel(
                  id: analytics.adId,
                  ownerId: analytics.ownerId,
                  type: AdType.banner_ad,
                  size: AdSize.medium,
                  imageUrl: '',
                  title: 'Deleted Ad',
                  description: '',
                  location: AdLocation.dashboard,
                  duration: AdDuration.oneDay,
                  startDate: DateTime.now(),
                  endDate: DateTime.now(),
                  status: AdStatus.pending,
                ),
              );

              return _buildAnalyticsCard(ad, analytics);
            }(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search ads...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          const SizedBox(width: 16),

          // Status filter
          DropdownButton<AdStatus?>(
            value: _statusFilter,
            hint: const Text('Filter by status'),
            items: [
              const DropdownMenuItem<AdStatus?>(
                value: null,
                child: Text('All'),
              ),
              ...AdStatus.values.map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Text(status.name.toUpperCase()),
                ),
              ),
            ],
            onChanged: (status) {
              setState(() => _statusFilter = status);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No ads found', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != null
                ? 'Try adjusting your search or filter'
                : 'Create your first ad to get started',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _navigateToCreateAd,
            icon: const Icon(Icons.add),
            label: const Text('Create Ad'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCard(AdModel ad, AdAnalyticsModel analytics) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ad thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ad.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Ad info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ad.description,
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatusChip(ad.status),
                          const SizedBox(width: 8),
                          Text(
                            '${ad.size.name} • ${ad.location.name}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  onSelected: (action) => _handleAdAction(action, ad),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'view',
                      child: Text('View Performance'),
                    ),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Performance metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  'Impressions',
                  analytics.totalImpressions.toString(),
                ),
                _buildMetric('Clicks', analytics.totalClicks.toString()),
                _buildMetric(
                  'CTR',
                  '${analytics.clickThroughRate.toStringAsFixed(1)}%',
                ),
                _buildMetric(
                  'Revenue',
                  '\$${analytics.totalRevenue.toStringAsFixed(2)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(AdModel ad, AdAnalyticsModel analytics) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ad.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToPerformanceScreen(ad),
                  child: const Text('View Details'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Performance grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              children: [
                _buildAnalyticsMetric(
                  'Impressions',
                  analytics.totalImpressions.toString(),
                  Icons.visibility,
                ),
                _buildAnalyticsMetric(
                  'Clicks',
                  analytics.totalClicks.toString(),
                  Icons.mouse,
                ),
                _buildAnalyticsMetric(
                  'CTR',
                  '${analytics.clickThroughRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
                _buildAnalyticsMetric(
                  'Revenue',
                  '\$${analytics.totalRevenue.toStringAsFixed(2)}',
                  Icons.attach_money,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(AdStatus status) {
    Color color;
    String text;

    switch (status) {
      case AdStatus.approved:
        color = Colors.green;
        text = 'Active';
        break;
      case AdStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case AdStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        break;
      case AdStatus.running:
        color = Colors.green;
        text = 'Running';
        break;
      case AdStatus.paused:
        color = Colors.grey;
        text = 'Paused';
        break;
      case AdStatus.expired:
        color = Colors.grey;
        text = 'Expired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAnalyticsMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAdAction(String action, AdModel ad) {
    switch (action) {
      case 'view':
        _navigateToPerformanceScreen(ad);
        break;
      case 'edit':
        // TODO: Navigate to edit screen
        _showNotImplementedDialog('Edit functionality');
        break;
      case 'duplicate':
        // TODO: Implement duplication
        _showNotImplementedDialog('Duplicate functionality');
        break;
      case 'delete':
        _showDeleteConfirmation(ad);
        break;
    }
  }

  void _navigateToCreateAd() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (context) => const SimpleAdCreateScreen()),
    ).then((_) => _refreshData());
  }

  void _navigateToPerformanceScreen(AdModel ad) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AdPerformanceScreen(ad: ad),
      ),
    );
  }

  void _showNotImplementedDialog(String feature) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(AdModel ad) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ad'),
        content: Text(
          'Are you sure you want to delete "${ad.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _adService.deleteAd(ad.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ad deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting ad: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
