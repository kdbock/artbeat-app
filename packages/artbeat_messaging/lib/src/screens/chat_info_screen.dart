import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart' as messaging;
import '../services/chat_service.dart';
import 'user_profile_screen.dart';

class ChatInfoScreen extends StatefulWidget {
  final ChatModel chat;

  const ChatInfoScreen({super.key, required this.chat});

  @override
  State<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> {
  bool _notificationsEnabled = true;
  bool _isGroup = false;
  List<messaging.UserModel> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _isGroup = widget.chat.isGroup;
    _loadParticipants();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: EnhancedUniversalHeader(
        title: _isGroup ? 'Group Info' : 'Chat Info',
        showLogo: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isGroup ? _editGroupInfo : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Chat header
                _buildChatHeader(),
                const SizedBox(height: 16),

                // Chat settings
                _buildChatSettings(),
                const SizedBox(height: 16),

                // Participants section
                if (_isGroup) ...[
                  _buildParticipantsSection(),
                  const SizedBox(height: 16),
                ],

                // Actions section
                _buildActionsSection(theme),
              ],
            ),
    );
  }

  Widget _buildChatHeader() {
    final chatName = _isGroup
        ? widget.chat.groupName ?? 'Group Chat'
        : _participants.isNotEmpty
        ? _participants.first.displayName
        : 'Loading...';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: ArtbeatColors.primaryPurple,
            backgroundImage: _getChatImage(),
            child: _getChatImage() == null
                ? Text(
                    chatName.isNotEmpty ? chatName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            chatName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (_isGroup) ...[
            const SizedBox(height: 8),
            Text(
              '${_participants.length} participants',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ] else if (_participants.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _participants.first.isOnline
                      ? Icons.circle
                      : Icons.circle_outlined,
                  size: 12,
                  color: _participants.first.isOnline
                      ? Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _participants.first.isOnline
                      ? 'Online'
                      : 'Last seen: ${_formatLastSeen(_participants.first.lastSeen)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                // TODO: Implement notification settings update
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wallpaper),
            title: const Text('Wallpaper'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Navigate to wallpaper selection
            },
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Participants',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...List.generate(_participants.length, (index) {
            final participant = _participants[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: participant.photoUrl != null
                    ? NetworkImage(participant.photoUrl!)
                    : null,
                child: participant.photoUrl == null
                    ? Text(participant.displayName[0].toUpperCase())
                    : null,
              ),
              title: Text(participant.displayName),
              subtitle: Text(
                participant.isOnline
                    ? 'Online'
                    : 'Last seen: ${_formatLastSeen(participant.lastSeen)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat),
                    onPressed: () => _messageParticipant(participant),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showParticipantOptions(participant),
                  ),
                ],
              ),
              onTap: () => _viewParticipantProfile(participant),
            );
          }),
          if (_isGroup)
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add participant'),
              onTap: _addParticipant,
            ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search in chat'),
            onTap: () {
              // TODO: Implement search in chat
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear chat'),
            onTap: _clearChat,
          ),
          if (!_isGroup)
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block user'),
              onTap: _blockUser,
            ),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: theme.colorScheme.error),
            title: Text(
              _isGroup ? 'Leave group' : 'Delete chat',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: _isGroup ? _leaveGroup : _deleteChat,
          ),
        ],
      ),
    );
  }

  ImageProvider? _getChatImage() {
    if (_isGroup) {
      return widget.chat.groupImage != null &&
              widget.chat.groupImage!.isNotEmpty
          ? NetworkImage(widget.chat.groupImage!)
          : null;
    } else if (_participants.isNotEmpty &&
        _participants.first.photoUrl != null) {
      return NetworkImage(_participants.first.photoUrl!);
    }
    return null;
  }

  void _editGroupInfo() {
    // TODO: Navigate to group edit screen
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group'),
        content: const Text('Group editing feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _viewParticipantProfile(messaging.UserModel participant) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => UserProfileScreen(user: participant),
      ),
    );
  }

  void _messageParticipant(messaging.UserModel participant) async {
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final chat = await chatService.createOrGetChat(participant.id);

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/messaging/chat',
          arguments: {'chat': chat},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showParticipantOptions(messaging.UserModel participant) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Message'),
            onTap: () {
              Navigator.pop(context);
              _messageParticipant(participant);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('View Profile'),
            onTap: () {
              Navigator.pop(context);
              _viewParticipantProfile(participant);
            },
          ),
          if (_isGroup) ...[
            ListTile(
              leading: const Icon(Icons.person_remove),
              title: const Text('Remove from group'),
              onTap: () {
                Navigator.pop(context);
                _removeParticipant(participant);
              },
            ),
          ],
        ],
      ),
    );
  }

  void _addParticipant() {
    Navigator.pushNamed(context, '/messaging/new');
  }

  void _removeParticipant(messaging.UserModel participant) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Participant'),
        content: Text('Remove ${participant.displayName} from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement remove participant
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _clearChat() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to clear all messages in this chat?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear chat
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _blockUser() {
    if (_participants.isNotEmpty) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Block User'),
          content: Text('Block ${_participants.first.displayName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement block user
              },
              child: const Text('Block'),
            ),
          ],
        ),
      );
    }
  }

  void _leaveGroup() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement leave group
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete chat
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
}
