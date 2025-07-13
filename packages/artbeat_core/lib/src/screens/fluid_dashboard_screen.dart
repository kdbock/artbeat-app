import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_community/artbeat_community.dart' show PostModel;
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
              actions: [
                Consumer<DashboardViewModel>(
                  builder: (context, viewModel, _) => IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.chat_bubble_outline),
                        if (viewModel.hasUnreadMessages)
                          Positioned(
                            right: -5,
                            top: -3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ArtbeatColors.error,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                viewModel.unreadMessageCount > 99
                                    ? '99+'
                                    : '${viewModel.unreadMessageCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    tooltip: 'Messages',
                    onPressed: () => viewModel.showMessagingMenu(context),
                  ),
                ),
              ],
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
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A3DE8), // Deeper purple
              Color(0xFF9D50DD), // Medium purple
              Color(0xFF6A3DE8), // Back to deeper purple
            ],
          ),
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
          children: [
            // Decorative elements
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
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                // Add SizedBox with fixed height
                height: 180, // Adjust this value as needed
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Add this to minimize height
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.palette,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to ARTbeat!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Discover local art & connect with artists',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildWelcomeActionButton(
                          icon: Icons.directions_walk,
                          label: 'Art Walks',
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/art-walk/dashboard',
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildWelcomeActionButton(
                          icon: Icons.camera_alt,
                          label: 'Capture Art',
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/capture/dashboard',
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildWelcomeActionButton(
                          icon: Icons.login,
                          label: 'Sign In',
                          onTap: () => Navigator.pushNamed(context, '/auth'),
                        ),
                      ],
                    ),
                  ],
                ),
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

  Widget _buildWelcomeActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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
                onTap: () => Navigator.pushNamed(context, '/artwork/browse'),
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
              _buildFeatureButton(
                icon: Icons.chat_bubble_outline,
                label: 'Messages',
                onTap: () => viewModel.showMessagingMenu(context),
                showBadge: viewModel.hasUnreadMessages,
                badgeCount: viewModel.unreadMessageCount,
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
        color: Colors.transparent,
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
                            color: Colors.white.withOpacity(0.2),
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
                              color: Colors.white.withOpacity(0.9),
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
                      color: Colors.white.withValues(alpha: 51), // 0.2 opacity
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
                        color: Colors.black.withValues(
                          alpha: 26,
                        ), // 0.1 opacity
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
            const SizedBox(height: 8),
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
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/art-walk/map'),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: ArtbeatColors.primaryGreen.withValues(
                          alpha: 77,
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
                            alpha: 77,
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
                        alpha: 77,
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
                                              .withOpacity(0.1),
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
    // Vibrant horizontal list of user-created art walks
    if (viewModel.isLoadingUserArtWalks) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (viewModel.userArtWalks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('No Art Walks created yet. Start your own!')),
      );
    }
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.userArtWalks.length,
        itemBuilder: (context, index) {
          final walk = viewModel.userArtWalks[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/art-walk/detail',
                arguments: walk.id,
              );
            },
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ArtbeatColors.primaryPurple.withAlphaValue(0.15),
                    ArtbeatColors.primaryGreen.withAlphaValue(0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ArtbeatColors.primaryPurple.withAlphaValue(0.08),
                    blurRadius: 8,
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
                      child:
                          walk.coverImageUrl != null &&
                              walk.coverImageUrl!.isNotEmpty
                          ? Image.network(
                              walk.coverImageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 48),
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
                          walk.title,
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
                          walk.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ArtbeatColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                onPressed: () => Navigator.pushNamed(context, '/artist/browse'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (viewModel.isLoadingFeaturedArtists)
            const Center(child: CircularProgressIndicator())
          else if (viewModel.featuredArtists.isEmpty)
            Center(
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
                    'Discovering featured artists...',
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
          else
            SizedBox(
              height: 280,
              child: ListView.builder(
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
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 26), // 0.1 opacity
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, '/artist/profile/${artist.userId}'),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image with profile image overlay
              SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(
                  children: [
                    // Cover image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: artist.coverImageUrl ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 120,
                        placeholder: (context, url) => Container(
                          color: ArtbeatColors.primaryPurple.withOpacity(0.1),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: ArtbeatColors.primaryPurple.withOpacity(0.1),
                          child: const Icon(Icons.image),
                        ),
                      ),
                    ),
                    // Profile image
                    Positioned(
                      left: 16,
                      bottom: -32,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 26),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          backgroundImage: artist.profileImageUrl != null
                              ? CachedNetworkImageProvider(
                                  artist.profileImageUrl!,
                                )
                              : null,
                          child: artist.profileImageUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                      ),
                    ),
                    // Verified badge
                    if (artist.isVerified)
                      Positioned(
                        right: 16,
                        top: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Artist info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ArtbeatColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist.mediums.join(' • '),
                        style: const TextStyle(
                          fontSize: 14,
                          color: ArtbeatColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          artist.bio ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: ArtbeatColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withOpacity(0.3),
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
                        color: Colors.white.withOpacity(0.2),
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
                              color: Colors.white.withOpacity(0.9),
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
                    onPressed: () =>
                        Navigator.pushNamed(context, '/artist/onboarding'),
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
                      shadowColor: Colors.black.withValues(
                        alpha: 77,
                      ), // 0.3 opacity
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
                color: Colors.white.withValues(alpha: 13), // 0.05 opacity
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
                color: Colors.white.withValues(alpha: 13), // 0.05 opacity
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
                    color: Colors.black.withValues(alpha: 26), // 0.1 opacity
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
                        alpha: 26,
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
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
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
                  alpha: 204,
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              ArtbeatColors.primaryPurple.withValues(alpha: 179), // 0.7 opacity
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your ARTbeat experience...',
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 179), // 0.7 opacity
              fontSize: 16,
            ),
          ),
        ],
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
          Colors.grey.withValues(alpha: 26), // 0.1 opacity
          Colors.white,
        ],
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
