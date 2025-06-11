import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' hide CaptureModel;
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
          '🔄 ProfileViewScreen: Loading profile for user ID: ${widget.userId}');

      // First, try to get user from Firestore
      UserModel? userModel = await _userService.getUserById(widget.userId);

      // If no user model found, and this is the current user, create a placeholder
      if (userModel == null && widget.isCurrentUser) {
        userModel = UserModel.placeholder(widget.userId);
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
