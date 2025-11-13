import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_artist/artbeat_artist.dart';
import '../../theme/artbeat_colors.dart';
import '../../theme/artbeat_typography.dart';
import '../../models/user_model.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/artbeat_drawer.dart';

/// Artist Dashboard - Focused on Creation, Analytics, and Business Management
///
/// Designed for artists who want to:
/// - Showcase and manage their artwork
/// - Track analytics and engagement
/// - Manage commissions and sales
/// - Connect with fans and galleries
class ArtistDashboard extends StatefulWidget {
  const ArtistDashboard({super.key, required this.user});

  final UserModel user;

  @override
  State<ArtistDashboard> createState() => _ArtistDashboardState();
}

class _ArtistDashboardState extends State<ArtistDashboard> {
  final ScrollController _scrollController = ScrollController();

  // Data state
  Map<String, dynamic>? _analyticsData;
  List<artwork.ArtworkModel>? _artworks;
  EarningsModel? _earnings;
  bool _isLoadingData = true;
  String? _dataError;

  @override
  void initState() {
    super.initState();
    _loadArtistData();
  }

  Future<void> _loadArtistData() async {
    setState(() {
      _isLoadingData = true;
      _dataError = null;
    });

    try {
      // Load analytics data
      final analyticsService = AnalyticsService();
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));
      _analyticsData = await analyticsService.getBasicArtistAnalyticsData(
        widget.user.id,
        startDate,
        endDate,
      );

      // Load artworks
      final artworkService = artwork.ArtworkPaginationService();
      final artworksResult = await artworkService.loadArtistArtworks(
        artistId: widget.user.id,
      );
      _artworks = artworksResult.items;

      // Load earnings
      final earningsService = EarningsService();
      _earnings = await earningsService.getArtistEarnings();

