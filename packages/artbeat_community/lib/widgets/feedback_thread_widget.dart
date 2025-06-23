import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'avatar_widget.dart';
import '../models/comment_model.dart';

class FeedbackThreadWidget extends StatelessWidget {
  final List<CommentModel> comments;
  final void Function(CommentModel) onReply;

  const FeedbackThreadWidget({
    super.key,
    required this.comments,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarWidget(avatarUrl: comment.userAvatarUrl, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          timeago.format(comment.createdAt.toDate()),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(
                  left: 52,
                ), // Align with content above
                child: Text(
                  comment.content,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(
                  left: 52,
                ), // Align with content above
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => onReply(comment),
                      child: const Text('Reply'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        comment.type,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
