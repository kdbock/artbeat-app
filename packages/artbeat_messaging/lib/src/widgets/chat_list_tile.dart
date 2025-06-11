import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_model.dart';

class ChatListTile extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const ChatListTile({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastMessage = chat.lastMessage;
    final dateFormat = DateFormat.jm();

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary,
        radius: 24,
        child: Text(
          _getInitials(),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.isGroup
                  ? chat.groupName ?? 'Group Chat'
                  : chat.participants.first.displayName ?? 'Unknown',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight:
                    lastMessage?.isRead == false
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
          ),
          if (lastMessage != null)
            Text(
              dateFormat.format(lastMessage.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMessage?.content ?? 'No messages yet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    lastMessage?.isRead == false
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (lastMessage?.isRead == false)
            Container(
              margin: const EdgeInsets.only(left: 8),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  String _getInitials() {
    if (chat.isGroup) {
      return 'G';
    }
    final name = chat.participants.first.displayName ?? '';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
