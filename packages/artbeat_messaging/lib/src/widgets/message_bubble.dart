import 'package:flutter/material.dart';
import '../models/message.dart';
import '../utils/date_formatter.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
        margin: EdgeInsets.only(
          left: isCurrentUser ? 64 : 8,
          right: isCurrentUser ? 8 : 64,
          top: 4,
          bottom: 4,
        ),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isCurrentUser ? const Radius.circular(0) : null,
            bottomLeft: !isCurrentUser ? const Radius.circular(0) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null)
              GestureDetector(
                onTap: onImageTap,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: message.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    errorWidget:
                        (context, url, error) => const SizedBox(
                          height: 200,
                          child: Center(child: Icon(Icons.error)),
                        ),
                  ),
                ),
              ),
            if (message.text != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  message.text!,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4, left: 8),
              child: Text(
                DateFormatter.formatMessageTime(message.timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: isCurrentUser ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
