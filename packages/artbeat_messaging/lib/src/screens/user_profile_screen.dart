import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final UserModel user;

  const UserProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatService = Provider.of<ChatService>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(user.displayName),
              background: user.photoUrl != null
                  ? Image.network(user.photoUrl!, fit: BoxFit.cover)
                  : Container(
                      color: theme.primaryColor,
                      child: Center(
                        child: Text(
                          user.displayName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 72,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                user.isOnline
                                    ? Icons.circle
                                    : Icons.circle_outlined,
                                size: 12,
                                color: user.isOnline
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.isOnline
                                    ? 'Online'
                                    : 'Last seen: ${_formatLastSeen(user.lastSeen)}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.chat),
                                  label: const Text('Message'),
                                  onPressed: () async {
                                    try {
                                      final chat = await chatService
                                          .createOrGetChat(user.id);
                                      if (!context.mounted) return;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (context) =>
                                              ChatScreen(chat: chat),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error creating chat: ${e.toString()}',
                                          ),
                                          backgroundColor:
                                              theme.colorScheme.error,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showUserOptions(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _buildActionSheet(context),
    );
  }

  Widget _buildActionSheet(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.block),
          title: const Text('Block User'),
          onTap: () {
            Navigator.pop(context);
            // TODO: Implement block user functionality
          },
        ),
        ListTile(
          leading: const Icon(Icons.flag),
          title: const Text('Report User'),
          onTap: () {
            Navigator.pop(context);
            // TODO: Implement report user functionality
          },
        ),
      ],
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }
}
