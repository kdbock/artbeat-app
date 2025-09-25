import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';

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

  // Add a key to open the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  UserModel? _userModel;
  List<CaptureModel> _userCaptures = [];
  bool _isLoadingCaptures = true;
  // Art walk tracking is handled by the existing achievement/reward system
  final int _artwalksCompleted = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        drawer: const ArtbeatDrawer(),
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: ArtbeatColors.textPrimary,
          leading: !widget.isCurrentUser
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.pushNamed(context, '/search'),
            ),
          ],
        ),
        body: Container(
          decoration: _buildArtisticBackground(),
          child: SafeArea(child: _buildProfileContent()),
        ),
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

              // Additional profile stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Posts', postsCount),
                  _buildStatColumn('Captures', capturesCount),
                  _buildStatColumn('Art Walks', _artwalksCompleted),
                ],
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
          ],
        ),
        // Tab Content
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: TabBarView(
            controller: _tabController,
            children: [_buildCapturesTab(), _buildAchievementsTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
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

  Widget _buildAchievementsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                color: ArtbeatColors.accentYellow,
              ),
              SizedBox(width: 8),
              Text(
                'Achievements',
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
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildAchievementCard(
                  'First Capture',
                  'Captured your first artwork',
                  Icons.camera_alt_outlined,
                  ArtbeatColors.primaryPurple,
                  true,
                ),
                _buildAchievementCard(
                  'Art Explorer',
                  'Visited 5 art locations',
                  Icons.explore_outlined,
                  ArtbeatColors.primaryGreen,
                  false,
                ),
                _buildAchievementCard(
                  'Community Member',
                  'Made your first comment',
                  Icons.comment_outlined,
                  ArtbeatColors.secondaryTeal,
                  true,
                ),
                _buildAchievementCard(
                  'Art Critic',
                  'Left 10 thoughtful critiques',
                  Icons.rate_review_outlined,
                  ArtbeatColors.accentYellow,
                  false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    String title,
    String description,
    IconData icon,
    Color color,
    bool isUnlocked,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? color.withValues(alpha: 0.1)
            : ArtbeatColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? color.withValues(alpha: 0.3)
              : ArtbeatColors.border,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: isUnlocked ? color : ArtbeatColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isUnlocked
                  ? ArtbeatColors.textPrimary
                  : ArtbeatColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 10,
              color: ArtbeatColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
