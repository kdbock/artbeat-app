import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_ads/artbeat_ads.dart';

import '../widgets/dashboard/dashboard_hero_section.dart';
import '../widgets/dashboard/dashboard_user_section.dart';
import '../widgets/dashboard/dashboard_captures_section.dart';
import '../widgets/dashboard/dashboard_artists_section.dart';
import '../widgets/dashboard/dashboard_artwork_section.dart';
import '../widgets/dashboard/dashboard_community_section.dart';
import '../widgets/dashboard/dashboard_events_section.dart';
import '../widgets/dashboard/dashboard_profile_menu.dart';
import '../widgets/dashboard/dashboard_app_explanation.dart';
import '../widgets/dashboard/dashboard_trending_posts_section.dart';
import '../widgets/dashboard/dashboard_featured_posts_section.dart';
import '../widgets/dashboard/dashboard_artist_cta_section.dart';

/// Fluid Dashboard Screen - Refactored for better maintainability
///
/// This is the main dashboard for the ARTbeat app, now properly organized
/// into smaller, focused components for better code maintainability.
class FluidDashboardScreen extends StatefulWidget {
  const FluidDashboardScreen({Key? key}) : super(key: key);

  @override
  State<FluidDashboardScreen> createState() => _FluidDashboardScreenState();
}

class _FluidDashboardScreenState extends State<FluidDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final viewModel = Provider.of<DashboardViewModel>(
          context,
          listen: false,
        );
        await viewModel.initialize();
      } catch (e, stack) {
        debugPrint('❌ Error initializing dashboard: $e');
        debugPrint('❌ Stack trace: $stack');
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DashboardViewModel>(context);

    return MainLayout(
      currentIndex: 0, // Dashboard is index 0
      scaffoldKey: _scaffoldKey,
      drawer: const ArtbeatDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 4),
        child: ArtbeatGradientBackground(
          addShadow: true,
          child: EnhancedUniversalHeader(
            title: 'ARTbeat',
            showLogo: true,
            showSearch: true,
            showDeveloperTools: false,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            onSearchPressed: () => _handleSearch(context),
            onProfilePressed: () => _showProfileMenu(context),
            onMenuPressed: () => _openDrawer(),
          ),
        ),
      ),
      child: _buildContent(viewModel),
    );
  }

  Widget _buildContent(DashboardViewModel viewModel) {
    // Show loading indicator while initializing
    if (viewModel.isInitializing) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            ArtbeatColors.primaryPurple,
          ),
        ),
      );
    }

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
          // 1. Hero Map Section (ARTbeat map hero)
          SliverToBoxAdapter(
            child: DashboardHeroSection(
              viewModel: viewModel,
              onProfileMenuTap: () => _showProfileMenu(context),
              onFindArtTap: () => _navigateToArtWalk(context),
            ),
          ),

          // 2. User experience section (for logged in users)
          if (viewModel.isAuthenticated && viewModel.currentUser != null)
            SliverToBoxAdapter(
              child: DashboardUserSection(viewModel: viewModel),
            ),

          // App explanation section (for new/anonymous users)
          if (!viewModel.isAuthenticated)
            const SliverToBoxAdapter(child: DashboardAppExplanation()),

          // 3. Ad1
          if (viewModel.isAuthenticated)
            const SliverToBoxAdapter(
              child: BannerAdWidget(location: AdLocation.dashboard),
            ),

          // 4. Local captures
          SliverToBoxAdapter(
            child: DashboardCapturesSection(viewModel: viewModel),
          ),

          // 5. Featured artists
          SliverToBoxAdapter(
            child: DashboardArtistsSection(viewModel: viewModel),
          ),

          // 6. Featured artworks
          SliverToBoxAdapter(
            child: DashboardArtworkSection(viewModel: viewModel),
          ),

          // 7. Ad2
          const SliverToBoxAdapter(
            child: BannerAdWidget(location: AdLocation.artWalkDashboard),
          ),

          // 8. Trending posts
          SliverToBoxAdapter(
            child: DashboardTrendingPostsSection(viewModel: viewModel),
          ),

          // 9. Featured posts
          SliverToBoxAdapter(
            child: DashboardFeaturedPostsSection(viewModel: viewModel),
          ),

          // 10. Ad3
          const SliverToBoxAdapter(
            child: BannerAdWidget(location: AdLocation.dashboard),
          ),

          // 11. Featured events
          SliverToBoxAdapter(
            child: DashboardEventsSection(viewModel: viewModel),
          ),

          // 12. Upcoming events (using community section for now)
          SliverToBoxAdapter(
            child: DashboardCommunitySection(viewModel: viewModel),
          ),

          // 13. Ad4
          const SliverToBoxAdapter(
            child: BannerAdWidget(location: AdLocation.artWalkDashboard),
          ),

          // 14. Are you an artist section
          SliverToBoxAdapter(
            child: DashboardArtistCtaSection(viewModel: viewModel),
          ),

          // 15. Ad5
          const SliverToBoxAdapter(
            child: BannerAdWidget(location: AdLocation.dashboard),
          ),

          // 16. Ad6
          const SliverToBoxAdapter(
            child: BannerAdWidget(location: AdLocation.artWalkDashboard),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DashboardProfileMenu(),
    );
  }

  void _handleSearch(BuildContext context) {
    // Navigate to search screen
    Navigator.pushNamed(context, '/search');
  }

  void _navigateToArtWalk(BuildContext context) {
    // Navigate to art walk dashboard
    Navigator.pushNamed(context, '/art-walk/dashboard');
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }
}
