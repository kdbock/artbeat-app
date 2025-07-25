import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart' as messaging;
import '../services/chat_service.dart';
import 'group_edit_screen.dart';

class ChatInfoScreen extends StatefulWidget {
  final ChatModel chat;

  const ChatInfoScreen({super.key, required this.chat});

  @override
  State<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> {
  bool _isGroup = false;
  List<messaging.UserModel> _participants = [];
  bool _isLoading = true;
  Color? _chatWallpaper;

  void _editGroupInfo() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => GroupEditScreen(chatId: widget.chat.id),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _isGroup = widget.chat.isGroup;
    _loadParticipants();
    _loadWallpaper();
  }

  Future<void> _loadWallpaper() async {
    final doc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chat.id)
        .get();
    if (doc.exists &&
        doc.data() != null &&
        doc.data()!.containsKey('wallpaper')) {
      setState(() {
        _chatWallpaper = Color(doc.data()!['wallpaper'] as int);
      });
    }
  }

  Future<void> _loadParticipants() async {
    setState(() => _isLoading = true);

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final participants = <messaging.UserModel>[];

      for (final participantId in widget.chat.participantIds) {
        final user = await chatService.getUser(participantId);
        if (user != null) {
          participants.add(user);
        }
      }

      setState(() {
        _participants = participants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading participants: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteChat() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final chatService = Provider.of<ChatService>(
                  context,
                  listen: false,
                );
                await chatService.deleteChat(widget.chat.id);
                if (mounted) {
                  Navigator.pop(context); // Go back to previous screen
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Chat deleted')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete chat: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isGroup ? 'Group Info' : 'Chat Info'),
        actions: [
          if (_isGroup)
            IconButton(icon: const Icon(Icons.edit), onPressed: _editGroupInfo),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: _chatWallpaper ?? Colors.grey,
                        child: Icon(
                          _isGroup ? Icons.group : Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isGroup
                            ? (widget.chat.groupName ?? 'Group')
                            : _participants.isNotEmpty
                            ? _participants.first.displayName
                            : 'Chat',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (!_isGroup && _participants.isNotEmpty)
                        Text(
                          'Last seen: ${_formatLastSeen(_participants.first.lastSeen)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      if (_isGroup) ...[
                        const Divider(),
                        ListTile(
                          title: const Text('Participants'),
                          subtitle: Text('${_participants.length} members'),
                        ),
                        ...(_participants.map(
                          (user) => ListTile(
                            leading: (user.photoUrl?.isNotEmpty == true)
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      user.photoUrl!,
                                    ),
                                  )
                                : CircleAvatar(
                                    child: Text(
                                      user.displayName.isNotEmpty
                                          ? user.displayName[0].toUpperCase()
                                          : '?',
                                    ),
                                  ),
                            title: Text(user.displayName),
                          ),
                        )),
                      ],
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.delete),
                        title: const Text('Delete Chat'),
                        onTap: _deleteChat,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
