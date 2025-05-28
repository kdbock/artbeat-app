import 'package:flutter/material.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
    });

    // In a real app, fetch from Firestore
    // For demo purposes, use mock data
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _blockedUsers = List.generate(
        5,
        (index) => {
          'id': 'user_$index',
          'username': 'blocked_user_$index',
          'name': 'Blocked User ${index + 1}',
          'profileImageUrl': '', // Would come from Firebase storage
          'blockedDate': DateTime.now().subtract(Duration(days: index * 5)),
        },
      );
      _isLoading = false;
    });
  }

  Future<void> _unblockUser(Map<String, dynamic> user) async {
    setState(() {
      _isLoading = true;
    });

    // In a real app, update in Firestore
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _blockedUsers.remove(user);
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unblocked ${user['username']}'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              setState(() {
                _blockedUsers.add(user);
              });
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blocked Users ${_blockedUsers.isNotEmpty ? "(${_blockedUsers.length})" : ""}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showBlockingInfoDialog();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _blockedUsers.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                itemCount: _blockedUsers.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final user = _blockedUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          user['profileImageUrl'].isNotEmpty
                              ? NetworkImage(user['profileImageUrl'])
                                  as ImageProvider
                              : const AssetImage('assets/default_profile.png'),
                      child:
                          user['profileImageUrl'].isEmpty
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                    ),
                    title: Text(
                      user['username'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(user['name']),
                    trailing: TextButton(
                      child: const Text('Unblock'),
                      onPressed: () => _showUnblockConfirmationDialog(user),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Blocked Users',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'You haven\'t blocked any users yet',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // In a real app, navigate to user search
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User search will be implemented soon'),
                ),
              );
            },
            child: const Text('Find Users'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUnblockConfirmationDialog(Map<String, dynamic> user) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Unblock User'),
            content: Text(
              'Are you sure you want to unblock ${user['username']}? They will be able to '
              'see your profile, follow you, and send you messages again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('UNBLOCK'),
              ),
            ],
          ),
    );

    if (result == true && mounted) {
      await _unblockUser(user);
    }
  }

  Future<void> _showBlockingInfoDialog() async {
    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('About Blocking'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'When you block someone:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• They can\'t see your profile'),
                Text('• They can\'t follow you'),
                Text('• They can\'t send you messages'),
                Text('• They can\'t see your posts or comments'),
                Text('• They won\'t be notified that they were blocked'),
                SizedBox(height: 16),
                Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  'If you unblock someone, you\'ll need to follow them again if you '
                  'previously followed them.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
            ],
          ),
    );
  }
}
