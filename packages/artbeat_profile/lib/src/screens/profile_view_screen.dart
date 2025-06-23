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
  late TabController _tabController;

  bool _isLoading = true;
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get username => _userModel?.username ?? "wordnerd_user";
  String get name => _userModel?.fullName ?? "WordNerd User";
  String get bio =>
      _userModel?.bio ?? "Vocabulary enthusiast and language lover";
  String get location => _userModel?.location ?? "United States";
  String get profileImageUrl => _userModel?.profileImageUrl ?? "";
  int get postsCount => _userModel?.posts.length ?? 0;
  int get followersCount => _userModel?.followers.length ?? 0;
  int get followingCount => _userModel?.following.length ?? 0;
  int get capturesCount => _userModel?.captures.length ?? 0;

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

  void _navigateToCaptureDetail(CaptureModel capture) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CaptureDetailScreen(
          capture: capture,
          isCurrentUser: widget.isCurrentUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show error state if user model is null and this is the current user
    if (_userModel == null && widget.isCurrentUser) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Profile Not Found',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your profile data is missing from the database.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    await _loadUserProfile();
                  },
                  child: const Text('Try to Create Profile'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: ArtbeatColors.textPrimary),
        actions: [
          if (widget.isCurrentUser)
            IconButton(
              icon: Icon(Icons.edit, color: ArtbeatColors.primaryPurple),
              onPressed: () {
                Navigator.pushNamed(context, '/profile/edit');
              },
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArtbeatColors.primaryPurple.withAlpha(13), // 0.05 opacity
              Colors.white,
              ArtbeatColors.primaryGreen.withAlpha(13), // 0.05 opacity
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Easel Header Section
              Container(
                height: 280,
                margin: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    // Easel base
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 240,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4513), // Brown wood color
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomPaint(
                          painter: EaselPainter(),
                        ),
                      ),
                    ),
                    // Canvas (user avatar as painting)
                    Positioned(
                      top: 20,
                      left: 40,
                      right: 40,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF8B4513),
                            width: 8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(77),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: profileImageUrl.isNotEmpty
                              ? Image.network(
                                  profileImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
                                )
                              : _buildFallbackAvatar(),
                        ),
                      ),
                    ),
                    // Artist signature
                    Positioned(
                      bottom: 20,
                      right: 50,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          name,
                          style: TextStyle(
                            color: ArtbeatColors.textPrimary,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Profile Info Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ArtbeatColors.border.withAlpha(128)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ArtbeatColors.textPrimary,
                      ),
                    ),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        bio,
                        style: TextStyle(
                          fontSize: 16,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: ArtbeatColors.primaryPurple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: TextStyle(
                              color: ArtbeatColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Captures', capturesCount, ArtbeatColors.primaryPurple),
                        _buildStat('Fan of', followersCount, ArtbeatColors.accentYellow),
                        _buildStat('Following', followingCount, ArtbeatColors.primaryGreen),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tab Section
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(128),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: ArtbeatColors.primaryPurple,
                          unselectedLabelColor: ArtbeatColors.textSecondary,
                          indicatorColor: ArtbeatColors.primaryPurple,
                          tabs: const [
                            Tab(text: 'Captures'),
                            Tab(text: 'Fan of'),
                            Tab(text: 'Achievements'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Captures tab with upload status
                            _buildCapturesTab(),
                            // Fan of tab (formerly likes)
                            _buildFanOfTab(),
                            // Achievements tab
                            _buildAchievementsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
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
            label == 'Captures' ? Icons.camera_alt_outlined :
            label == 'Fan of' ? Icons.front_hand :
            Icons.people_outline,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: ArtbeatColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryPurple.withAlpha(51),
            ArtbeatColors.primaryGreen.withAlpha(51),
          ],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.primaryPurple,
          ),
        ),
      ),
    );
  }

  Widget _buildCapturesTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt_outlined, color: ArtbeatColors.primaryPurple),
              const SizedBox(width: 8),
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
            child: capturesCount > 0
                ? GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: capturesCount,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: ArtbeatColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ArtbeatColors.border),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                color: ArtbeatColors.textSecondary,
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Uploaded',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: ArtbeatColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 64,
                          color: ArtbeatColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No captures yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
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
          Row(
            children: [
              Icon(Icons.front_hand, color: ArtbeatColors.accentYellow),
              const SizedBox(width: 8),
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
                        subtitle: Text('Art enthusiast'),
                        trailing: Icon(
                          Icons.front_hand,
                          color: ArtbeatColors.accentYellow,
                        ),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.front_hand,
                          size: 64,
                          color: ArtbeatColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No fans yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
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
          Row(
            children: [
              Icon(Icons.emoji_events_outlined, color: ArtbeatColors.accentYellow),
              const SizedBox(width: 8),
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
        color: isUnlocked ? color.withAlpha(25) : ArtbeatColors.backgroundSecondary,
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
              color: isUnlocked ? ArtbeatColors.textPrimary : ArtbeatColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
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

// Custom painter for the easel design
class EaselPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.fill;

    // Draw easel legs
    final leftLeg = Path()
      ..moveTo(size.width * 0.1, size.height * 0.9)
      ..lineTo(size.width * 0.3, size.height * 0.1)
      ..lineTo(size.width * 0.35, size.height * 0.1)
      ..lineTo(size.width * 0.15, size.height * 0.9)
      ..close();

    final rightLeg = Path()
      ..moveTo(size.width * 0.85, size.height * 0.9)
      ..lineTo(size.width * 0.65, size.height * 0.1)
      ..lineTo(size.width * 0.7, size.height * 0.1)
      ..lineTo(size.width * 0.9, size.height * 0.9)
      ..close();

    final centerSupport = Path()
      ..moveTo(size.width * 0.45, size.height * 0.6)
      ..lineTo(size.width * 0.55, size.height * 0.6)
      ..lineTo(size.width * 0.55, size.height * 0.65)
      ..lineTo(size.width * 0.45, size.height * 0.65)
      ..close();

    canvas.drawPath(leftLeg, paint);
    canvas.drawPath(rightLeg, paint);
    canvas.drawPath(centerSupport, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
