import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    await Future.delayed(
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Following ${_isLoading ? '' : '(${_following.length})'}'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _following.isEmpty
              ? const Center(
                child: Text(
                  'Not following anyone yet',
                  style: TextStyle(fontSize: 16),
                ),
              )
              : ListView.builder(
                itemCount: _following.length,
                itemBuilder: (context, index) {
                  final followedUser = _following[index];
                  final isCurrentUser = followedUser['id'] == _currentUser?.uid;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          followedUser['profileImageUrl'].isNotEmpty
                              ? NetworkImage(followedUser['profileImageUrl'])
                                  as ImageProvider
                              : const AssetImage('assets/default_profile.png'),
                      child:
                          followedUser['profileImageUrl'].isEmpty
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                    ),
                    title: Text(
                      followedUser['username'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(followedUser['name']),
                    trailing:
                        isCurrentUser
                            ? null
                            : TextButton(
                              onPressed: () => _unfollow(index),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                minimumSize: const Size(80, 30),
                              ),
                              child: const Text(
                                'Following',
                                style: TextStyle(color: Colors.black),
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
                  );
                },
              ),
    );
  }
}
