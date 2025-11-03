import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/blocked_user_model.dart';
import '../services/integrated_settings_service.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final IntegratedSettingsService _settingsService =
      IntegratedSettingsService();
  List<BlockedUserModel> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);

    try {
      final blockedUsers = await _settingsService.getBlockedUsers();
      if (mounted) {
        setState(() {
          _blockedUsers = blockedUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading blocked users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EnhancedUniversalHeader(
        title: 'Blocked Users',
        showLogo: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
          ? _buildEmptyState()
          : _buildBlockedUsersList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.block,
              size: 64,
              color: ArtbeatColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No blocked users',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Users you block will appear here.\nYou can unblock them at any time.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUsersList() {
    return RefreshIndicator(
      onRefresh: _loadBlockedUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _blockedUsers.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildListHeader();
          }

          final user = _blockedUsers[index - 1];
          return _buildBlockedUserCard(user);
        },
      ),
    );
  }

  Widget _buildListHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ArtbeatColors.primaryPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: ArtbeatColors.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${_blockedUsers.length} blocked user${_blockedUsers.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ArtbeatColors.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Blocked users cannot message you or see your content. You can unblock them at any time.',
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUserCard(BlockedUserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
          backgroundImage: user.blockedUserProfileImage.isNotEmpty
              ? NetworkImage(user.blockedUserProfileImage)
              : null,
          child: user.blockedUserProfileImage.isEmpty
              ? Text(
                  user.blockedUserName.isNotEmpty
                      ? user.blockedUserName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: ArtbeatColors.primaryPurple,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user.blockedUserName.isNotEmpty
              ? user.blockedUserName
              : 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.reason.isNotEmpty)
              Text(
                'Reason: ${user.reason}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            Text(
              'Blocked ${_formatDate(user.blockedAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: TextButton(
          onPressed: () => _showUnblockDialog(user),
          child: const Text(
            'Unblock',
            style: TextStyle(color: ArtbeatColors.primaryPurple),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showUnblockDialog(BlockedUserModel user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text(
          'Are you sure you want to unblock ${user.blockedUserName}? They will be able to message you and see your content again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _unblockUser(user);
            },
            child: const Text(
              'Unblock',
              style: TextStyle(color: ArtbeatColors.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _unblockUser(BlockedUserModel user) async {
    try {
      await _settingsService.unblockUser(user.blockedUserId);

      if (mounted) {
        setState(() {
          _blockedUsers.removeWhere(
            (blockedUser) => blockedUser.blockedUserId == user.blockedUserId,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.blockedUserName} has been unblocked'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unblock user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
