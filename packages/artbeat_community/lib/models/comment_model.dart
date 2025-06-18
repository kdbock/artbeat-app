import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final String parentCommentId;
  final String type; // Critique, Appreciation, Question, Tip
  final Timestamp createdAt;
  final String userName;
  final String userAvatarUrl;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.parentCommentId,
    required this.type,
    required this.createdAt,
    required this.userName,
    required this.userAvatarUrl,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      postId: (data['postId'] as String?) ?? '',
      userId: (data['userId'] as String?) ?? '',
      content: (data['content'] as String?) ?? '',
      parentCommentId: (data['parentCommentId'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'Appreciation',
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
      userName: (data['userName'] as String?) ?? '',
      userAvatarUrl: (data['userAvatarUrl'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'content': content,
      'parentCommentId': parentCommentId,
      'type': type,
      'createdAt': createdAt,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
    };
  }
}
