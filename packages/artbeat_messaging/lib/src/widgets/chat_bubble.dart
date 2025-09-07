import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../theme/chat_theme.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? ChatTheme.currentUserBubbleColor
              : ChatTheme.otherUserBubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isCurrentUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
