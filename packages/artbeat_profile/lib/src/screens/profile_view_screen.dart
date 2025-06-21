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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(username),
                background: Image.network(
                  profileImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: const Center(child: Icon(Icons.person)),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleLarge),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(bio),
                    ],
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16),
                          const SizedBox(width: 4),
                          Text(location),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Posts', postsCount),
                        _buildStat('Captures', capturesCount),
                        _buildStat('Followers', followersCount),
                        _buildStat('Following', followingCount),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on), text: 'Posts'),
                    Tab(icon: Icon(Icons.camera_alt), text: 'Captures'),
                    Tab(icon: Icon(Icons.favorite_border), text: 'Likes'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Posts Grid
            const Center(child: Text('Posts coming soon')),

            // Captures Grid
            CapturesGrid(
              userId: widget.userId,
              showPublicOnly: !widget.isCurrentUser,
              onCaptureTap: _navigateToCaptureDetail,
            ),

            // Likes Grid
            const Center(child: Text('Likes coming soon')),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(value.toString(), style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}
