import 'package:flutter/material.dart';
import '../models/comment_model.dart';

class FeedbackThreadWidget extends StatelessWidget {
  final List<CommentModel> comments;
  final Function(CommentModel) onReply;

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
                  CircleAvatar(
                    backgroundImage: NetworkImage(comment.userAvatarUrl),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        comment.createdAt.toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                comment.content,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => onReply(comment),
                    child: const Text('Reply'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    comment.type,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
