import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for comments on captures, artwork, and other content
class CommentModel {
  final String id;
  final String
  contentId; // The ID of the content being commented on (capture, artwork, etc.)
  final String contentType; // 'capture', 'artwork', 'post', etc.
  final String userId;
  final String userName;
  final String? userAvatar;
  final String text;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final List<String> likedBy; // User IDs who liked this comment

  CommentModel({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.text,
    required this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
    this.likedBy = const [],
  });

  /// Convert from Firestore document to CommentModel
  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      contentId: data['contentId'] as String? ?? '',
      contentType: data['contentType'] as String? ?? 'capture',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Anonymous',
      userAvatar: data['userAvatar'] as String?,
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      likeCount: data['likeCount'] as int? ?? 0,
      likedBy: List<String>.from(data['likedBy'] as List? ?? []),
    );
  }

  /// Convert from JSON (for offline support and local serialization)
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String? ?? '',
      contentId: json['contentId'] as String? ?? '',
      contentType: json['contentType'] as String? ?? 'capture',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Anonymous',
      userAvatar: json['userAvatar'] as String?,
      text: json['text'] as String? ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String? ?? '')
          : null,
      likeCount: json['likeCount'] as int? ?? 0,
      likedBy: List<String>.from(json['likedBy'] as List? ?? []),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'contentId': contentId,
      'contentType': contentType,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'likeCount': likeCount,
      'likedBy': likedBy,
    };
  }

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contentId': contentId,
      'contentType': contentType,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'likeCount': likeCount,
      'likedBy': likedBy,
    };
  }

  /// Create a copy with optional modifications
  CommentModel copyWith({
    String? id,
    String? contentId,
    String? contentType,
    String? userId,
    String? userName,
    String? userAvatar,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likeCount,
    List<String>? likedBy,
  }) {
    return CommentModel(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  @override
  String toString() {
    return 'CommentModel(id: $id, contentId: $contentId, userId: $userId, '
        'userName: $userName, text: $text, likeCount: $likeCount)';
  }
}
