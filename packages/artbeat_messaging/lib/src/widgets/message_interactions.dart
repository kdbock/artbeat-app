import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

/// Widget for displaying message interaction options
class MessageActionsSheet extends StatelessWidget {
  final MessageModel message;
  final ChatModel chat;
  final String currentUserId;
  final VoidCallback? onEdit;
  final VoidCallback? onForward;
  final VoidCallback? onStar;
  final VoidCallback? onDelete;

  const MessageActionsSheet({
    super.key,
    required this.message,
    required this.chat,
    required this.currentUserId,
    this.onEdit,
    this.onForward,
    this.onStar,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final canEdit =
        message.senderId == currentUserId && message.type == MessageType.text;
    final canDelete = message.senderId == currentUserId;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Message Preview
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          if (canEdit)
            _ActionTile(
              icon: Icons.edit,
              title: 'Edit Message',
              onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              },
            ),

          _ActionTile(
            icon: message.isStarred ? Icons.star : Icons.star_border,
            title: message.isStarred ? 'Remove Star' : 'Star Message',
            onTap: () {
              Navigator.pop(context);
              onStar?.call();
            },
          ),

          _ActionTile(
            icon: Icons.forward,
            title: 'Forward Message',
            onTap: () {
              Navigator.pop(context);
              onForward?.call();
            },
          ),

          _ActionTile(
            icon: Icons.copy,
            title: 'Copy Text',
            onTap: () {
              Navigator.pop(context);
              _copyToClipboard(context, message.content);
            },
          ),

          if (canDelete)
            _ActionTile(
              icon: Icons.delete,
              title: 'Delete Message',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),

          // Cancel
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    // Implementation would copy text to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard')),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}

/// Widget for editing a message
class MessageEditWidget extends StatefulWidget {
  final MessageModel message;
  final void Function(String) onSave;
  final VoidCallback onCancel;

  const MessageEditWidget({
    super.key,
    required this.message,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<MessageEditWidget> createState() => _MessageEditWidgetState();
}

class _MessageEditWidgetState extends State<MessageEditWidget> {
  late TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Edit Message',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancel,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Original message indicator
          if (widget.message.isEdited)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This message was previously edited',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),

          // Text field
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Enter your message...',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving ? null : widget.onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSaving || _controller.text.trim().isEmpty
                    ? null
                    : _saveMessage,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveMessage() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    try {
      widget.onSave(_controller.text.trim());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving message: $e')));
      }
    }

    setState(() => _isSaving = false);
  }
}

/// Widget for forwarding messages
class ForwardMessageSheet extends StatefulWidget {
  final MessageModel message;
  final void Function(List<ChatModel>) onForward;

  const ForwardMessageSheet({
    super.key,
    required this.message,
    required this.onForward,
  });

  @override
  State<ForwardMessageSheet> createState() => _ForwardMessageSheetState();
}

class _ForwardMessageSheetState extends State<ForwardMessageSheet> {
  final ChatService _chatService = ChatService();
  final List<ChatModel> _selectedChats = [];
  List<ChatModel> _allChats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await _chatService.getChats();
      setState(() {
        _allChats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading chats: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Forward Message',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Message preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.forward, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.message.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Chat list
          Text(
            'Select conversations:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allChats.isEmpty
                ? const Center(child: Text('No conversations available'))
                : ListView.builder(
                    itemCount: _allChats.length,
                    itemBuilder: (context, index) {
                      final chat = _allChats[index];
                      final isSelected = _selectedChats.contains(chat);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedChats.add(chat);
                            } else {
                              _selectedChats.remove(chat);
                            }
                          });
                        },
                        title: Text(
                          chat.isGroup
                              ? chat.groupName ?? 'Group Chat'
                              : 'Direct Message',
                        ),
                        subtitle: Text(chat.lastMessage?.content ?? ''),
                        secondary: CircleAvatar(
                          backgroundImage: chat.groupImage != null
                              ? NetworkImage(chat.groupImage!)
                              : null,
                          child: chat.groupImage == null
                              ? Text(
                                  chat.isGroup
                                      ? chat.groupName?.substring(0, 1) ?? 'G'
                                      : 'U',
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),

          // Actions
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _selectedChats.isEmpty
                    ? null
                    : () {
                        widget.onForward(_selectedChats);
                        Navigator.pop(context);
                      },
                child: Text(
                  'Forward to ${_selectedChats.length} chat${_selectedChats.length == 1 ? '' : 's'}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Enhanced message bubble with interaction support
class InteractiveMessageBubble extends StatelessWidget {
  final MessageModel message;
  final ChatModel chat;
  final String currentUserId;
  final ChatService chatService;

  const InteractiveMessageBubble({
    super.key,
    required this.message,
    required this.chat,
    required this.currentUserId,
    required this.chatService,
  });

  @override
  Widget build(BuildContext context) {
    final isSentByMe = message.senderId == currentUserId;

    return GestureDetector(
      onLongPress: () => _showMessageActions(context),
      child: Container(
        margin: EdgeInsets.only(
          left: isSentByMe ? 64 : 16,
          right: isSentByMe ? 16 : 64,
          top: 4,
          bottom: 4,
        ),
        child: Align(
          alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSentByMe
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Forwarded indicator
                if (message.isForwarded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.forward,
                          size: 12,
                          color: isSentByMe ? Colors.white70 : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Forwarded',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSentByMe
                                ? Colors.white70
                                : Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Message content
                Text(
                  message.content,
                  style: TextStyle(
                    color: isSentByMe ? Colors.white : Colors.black,
                  ),
                ),

                // Message metadata
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.isEdited)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.edit,
                          size: 10,
                          color: isSentByMe ? Colors.white70 : Colors.grey[600],
                        ),
                      ),

                    if (message.isStarred)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.star, size: 12, color: Colors.amber),
                      ),

                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isSentByMe ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => MessageActionsSheet(
        message: message,
        chat: chat,
        currentUserId: currentUserId,
        onEdit: () => _showEditDialog(context),
        onForward: () => _showForwardDialog(context),
        onStar: () => _toggleStar(context),
        onDelete: () => _deleteMessage(context),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => MessageEditWidget(
        message: message,
        onSave: (newContent) async {
          try {
            await chatService.editMessage(chat.id, message.id, newContent);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message edited successfully')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error editing message: $e')),
              );
            }
          }
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showForwardDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ForwardMessageSheet(
        message: message,
        onForward: (selectedChats) async {
          try {
            for (final targetChat in selectedChats) {
              await chatService.forwardMessage(
                message.id,
                chat.id,
                targetChat.id,
              );
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Message forwarded to ${selectedChats.length} chat${selectedChats.length == 1 ? '' : 's'}',
                  ),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error forwarding message: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _toggleStar(BuildContext context) async {
    try {
      await chatService.toggleMessageStar(chat.id, message.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.isStarred ? 'Message unstarred' : 'Message starred',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteMessage(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await chatService.deleteMessage(chat.id, message.id);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Message deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting message: $e')));
        }
      }
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    if (now.day == timestamp.day &&
        now.month == timestamp.month &&
        now.year == timestamp.year) {
      // Same day - show time
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      // Different day - show date
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
