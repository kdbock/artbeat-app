import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:artbeat_core/artbeat_core.dart';
import '../models/message.dart';
import 'message_reactions_widget.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final String? chatId;
  final VoidCallback? onImageTap;
  final VoidCallback? onReactionAdded;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.chatId,
    this.onImageTap,
    this.onReactionAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isCurrentUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isCurrentUser) _buildAvatar(),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  margin: EdgeInsets.only(
                    left: isCurrentUser ? 48 : 0,
                    right: isCurrentUser ? 0 : 48,
                  ),
                  padding: message.imageUrl != null && message.text == null
                      ? const EdgeInsets.all(4)
                      : const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? ArtbeatColors.primaryPurple
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
                      bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isCurrentUser
                            ? ArtbeatColors.primaryPurple.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.imageUrl != null) _buildImageContent(),
                      if (message.text != null) _buildTextContent(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isCurrentUser) _buildAvatar(),
            ],
          ),

          // Add reactions widget if chatId is provided
          if (chatId != null)
            Padding(
              padding: EdgeInsets.only(
                left: isCurrentUser ? 0 : 48,
                right: isCurrentUser ? 48 : 0,
              ),
              child: MessageReactionsWidget(
                messageId: message.id,
                chatId: chatId!,
                onReactionAdded: onReactionAdded,
              ),
            ),

          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isCurrentUser ? 0 : 48,
              right: isCurrentUser ? 48 : 0,
            ),
            child: Text(
              _formatTime(message.timestamp),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return ImageUtils.safeCircleAvatar(
      imageUrl: message.senderPhotoUrl,
      displayName: message.senderName ?? 'User',
      radius: 16.0,
    );
  }

  Widget _buildImageContent() {
    return GestureDetector(
      onTap: onImageTap,
      child: Hero(
        tag: 'image_${message.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.network(
                message.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          ArtbeatColors.primaryPurple,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey.shade200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (message.text != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Text(
                      message.text!,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    if (message.imageUrl != null) return const SizedBox.shrink();

    return Text(
      message.text!,
      style: TextStyle(
        color: isCurrentUser ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return intl.DateFormat.jm().format(timestamp);
  }
}