      setState(() {
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _dataError = e.toString();
        _isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ArtbeatDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: ArtbeatColors.primaryPurple,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar with Artist Profile
            _buildAppBar(),

            // Welcome Section
            _buildWelcomeSection(),

            // Quick Actions for Artists
            _buildQuickActions(),

            // Recent Activity
            _buildRecentActivity(),

            // Analytics Overview
            _buildAnalyticsOverview(),

            // Commission Hub
            _buildCommissionHub(),

            // Artwork Management
            _buildArtworkManagement(),

            // Community Engagement
            _buildCommunityEngagement(),

            // Business Tools
            _buildBusinessTools(),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: const SizedBox.shrink(),
      actions: [
        IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu, color: ArtbeatColors.textPrimary),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  UserAvatar(
                    imageUrl: widget.user.profileImageUrl.isNotEmpty
                        ? widget.user.profileImageUrl
                        : null,
                    displayName: widget.user.username,
                    radius: 30.0,
                    isVerified: true, // Artists are verified
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'artist_dashboard_welcome_back'.tr(
                            args: [widget.user.username],
                          ),
                          style: ArtbeatTypography.textTheme.headlineSmall!,
                        ),
                        Text(
                          'artist_dashboard_manage_your_art'.tr(),
                          style: ArtbeatTypography.textTheme.bodyMedium!,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ArtbeatColors.primaryGreen, ArtbeatColors.primaryPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ArtbeatColors.primaryGreen.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.palette, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'artist_dashboard_your_studio'.tr(),
                    style: ArtbeatTypography.textTheme.headlineMedium!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'artist_dashboard_manage_create_connect'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _navigateToUploadArtwork(context),
                icon: const Icon(Icons.add_photo_alternate),
                label: Text('artist_dashboard_upload_artwork'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ArtbeatColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'artist_dashboard_quick_actions'.tr(),
              style: ArtbeatTypography.textTheme.headlineSmall!,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActionCard(
                  icon: Icons.analytics,
                  title: 'artist_dashboard_analytics'.tr(),
                  subtitle: 'artist_dashboard_track_performance'.tr(),
                  color: ArtbeatColors.primaryGreen,
                  onTap: () => _navigateToAnalytics(context),
                ),
                const SizedBox(width: 12),
                _buildActionCard(
                  icon: Icons.attach_money,
                  title: 'artist_dashboard_earnings'.tr(),
                  subtitle: 'artist_dashboard_manage_income'.tr(),
                  color: ArtbeatColors.accentGold,
                  onTap: () => _navigateToEarnings(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActionCard(
                  icon: Icons.handshake,
                  title: 'artist_dashboard_commissions'.tr(),
                  subtitle: 'artist_dashboard_manage_requests'.tr(),
                  color: ArtbeatColors.primaryPurple,
                  onTap: () => _navigateToCommissions(context),
                ),
                const SizedBox(width: 12),
                _buildActionCard(
                  icon: Icons.edit,
                  title: 'artist_dashboard_profile'.tr(),
                  subtitle: 'artist_dashboard_update_info'.tr(),
                  color: ArtbeatColors.primaryBlue,
                  onTap: () => _navigateToProfile(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: ArtbeatTypography.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: ArtbeatTypography.textTheme.bodyMedium!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'artist_dashboard_recent_activity'.tr(),
                  style: ArtbeatTypography.textTheme.headlineSmall!,
                ),
                TextButton(
                  onPressed: () => _navigateToActivityFeed(context),
                  child: Text('artist_dashboard_view_all'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_up,
                    color: ArtbeatColors.primaryGreen,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'artist_dashboard_great_progress'.tr(),
                          style: ArtbeatTypography.textTheme.titleLarge!,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'artist_dashboard_keep_creating'.tr(),
                          style: ArtbeatTypography.textTheme.bodyMedium!,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsOverview() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bar_chart,
                    color: ArtbeatColors.primaryGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'artist_dashboard_analytics_overview'.tr(),
                    style: ArtbeatTypography.textTheme.headlineSmall!,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_dataError != null)
                Center(
                  child: Text(
                    'Failed to load analytics data',
                    style: ArtbeatTypography.textTheme.bodyMedium!.copyWith(
                      color: ArtbeatColors.error,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    _buildAnalyticsStat(
                      icon: Icons.visibility,
                      value: _isLoadingData
                          ? '...'
                          : (_analyticsData?['totalArtworkViews'] ?? 0)
                                .toString(),
                      label: 'artist_dashboard_views'.tr(),
                      color: ArtbeatColors.primaryPurple,
                    ),
                    _buildAnalyticsStat(
                      icon: Icons.favorite,
                      value: _isLoadingData
                          ? '...'
                          : (_analyticsData?['totalArtwork'] ?? 0).toString(),
                      label: 'artist_dashboard_artworks'.tr(),
                      color: Colors.red,
                    ),
                    _buildAnalyticsStat(
                      icon: Icons.people,
                      value: _isLoadingData
                          ? '...'
                          : (_analyticsData?['totalProfileViews'] ?? 0)
                                .toString(),
                      label: 'artist_dashboard_profile_views'.tr(),
                      color: ArtbeatColors.primaryGreen,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: ArtbeatTypography.textTheme.headlineSmall!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: ArtbeatTypography.textTheme.bodyMedium!,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionHub() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'artist_dashboard_commission_hub'.tr(),
              style: ArtbeatTypography.textTheme.headlineSmall!,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.handshake,
                    color: ArtbeatColors.primaryPurple,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'artist_dashboard_active_commissions'.tr(),
                          style: ArtbeatTypography.textTheme.titleLarge!,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'artist_dashboard_manage_opportunities'.tr(),
                          style: ArtbeatTypography.textTheme.bodyMedium!,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ArtbeatColors.primaryPurple,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _dataError != null
                          ? 'Error'
                          : _isLoadingData
                          ? '...'
                          : '\$${_earnings?.commissionEarnings.toStringAsFixed(0) ?? '0'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtworkManagement() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'artist_dashboard_your_artwork'.tr(),
                  style: ArtbeatTypography.textTheme.headlineSmall!,
                ),
                TextButton(
                  onPressed: () => _navigateToArtworkManagement(context),
                  child: Text('artist_dashboard_manage_all'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator())
                  : _artworks?.isEmpty ?? true
                  ? Center(
                      child: Text(
                        'artist_dashboard_no_artworks_yet'.tr(),
                        style: ArtbeatTypography.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _artworks?.length ?? 0,
                      itemBuilder: (context, index) {
                        final artwork = _artworks![index];
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(artwork.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  artwork.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityEngagement() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ArtbeatColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.people,
                color: ArtbeatColors.primaryBlue,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'artist_dashboard_engage_fans'.tr(),
                      style: ArtbeatTypography.textTheme.titleLarge!,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'artist_dashboard_build_community'.tr(),
                      style: ArtbeatTypography.textTheme.bodyMedium!,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _navigateToCommunity(context),
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: ArtbeatColors.primaryBlue,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessTools() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'artist_dashboard_business_tools'.tr(),
              style: ArtbeatTypography.textTheme.headlineSmall!,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildBusinessToolCard(
                  icon: Icons.campaign,
                  title: 'artist_dashboard_advertise'.tr(),
                  subtitle: 'artist_dashboard_promote_work'.tr(),
                  color: ArtbeatColors.accentOrange,
                ),
                const SizedBox(width: 12),
                _buildBusinessToolCard(
                  icon: Icons.store,
                  title: 'artist_dashboard_sales'.tr(),
                  subtitle: 'artist_dashboard_track_revenue'.tr(),
                  color: ArtbeatColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: ArtbeatTypography.textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: ArtbeatTypography.textTheme.bodyMedium!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    // Simulate refresh
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  // Navigation methods
  void _navigateToUploadArtwork(BuildContext context) {
    Navigator.pushNamed(context, '/artwork/upload');
  }

  void _navigateToAnalytics(BuildContext context) {
    Navigator.pushNamed(context, '/artist/analytics');
  }

  void _navigateToEarnings(BuildContext context) {
    Navigator.pushNamed(context, '/artist/earnings');
  }

  void _navigateToCommissions(BuildContext context) {
    Navigator.pushNamed(context, '/commission/hub');
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, '/artist/profile-edit');
  }

  void _navigateToActivityFeed(BuildContext context) {
    Navigator.pushNamed(context, '/artist/dashboard');
  }

  void _navigateToArtworkManagement(BuildContext context) {
    Navigator.pushNamed(context, '/artist/artwork');
  }

  void _navigateToCommunity(BuildContext context) {
    Navigator.pushNamed(context, '/community/feed');
  }
}
