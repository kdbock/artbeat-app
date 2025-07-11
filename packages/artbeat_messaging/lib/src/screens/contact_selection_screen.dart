import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../services/chat_service.dart';
import '../models/user_model.dart' as messaging;
import 'chat_screen.dart';

class ContactSelectionScreen extends StatefulWidget {
  const ContactSelectionScreen({super.key});

  @override
  State<ContactSelectionScreen> createState() => _ContactSelectionScreenState();
}

class _ContactSelectionScreenState extends State<ContactSelectionScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatService = Provider.of<ChatService>(context);

    return Scaffold(
      appBar: const EnhancedUniversalHeader(title: 'New Message', showLogo: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search people...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<messaging.UserModel>>(
              future: chatService.searchUsers(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading users',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  );
                }

                final users = snapshot.data ?? [];

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      'No users found',
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(user.displayName[0].toUpperCase())
                            : null,
                      ),
                      title: Text(user.displayName),
                      subtitle: Text(
                        user.isOnline
                            ? 'Online'
                            : 'Last seen: ${_formatLastSeen(user.lastSeen)}',
                      ),
                      onTap: () async {
                        try {
                          // Create or get existing chat
                          final chat = await chatService.createOrGetChat(
                            user.id,
                          );
                          if (!mounted) return;

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => ChatScreen(chat: chat),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error creating chat: ${e.toString()}',
                              ),
                              backgroundColor: theme.colorScheme.error,
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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
