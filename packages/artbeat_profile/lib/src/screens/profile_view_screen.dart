import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import '../widgets/widgets.dart';

class ProfileViewScreen extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;

  const ProfileViewScreen({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
  });

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen>
    with SingleTickerProviderStateMixin {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final UserService _userService = UserService();
  final CaptureService _captureService = CaptureService();
  late TabController _tabController;

  bool _isLoading = true;
  UserModel? _userModel;
  List<CaptureModel> _userCaptures = [];
  bool _isLoadingCaptures = true;
  // Art walk tracking is handled by the existing achievement/reward system
  final int _artwalksCompleted = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed to 3 tabs
    _loadUserProfile();
    _loadUserCaptures();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Profile data getters
  String get username => _userModel?.username ?? "artbeat_user";
  String get name => _userModel?.fullName ?? "ARTbeat User";
  String get bio => _userModel?.bio ?? "Art enthusiast and creative explorer";
  String get location => _userModel?.location ?? "United States";
  String get profileImageUrl => _userModel?.profileImageUrl ?? "";
  int get postsCount => _userModel?.posts.length ?? 0;

  int get capturesCount => _userCaptures.length;
  String get cityState => _userModel?.location ?? "City, State";
  int get artwalksCompleted => _artwalksCompleted;

  Future<void> _loadUserProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Loading profile for user ID

      // Check if userId is valid
      if (widget.userId.isEmpty) {
        // debugPrint('❌ ProfileViewScreen: Empty userId provided');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid user profile')));
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // First, try to get user from Firestore
      UserModel? userModel = await _userService.getUserById(widget.userId);

      // If no user model found, and this is the current user, create a placeholder
      if (userModel == null && widget.isCurrentUser) {
        // Creating placeholder for current user
        userModel = UserModel.placeholder(widget.userId);

        // Try to reload user data from authentication
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            userModel = userModel.copyWith(
              email: currentUser.email,
              fullName: currentUser.displayName ?? 'ARTbeat User',
              profileImageUrl: currentUser.photoURL,
            );
          }
        } catch (e) {
          // debugPrint('⚠️ ProfileViewScreen: Error loading auth data: $e');
        }
      }

      if (mounted) {
        setState(() {
          _userModel = userModel;
          _isLoading = false;
        });
      }

      if (userModel == null) {
        // debugPrint('❌ ProfileViewScreen: Could not load user profile');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User profile not found')),
          );
        }
        return;
      }

      // Successfully loaded profile
    } catch (e) {
      // debugPrint('❌ ProfileViewScreen: Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserCaptures() async {
    try {
      // Loading captures for user

      if (widget.userId.isEmpty) {
        // debugPrint('❌ ProfileViewScreen: Empty userId for captures');
        return;
      }

      final captures = await _captureService.getCapturesForUser(widget.userId);

      if (mounted) {
        setState(() {
          _userCaptures = captures;
          _isLoadingCaptures = false;
        });
      }

      // Successfully loaded captures
    } catch (e) {
      // debugPrint('❌ ProfileViewScreen: Error loading captures: $e');
      if (mounted) {
        setState(() {
          _isLoadingCaptures = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MainLayout(
      currentIndex: -1,
      child: Container(
        decoration: _buildArtisticBackground(),
        child: SafeArea(child: _buildProfileContent()),
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

  Widget _buildProfileContent() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Profile Header
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ArtbeatColors.primaryPurple,
                ArtbeatColors.primaryPurple.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  OptimizedAvatar(
                    imageUrl: profileImageUrl,
                    displayName: name,
                    radius: 40,
                    isVerified: false,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@$username',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cityState,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                bio,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),
              // Content engagement bar for profile
              ContentEngagementBar(
                contentId: widget.userId,
                contentType: 'profile',
                initialStats:
                    _userModel?.engagementStats ??
                    EngagementStats(lastUpdated: DateTime.now()),
                showSecondaryActions: !widget.isCurrentUser,
              ),

              const SizedBox(height: 16),

              // Level Progress Bar
              LevelProgressBar(
                currentXP: _userModel?.experiencePoints ?? 0,
                level: _userModel?.level ?? 1,
                showDetails: true,
              ),

              const SizedBox(height: 12),

              // Streak Display
              const StreakDisplay(
                loginStreak: 5, // TODO: Get from user data
                challengeStreak: 3, // TODO: Get from user data
                categoryStreak: 7, // TODO: Get from user data
                categoryName: 'Street Art',
              ),

              const SizedBox(height: 12),

              // Recent Badges Carousel
              RecentBadgesCarousel(
                recentBadges: _getRecentBadges(),
                onViewAll: () {
                  _tabController.animateTo(1); // Switch to achievements tab
                },
              ),

              const SizedBox(height: 12),

              // Enhanced Stats Grid
              EnhancedStatsGrid(
                posts: postsCount,
                captures: capturesCount,
                artWalks: _artwalksCompleted,
                likes: _userModel?.engagementStats.likeCount ?? 0,
                shares: _userModel?.engagementStats.shareCount ?? 0,
                comments: _userModel?.engagementStats.commentCount ?? 0,
                followers: _userModel?.engagementStats.followCount ?? 0,
                following: 0, // TODO: Get from engagement service
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Actions Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile/edit');
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/captures');
              },
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('View Captures'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Tabs
        TabBar(
          controller: _tabController,
          labelColor: ArtbeatColors.primaryPurple,
          unselectedLabelColor: ArtbeatColors.textSecondary,
          tabs: const [
            Tab(text: 'Captures'),
            Tab(text: 'Achievements'),
            Tab(text: 'Progress'),
          ],
        ),
        // Tab Content
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCapturesTab(),
              DynamicAchievementsTab(userId: widget.userId),
              ProgressTab(userId: widget.userId),
            ],
          ),
        ),
      ],
    );
  }

  List<BadgeData> _getRecentBadges() {
    // TODO: Get actual recent badges from user data
    // For now, return sample badges
    return [
      BadgeData(
        id: 'first_walk_completed',
        name: 'First Walk',
        description: 'Complete your first art walk',
        icon: '🚶',
        earnedAt: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Quest',
      ),
      BadgeData(
        id: 'first_capture_approved',
        name: 'First Capture',
        description: 'Get your first art capture approved',
        icon: '📸',
        earnedAt: DateTime.now().subtract(const Duration(days: 2)),
        category: 'Creator',
      ),
      BadgeData(
        id: 'ten_walks_completed',
        name: 'Ten Walks',
        description: 'Complete 10 art walks',
        icon: '🏃',
        earnedAt: DateTime.now().subtract(const Duration(days: 5)),
        category: 'Quest',
      ),
    ];
  }

  Widget _buildCapturesTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.camera_alt_outlined,
                color: ArtbeatColors.primaryPurple,
              ),
              SizedBox(width: 8),
              Text(
                'My Captures',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingCaptures
                ? const Center(child: CircularProgressIndicator())
                : _userCaptures.isNotEmpty
                ? GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: _userCaptures.length,
                    itemBuilder: (context, index) {
                      final capture = _userCaptures[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/capture/detail',
                            arguments: {'captureId': capture.id},
                          );
                        },
                        child: Card(
                          elevation: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    image: capture.imageUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              capture.imageUrl,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: capture.imageUrl.isEmpty
                                      ? const Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  capture.title ?? 'Untitled',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 48,
                          color: ArtbeatColors.textSecondary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No captures yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Start capturing art to see it here!',
                          style: TextStyle(
                            fontSize: 14,
                            color: ArtbeatColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
