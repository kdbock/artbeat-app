import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_community/artbeat_community.dart' show PostModel;
import '../widgets/user_experience_card.dart';

/// Fluid Dashboard Screen with seamless scrolling and better UX
///
/// This is the redesigned main dashboard for the ARTbeat app, featuring:
/// - Fluid, continuous scrolling without jarring stops
/// - Intuitive layout optimized for artists and art enthusiasts
/// - Enhanced visual hierarchy with artistic gradients
/// - Optimized performance with smart loading
/// - Beautiful artistic design elements
/// - Preserved all original functionality from dashboard_screen.dart
/// - Reduced debugging noise
/// - Better mobile experience with responsive design
///
/// Usage: Replace DashboardScreen with FluidDashboardScreen in app.dart routing
class FluidDashboardScreen extends StatefulWidget {
  const FluidDashboardScreen({super.key});

  @override
  State<FluidDashboardScreen> createState() => _FluidDashboardScreenState();
}

class _FluidDashboardScreenState extends State<FluidDashboardScreen> {
  late ScrollController _scrollController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Initialize dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final viewModel = context.read<DashboardViewModel>();
      viewModel.initialize();

      // Debug: Verify drawer is available
      debugPrint('FluidDashboardScreen initialized');
      debugPrint('Scaffold key: $_scaffoldKey');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building FluidDashboardScreen...');

