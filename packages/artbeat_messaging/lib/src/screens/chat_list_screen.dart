import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../widgets/chat_list_tile.dart';
import 'chat_screen.dart';
import 'contact_selection_screen.dart';
import 'group_creation_screen.dart';
import 'chat_settings_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showChatOptions(context);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: chatService.getChatStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading chats',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!;

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text('No messages yet', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation with fellow artists',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToNewChat(context),
                    icon: const Icon(Icons.add),
                    label: const Text('New Message'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ChatListTile(
                chat: chat,
                onTap: () => _navigateToChat(context, chat),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToNewChat(context),
        child: const Icon(Icons.chat),
      ),
    );
  }

  void _navigateToNewChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const ContactSelectionScreen(),
      ),
    );
  }

  void _navigateToChat(BuildContext context, ChatModel chat) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => ChatScreen(chat: chat)),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => _ChatSearchDialog(),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('New Group'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const GroupCreationScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Chat Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const ChatSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ChatSearchDialog extends StatefulWidget {
  @override
  _ChatSearchDialogState createState() => _ChatSearchDialogState();
}

class _ChatSearchDialogState extends State<_ChatSearchDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getChatName(ChatModel chat) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    if (chat.isGroup) {
      return chat.groupName ?? 'Unnamed Group';
    }
    // For 1-1 chats, find the other participant
    final otherParticipant = chat.participants.firstWhere(
      (p) => p.id != chatService.currentUserId,
    );
    return otherParticipant.displayName;
  }

  String _getChatImage(ChatModel chat) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    if (chat.isGroup) {
      return chat.groupImage ?? '';
    }
    // For 1-1 chats, find the other participant's photo
    final otherParticipant = chat.participants.firstWhere(
      (p) => p.id != chatService.currentUserId,
    );
    return otherParticipant.photoUrl ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search chats...',
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
            const SizedBox(height: 16),
            if (_searchQuery.isNotEmpty)
              Flexible(
                child: Consumer<ChatService>(
                  builder: (context, chatService, child) {
                    return FutureBuilder<List<ChatModel>>(
                      future: chatService.searchChats(_searchQuery),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error searching chats',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          );
                        }

                        final results = snapshot.data ?? [];

                        if (results.isEmpty) {
                          return Center(
                            child: Text(
                              'No chats found',
                              style: theme.textTheme.bodyLarge,
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final chat = results[index];
                            final chatName = _getChatName(chat);
                            final imageUrl = _getChatImage(chat);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: imageUrl.isNotEmpty
                                    ? NetworkImage(imageUrl)
                                    : null,
                                child: imageUrl.isEmpty
                                    ? Text(chatName[0].toUpperCase())
                                    : null,
                              ),
                              title: Text(chatName),
                              subtitle: chat.lastMessage != null
                                  ? Text(
                                      chat.lastMessage!.content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : const Text('No messages yet'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (context) =>
                                        ChatScreen(chat: chat),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
