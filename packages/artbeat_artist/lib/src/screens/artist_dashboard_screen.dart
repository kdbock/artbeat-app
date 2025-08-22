import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:flutter/material.dart';
import '../models/activity_model.dart';

class ArtistDashboardScreen extends StatefulWidget {
  const ArtistDashboardScreen({super.key});

  @override
  State<ArtistDashboardScreen> createState() => _ArtistDashboardScreenState();
}

class _ArtistDashboardScreenState extends State<ArtistDashboardScreen> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _quickStats = {};
  List<ActivityModel> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadArtistData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadArtistData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await Future<void>.delayed(
          const Duration(seconds: 1)); // Simulate network delay

      setState(() {
        _quickStats = {
          'totalSales': 1234.56,
          'totalArtworks': 42,
          'totalGiftValue': 567.89,
          'sponsorshipsValue': 890.12,
        };
        _recentActivities = [
          const ActivityModel(
            type: ActivityType.sale,
            title: 'New Artwork Sale',
            description: 'Your artwork "Summer Breeze" was sold',
            timeAgo: '2h ago',
          ),
          const ActivityModel(
            type: ActivityType.commission,
            title: 'New Commission Request',
            description: 'You received a new commission inquiry',
            timeAgo: '5h ago',
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    final updatedColor = color.withValues(alpha: color.a);
    return Card(
      elevation: 2,
      shadowColor: updatedColor.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: updatedColor,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: updatedColor,
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

  Widget _buildArtistMarketingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Artist Marketing',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.purple.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.campaign,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Promote Your Art',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create animated ads featuring your artwork to reach more art lovers',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.blue.shade700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToCreateArtistApprovedAd(context),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create Artist Approved Ad'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber.shade600, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Premium feature: Animated GIF ads with your artwork',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToCreateArtistApprovedAd(BuildContext context) {
    // TODO: Implement artist approved ad creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Artist approved ad creation coming soon!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
            showSearch: false,
            showDeveloperTools: true,
            onProfilePressed: () =>
                Navigator.pushNamed(context, '/artist/profile'),
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
            backgroundColor: Colors.transparent,
            foregroundColor: core.ArtbeatColors.textPrimary,
            elevation: 0,
          ),
        ),
      ),
      body: _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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
              onPressed: _loadArtistData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final surfaceColor = Theme.of(context).colorScheme.surface;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surfaceColor,
            surfaceColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats Overview Section
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
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildStatCard(
                        'Total Sales',
                        '\$${_quickStats['totalSales']?.toString() ?? '0.00'}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Total Artworks',
                        _quickStats['totalArtworks']?.toString() ?? '0',
                        Icons.palette,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Total Gifts',
                        '\$${_quickStats['totalGiftValue']?.toString() ?? '0.00'}',
                        Icons.card_giftcard,
                        Colors.purple,
                      ),
                      _buildStatCard(
                        'Sponsorships',
                        '\$${_quickStats['sponsorshipsValue']?.toString() ?? '0.00'}',
                        Icons.handshake,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Artist Marketing Section
                  _buildArtistMarketingSection(context),
                  const SizedBox(height: 24),

                  // Recent Activity Section
                  if (_recentActivities.isNotEmpty) ...[
                    Text(
                      'Recent Activity',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentActivities.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final activity = _recentActivities[index];
                        final activityColor = activity.type.color;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: activityColor.withValues(
                              alpha: 0.2,
                            ),
                            child: Icon(
                              activity.type.icon,
                              color: activityColor,
                            ),
                          ),
                          title: Text(activity.title),
                          subtitle: Text(activity.description),
                          trailing: Text(
                            activity.timeAgo,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/artist/activity');
                        },
                        child: const Text('View All Activity'),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
