import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_ads/artbeat_ads.dart';
import '../widgets/leaderboard_preview_widget.dart';

import '../widgets/dashboard/dashboard_browse_section.dart';
import '../widgets/dashboard/art_walk_hero_section.dart';
import '../widgets/dashboard/user_progress_card.dart';

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
  void dispose() {
    _heroAnimationController.dispose();
    _celebrationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Create a test challenge for development/testing purposes
  ChallengeModel _createTestChallenge() {
    return ChallengeModel(
      id: 'test_daily_challenge',
      userId: 'test_user',
      title: 'Art Explorer',
      description: 'Discover 3 pieces of public art today',
      type: ChallengeType.daily,
      targetCount: 3,
      currentCount: 1,
      rewardXP: 100,
      rewardDescription: '🎨 Artist Badge + 100 XP',
      isCompleted: false,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 20)),
    );
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
        (viewModel.artworkError != null && viewModel.artwork.isEmpty) ||
        (viewModel.artistsError != null && viewModel.artists.isEmpty);
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

              // === USER EXPERIENCE SECTION ===
              // Personalized content directly after hero for immediate relevance
              if (viewModel.isAuthenticated && viewModel.currentUser != null)
                SliverToBoxAdapter(
                  child: DashboardUserSection(viewModel: viewModel),
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

              // === STRATEGIC MONETIZATION ===
              // Thoughtfully placed, native-style ads (max 2)
              ..._buildStrategicAds(viewModel),

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

          // Immediate engagement hook - Active quest
          if (viewModel.todaysChallenge != null || true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DailyQuestCard(
                challenge: viewModel.todaysChallenge ?? _createTestChallenge(),
                onTap: () => _navigateToQuestJournal(context),
              ),
            ),
        ],
      ),
    );
  }

  /// ENGAGEMENT CATALYSTS - Dynamic, context-aware content
  List<Widget> _buildEngagementCatalysts(DashboardViewModel viewModel) {
    final catalysts = <Widget>[];

    // Slot 1: Top carousel banner (hero placement)
    if (viewModel.isAuthenticated) {
      catalysts.add(
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: AdCarouselWidget(
              zone: LocalAdZone.home,
              height: 200,
            ),
          ),
        ),
      );
    }

    // Live social proof - builds FOMO and community feeling
    catalysts.add(
      SliverToBoxAdapter(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.translationValues(0, _scrollDepth * -2.0, 0),
          child: LiveActivityFeed(
            activities: viewModel.activities,
            onTap: () => _navigateToCommunityHub(context),
          ),
        ),
      ),
    );

    // Leaderboard preview - competitive element right after social proof
    if (viewModel.isAuthenticated && viewModel.currentUser != null) {
      catalysts.add(
        const SliverToBoxAdapter(child: LeaderboardPreviewWidget()),
      );

      // Slot 4: Below leaderboard - Small banner ad
      catalysts.add(
        const SliverToBoxAdapter(
          child: AdSmallBannerWidget(
            zone: LocalAdZone.home,
            height: 100,
          ),
        ),
      );
    }

    // Personal progress - immediate gratification
    catalysts.add(
      SliverToBoxAdapter(
        child: UserProgressCard(
          currentStreak: viewModel.currentStreak,
          totalDiscoveries: viewModel.totalDiscoveries,
          weeklyProgress: viewModel.weeklyProgress,
          weeklyGoal: 7,
          onTap: () => _navigateToWeeklyGoals(context),
        ),
      ),
    );

    // Slot 2: Between progress & browse - Native card ad
    if (viewModel.isAuthenticated) {
      catalysts.add(
        const SliverToBoxAdapter(
          child: AdNativeCardWidget(
            zone: LocalAdZone.home,
          ),
        ),
      );
    }

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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

    // Slot 3: Browse carousel footer - Ad placement after browse section
    if (viewModel.isAuthenticated) {
      discoveries.add(
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: AdSmallBannerWidget(
              zone: LocalAdZone.home,
              height: 60,
            ),
          ),
        ),
      );
    }

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

  /// STRATEGIC ADS - Maximum 2, native integration
  List<Widget> _buildStrategicAds(DashboardViewModel viewModel) {
    if (!viewModel.isAuthenticated) return [];

    return [
      // Slot 5: Optional strategic ad between zones
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: AdCtaCardWidget(
            zone: LocalAdZone.home,
            ctaText: 'Discover More',
          ),
        ),
      ),
    ];
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
            content: Text('error_navigation'.tr(namedArgs: {'error': error.toString()})),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _navigateToQuestJournal(BuildContext context) {
    // Navigate to quest history/journal screen
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (context) => const QuestHistoryScreen()),
    );
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
