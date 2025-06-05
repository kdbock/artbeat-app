import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowersListScreen extends StatefulWidget {
  final String userId;

  const FollowersListScreen({super.key, required this.userId});

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _followers = [];
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    // In a real app, fetch followers from Firestore
    // For now, use placeholder data
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay

    if (mounted) {
      setState(() {
        _followers = List.generate(
          15,
          (index) => {
            'id': 'user_$index',
            'username': 'follower_$index',
            'name': 'Follower ${index + 1}',
            'profileImageUrl': '', // This would come from Firebase Storage
            'isFollowedByMe':
                index % 3 == 0, // Some are followed by current user
          },
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow(int index) async {
    // In a real app, update follow status in Firestore
    setState(() {
      _followers[index]['isFollowedByMe'] =
          !_followers[index]['isFollowedByMe'];
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Show confirmation
    if (mounted) {
      final isFollowing = _followers[index]['isFollowedByMe'];
      final username = _followers[index]['username'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFollowing
                ? 'You are now following $username'
                : 'You unfollowed $username',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Followers ${_isLoading ? '' : '(${_followers.length})'}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _followers.isEmpty
              ? const Center(
                  child:
                      Text('No followers yet', style: TextStyle(fontSize: 16)),
                )
              : ListView.builder(
                  itemCount: _followers.length,
                  itemBuilder: (context, index) {
                    final follower = _followers[index];
                    final isCurrentUser = follower['id'] == _currentUser?.uid;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: follower['profileImageUrl'].isNotEmpty
                            ? NetworkImage(follower['profileImageUrl'])
                                as ImageProvider
                            : const AssetImage('assets/default_profile.png'),
                        child: follower['profileImageUrl'].isEmpty
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                      title: Text(
                        follower['username'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(follower['name']),
                      trailing: isCurrentUser
                          ? null
                          : TextButton(
                              onPressed: () => _toggleFollow(index),
                              style: TextButton.styleFrom(
                                backgroundColor: follower['isFollowedByMe']
                                    ? Colors.grey.shade200
                                    : Theme.of(
                                        context,
                                      ).primaryColor.withAlpha(25),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  side: follower['isFollowedByMe']
                                      ? BorderSide.none
                                      : BorderSide(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                ),
                                minimumSize: const Size(80, 30),
                              ),
                              child: Text(
                                follower['isFollowedByMe']
                                    ? 'Following'
                                    : 'Follow',
                                style: TextStyle(
                                  color: follower['isFollowedByMe']
                                      ? Colors.black
                                      : Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                      onTap: () {
                        // Navigate to the follower's profile
                        Navigator.pushNamed(
                          context,
                          '/profile/view',
                          arguments: {
                            'userId': follower['id'],
                            'isCurrentUser': isCurrentUser,
                          },
                        );
                      },
                    );
                  },
                ),
    );
  }
}
