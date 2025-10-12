import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_ads/artbeat_ads.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_community/artbeat_community.dart';
import '../widgets/leaderboard_preview_widget.dart';

import '../widgets/dashboard/dashboard_browse_section.dart';
import '../widgets/dashboard/art_walk_hero_section.dart';
import '../widgets/dashboard/user_progress_card.dart';

/// Artbeat Dashboard Screen - Refactored for better maintainability
///
/// This is the main dashboard for the ARTbeat app, now properly organized
/// into smaller, focused components for better code maintainability.
class ArtbeatDashboardScreen extends StatefulWidget {
  const ArtbeatDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ArtbeatDashboardScreen> createState() => _ArtbeatDashboardScreenState();
}

class _ArtbeatDashboardScreenState extends State<ArtbeatDashboardScreen>
    with RouteAware {
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
              // 1. Art Walk Hero Section (ARTbeat's star feature)
              SliverToBoxAdapter(
                child: ArtWalkHeroSection(
                  onInstantDiscoveryTap: () => _navigateToArtWalk(context),
                  onProfileMenuTap: () => _showProfileMenu(context),
                  onMenuPressed: () => _openDrawer(),
                ),
              ),

              // 1.2. Live Activity Feed (social proof)
              SliverToBoxAdapter(
                child: LiveActivityFeed(
                  activities: viewModel.activities,
                  onTap: () => _navigateToCommunityHub(context),
                ),
              ),

              // 1.3. User Progress Card (gamification)
              SliverToBoxAdapter(
                child: UserProgressCard(
                  currentStreak: viewModel.currentStreak,
                  totalDiscoveries: viewModel.totalDiscoveries,
                  weeklyProgress: viewModel.weeklyProgress,
                  weeklyGoal: 7, // Default weekly goal
                  onTap: () => _navigateToWeeklyGoals(context),
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

              // 3. Ad1 - Home & Discovery Zone
              if (viewModel.isAuthenticated)
                const SliverToBoxAdapter(
                  child: ZoneAdPlacementWidget(
                    zone: AdZone.homeDiscovery,
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

              // 7. Ad2 - Home & Discovery Zone
              const SliverToBoxAdapter(
                child: ZoneAdPlacementWidget(
                  zone: AdZone.homeDiscovery,
                  adIndex: 1, // Show second ad from rotation
                  showIfEmpty: true,
                ),
              ),

              // 8. Ad3 - Home & Discovery Zone
              const SliverToBoxAdapter(
                child: ZoneAdPlacementWidget(
                  zone: AdZone.homeDiscovery,
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

              // 11. Ad4 - Home & Discovery Zone
              const SliverToBoxAdapter(
                child: ZoneAdPlacementWidget(
                  zone: AdZone.homeDiscovery,
                  adIndex: 3, // Show fourth ad from rotation
                  showIfEmpty: true,
                ),
              ),

              // 12. Are you an artist section
              SliverToBoxAdapter(
                child: DashboardArtistCtaSection(viewModel: viewModel),
              ),

              // 13. Ad5 - Home & Discovery Zone
              const SliverToBoxAdapter(
                child: ZoneAdPlacementWidget(
                  zone: AdZone.homeDiscovery,
                  adIndex: 4, // Show fifth ad from rotation
                  showIfEmpty: true,
                ),
              ),

              // 14. Ad6 - Home & Discovery Zone
              const SliverToBoxAdapter(
                child: ZoneAdPlacementWidget(
                  zone: AdZone.homeDiscovery,
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
      builder: (context) => const EnhancedProfileMenu(),
    );
  }

  Future<void> _navigateToArtWalk(BuildContext context) async {
    // Navigate to art walk dashboard
    final result = await Navigator.pushNamed(context, '/art-walk/dashboard');

    // Refresh dashboard if discoveries were made
    if (result == true && context.mounted) {
      final viewModel = Provider.of<DashboardViewModel>(context, listen: false);
      await viewModel.refresh();
    }
  }

  void _navigateToWeeklyGoals(BuildContext context) {
    // Navigate to weekly goals screen
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (context) => const WeeklyGoalsScreen()),
    );
  }

  void _navigateToCommunityHub(BuildContext context) {
    // Navigate to art community hub
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (context) => const ArtCommunityHub()),
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }
}
