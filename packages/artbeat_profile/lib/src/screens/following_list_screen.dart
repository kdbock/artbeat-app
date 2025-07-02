import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';

class FollowingListScreen extends StatefulWidget {
  final String userId;

  const FollowingListScreen({super.key, required this.userId});

  @override
  State<FollowingListScreen> createState() => _FollowingListScreenState();
}

class _FollowingListScreenState extends State<FollowingListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _following = [];
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    // In a real app, fetch following from Firestore
    // For now, use placeholder data
    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay

    if (mounted) {
      setState(() {
        _following = List.generate(
          10,
          (index) => {
            'id': 'user_${index + 100}',
            'username': 'wordnerd_${index + 100}',
            'name': 'WordNerd User ${index + 1}',
            'profileImageUrl': '', // This would come from Firebase Storage
            'isFollowing': true, // By definition, all are being followed
          },
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _unfollow(int index) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unfollow ${_following[index]['username']}?'),
          content: const Text('Are you sure you want to unfollow this user?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('UNFOLLOW'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // In a real app, update follow status in Firestore
      final username = _following[index]['username'];

      setState(() {
        _following.removeAt(index);
      });

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You unfollowed $username'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: UniversalHeader(
          title: 'Following ${_isLoading ? '' : '(${_following.length})'}',
          showLogo: false,
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ArtbeatColors.primaryPurple,
                    ),
                  )
                : _following.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: ArtbeatColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Not following anyone yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _following.length,
                    itemBuilder: (context, index) {
                      final followedUser = _following[index];
                      final isCurrentUser =
                          (followedUser['id'] as String) == _currentUser?.uid;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.white.withAlpha(230),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: ArtbeatColors.border.withAlpha(128),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: ArtbeatColors.primaryPurple,
                            backgroundImage:
                                (followedUser['profileImageUrl'] as String)
                                    .isNotEmpty
                                ? NetworkImage(
                                    followedUser['profileImageUrl'] as String,
                                  )
                                : null,
                            child:
                                (followedUser['profileImageUrl'] as String)
                                    .isEmpty
                                ? Text(
                                    (followedUser['name'] as String).isNotEmpty
                                        ? (followedUser['name'] as String)[0]
                                              .toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            followedUser['username'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            followedUser['name'] as String,
                            style: const TextStyle(
                              color: ArtbeatColors.textSecondary,
                            ),
                          ),
                          trailing: isCurrentUser
                              ? null
                              : TextButton(
                                  onPressed: () => _unfollow(index),
                                  style: TextButton.styleFrom(
                                    backgroundColor: ArtbeatColors.primaryPurple
                                        .withAlpha(25),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: ArtbeatColors.primaryPurple
                                            .withAlpha(77),
                                      ),
                                    ),
                                    minimumSize: const Size(80, 32),
                                  ),
                                  child: const Text(
                                    'Following',
                                    style: TextStyle(
                                      color: ArtbeatColors.primaryPurple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                          onTap: () {
                            // Navigate to the followed user's profile
                            Navigator.pushNamed(
                              context,
                              '/profile/view',
                              arguments: {
                                'userId': followedUser['id'],
                                'isCurrentUser': isCurrentUser,
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
