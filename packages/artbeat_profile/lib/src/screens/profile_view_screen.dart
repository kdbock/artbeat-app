import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_ads/artbeat_ads.dart';

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
  final int _artwalksCompleted = 0; // TODO: Implement artwalk tracking

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
    _loadUserCaptures();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get username => _userModel?.username ?? "artbeat_user";
  String get name => _userModel?.fullName ?? "ARTbeat User";
  String get bio => _userModel?.bio ?? "Art enthusiast and creative explorer";
  String get location => _userModel?.location ?? "United States";
  String get profileImageUrl => _userModel?.profileImageUrl ?? "";
  int get postsCount => _userModel?.posts.length ?? 0;
  int get followersCount => _userModel?.followers.length ?? 0;
  int get followingCount => _userModel?.following.length ?? 0;
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
      debugPrint(
        '🔄 ProfileViewScreen: Loading profile for user ID: ${widget.userId}',
      );

      // Check if userId is valid
      if (widget.userId.isEmpty) {
        debugPrint('❌ ProfileViewScreen: Empty userId provided');
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
        debugPrint(
          '⚠️ ProfileViewScreen: Creating placeholder for current user',
        );
        userModel = UserModel.placeholder(widget.userId);

        // Try to reload user data from authentication
        try {
          final authUser = FirebaseAuth.instance.currentUser;
          if (authUser != null) {
            debugPrint('🔄 Creating user document for: ${authUser.uid}');
            debugPrint('📧 Email: ${authUser.email}');
            debugPrint('👤 Display Name: ${authUser.displayName}');

            await _userService.createNewUser(
              uid: authUser.uid,
              email: authUser.email ?? '',
              displayName: authUser.displayName ?? 'ARTbeat User',
            );

            debugPrint('✅ User document creation completed');

            // Try to get the user again
            userModel = await _userService.getUserById(widget.userId);

            if (userModel != null) {
              debugPrint(
                '✅ User document retrieved successfully after creation',
              );
            } else {
              debugPrint(
                '❌ User document still not found after creation attempt',
              );
            }
          } else {
            debugPrint('❌ No authenticated user found');
          }
        } catch (reloadError) {
          debugPrint('❌ Failed to reload user data: $reloadError');
          debugPrint('❌ Error details: ${reloadError.toString()}');
        }
      }

      // If still no user model, we have a real problem
      if (userModel == null) {
        debugPrint('❌ ProfileViewScreen: Could not load user profile');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User profile not found')),
          );
        }
      } else {
        debugPrint('✅ ProfileViewScreen: User profile loaded successfully');
      }

      if (mounted) {
        setState(() {
          _userModel = userModel;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ ProfileViewScreen: Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );

        setState(() {
          _userModel = widget.isCurrentUser
              ? UserModel.placeholder(widget.userId)
              : null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserCaptures() async {
    if (mounted) {
      setState(() {
        _isLoadingCaptures = true;
      });
    }

    try {
      debugPrint(
        '🔄 ProfileViewScreen: Loading captures for user ID: ${widget.userId}',
      );

      final captures = await _captureService.getCapturesForUser(widget.userId);

      debugPrint('✅ ProfileViewScreen: Found ${captures.length} captures');

      if (mounted) {
        setState(() {
          _userCaptures = captures;
          _isLoadingCaptures = false;
        });
      }
    } catch (e) {
      debugPrint('❌ ProfileViewScreen: Error loading captures: $e');
      if (mounted) {
        setState(() {
          _userCaptures = [];
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
        appBar: EnhancedUniversalHeader(
          title: 'Profile',
          showLogo: false,
          showDeveloperTools: true,
          onMenuPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          onSearchPressed: () => Navigator.pushNamed(context, '/search'),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ArtbeatColors.primaryPurple,
                      Color.fromARGB(
                        (0.8 * 255).round(),
                        (ArtbeatColors.primaryPurple.r * 255).round(),
                        (ArtbeatColors.primaryPurple.g * 255).round(),
                        (ArtbeatColors.primaryPurple.b * 255).round(),
                      ),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OptimizedAvatar(
                      imageUrl: profileImageUrl,
                      displayName: name,
                      radius: 30,
                      isVerified: false,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      cityState,
                      style: const TextStyle(
                        color: Color.fromARGB(204, 255, 255, 255),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.home_outlined,
                  color: ArtbeatColors.primaryPurple,
                ),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/');
                },
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: ArtbeatColors.primaryPurple,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'My Captures',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  subtitle: const Text(
                    'View your art collection',
                    style: TextStyle(
                      fontSize: 12,
                      color: ArtbeatColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/captures');
                  },
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.map_outlined,
                  color: ArtbeatColors.primaryPurple,
                ),
                title: const Text('Art Walks'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/art-walks');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.people_outline,
                  color: ArtbeatColors.primaryPurple,
                ),
                title: const Text('Artist Community'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/community');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.front_hand,
                  color: ArtbeatColors.accentYellow,
                ),
                title: const Text('Fan of'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile/following');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.emoji_events_outlined,
                  color: ArtbeatColors.accentYellow,
                ),
                title: const Text('Achievements'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile/achievements');
                },
              ),
              const Divider(color: ArtbeatColors.border),
              // Are you an artist? section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color.fromARGB(
                    25,
                    (ArtbeatColors.primaryPurple.r * 255).round(),
                    (ArtbeatColors.primaryPurple.g * 255).round(),
                    (ArtbeatColors.primaryPurple.b * 255).round(),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color.fromARGB(
                      76,
                      (ArtbeatColors.primaryPurple.r * 255).round(),
                      (ArtbeatColors.primaryPurple.g * 255).round(),
                      (ArtbeatColors.primaryPurple.b * 255).round(),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          color: ArtbeatColors.primaryPurple,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Are you an artist?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ArtbeatColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Share your art with the community and grow your audience.',
                      style: TextStyle(
                        fontSize: 12,
                        color: ArtbeatColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/artist/register');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ArtbeatColors.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Get Started'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: ArtbeatColors.border),
              ListTile(
                leading: const Icon(
                  Icons.settings_outlined,
                  color: ArtbeatColors.primaryPurple,
                ),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              if (widget.isCurrentUser) ...[
                ListTile(
                  leading: const Icon(
                    Icons.dashboard_outlined,
                    color: ArtbeatColors.primaryPurple,
                  ),
                  title: const Text('Artist Dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/artist/dashboard');
                  },
                ),
              ],
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ArtbeatColors.primaryPurple.withAlpha(13),
                Colors.white,
                ArtbeatColors.primaryGreen.withAlpha(13),
              ],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadUserProfile();
              await _loadUserCaptures();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ArtbeatColors.border.withAlpha(128),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Profile Image and Edit Button
                        Row(
                          children: [
                            OptimizedAvatar(
                              imageUrl: profileImageUrl,
                              displayName: name,
                              radius: 40,
                              isVerified:
                                  false, // TODO: Add verification status
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    cityState,
                                    style: const TextStyle(
                                      color: ArtbeatColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (widget.isCurrentUser) ...[
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/profile/edit',
                                        );
                                      },
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Edit Profile'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            ArtbeatColors.primaryPurple,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat(
                              'Captures',
                              capturesCount,
                              ArtbeatColors.primaryPurple,
                            ),
                            _buildStat(
                              'Fan of',
                              followersCount,
                              ArtbeatColors.accentYellow,
                            ),
                            _buildStat(
                              'Artwalks Completed',
                              artwalksCompleted,
                              ArtbeatColors.primaryGreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    labelColor: ArtbeatColors.primaryPurple,
                    unselectedLabelColor: ArtbeatColors.textSecondary,
                    tabs: const [
                      Tab(text: 'Captures'),
                      Tab(text: 'Fan of'),
                      Tab(text: 'Achievements'),
                    ],
                  ),

                  // Tab Content
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCapturesTab(),
                        _buildFanOfTab(),
                        _buildAchievementsTab(),
                      ],
                    ),
                  ),

                  // Ad Space
                  const ProfileAdWidget(
                    margin: EdgeInsets.all(16),
                    height: 100,
                    showPlaceholder: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(77)),
          ),
          child: Icon(
            label == 'Captures'
                ? Icons.camera_alt_outlined
                : label == 'Fan of'
                ? Icons.front_hand
                : label == 'Artwalks Completed'
                ? Icons.map_outlined
                : Icons.people_outline,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: ArtbeatColors.textSecondary,
          ),
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
                'Art Captures',
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
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _userCaptures.length,
                    itemBuilder: (context, index) {
                      final capture = _userCaptures[index];
                      return OptimizedGridImage(
                        imageUrl: capture.imageUrl,
                        thumbnailUrl: capture.thumbnailUrl,
                        heroTag: 'profile_capture_${capture.id}',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/capture/detail',
                            arguments: capture
                                .id, // Pass only the ID, not the whole model
                          );
                        },
                        overlay: capture.title?.isNotEmpty == true
                            ? Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Color.fromARGB(178, 0, 0, 0),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Text(
                                    capture.title!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
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

  Widget _buildFanOfTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.front_hand, color: ArtbeatColors.accentYellow),
              SizedBox(width: 8),
              Text(
                'Fan of',
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
            child: followersCount > 0
                ? ListView.builder(
                    itemCount: followersCount,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ArtbeatColors.primaryPurple,
                          child: Text(
                            'U${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text('User ${index + 1}'),
                        subtitle: const Text('Art enthusiast'),
                        trailing: const Icon(
                          Icons.front_hand,
                          color: ArtbeatColors.accentYellow,
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.front_hand,
                          size: 64,
                          color: ArtbeatColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No fans yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Keep creating great art to gain fans!',
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
            ? color.withAlpha(25)
            : ArtbeatColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? color.withAlpha(77) : ArtbeatColors.border,
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
