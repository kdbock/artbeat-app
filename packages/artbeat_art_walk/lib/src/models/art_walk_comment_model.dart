import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for comments on art walks
class ArtWalkCommentModel {
  final String id;
  final String artWalkId;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final String? parentCommentId; // For threaded comments
  final bool isEdited;
  final double? rating; // Optional rating (1-5 stars)
  final List<String>? mentionedUsers;

  /// Constructor
  ArtWalkCommentModel({
    required this.id,
    required this.artWalkId,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.content,
    required this.createdAt,
    required this.likeCount,
    this.parentCommentId,
    this.isEdited = false,
    this.rating,
    this.mentionedUsers,
  });

  /// Create an ArtWalkCommentModel from Firestore document
  factory ArtWalkCommentModel.fromFirestore(DocumentSnapshot doc,
      {String? artWalkId}) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle server timestamps that might be null for new comments
    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else {
      createdAt = DateTime.now(); // Fallback for new comments
    }

    return ArtWalkCommentModel(
      id: doc.id,
      artWalkId: artWalkId ?? data['artWalkId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      content: data['content'] ?? '',
      createdAt: createdAt,
      likeCount: data['likeCount'] ?? 0,
      parentCommentId: data['parentCommentId'],
      isEdited: data['isEdited'] ?? false,
      rating: data['rating']?.toDouble(),
      mentionedUsers: data['mentionedUsers'] != null
          ? List<String>.from(data['mentionedUsers'])
          : null,
    );
  }

  /// Convert to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'artWalkId': artWalkId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': likeCount,
      'parentCommentId': parentCommentId,
      'isEdited': isEdited,
      'rating': rating,
      'mentionedUsers': mentionedUsers,
    };
  }

  /// Create a copy of this comment with modified fields
  ArtWalkCommentModel copyWith({
    String? id,
    String? artWalkId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? content,
    DateTime? createdAt,
    int? likeCount,
    String? parentCommentId,
    bool? isEdited,
    double? rating,
    List<String>? mentionedUsers,
    bool clearMentionedUsers = false,
  }) {
    return ArtWalkCommentModel(
      id: id ?? this.id,
      artWalkId: artWalkId ?? this.artWalkId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      isEdited: isEdited ?? this.isEdited,
      rating: rating ?? this.rating,
      mentionedUsers:
          clearMentionedUsers ? null : (mentionedUsers ?? this.mentionedUsers),
    );
  }
}
