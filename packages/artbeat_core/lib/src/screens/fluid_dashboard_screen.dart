import 'package:artbeat_artist/src/screens/artist_onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_capture/artbeat_capture.dart'
    show CaptureService, CaptureModel, CapturesListScreen;
import 'package:artbeat_community/artbeat_community.dart'
    show PostModel, ApplauseButton, GiftModal;
import 'package:cached_network_image/cached_network_image.dart';
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

// Static flag to prevent multiple dashboard builds
bool _isDashboardBuilding = false;

class _FluidDashboardScreenState extends State<FluidDashboardScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Initialize shimmer animation
    _shimmerController = SkeletonWidgets.createShimmerController(this);
    _shimmerAnimation = _shimmerController;

    // Initialize dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasInitialized) return;
      _hasInitialized = true;

      try {
        final viewModel = context.read<DashboardViewModel>();
        viewModel.initialize();

        // Debug: Verify drawer is available
        debugPrint('FluidDashboardScreen initialized');
        debugPrint('Scaffold key: $_scaffoldKey');
      } catch (e) {
        debugPrint('Error initializing dashboard: $e');
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDashboardBuilding) {
      debugPrint(
        '🔄 FluidDashboardScreen: Already building, preventing duplicate...',
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _isDashboardBuilding = true;
    debugPrint('🏠 Building FluidDashboardScreen...');

    // Reset the building flag after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isDashboardBuilding = false;
    });

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
                // Robust error handling for user data load
                if (viewModel.isLoadingUser || viewModel.isInitializing) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (viewModel.currentUser == null &&
                    !viewModel.isLoadingUser &&
                    !viewModel.isInitializing) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Unable to load your profile data.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please check your connection or try again.',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          onPressed: () => viewModel.refresh(),
                        ),
                      ],
                    ),
                  );
                }
                // Always show dashboard structure, use skeleton loading for individual sections
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

    // First try using the GlobalKey with null-safe access
    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState != null) {
      debugPrint('Opening drawer using GlobalKey...');
      scaffoldState.openDrawer();
      return;
    }

    // Fallback to Scaffold.maybeOf
    final fallbackScaffoldState = Scaffold.maybeOf(context);
    debugPrint('Scaffold state: $fallbackScaffoldState');

    if (fallbackScaffoldState != null && fallbackScaffoldState.hasDrawer) {
      debugPrint('Opening drawer using Scaffold.maybeOf...');
      fallbackScaffoldState.openDrawer();
    } else {
      debugPrint('No drawer found or scaffold state is null');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigation drawer not available'),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
                        Navigator.pushNamed(context, '/artwork/featured');
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
          // Hero Map Section with tagline overlay
          SliverToBoxAdapter(
            child: _buildSafeSection(() => _buildHeroMapSection(viewModel)),
          ),

          // User experience card (for logged in users)
          if (viewModel.currentUser != null)
            SliverToBoxAdapter(
              child: _buildSafeSection(
                () => _buildUserExperienceSection(viewModel),
              ),
            ),

          // App explanation section (for new/anonymous users)
          if (viewModel.currentUser == null)
            SliverToBoxAdapter(
              child: _buildSafeSection(() => _buildAppExplanationSection()),
            ),

          // Public Art Captures section
          SliverToBoxAdapter(
            child: _buildSafeSection(
              () => _buildRecentCapturesSection(viewModel),
            ),
          ),

          // Artists showcase section
          SliverToBoxAdapter(
            child: _buildSafeSection(
              () => _buildArtistsShowcaseSection(viewModel),
            ),
          ),

          // Artwork gallery section
          SliverToBoxAdapter(
            child: _buildSafeSection(
              () => _buildArtworkGallerySection(viewModel),
            ),
          ),

          // Community highlights section
          SliverToBoxAdapter(
            child: _buildSafeSection(
              () => _buildCommunityHighlightsSection(viewModel),
            ),
          ),

          // Events section
          SliverToBoxAdapter(
            child: _buildSafeSection(() => _buildEventsSection(viewModel)),
          ),

          // Artist CTA section
          SliverToBoxAdapter(
            child: _buildSafeSection(() => _buildArtistCTASection()),
          ),

          // Bottom padding for navigation
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeroMapSection(DashboardViewModel viewModel) {
    return Container(
      height: 400, // Taller hero section
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Map background
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: viewModel.isLoadingMap
                ? Container(
                    color: ArtbeatColors.backgroundSecondary,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ArtbeatColors.primaryGreen,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading your canvas...',
                          style: TextStyle(
                            color: ArtbeatColors.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : AbsorbPointer(
                    child: GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: viewModel.initialCameraPosition,
                      onMapCreated: viewModel.onMapCreated,
                      markers: viewModel.markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),
                  ),
          ),

          // Gradient overlay for text readability (extend further down)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.92),
                  Colors.black.withValues(alpha: 0.80),
                  Colors.black.withValues(alpha: 0.65),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.80),
                  Colors.black.withValues(alpha: 0.92),
                ],
                stops: const [0.0, 0.18, 0.32, 0.55, 0.82, 1.0],
              ),
            ),
          ),

          // Hero text overlay
          Positioned(
            top: 32,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ArtbeatColors.primaryPurple.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ARTbeat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'The city is the canvas.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const Text(
                  'You choose the path.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Removed the 'Discover public art...' text as requested
              ],
            ),
          ),

          // Action buttons at bottom
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/art-walk/map'),
                    icon: const Icon(Icons.explore, size: 20),
                    label: const Text('Explore Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtbeatColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/art-walk/dashboard'),
                    icon: const Icon(Icons.directions_walk, size: 20),
                    label: const Text('Art Walks'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      foregroundColor: ArtbeatColors.primaryGreen,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Location button
          Positioned(
            top: 24,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => viewModel.centerMapOnUserLocation(),
                icon: const Icon(
                  Icons.my_location,
                  color: ArtbeatColors.primaryGreen,
                ),
                tooltip: 'Center on my location',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserExperienceSection(DashboardViewModel viewModel) {
    final user = viewModel.currentUser;
    if (user == null) return const SizedBox.shrink();

    return UserExperienceCard(
      key: ValueKey<String>(user.id),
      user: user,
      achievements: viewModel.achievements,
      onTap: () => Navigator.pushNamed(context, '/achievements'),
      showAnimations: true,
      margin: const EdgeInsets.all(16),
    );
  }

  Widget _buildAppExplanationSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How ARTbeat Works',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildFeatureRow(
            Icons.camera_alt,
            'Capture Public Art',
            'Discover and photograph murals, sculptures, and street art around your city.',
            ArtbeatColors.primaryGreen,
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            Icons.palette,
            'Connect with Artists',
            'Follow local artists, view their portfolios, and support their work.',
            ArtbeatColors.primaryPurple,
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            Icons.directions_walk,
            'Take Art Walks',
            'Follow curated routes to discover the best art in your neighborhood.',
            ArtbeatColors.primaryGreen,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/auth'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Join ARTbeat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: ArtbeatColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(DashboardViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bolt,
                  color: ArtbeatColors.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // First row with animated cards
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildAnimatedQuickActionCard(
                  icon: Icons.directions_walk,
                  title: 'Start Art Walk',
                  subtitle: 'Discover nearby art installations and galleries',
                  color: ArtbeatColors.primaryGreen,
                  gradientColors: [
                    ArtbeatColors.primaryGreen,
                    ArtbeatColors.primaryGreen.withValues(alpha: 0.7),
                  ],
                  onTap: () => Navigator.pushNamed(context, '/art-walk/create'),
                ),
                _buildAnimatedQuickActionCard(
                  icon: Icons.camera_alt,
                  title: 'Capture Art',
                  subtitle:
                      'Share your artistic discoveries with the community',
                  color: ArtbeatColors.primaryPurple,
                  gradientColors: [
                    ArtbeatColors.primaryPurple,
                    ArtbeatColors.primaryPurple.withValues(alpha: 0.7),
                  ],
                  onTap: () =>
                      Navigator.pushNamed(context, '/capture/dashboard'),
                ),
                _buildAnimatedQuickActionCard(
                  icon: Icons.people,
                  title: 'Community',
                  subtitle: 'Connect with artists and art enthusiasts',
                  color: ArtbeatColors.secondaryTeal,
                  gradientColors: [
                    ArtbeatColors.secondaryTeal,
                    ArtbeatColors.secondaryTeal.withValues(alpha: 0.7),
                  ],
                  onTap: () =>
                      Navigator.pushNamed(context, '/community/dashboard'),
                ),
                _buildAnimatedQuickActionCard(
                  icon: Icons.event,
                  title: 'Events',
                  subtitle: 'Find art exhibitions and events near you',
                  color: ArtbeatColors.accentYellow,
                  gradientColors: [
                    ArtbeatColors.accentYellow,
                    ArtbeatColors.accentYellow.withValues(alpha: 0.7),
                  ],
                  onTap: () =>
                      Navigator.pushNamed(context, '/events/dashboard'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Feature buttons row
          Row(
            children: [
              _buildFeatureButton(
                icon: Icons.palette,
                label: 'Explore Art',
                onTap: () => Navigator.pushNamed(context, '/artwork/featured'),
              ),
              _buildFeatureButton(
                icon: Icons.route,
                label: 'My Art Walks',
                onTap: () => Navigator.pushNamed(context, '/art-walk/my-walks'),
              ),
              _buildFeatureButton(
                icon: Icons.map,
                label: 'Art Map',
                onTap: () => Navigator.pushNamed(context, '/art-walk/map'),
              ),
              Selector<MessagingProvider, ({bool hasUnread, int count})>(
                selector: (context, provider) => (
                  hasUnread: provider.hasUnreadMessages,
                  count: provider.unreadCount,
                ),
                builder: (context, data, child) {
                  return _buildFeatureButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Messages',
                    onTap: () => viewModel.showMessagingMenu(context),
                    showBadge: data.hasUnread,
                    badgeCount: data.count,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        color: const Color.fromARGB(0, 232, 152, 152),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circle
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 100),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8), // Reduced from 10
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 20,
                          ), // Reduced from 24
                        ),
                        const SizedBox(height: 8), // Reduced from 12
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16, // Reduced from 18
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2), // Reduced from 4
                        Flexible(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12, // Reduced from 14
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Arrow indicator
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2), // 0.2 opacity
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F8FF), // Very light blue
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(
                          255,
                          75,
                          73,
                          73,
                        ).withValues(alpha: 0.1), // 0.1 opacity
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: ArtbeatColors.primaryPurple,
                    size: 24,
                  ),
                ),
                if (showBadge)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: ArtbeatColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ArtbeatColors.textPrimary,
              ),
              textAlign: TextAlign.center,
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.map,
                  color: ArtbeatColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Art Around You',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/art-walk/dashboard'),
                icon: const Icon(Icons.directions_walk, size: 16),
                label: const Text('Art Walks'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArtbeatColors.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: ArtbeatColors.primaryGreen.withValues(
                    alpha: 0.4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: ArtbeatColors.primaryGreen.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Map container
                InkWell(
                  onTap: () {
                    debugPrint('🗺️ Map tapped - navigating to art walk map');
                    Navigator.pushNamed(context, '/art-walk/map');
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: ArtbeatColors.primaryGreen.withValues(
                          alpha: 0.3,
                        ), // 0.3 opacity
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: viewModel.isLoadingMap
                          ? Container(
                              color: ArtbeatColors.backgroundSecondary,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        ArtbeatColors.primaryGreen,
                                      ),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading art locations...',
                                    style: TextStyle(
                                      color: ArtbeatColors.primaryGreen,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : AbsorbPointer(
                              child: GoogleMap(
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
                ),

                // Location button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => viewModel.centerMapOnUserLocation(),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.my_location,
                            color: ArtbeatColors.primaryGreen,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Create art walk button
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/art-walk/create'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Create Art Walk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: ArtbeatColors.primaryGreen,
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: ArtbeatColors.primaryGreen.withValues(
                            alpha: 0.3,
                          ), // 0.3 opacity
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                // Art count indicator
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.palette,
                          color: ArtbeatColors.primaryGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${viewModel.markers.length} Art Pieces',
                          style: const TextStyle(
                            color: ArtbeatColors.textPrimary,
                            fontWeight: FontWeight.bold,
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

          // Art walks preview
          if (viewModel.userArtWalks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Your Art Walks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/art-walk/list'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: viewModel.userArtWalks.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final walk = viewModel.userArtWalks[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      elevation: 2,
                      shadowColor: ArtbeatColors.primaryGreen.withValues(
                        alpha: 0.3,
                      ), // 0.3 opacity
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/art-walk/detail',
                          arguments: {'walkId': walk.id},
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: ArtbeatColors.primaryGreen
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.directions_walk,
                                          color: ArtbeatColors.primaryGreen,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          walk.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    walk.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.place,
                                    size: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${walk.artPieces.length} stops',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 10,
                                    color: ArtbeatColors.primaryGreen,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: ArtbeatColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local Captures',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ArtbeatColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Street art, murals, and sculptures discovered by the community',
                      style: TextStyle(
                        fontSize: 14,
                        color: ArtbeatColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const CapturesListScreen(),
                  ),
                ),
                icon: const Icon(Icons.explore, size: 16),
                label: const Text('Local Captures'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArtbeatColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Use viewModel data instead of FutureBuilder to prevent repeated calls
          _buildCapturesContent(viewModel),
        ],
      ),
    );
  }

  Widget _buildCapturesContent(DashboardViewModel viewModel) {
    if (viewModel.isLoadingAllCaptures) {
      return SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: 4, // Show 4 skeleton cards
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(left: 12),
              child: SkeletonWidgets.captureCardSkeleton(_shimmerAnimation),
            );
          },
        ),
      );
    }

    if (viewModel.allCapturesError != null) {
      debugPrint('❌ Captures section error: ${viewModel.allCapturesError}');
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: ArtbeatColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: ArtbeatColors.textSecondary,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Unable to load captures',
                style: TextStyle(color: ArtbeatColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final captures = viewModel.allCaptures;
    if (captures.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: ArtbeatColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  color: ArtbeatColors.textSecondary,
                  size: 40,
                ),
                const SizedBox(height: 8),
                const Text(
                  'No public art captured yet',
                  style: TextStyle(
                    color: ArtbeatColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Be the first to discover and share art in your city!',
                  style: TextStyle(
                    color: ArtbeatColors.textSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/capture/dashboard'),
                    icon: const Icon(Icons.add_a_photo, size: 16),
                    label: const Text(
                      'Start Capturing',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtbeatColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: captures.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final capture = captures[index];
          return SizedBox(width: 150, child: _buildSafeCaptureCard(capture));
        },
      ),
    );
  }

  Widget _buildSafeCaptureCard(CaptureModel capture) {
    try {
      return _buildCaptureCard(capture);
    } catch (e) {
      debugPrint('❌ Error rendering capture card: $e');
      return Container(
        decoration: BoxDecoration(
          color: ArtbeatColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: ArtbeatColors.textSecondary,
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                'Error loading capture',
                style: TextStyle(
                  color: ArtbeatColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCaptureCard(CaptureModel capture) {
    return GestureDetector(
      onTap: () => _showCaptureDetailsPopup(capture),
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
        child: SizedBox(
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed image height
              SizedBox(
                height: 120,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: _buildCaptureImage(capture),
                ),
              ),
              // Info section expands to fill remaining space without overflow
              SizedBox(height: 80, child: _buildCaptureInfo(capture)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureImage(CaptureModel capture) {
    // Add null safety check for imageUrl
    final imageUrl = capture.imageUrl;
    if (imageUrl.isEmpty) {
      return Container(
        color: ArtbeatColors.backgroundSecondary,
        child: const Center(
          child: Icon(
            Icons.image,
            size: 48,
            color: ArtbeatColors.textSecondary,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
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
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Image loading error for capture ${capture.id}: $error');
        return Container(
          color: ArtbeatColors.backgroundSecondary,
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 48,
              color: ArtbeatColors.textSecondary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCaptureInfo(CaptureModel capture) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (capture.title?.isNotEmpty == true)
                ? capture.title ?? 'Untitled Capture'
                : 'Untitled Capture',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            (capture.locationName?.isNotEmpty == true)
                ? capture.locationName ?? 'Unknown Location'
                : 'Unknown Location',
            style: const TextStyle(
              fontSize: 11,
              color: ArtbeatColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showCaptureDetailsPopup(CaptureModel capture) {
    try {
      _showCaptureDetailsPopupInternal(capture);
    } catch (e) {
      debugPrint('❌ Error showing capture details popup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to show capture details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCaptureDetailsPopupInternal(CaptureModel capture) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
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

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      if (capture.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: capture.imageUrl,
                            width: double.infinity,
                            height: 240,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 250,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 250,
                              color: Colors.grey[200],
                              child: const Icon(Icons.error),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        (capture.title?.isNotEmpty == true)
                            ? capture.title ?? 'Public Art Capture'
                            : 'Public Art Capture',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Location
                      if (capture.locationName?.isNotEmpty == true)
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
                                capture.locationName ?? 'Unknown Location',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: ArtbeatColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Description
                      if (capture.description?.isNotEmpty == true)
                        Text(
                          capture.description ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: ArtbeatColors.textPrimary,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Create Art Walk Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              '/art-walk/create',
                              arguments: {'captureId': capture.id},
                            );
                          },
                          icon: const Icon(Icons.directions_walk),
                          label: const Text('Create Art Walk'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ArtbeatColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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

  Widget _buildArtistsShowcaseSection(DashboardViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.palette,
                  color: ArtbeatColors.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured Artists',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ArtbeatColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Connect with local creators and discover their work',
                      style: TextStyle(
                        fontSize: 14,
                        color: ArtbeatColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/artist-search'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: viewModel.isLoadingFeaturedArtists
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: 3, // Show 3 skeleton cards
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: SkeletonWidgets.artistCardSkeleton(
                          _shimmerAnimation,
                        ),
                      );
                    },
                  )
                : viewModel.featuredArtists.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.palette_outlined,
                          size: 48,
                          color: ArtbeatColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No featured artists yet',
                          style: TextStyle(
                            color: ArtbeatColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => viewModel.refresh(),
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: viewModel.featuredArtists.length,
                    itemBuilder: (context, index) {
                      final artist = viewModel.featuredArtists[index];
                      return _buildArtistCard(artist);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCard(ArtistProfileModel artist) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/artist/public-profile',
          arguments: {'artistId': artist.userId},
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              ArtbeatColors.primaryPurple.withValues(alpha: 0.02),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            12,
            12,
            12,
            8,
          ), // Reduced bottom padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile avatar - centered
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ArtbeatColors.primaryPurple.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  backgroundImage: (artist.profileImageUrl?.isNotEmpty == true)
                      ? CachedNetworkImageProvider(artist.profileImageUrl ?? '')
                      : null,
                  child: (artist.profileImageUrl?.isEmpty != false)
                      ? Text(
                          artist.displayName.isNotEmpty
                              ? artist.displayName.substring(0, 1).toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ArtbeatColors.primaryPurple,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(
                height: 8,
              ), // Slightly increased for better balance
              // Artist name
              Text(
                artist.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4), // Increased slightly
              // Mediums
              artist.mediums.isNotEmpty
                  ? Text(
                      artist.mediums.take(2).join(' • '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: ArtbeatColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    )
                  : const SizedBox.shrink(),
              // Conditional spacing only if bio exists
              if (artist.bio != null && artist.bio!.isNotEmpty)
                const SizedBox(height: 6),
              // Bio snippet (limited to 2 lines)
              (artist.bio != null && artist.bio!.isNotEmpty)
                  ? Text(
                      artist.bio!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: ArtbeatColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : const SizedBox.shrink(),
              const SizedBox(height: 8), // Consistent spacing before button
              // Be a Fan button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement follow/fan functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Following ${artist.displayName}!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.favorite_border, size: 16),
                  label: const Text('Be a Fan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArtbeatColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ), // Better padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    minimumSize: const Size(0, 32), // Consistent button height
                  ),
                ),
              ),
            ],
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
          SizedBox(
            height: 200,
            child: viewModel.isLoadingPosts
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: 3, // Show 3 skeleton cards
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: SkeletonWidgets.communityPostSkeleton(
                          _shimmerAnimation,
                        ),
                      );
                    },
                  )
                : viewModel.posts.isEmpty
                ? _buildEmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'No posts yet',
                    subtitle: 'Be the first to share with the community!',
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: viewModel.posts.length.clamp(0, 10),
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    itemBuilder: (context, index) {
                      final post = viewModel.posts[index];
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 16),
                        child: _buildCommunityHighlightCard(post),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityHighlightCard(PostModel post) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image section
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: (post.imageUrls.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: post.imageUrls.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: ArtbeatColors.backgroundSecondary,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: ArtbeatColors.backgroundSecondary,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ),
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

          // Seeking Critique button
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/community/post-detail',
                    arguments: {'postId': post.id},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArtbeatColors.secondaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Seeking Critique',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.brush,
                  color: ArtbeatColors.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Artwork Gallery',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ArtbeatColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Original pieces and digital art from local creators',
                      style: TextStyle(
                        fontSize: 14,
                        color: ArtbeatColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/artwork/browse'),
                icon: const Icon(Icons.collections, size: 16),
                label: const Text('Browse'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArtbeatColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: viewModel.isLoadingArtworks
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: 3, // Show 3 skeleton cards
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: SkeletonWidgets.artworkCardSkeleton(
                          _shimmerAnimation,
                        ),
                      );
                    },
                  )
                : viewModel.artworks.isEmpty
                ? _buildEmptyState(
                    icon: Icons.palette_outlined,
                    title: 'No artwork yet',
                    subtitle: 'Artists will showcase their work here!',
                  )
                : ListView.builder(
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

  Widget _buildArtworkCard(artwork.ArtworkModel artwork) {
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
                  const SizedBox(height: 8),
                  // Action buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Applause button
                      Expanded(
                        child: ApplauseButton(
                          postId: artwork.id,
                          userId: artwork.userId,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Applause sent!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          count: artwork
                              .applauseCount, // Applause count from model
                        ),
                      ),
                      // Gift button
                      IconButton(
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (context) =>
                                GiftModal(recipientId: artwork.userId),
                          );
                        },
                        icon: const Icon(
                          Icons.card_giftcard,
                          color: ArtbeatColors.primaryPurple,
                          size: 20,
                        ),
                        tooltip: 'Send Gift',
                      ),
                    ],
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
          viewModel.isLoadingEvents
              ? Column(
                  children: List.generate(
                    3, // Show 3 skeleton cards
                    (index) =>
                        SkeletonWidgets.eventCardSkeleton(_shimmerAnimation),
                  ),
                )
              : viewModel.events.isEmpty
              ? _buildEmptyState(
                  icon: Icons.event_outlined,
                  title: 'No events yet',
                  subtitle: 'Check back soon for exciting art events!',
                )
              : Column(
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
          // Event image (small)
          if (event.imageUrl?.isNotEmpty == true)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: event.imageUrl ?? '',
                height: 80,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 80,
                  color: ArtbeatColors.backgroundSecondary,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 80,
                  color: ArtbeatColors.backgroundSecondary,
                  child: const Center(
                    child: Icon(
                      Icons.event,
                      size: 32,
                      color: ArtbeatColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

          // Event details
          Padding(
            padding: const EdgeInsets.all(16),
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
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCTASection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background with gradient
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8E2DE2), // Deep purple
                  Color(0xFF4A00E0), // Royal purple
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.palette,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Are you an artist?',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Join our community of artists and showcase your work to art enthusiasts around the world.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Benefits list
                Column(
                  children: [
                    _buildArtistBenefitItem(
                      icon: Icons.visibility,
                      text: 'Showcase your artwork to a global audience',
                    ),
                    const SizedBox(height: 12),
                    _buildArtistBenefitItem(
                      icon: Icons.attach_money,
                      text: 'Sell your art directly to collectors',
                    ),
                    const SizedBox(height: 12),
                    _buildArtistBenefitItem(
                      icon: Icons.people,
                      text: 'Connect with other artists and art enthusiasts',
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // CTA button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      final user = context
                          .read<DashboardViewModel>()
                          .currentUser;
                      if (user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute<ArtistOnboardingScreen>(
                            builder: (context) =>
                                ArtistOnboardingScreen(user: user),
                          ),
                        );
                      } else {
                        showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Error'),
                            content: const Text(
                              'User not found. Please log in again.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E2DE2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.3),
                    ),
                    child: const Text(
                      'Join as Artist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Decorative elements
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05), // 0.05 opacity
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05), // 0.05 opacity
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Artist badge
          Positioned(
            top: -20,
            right: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1), // 0.1 opacity
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: ArtbeatColors.primaryPurple.withValues(
                        alpha: 0.1,
                      ), // 0.1 opacity
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: ArtbeatColors.primaryPurple,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Artist Benefits',
                    style: TextStyle(
                      color: ArtbeatColors.primaryPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistBenefitItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2)),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: ArtbeatColors.textSecondary.withValues(
                  alpha: 0.8,
                ), // 0.8 opacity
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Be the first'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ArtbeatColors.primaryPurple,
                side: BorderSide(
                  color: ArtbeatColors.primaryPurple.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildArtisticBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Colors.grey.withValues(alpha: 0.1), // 0.1 opacity
          Colors.white,
        ],
      ),
    );
  }

  String _formatEventDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  /// Wraps a section builder with error handling to prevent layout crashes
  Widget _buildSafeSection(Widget Function() builder) {
    try {
      return builder();
    } catch (e) {
      debugPrint('❌ Safe section error: $e');
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ArtbeatColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Section temporarily unavailable',
            style: TextStyle(color: ArtbeatColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }
}
