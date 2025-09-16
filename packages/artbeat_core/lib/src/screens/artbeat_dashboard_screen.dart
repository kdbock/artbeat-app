import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_ads/artbeat_ads.dart';
import '../widgets/leaderboard_preview_widget.dart';

import '../widgets/dashboard/dashboard_browse_section.dart';

/// Artbeat Dashboard Screen - Refactored for better maintainability
///
/// This is the main dashboard for the ARTbeat app, now properly organized
/// into smaller, focused components for better code maintainability.
class ArtbeatDashboardScreen extends StatefulWidget {
  const ArtbeatDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ArtbeatDashboardScreen> createState() => _ArtbeatDashboardScreenState();
}

class _ArtbeatDashboardScreenState extends State<ArtbeatDashboardScreen> {
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
        AppLogger.error('❌ Error initializing dashboard: $e');
        AppLogger.error('❌ Stack trace: $stack');
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

    return Scaffold(
      key: _scaffoldKey,
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
            // Removed foregroundColor: Colors.white to use the deep purple default
            onSearchPressed: (String query) => _handleSearch(context, query),
            onProfilePressed: () => _showProfileMenu(context),
            onMenuPressed: () => _openDrawer(),
          ),
        ),
      ),
      body: _buildContent(viewModel),
    );
  }

  Widget _buildContent(DashboardViewModel viewModel) {
    // Show loading screen while initializing
    if (viewModel.isInitializing) {
      return const LoadingScreen(enableNavigation: false);
    }

    return Stack(
      children: [
        RefreshIndicator(
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

              // 1.5. Browse section (quick access to all content)
              SliverToBoxAdapter(
                child: DashboardBrowseSection(viewModel: viewModel),
              ),

              // 2. User experience section (for logged in users)
              if (viewModel.isAuthenticated && viewModel.currentUser != null)
                SliverToBoxAdapter(
                  child: DashboardUserSection(viewModel: viewModel),
                ),

              // 2.5. Leaderboard preview (for logged in users)
              if (viewModel.isAuthenticated && viewModel.currentUser != null)
                const SliverToBoxAdapter(child: LeaderboardPreviewWidget()),

              // App explanation section (for new/anonymous users)
              if (!viewModel.isAuthenticated)
                const SliverToBoxAdapter(child: DashboardAppExplanation()),

              // 3. Ad1
              if (viewModel.isAuthenticated)
                const SliverToBoxAdapter(
                  child: RotatingAdPlacementWidget(
                    location: AdLocation.fluidDashboard,
                    adIndex: 0, // Show first ad from rotation
                    showIfEmpty: true,
                  ),
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
                child: RotatingAdPlacementWidget(
                  location: AdLocation.fluidDashboard,
                  adIndex: 1, // Show second ad from rotation
                  showIfEmpty: true,
                ),
              ),

              // 8. Ad3
              const SliverToBoxAdapter(
                child: RotatingAdPlacementWidget(
                  location: AdLocation.fluidDashboard,
                  adIndex: 2, // Show third ad from rotation
                  showIfEmpty: true,
                ),
              ),

              // 9. Featured events
              SliverToBoxAdapter(
                child: DashboardEventsSection(viewModel: viewModel),
              ),

              // 10. Upcoming events (using community section for now)
              SliverToBoxAdapter(
                child: DashboardCommunitySection(viewModel: viewModel),
              ),

              // 11. Ad4
              const SliverToBoxAdapter(
                child: RotatingAdPlacementWidget(
                  location: AdLocation.fluidDashboard,
                  adIndex: 3, // Show fourth ad from rotation
                  showIfEmpty: true,
                ),
              ),

              // 12. Are you an artist section
              SliverToBoxAdapter(
                child: DashboardArtistCtaSection(viewModel: viewModel),
              ),

              // 13. Ad5
              const SliverToBoxAdapter(
                child: RotatingAdPlacementWidget(
                  location: AdLocation.fluidDashboard,
                  adIndex: 4, // Show fifth ad from rotation
                  showIfEmpty: true,
                ),
              ),

              // 14. Ad6
              const SliverToBoxAdapter(
                child: RotatingAdPlacementWidget(
                  location: AdLocation.fluidDashboard,
                  adIndex: 5, // Show sixth ad from rotation
                  showIfEmpty: true,
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ],
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

  void _handleSearch(BuildContext context, String query) {
    // Navigate to search screen, optionally passing the search query
    Navigator.pushNamed(context, '/search', arguments: {'query': query});
  }

  void _navigateToArtWalk(BuildContext context) {
    // Navigate to art walk dashboard
    Navigator.pushNamed(context, '/art-walk/dashboard');
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }
}