    return MainLayout(
      currentIndex: 0, // Home is index 0
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
              title: 'ARTbeat',
              showLogo: false,
              showSearch: true,
              showDeveloperTools: true,
              onSearchPressed: () => Navigator.pushNamed(context, '/search'),
              onProfilePressed: () => _showProfileMenu(context),
              onMenuPressed: () {
                debugPrint('Menu button pressed');
                _openDrawer(context);
              },
              backgroundColor: Colors.transparent,
              foregroundColor: ArtbeatColors.textPrimary,
              elevation: 0,
            ),
          ),
        ),
        body: Container(
          decoration: _buildArtisticBackground(),
          child: SafeArea(
            child: Consumer<DashboardViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoadingUser) {
                  return _buildLoadingState();
                }
                return _buildFluidContent(viewModel);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _openDrawer(BuildContext context) {
    debugPrint('Attempting to open drawer...');

    // First try using the GlobalKey
    if (_scaffoldKey.currentState != null) {
      debugPrint('Opening drawer using GlobalKey...');
      _scaffoldKey.currentState!.openDrawer();
      return;
    }

    // Fallback to Scaffold.maybeOf
    final scaffoldState = Scaffold.maybeOf(context);
    debugPrint('Scaffold state: $scaffoldState');

    if (scaffoldState != null && scaffoldState.hasDrawer) {
      debugPrint('Opening drawer using Scaffold.maybeOf...');
      scaffoldState.openDrawer();
    } else {
      debugPrint('No drawer found or scaffold state is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigation drawer not available'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.explore,
                      color: ArtbeatColors.primaryPurple,
                      size: 24,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discover & Connect',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Find artists, explore art, join the community',
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
              ),

              // Menu items
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildProfileMenuTile(
                      icon: Icons.person_search,
                      title: 'Find Artists',
                      subtitle: 'Discover local and featured artists',
                      color: ArtbeatColors.primaryPurple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artist/search');
                      },
                    ),
                    _buildProfileMenuTile(
                      icon: Icons.trending_up,
                      title: 'Trending',
                      subtitle: 'Popular artists and trending art',
                      color: ArtbeatColors.warning,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/trending');
                      },
                    ),
                    _buildProfileMenuTile(
                      icon: Icons.palette,
                      title: 'Browse Artwork',
                      subtitle: 'Explore art collections and galleries',
                      color: ArtbeatColors.primaryGreen,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artwork/browse');
                      },
                    ),
                    _buildProfileMenuTile(
                      icon: Icons.location_on,
                      title: 'Local Scene',
                      subtitle: 'Art events and spaces near you',
                      color: ArtbeatColors.error,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/local');
                      },
                    ),
                    _buildProfileMenuTile(
                      icon: Icons.account_circle,
                      title: 'My Profile',
                      subtitle: 'View and edit your profile',
                      color: ArtbeatColors.info,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/profile');
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
              border: Border.all(color: color.withAlphaValue(0.2)),
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
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ArtbeatColors.textSecondary,
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

  Widget _buildFluidContent(DashboardViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: () => viewModel.refresh(),
      color: ArtbeatColors.primaryPurple,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Hero welcome section
          SliverToBoxAdapter(child: _buildHeroWelcomeSection(viewModel)),

          // Map preview section
          SliverToBoxAdapter(child: _buildMapPreviewSection(viewModel)),

          // Quick actions section
          SliverToBoxAdapter(child: _buildQuickActionsSection(viewModel)),

          // Recent captures section
          if (viewModel.captures.isNotEmpty)
            SliverToBoxAdapter(child: _buildRecentCapturesSection(viewModel)),

          // Artists showcase section
          SliverToBoxAdapter(child: _buildArtistsShowcaseSection(viewModel)),

          // Community highlights section
          SliverToBoxAdapter(
            child: _buildCommunityHighlightsSection(viewModel),
          ),

          // Artwork gallery section
          SliverToBoxAdapter(child: _buildArtworkGallerySection(viewModel)),

          // Events section
          SliverToBoxAdapter(child: _buildEventsSection(viewModel)),

          // Artist CTA section
          SliverToBoxAdapter(child: _buildArtistCTASection()),

          // Bottom padding for navigation
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeroWelcomeSection(DashboardViewModel viewModel) {
    final user = viewModel.currentUser;
    if (user == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
              ArtbeatColors.primaryGreen.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Welcome to ARTbeat!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.primaryPurple,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Where will art take you today?',
              style: TextStyle(
                fontSize: 16,
                color: ArtbeatColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: UserExperienceCard(
        key: ValueKey<String>(user.id),
        user: user,
        achievements: viewModel.achievements,
        onTap: () => Navigator.pushNamed(context, '/achievements'),
        showAnimations: true,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildQuickActionsSection(DashboardViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.directions_walk,
                  title: 'Start Art Walk',
                  subtitle: 'Discover nearby art',
                  color: ArtbeatColors.primaryGreen,
                  onTap: () =>
                      Navigator.pushNamed(context, '/art-walk/dashboard'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.camera_alt,
                  title: 'Capture Art',
                  subtitle: 'Share your finds',
                  color: ArtbeatColors.primaryPurple,
                  onTap: () =>
                      Navigator.pushNamed(context, '/capture/dashboard'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.people,
                  title: 'Community',
                  subtitle: 'Connect with artists',
                  color: ArtbeatColors.secondaryTeal,
                  onTap: () =>
                      Navigator.pushNamed(context, '/community/dashboard'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.event,
                  title: 'Events',
                  subtitle: 'Find art events',
                  color: ArtbeatColors.accentYellow,
                  onTap: () =>
                      Navigator.pushNamed(context, '/events/dashboard'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withAlphaValue(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withAlphaValue(0.1), width: 1),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: ArtbeatColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPreviewSection(DashboardViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Art Around You',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              SizedBox(
                height: 32,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/art-walk/dashboard'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: ArtbeatColors.primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Art Walks Near You',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, '/art-walk/dashboard'),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: viewModel.isLoadingMap
                        ? Container(
                            color: ArtbeatColors.backgroundSecondary,
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ArtbeatColors.primaryPurple,
                                ),
                              ),
                            ),
                          )
                        : GoogleMap(
                            mapType: MapType.normal,
                            initialCameraPosition:
                                viewModel.initialCameraPosition,
                            onMapCreated: viewModel.onMapCreated,
                            markers: viewModel.markers,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: IconButton(
                    icon: const Icon(
                      Icons.my_location,
                      color: ArtbeatColors.primaryPurple,
                    ),
                    tooltip: 'Sync to your location',
                    onPressed: () {
                      viewModel.centerMapOnUserLocation();
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCapturesSection(DashboardViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Captures',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/capture/dashboard'),
                child: const Text('Find Art'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: viewModel.captures.length.clamp(0, 10),
              itemBuilder: (context, index) {
                final capture = viewModel.captures[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16),
                  child: _buildCaptureCard(capture),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureCard(CaptureModel capture) {
    return GestureDetector(
      onTap: () {
        // Navigate to capture detail screen
        Navigator.pushNamed(
          context,
          '/capture/detail',
          arguments: capture.id, // Pass only the capture ID as a String
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlphaValue(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: capture.imageUrl.isNotEmpty
                    ? Image.network(
                        capture.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: ArtbeatColors.backgroundSecondary,
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ArtbeatColors.primaryPurple,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: ArtbeatColors.backgroundSecondary,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capture.title != null && capture.title!.isNotEmpty
                        ? capture.title!
                        : 'Untitled Capture',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ArtbeatColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    capture.locationName != null &&
                            capture.locationName!.isNotEmpty
                        ? capture.locationName!
                        : 'Unknown Location',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ArtbeatColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistsShowcaseSection(DashboardViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Featured Artists',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/artist_list'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (viewModel.isLoadingArtists)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  ArtbeatColors.primaryPurple,
                ),
              ),
            )
          else if (viewModel.artists.isEmpty)
            _buildEmptyState(
              icon: Icons.person_outline,
              title: 'No artists yet',
              subtitle: 'Be the first to join as an artist!',
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: viewModel.artists.length.clamp(0, 10),
                itemBuilder: (context, index) {
                  final artist = viewModel.artists[index];
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 16),
                    child: _buildArtistCard(artist),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArtistCard(ArtistProfileModel artist) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlphaValue(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
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
                          size: 40,
                          color: ArtbeatColors.primaryPurple,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  artist.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ArtbeatColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (artist.bio != null && artist.bio!.isNotEmpty)
                  Text(
                    artist.bio!,
                    style: const TextStyle(
                      color: ArtbeatColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityHighlightsSection(DashboardViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Community Highlights',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/community/dashboard'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (viewModel.isLoadingPosts)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  ArtbeatColors.primaryPurple,
                ),
              ),
            )
          else if (viewModel.posts.isEmpty)
            _buildEmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'No posts yet',
              subtitle: 'Be the first to share with the community!',
            )
          else
            Column(
              children: viewModel.posts
                  .take(3)
                  .map((post) => _buildCommunityPostCard(post))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCommunityPostCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlphaValue(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: ArtbeatColors.primaryPurple.withValues(
                  alpha: 0.1,
                ),
                child: Text(
                  post.userName.isNotEmpty
                      ? post.userName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: ArtbeatColors.primaryPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName.isNotEmpty ? post.userName : 'Unknown User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: ArtbeatColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(post.createdAt),
                      style: const TextStyle(
                        color: ArtbeatColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 14,
              color: ArtbeatColors.textPrimary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkGallerySection(DashboardViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Artwork Gallery',
                  style: TextStyle(
                    fontSize: 20,
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
          const SizedBox(height: 16),
          if (viewModel.isLoadingArtworks)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  ArtbeatColors.primaryPurple,
                ),
              ),
            )
          else if (viewModel.artworks.isEmpty)
            _buildEmptyState(
              icon: Icons.palette_outlined,
              title: 'No artwork yet',
              subtitle: 'Artists will showcase their work here!',
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: viewModel.artworks.length.clamp(0, 10),
                itemBuilder: (context, index) {
                  final artwork = viewModel.artworks[index];
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 16),
                    child: _buildArtworkCard(artwork),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArtworkCard(ArtworkModel artwork) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlphaValue(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: artwork.imageUrl.isNotEmpty
                    ? Image.network(
                        artwork.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: ArtbeatColors.backgroundSecondary,
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ArtbeatColors.primaryPurple,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: ArtbeatColors.backgroundSecondary,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ArtbeatColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artwork.userId.isNotEmpty
                        ? 'Artist: ${artwork.userId}'
                        : 'Unknown Artist',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ArtbeatColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection(DashboardViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Upcoming Events',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/events'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (viewModel.isLoadingEvents)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  ArtbeatColors.primaryPurple,
                ),
              ),
            )
          else if (viewModel.events.isEmpty)
            _buildEmptyState(
              icon: Icons.event_outlined,
              title: 'No events yet',
              subtitle: 'Check back soon for exciting art events!',
            )
          else
            Column(
              children: viewModel.events
                  .take(3)
                  .map((event) => _buildEventCard(event))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlphaValue(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: ArtbeatColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatEventDate(event.startDate),
                style: const TextStyle(
                  fontSize: 12,
                  color: ArtbeatColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: ArtbeatColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ArtbeatColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              event.description,
              style: const TextStyle(
                fontSize: 14,
                color: ArtbeatColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArtistCTASection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ArtbeatColors.primaryPurple, ArtbeatColors.primaryGreen],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.palette, size: 48, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            'Are you an artist?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Join our community of artists and showcase your work to art enthusiasts around the world.',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/artist/onboarding'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ArtbeatColors.primaryPurple,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Join as Artist',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtbeatColors.border, width: 1),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: ArtbeatColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: ArtbeatColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(ArtbeatColors.primaryPurple),
      ),
    );
  }

  BoxDecoration _buildArtisticBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE3F2FD), // Light blue
          Color(0xFFF8FBFF), // Very light blue/white
          Color(0xFFE1F5FE), // Light cyan blue
          Color(0xFFBBDEFB), // Slightly darker blue (darkest corner)
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
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

  String _formatEventDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
