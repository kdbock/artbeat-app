import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_community/artbeat_community.dart' show PostModel;
import 'package:artbeat_community/screens/feed/unified_community_feed.dart';
import 'events_dashboard_screen.dart';
import '../widgets/dashboard/achievement_dropdown.dart';

/// Dashboard Screen with ViewModel-based state management
///
/// This is the main dashboard for the ARTbeat app, displaying:
/// - User welcome section with level progress
/// - Achievement badges
/// - Tab-based navigation (Explore, Artists, Artwork)
/// - Bottom navigation
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Set correct bottomNavIndex based on route when dashboard is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<DashboardViewModel>();
      final currentRoute = ModalRoute.of(context)?.settings.name;
      int navIndex = 0;
      switch (currentRoute) {
        case '/dashboard':
          navIndex = 0;
          break;
        case '/art-walk/dashboard':
          navIndex = 1;
          break;
        case '/community':
          navIndex = 2;
          break;
        case '/events':
          navIndex = 3;
          break;
        case '/capture':
          navIndex = 4;
          break;
      }
      viewModel.updateBottomNavIndex(navIndex);
    });

    // Initialize dashboard data using ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<DashboardViewModel>();
      viewModel.initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UniversalHeader(title: 'ARTbeat', showDeveloperTools: true),
      drawer: const ArtbeatDrawer(),
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
              Colors.white,
              ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<DashboardViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoadingUser) {
                return const Center(child: CircularProgressIndicator());
              }
              return RefreshIndicator(
                onRefresh: () => viewModel.refresh(),
                child: Stack(
                  children: [
                    // Use IndexedStack to switch content based on bottomNavIndex
                    IndexedStack(
                      index: viewModel.bottomNavIndex,
                      children: [
                        // 0: Main dashboard tabs
                        Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildWelcomeSection(viewModel),
                                    _buildMapSection(viewModel),
                                    _buildQuickActionCards(viewModel),
                                    const SizedBox(height: 16),
                                    _buildTabBar(),
                                    _buildTabContent(viewModel),
                                    Container(
                                      margin: const EdgeInsets.all(16),
                                      child: _buildEventsSection(viewModel),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(16),
                                      child: _buildArtistCTASection(),
                                    ),
                                    const SizedBox(height: 80),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // 1: Art Walk dashboard (navigate or show placeholder)
                        Center(
                          child: Text(
                            'Art Walk Dashboard (TODO: Implement or navigate)',
                          ),
                        ),
                        // 2: Community feed
                        const UnifiedCommunityFeed(),
                        // 3: Events dashboard
                        const EventsDashboardScreen(),
                        // 4: Capture (should be handled by navigation, show empty)
                        Container(),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: Consumer<DashboardViewModel>(
        builder: (context, viewModel, child) {
          return UniversalBottomNav(
            currentIndex: viewModel.bottomNavIndex,
            onTap: (int index) {
              viewModel.updateBottomNavIndex(index);
              _handleBottomNavigation(context, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildMapSection(DashboardViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: viewModel.isLoadingMap
            ? Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              )
            : GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: viewModel.initialCameraPosition,
                onMapCreated: viewModel.onMapCreated,
                markers: viewModel.markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
      ),
    );
  }

  Widget _buildWelcomeSection(DashboardViewModel viewModel) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(
        0,
      ), // Remove default padding for custom hero
      decoration: BoxDecoration(
        color: ArtbeatColors.backgroundSecondary,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryPurple.withValues(alpha: 0.08),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withValues(alpha: 0.07),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section with image/illustration and headline
          Stack(
            children: [
              // Hero image or illustration (replace with your own asset if desired)
              Positioned(
                right: 0,
                top: 0,
                child: Opacity(
                  opacity: 0.18,
                  child: Image.asset(
                    'assets/images/artbeat_logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewModel.currentUser != null
                          ? 'Welcome Art Explorer, ${viewModel.currentUser!.fullName}.'
                          : 'Welcome Art Explorer.',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: ArtbeatColors.primaryPurple,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ready to explore art near you? Discover, walk, and celebrate creativity in your city.',
                      style: TextStyle(
                        fontSize: 15,
                        color: ArtbeatColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/art-walk/dashboard',
                            ),
                            icon: const Icon(
                              Icons.directions_walk,
                              color: Colors.white,
                            ),
                            label: const Text('Start Art Walk'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ArtbeatColors.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/art-walk/dashboard',
                            ),
                            icon: const Icon(
                              Icons.palette,
                              color: ArtbeatColors.primaryPurple,
                            ),
                            label: const Text('Browse Art Walks'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ArtbeatColors.primaryPurple,
                              side: const BorderSide(
                                color: ArtbeatColors.primaryPurple,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // User progress and achievements
          if (viewModel.currentUser != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level ${viewModel.currentUser!.level}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${viewModel.currentUser!.experiencePoints} XP',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: viewModel.getLevelProgress(),
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      ArtbeatColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    viewModel.getLevelTitle(viewModel.currentUser!.level),
                    style: const TextStyle(
                      fontSize: 11,
                      color: ArtbeatColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Discover local art, connect with artists, and join the creative community.',
                style: TextStyle(
                  fontSize: 14,
                  color: ArtbeatColors.textSecondary,
                ),
              ),
            ),
          ],
          // Achievement dropdown below exp bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AchievementDropdown(
              achievements: viewModel.achievements,
              isLoading: viewModel.isLoadingAchievements,
              isExpanded: viewModel.isAchievementsExpanded,
              onToggle: viewModel.toggleAchievementsExpansion,
            ),
          ),
          // Debug: Show button if no achievements
          if (!viewModel.isLoadingAchievements &&
              viewModel.achievements.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 20, right: 20),
              child: Column(
                children: [
                  Text(
                    'No achievements yet.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => viewModel.debugAwardTestAchievements(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('DEBUG: Award Test Achievements'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: ArtbeatColors.primaryPurple,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: ArtbeatColors.primaryPurple,
        tabs: const [
          Tab(text: 'Explore'),
          Tab(text: 'Artists'),
          Tab(text: 'Artwork'),
        ],
      ),
    );
  }

  Widget _buildTabContent(DashboardViewModel viewModel) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = MediaQuery.of(context).size.height;
        const double reservedHeight =
            350; // Reduced space for header, nav, welcome, etc.
        final double tabHeight = (availableHeight - reservedHeight).clamp(
          250.0, // Reduced minimum height
          400.0, // Reduced maximum height
        );

        return SizedBox(
          height: tabHeight,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Explore Tab
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: tabHeight),
                  child: _buildExploreTab(viewModel),
                ),
              ),
              // Artists Tab
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: tabHeight),
                  child: _buildArtistsTab(viewModel),
                ),
              ),
              // Artwork Tab
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: tabHeight),
                  child: _buildArtworkTab(viewModel),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExploreTab(DashboardViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore ARTbeat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Community posts preview
          _buildCommunityCritiqueSection(viewModel),
          const SizedBox(height: 16),

          // Recent captures
          if (viewModel.captures.isNotEmpty) ...[
            const Text(
              'Recent Captures',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: viewModel.captures.length > 5
                    ? 5
                    : viewModel.captures.length,
                itemBuilder: (context, index) =>
                    _buildCapturedArtCard(viewModel.captures[index]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArtistsTab(DashboardViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Local Artists',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/artist/browse'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (viewModel.isLoadingArtists)
            const Center(child: CircularProgressIndicator())
          else if (viewModel.artists.isEmpty)
            _buildEmptyState(
              icon: Icons.person_outline,
              title: 'No artists found',
              subtitle: 'Be the first to join as an artist!',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: viewModel.artists.length > 6
                  ? 6
                  : viewModel.artists.length,
              itemBuilder: (context, index) =>
                  _buildArtistCard(viewModel.artists[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildArtworkTab(DashboardViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Recent Artwork',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/artwork/browse'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (viewModel.isLoadingArtworks)
            const Center(child: CircularProgressIndicator())
          else if (viewModel.artworks.isEmpty)
            _buildEmptyState(
              icon: Icons.palette_outlined,
              title: 'No artwork found',
              subtitle: 'Artists will showcase their work here!',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: viewModel.artworks.length > 6
                  ? 6
                  : viewModel.artworks.length,
              itemBuilder: (context, index) =>
                  _buildArtworkCard(viewModel.artworks[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12), // Reduced from 16
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ArtbeatColors.primaryPurple, ArtbeatColors.primaryGreen],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
              blurRadius: 6, // Reduced from 8
              offset: const Offset(0, 3), // Reduced from 4
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24), // Reduced from 32
            const SizedBox(height: 6), // Reduced from 8
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14, // Added smaller font size
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ArtbeatColors.textSecondary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPostsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to share with the community!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Card builders for the tabs
  Widget _buildArtistCard(ArtistProfileModel artist) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/artist/public-profile',
            arguments: {'artistId': artist.userId},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: ArtbeatColors.primaryPurple.withValues(
                  alpha: 0.1,
                ),
                backgroundImage:
                    artist.profileImageUrl != null &&
                        artist.profileImageUrl!.isNotEmpty
                    ? NetworkImage(artist.profileImageUrl!)
                    : null,
                child:
                    artist.profileImageUrl == null ||
                        artist.profileImageUrl!.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 30,
                        color: ArtbeatColors.primaryPurple,
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                artist.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              if (artist.bio != null)
                Text(
                  artist.bio!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtworkCard(ArtworkModel artwork) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/artist/artwork-detail',
            arguments: {'artworkId': artwork.id},
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: artwork.imageUrl.isNotEmpty
                      ? Image.network(
                          artwork.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 40,
                              ),
                            );
                          },
                        )
                      : Icon(Icons.image, color: Colors.grey[400], size: 40),
                ),
              ),
            ),
            // Artwork info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (artwork.price != null)
                      Text(
                        '\$${artwork.price!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: ArtbeatColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
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

  Widget _buildCapturedArtCard(CaptureModel capture) {
    return SizedBox(
      width: 150.0,
      height: 180.0,
      child: Container(
        margin: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _showCaptureDetails(context, capture),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Captured art image
              SizedBox(
                height: 100,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    capture.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capture.title ?? 'Untitled',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      capture.locationName ?? 'Unknown location',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  void _showCaptureDetails(BuildContext context, CaptureModel capture) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capture.title ?? 'Untitled',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (capture.description != null) ...[
                  Text(
                    capture.description!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                ],
                if (capture.locationName != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        capture.locationName!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/capture/detail',
                          arguments: capture.id,
                        );
                      },
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // New widget methods for missing sections

  Widget _buildEventsSection(DashboardViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Upcoming Events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/events/dashboard'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (viewModel.isLoadingEvents)
          const Center(child: CircularProgressIndicator())
        else if (viewModel.events.isEmpty)
          _buildEmptyState(
            icon: Icons.event_outlined,
            title: 'No upcoming events',
            subtitle: 'Check back later for art events and exhibitions!',
          )
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: viewModel.events.length > 5
                  ? 5
                  : viewModel.events.length,
              itemBuilder: (context, index) =>
                  _buildEventCard(viewModel.events[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildEventCard(EventModel event) {
    return SizedBox(
      width: 200,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/events/detail',
              arguments: {'eventId': event.id},
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event image
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                        ? Image.network(
                            event.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.event,
                                  color: Colors.grey[400],
                                  size: 30,
                                ),
                              );
                            },
                          )
                        : Icon(Icons.event, color: Colors.grey[400], size: 30),
                  ),
                ),
              ),
              // Event info
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${event.startDate.month}/${event.startDate.day}',
                        style: const TextStyle(
                          color: ArtbeatColors.primaryPurple,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistCTASection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ArtbeatColors.primaryPurple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.brush, color: ArtbeatColors.primaryPurple, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you an artist?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ArtbeatColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Join our community and showcase your work',
                      style: TextStyle(
                        fontSize: 14,
                        color: ArtbeatColors.textSecondary,
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
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/artist/onboarding'),
              style:
                  ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                    overlayColor: WidgetStateProperty.all(
                      Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ArtbeatColors.primaryPurple,
                      ArtbeatColors.primaryGreen,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: const Text(
                    'Become an Artist',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardAdSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ArtbeatColors.primaryPurple,
                      ArtbeatColors.primaryGreen,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upgrade to ARTbeat Pro',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ArtbeatColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Unlock premium features and support local artists',
                      style: TextStyle(
                        fontSize: 12,
                        color: ArtbeatColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/subscription/comparison'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ArtbeatColors.primaryPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Learn More',
                    style: TextStyle(
                      color: ArtbeatColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/subscription/comparison'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ArtbeatColors.primaryPurple,
                          ArtbeatColors.primaryGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const Text(
                        'Upgrade',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCritiqueSection(DashboardViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Community Critique',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/community/feed'),
              child: const Text('Join Discussion'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Latest Community Posts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Post Content Slider
              if (viewModel.isLoadingPosts)
                const Center(child: CircularProgressIndicator())
              else if (viewModel.posts.isEmpty)
                _buildEmptyPostsState()
              else
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: viewModel.posts.length > 5
                        ? 5
                        : viewModel.posts.length,
                    itemBuilder: (context, index) =>
                        _buildPostSliderCard(viewModel.posts[index]),
                  ),
                ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/community/feed'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ArtbeatColors.primaryPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'View All Posts',
                    style: TextStyle(
                      color: ArtbeatColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostSliderCard(PostModel post) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/community/feed'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info row
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: ArtbeatColors.primaryPurple.withValues(
                      alpha: 0.1,
                    ),
                    backgroundImage: post.userPhotoUrl.isNotEmpty
                        ? NetworkImage(post.userPhotoUrl)
                        : null,
                    child: post.userPhotoUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 12,
                            color: ArtbeatColors.primaryPurple,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _getTimeAgo(post.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Post content
              Expanded(
                child: Text(
                  post.content,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ArtbeatColors.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Engagement stats
              Row(
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${post.applauseCount}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${post.commentCount}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  void _handleBottomNavigation(BuildContext context, int index) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    switch (index) {
      case 0:
        if (currentRoute != '/dashboard') {
          Navigator.pushNamed(context, '/dashboard');
        }
        break;
      case 1:
        if (currentRoute != '/art-walk/dashboard') {
          Navigator.pushNamed(context, '/art-walk/dashboard');
        }
        break;
      case 2:
        // Community: do not navigate, just update index (handled by viewModel)
        break;
      case 3:
        // Events: do not navigate, just update index (handled by viewModel)
        break;
      case 4:
        // For capture, use push (not replacement) so dashboard is not destroyed
        if (currentRoute != '/capture') {
          Navigator.pushNamed(context, '/capture');
        }
        break;
    }
  }

  Widget _buildQuickActionCards(DashboardViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.camera_alt,
              title: 'Capture Art',
              onTap: () => Navigator.pushNamed(context, '/capture/camera'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.directions_walk,
              title: 'Browse Art Walks',
              onTap: () => Navigator.pushNamed(context, '/art-walk/dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}
