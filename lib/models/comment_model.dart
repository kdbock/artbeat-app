import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for comments on posts
class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final String? parentCommentId; // For threaded comments
  final bool isEdited;
  final List<String>? mentionedUsers;

  /// Constructor
  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.content,
    required this.createdAt,
    required this.likeCount,
    this.parentCommentId,
    this.isEdited = false,
    this.mentionedUsers,
  });

  /// Create a CommentModel from Firestore document
  factory CommentModel.fromFirestore(DocumentSnapshot doc, {String? postId}) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle server timestamps that might be null for new comments
    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else {
      createdAt = DateTime.now(); // Fallback for new comments
    }

    return CommentModel(
      id: doc.id,
      postId: postId ?? data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      content: data['content'] ?? '',
      createdAt: createdAt,
      likeCount: data['likeCount'] ?? 0,
      parentCommentId: data['parentCommentId'],
      isEdited: data['isEdited'] ?? false,
      mentionedUsers: data['mentionedUsers'] != null
          ? List<String>.from(data['mentionedUsers'])
          : null,
    );
  }

  /// Convert CommentModel to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'likeCount': likeCount,
      'parentCommentId': parentCommentId,
      'isEdited': isEdited,
      'mentionedUsers': mentionedUsers,
    };
  }

  /// Create a copy of this CommentModel with updated values
  CommentModel copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? content,
    DateTime? createdAt,
    int? likeCount,
    String? parentCommentId,
    bool? isEdited,
    List<String>? mentionedUsers,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      isEdited: isEdited ?? this.isEdited,
      mentionedUsers: mentionedUsers ?? this.mentionedUsers,
    );
  }
}
