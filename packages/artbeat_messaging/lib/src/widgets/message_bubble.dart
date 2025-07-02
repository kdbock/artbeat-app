import 'package:flutter/material.dart';
import '../models/message.dart';
import '../theme/chat_theme.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final VoidCallback? onImageTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onImageTap,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null)
              GestureDetector(
                onTap: onImageTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    message.imageUrl!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (message.text != null)
              Text(
                message.text!,
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.black87,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
