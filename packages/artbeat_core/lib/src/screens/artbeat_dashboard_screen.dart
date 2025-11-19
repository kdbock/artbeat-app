import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import '../widgets/dashboard/dashboard_browse_section.dart';
import '../widgets/dashboard/art_walk_hero_section.dart';

/// ARTbeat Dynamic Engagement Dashboard
///
/// Designed for maximum user engagement, retention, and immersive experience.
/// Uses progressive disclosure, gamification, and context-aware content delivery.
class ArtbeatDashboardScreen extends StatefulWidget {
  const ArtbeatDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ArtbeatDashboardScreen> createState() => _ArtbeatDashboardScreenState();
}

class _ArtbeatDashboardScreenState extends State<ArtbeatDashboardScreen>
    with TickerProviderStateMixin, RouteAware {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation controllers for micro-interactions
  late AnimationController _heroAnimationController;
  late AnimationController _celebrationController;
  late Animation<double> _heroFadeAnimation;

  // Dynamic content management
  bool _showCelebration = false;
  String? _celebrationMessage;
  int _scrollDepth = 0;

  @override
  void initState() {
    super.initState();

    // Initialize animations for enhanced engagement
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _heroFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroAnimationController, curve: Curves.easeOut),
    );

    // Setup scroll listener for engagement tracking
    _scrollController.addListener(_onScroll);

    // Start hero animation
    _heroAnimationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final viewModel = Provider.of<DashboardViewModel>(
          context,
          listen: false,
        );
        await viewModel.initialize();

        // Check for celebration triggers
        _checkForCelebrations(viewModel);
      } catch (e, stack) {
        AppLogger.error('❌ Error initializing dashboard: $e');
        AppLogger.error('❌ Stack trace: $stack');
      }
    });
  }

  void _onScroll() {
    final scrollPercent = (_scrollController.offset / 1000).clamp(0.0, 1.0);
    final newDepth = (scrollPercent * 10).round();
    if (newDepth != _scrollDepth) {
      setState(() => _scrollDepth = newDepth);
    }
  }

  void _checkForCelebrations(DashboardViewModel viewModel) {
    // Check for achievements, streaks, or milestones
    if (viewModel.currentStreak >= 7 && !_showCelebration) {
      _triggerCelebration('🔥 7-day streak! You\'re on fire!');
    } else if (viewModel.totalDiscoveries > 0 &&
        viewModel.totalDiscoveries % 10 == 0) {
      _triggerCelebration(
        '🎨 ${viewModel.totalDiscoveries} discoveries! Amazing progress!',
      );
    }
  }

  void _triggerCelebration(String message) {
    setState(() {
      _showCelebration = true;
      _celebrationMessage = message;
    });
    _celebrationController.forward().then((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showCelebration = false);
          _celebrationController.reset();
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      // Subscribe to route changes
    }
  }

  @override
  void didPopNext() {
    // Called when returning to this screen (e.g., from onboarding)
    super.didPopNext();
    // Refresh user data in case user type changed during onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final viewModel = Provider.of<DashboardViewModel>(
          context,
          listen: false,
        );
        await viewModel.refreshUserData();
      } catch (e) {
        AppLogger.error('❌ Error refreshing user data on dashboard return: $e');
      }
    });
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    _celebrationController.dispose();
    _scrollController.removeListener(_onScroll);
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

  /// Check if there are any critical errors
  bool _hasErrors(DashboardViewModel viewModel) {
    return (viewModel.eventsError != null && viewModel.events.isEmpty) ||
        (viewModel.artworkError != null && viewModel.artwork.isEmpty);
  }

  /// Get appropriate error message
  String _getErrorMessage(DashboardViewModel viewModel) {
    if (viewModel.eventsError != null) return 'Unable to load events';
    if (viewModel.artworkError != null) return 'Unable to load artwork';
    if (viewModel.artistsError != null) return 'Unable to load artists';
    return 'Something went wrong. Please try again.';
  }

  Widget _buildContent(DashboardViewModel viewModel) {
    // Show loading screen while initializing
    if (viewModel.isInitializing) {
      return const LoadingScreen(enableNavigation: false);
    }

    // Handle error states gracefully
    if (_hasErrors(viewModel)) {
      return _buildErrorState(
        _getErrorMessage(viewModel),
        () => viewModel.refresh(),
      );
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
              // === IMMERSIVE HERO ZONE ===
              // The star of the show - animated, engaging entry point
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _heroFadeAnimation,
                  child: _buildEnhancedHeroZone(viewModel),
                ),
              ),

              // === LIVE ACTIVITY FEED ===
              // Real-time community activity proof
              SliverToBoxAdapter(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  transform: Matrix4.translationValues(
                    0,
                    _scrollDepth * -2.0,
                    0,
                  ),
                  child: LiveActivityFeed(
                    activities: viewModel.activities,
                    onTap: () {},
                  ),
                ),
              ),

              // === INTEGRATED ENGAGEMENT WIDGET ===
              // Combines Daily Quest, Weekly Goals & Leaderboard
              if (viewModel.isAuthenticated && viewModel.currentUser != null)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 500,
                    child: IntegratedEngagementWidget(
                      user: viewModel.currentUser!,
                      currentStreak: viewModel.currentStreak,
                      totalDiscoveries: viewModel.totalDiscoveries,
                      weeklyProgress: viewModel.weeklyProgress,
                      weeklyGoal: 7,
                      achievements: viewModel.achievements,
                      activities: viewModel.activities,
                      onProfileTap: () => _showProfileMenu(context),
                      onAchievementsTap: () =>
                          Navigator.pushNamed(context, '/achievements'),
                      onWeeklyGoalsTap: () => _navigateToWeeklyGoals(context),
                      onLeaderboardTap: () =>
                          Navigator.pushNamed(context, '/leaderboard'),
                    ),
                  ),
                ),

              // === ENGAGEMENT CATALYST ZONE ===
              // Dynamic content that adapts to user state and achievements
              ..._buildEngagementCatalysts(viewModel),

              // === DISCOVERY FEED ZONE ===
              // Personalized, context-aware content discovery
              ..._buildDiscoveryFeed(viewModel),

              // === SOCIAL CONNECTION ZONE ===
              // Community features that build long-term engagement
              ..._buildSocialConnectionZone(viewModel),

              // === GROWTH & ACHIEVEMENT ZONE ===
              // Gamification and progress tracking
              ..._buildGrowthAchievementZone(viewModel),

              // === CONVERSION ZONE ===
              // Artist onboarding and premium features
              ..._buildConversionZone(viewModel),

              // Bottom padding for comfortable scrolling
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),

        // === CELEBRATION OVERLAY ===
        // Full-screen achievement celebrations
        if (_showCelebration) _buildCelebrationOverlay(),
      ],
    );
  }

  /// IMMERSIVE HERO ZONE - The main attraction
  Widget _buildEnhancedHeroZone(DashboardViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // Enhanced Art Walk Hero with location context
          ArtWalkHeroSection(
            onInstantDiscoveryTap: () => _navigateToArtWalk(context),
            onProfileMenuTap: () => _showProfileMenu(context),
            onMenuPressed: () => _openDrawer(),
            onNotificationPressed: () => _navigateToNotifications(context),
            hasNotifications: _hasNotifications(viewModel),
            notificationCount: _getNotificationCount(viewModel),
          ),
        ],
      ),
    );
  }

  /// ENGAGEMENT CATALYSTS - Dynamic, context-aware content
  List<Widget> _buildEngagementCatalysts(DashboardViewModel viewModel) {
    final catalysts = <Widget>[];

    // Achievement showcase (when available)
    if (viewModel.achievements.isNotEmpty) {
      catalysts.add(
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'dashboard_recent_achievements'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: viewModel.achievements
                      .take(3)
                      .map(
                        (achievement) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ArtbeatColors.primaryPurple.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: ArtbeatColors.primaryPurple,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                achievement.title,
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return catalysts;
  }

  /// DISCOVERY FEED - Personalized content that keeps users exploring
  List<Widget> _buildDiscoveryFeed(DashboardViewModel viewModel) {
    final discoveries = <Widget>[];

    // Quick browse - gateway to all content
    discoveries.add(
      SliverToBoxAdapter(child: DashboardBrowseSection(viewModel: viewModel)),
    );

    // Local art captures - immediate relevance
    discoveries.add(
      SliverToBoxAdapter(child: DashboardCapturesSection(viewModel: viewModel)),
    );

    // Featured content rotation - keeps feed fresh
    if (viewModel.artists.isNotEmpty) {
      discoveries.add(
        SliverToBoxAdapter(
          child: DashboardArtistsSection(viewModel: viewModel),
        ),
      );
    }

    if (viewModel.artwork.isNotEmpty) {
      discoveries.add(
        SliverToBoxAdapter(
          child: DashboardArtworkSection(viewModel: viewModel),
        ),
      );
    }

    return discoveries;
  }

  /// SOCIAL CONNECTION ZONE - Building community and retention
  List<Widget> _buildSocialConnectionZone(DashboardViewModel viewModel) {
    final socialWidgets = <Widget>[];

    // Community content
    socialWidgets.add(
      SliverToBoxAdapter(
        child: DashboardCommunitySection(viewModel: viewModel),
      ),
    );

    // Events - creates anticipation and return visits
    if (viewModel.events.isNotEmpty) {
      socialWidgets.add(
        SliverToBoxAdapter(child: DashboardEventsSection(viewModel: viewModel)),
      );
    }

    return socialWidgets;
  }

  /// GROWTH & ACHIEVEMENT ZONE - Gamification for retention
  List<Widget> _buildGrowthAchievementZone(DashboardViewModel viewModel) {
    final growthWidgets = <Widget>[];

    // App explanation for new users
    if (!viewModel.isAuthenticated) {
      growthWidgets.add(
        const SliverToBoxAdapter(child: DashboardAppExplanation()),
      );
    }

    return growthWidgets;
  }

  /// CONVERSION ZONE - Artist onboarding and premium features
  List<Widget> _buildConversionZone(DashboardViewModel viewModel) {
    return [
      // Artist CTA - convert users to contributors
      SliverToBoxAdapter(
        child: DashboardArtistCtaSection(viewModel: viewModel),
      ),
    ];
  }

  /// CELEBRATION OVERLAY - Full-screen achievement celebrations
  Widget _buildCelebrationOverlay() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.8 * _celebrationController.value,
              ),
            ),
            child: Center(
              child: Transform.scale(
                scale: _celebrationController.value,
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.celebration,
                        size: 64,
                        color: ArtbeatColors.primaryPurple,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _celebrationMessage ?? 'Achievement Unlocked!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  /// Check if user has notifications
  bool _hasNotifications(DashboardViewModel viewModel) {
    // Check for various notification types
    return (viewModel.achievements.isNotEmpty) ||
        (viewModel.currentStreak >= 7) ||
        (viewModel.activities.isNotEmpty);
  }

  /// Get notification count
  int _getNotificationCount(DashboardViewModel viewModel) {
    int count = 0;
    if (viewModel.achievements.isNotEmpty)
      count += viewModel.achievements.length;
    if (viewModel.currentStreak >= 7) count += 1; // Streak milestone
    return count.clamp(0, 99); // Max 99 to show "99+"
  }

  void _navigateToNotifications(BuildContext context) {
    // Debug: Check if button is being tapped
    if (kDebugMode) {
      print('🔔 Notification button tapped! Route: /notifications');
    }

    // Try to navigate to notifications
    try {
      Navigator.pushNamed(context, '/notifications');
    } catch (error) {
      // If route navigation fails, show error
      AppLogger.error('Notification navigation error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'error_navigation'.tr(namedArgs: {'error': error.toString()}),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Handle error states gracefully
  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'error_something_wrong'.tr(),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text('error_try_again'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: ArtbeatColors.primaryPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
