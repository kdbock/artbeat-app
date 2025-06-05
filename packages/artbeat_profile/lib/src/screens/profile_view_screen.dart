import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';

class ProfileViewScreen extends StatefulWidget {
  final String userId; // Firebase User ID
  final bool
      isCurrentUser; // Flag to determine if this is the current user's profile

  const ProfileViewScreen({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
  });

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final UserService _userService = UserService();

  // User data
  bool _isLoading = true;
  UserModel? _userModel;
  bool _isFollowing = false;

  // For UI access
  String get username => _userModel?.username ?? "wordnerd_user";
  String get name => _userModel?.fullName ?? "WordNerd User";
  String get bio =>
      _userModel?.bio ?? "Vocabulary enthusiast and language lover";
  String get location => _userModel?.location ?? "United States";
  String get profileImageUrl => _userModel?.profileImageUrl ?? "";
  int get postsCount => _userModel?.posts.length ?? 0;
  int get followersCount => _userModel?.followers.length ?? 0;
  int get followingCount => _userModel?.following.length ?? 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

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
          _isFollowing = userModel?.isFollowedByCurrentUser ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ ProfileViewScreen: Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );

        // Even on error, attempt to provide something to display
        setState(() {
          _userModel = widget.isCurrentUser
              ? UserModel.placeholder(widget.userId)
              : null;
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to get the right image provider for profile picture
  ImageProvider<Object>? _getProfileImageProvider() {
    if (_userModel != null &&
        (_userModel!.profileImageUrl?.isNotEmpty ?? false)) {
      final url = _userModel!.profileImageUrl!;
      debugPrint('🖼️ ProfileViewScreen: profileImageUrl from Firestore: $url');
      // If the URL is a gs:// path, convert to https
      if (url.startsWith('gs://')) {
        debugPrint(
            '🖼️ ProfileViewScreen: Detected gs:// URL, cannot display directly.');
        return const AssetImage('assets/default_profile.png');
      }
      // If the URL is a valid http/https URL, use it
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return NetworkImage(url);
      }
      // If the URL is not valid, fallback
      debugPrint(
          '🖼️ ProfileViewScreen: Invalid profileImageUrl, falling back to default.');
      return const AssetImage('assets/default_profile.png');
    } else if (currentUser != null &&
        currentUser!.photoURL != null &&
        currentUser!.photoURL!.isNotEmpty) {
      return NetworkImage(currentUser!.photoURL!);
    } else {
      return const AssetImage('assets/default_profile.png');
    }
  }

  // Helper to determine if placeholder icon should be shown
  bool _shouldShowProfilePlaceholder() {
    final hasProfileUrl = _userModel != null &&
        (_userModel!.profileImageUrl?.isNotEmpty ?? false);
    final hasFirebasePhotoUrl = currentUser != null &&
        currentUser!.photoURL != null &&
        currentUser!.photoURL!.isNotEmpty;
    return !hasProfileUrl && !hasFirebasePhotoUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(username),
        actions: [
          // Add actions like settings, logout, etc.
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile header with image and stats
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile picture
                            GestureDetector(
                              onTap: () {
                                // Get the URL to display from either model or Firebase Auth
                                final String imageUrl =
                                    _userModel?.profileImageUrl ??
                                        currentUser?.photoURL ??
                                        '';
                                // Navigate to profile picture viewer if we have an image URL
                                if (imageUrl.isNotEmpty) {
                                  Navigator.pushNamed(
                                    context,
                                    '/profile/picture-viewer',
                                    arguments: {'imageUrl': imageUrl},
                                  );
                                }
                              },
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _getProfileImageProvider(),
                                child: _shouldShowProfilePlaceholder()
                                    ? const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Stats (posts, followers, following)
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatColumn(postsCount, 'Posts'),
                                      _buildFollowersColumn(
                                        followersCount,
                                        'Followers',
                                      ),
                                      _buildFollowingColumn(
                                        followingCount,
                                        'Following',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Edit profile or Follow button
                                  if (widget.isCurrentUser)
                                    _buildEditProfileButton()
                                  else
                                    _buildFollowButton(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // User info (name, bio)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(bio),
                              if (location.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      location,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Profile Actions
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.favorite,
                          label: 'Favorites',
                          onTap: () => _navigateToFavorites(),
                        ),
                        _buildActionButton(
                          icon: Icons.emoji_events,
                          label: 'Achievements',
                          onTap: () => _navigateToAchievements(),
                        ),
                        _buildActionButton(
                          icon: Icons.bookmark,
                          label: 'Saved',
                          onTap: () {
                            // Will be implemented in the future
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Coming soon')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const Divider(),
                  // Posts grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: postsCount,
                    itemBuilder: (context, index) {
                      // Placeholder for post thumbnails
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Text(
                            'Post ${index + 1}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatColumn(int count, String label) {
    return GestureDetector(
      onTap: () {
        // Navigate based on stat type
        if (label == 'Posts') {
          // Handle posts tap
        }
      },
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFollowersColumn(int count, String label) {
    return GestureDetector(
      onTap: () {
        // Navigate to followers list
        Navigator.pushNamed(
          context,
          '/profile/followers',
          arguments: {'userId': widget.userId},
        );
      },
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFollowingColumn(int count, String label) {
    return GestureDetector(
      onTap: () {
        // Navigate to following list
        Navigator.pushNamed(
          context,
          '/profile/following',
          arguments: {'userId': widget.userId},
        );
      },
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/profile/edit',
            arguments: {'userId': widget.userId},
          );
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: const Text('Edit Profile'),
      ),
    );
  }

  Widget _buildFollowButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_userModel != null) {
            setState(() {
              _isFollowing = !_isFollowing;
            });

            // Update in Firestore
            if (_isFollowing) {
              _userService.followUser(widget.userId);
            } else {
              _userService.unfollowUser(widget.userId);
            }

            // Reload profile after a short delay to get updated counts
            Future.delayed(const Duration(milliseconds: 500), () {
              _loadUserProfile();
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isFollowing ? Colors.grey[300] : Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(
          _isFollowing ? 'Following' : 'Follow',
          style: TextStyle(color: _isFollowing ? Colors.black : Colors.white),
        ),
      ),
    );
  }

  void _navigateToFavorites() {
    Navigator.pushNamed(
      context,
      '/profile/favorites',
      arguments: {'userId': widget.userId},
    );
  }

  void _navigateToAchievements() {
    Navigator.pushNamed(context, '/profile/achievements');
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
