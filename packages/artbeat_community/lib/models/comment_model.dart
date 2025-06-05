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
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      parentCommentId: data['parentCommentId'] ?? '',
      type: data['type'] ?? 'Appreciation',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      userName: data['userName'] ?? '',
      userAvatarUrl: data['userAvatarUrl'] ?? '',
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
