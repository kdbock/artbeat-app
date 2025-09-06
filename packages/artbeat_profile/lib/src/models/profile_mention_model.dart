import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking where a user has been mentioned
class ProfileMentionModel {
  final String id;
  final String userId; // User who was mentioned
  final String mentionedByUserId;
  final String mentionedByUserName;
  final String? mentionedByUserAvatar;
  final String mentionType; // 'post', 'comment', 'caption', 'bio'
  final String contextId; // ID of the post, comment, etc.
  final String? contextTitle;
  final String? contextPreview;
  final String? contextImageUrl;
  final DateTime createdAt;
  final bool isRead;
  final bool isDeleted;

  ProfileMentionModel({
    required this.id,
    required this.userId,
    required this.mentionedByUserId,
    required this.mentionedByUserName,
    this.mentionedByUserAvatar,
    required this.mentionType,
    required this.contextId,
    this.contextTitle,
    this.contextPreview,
    this.contextImageUrl,
    required this.createdAt,
    this.isRead = false,
    this.isDeleted = false,
  });

  factory ProfileMentionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileMentionModel(
      id: doc.id,
      userId: data['userId'] as String,
      mentionedByUserId: data['mentionedByUserId'] as String,
      mentionedByUserName: data['mentionedByUserName'] as String,
      mentionedByUserAvatar: data['mentionedByUserAvatar'] as String?,
      mentionType: data['mentionType'] as String,
      contextId: data['contextId'] as String,
      contextTitle: data['contextTitle'] as String?,
      contextPreview: data['contextPreview'] as String?,
      contextImageUrl: data['contextImageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: (data['isRead'] as bool?) ?? false,
      isDeleted: (data['isDeleted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'mentionedByUserId': mentionedByUserId,
      'mentionedByUserName': mentionedByUserName,
      'mentionedByUserAvatar': mentionedByUserAvatar,
      'mentionType': mentionType,
      'contextId': contextId,
      'contextTitle': contextTitle,
      'contextPreview': contextPreview,
      'contextImageUrl': contextImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'isDeleted': isDeleted,
    };
  }

  ProfileMentionModel copyWith({
    String? mentionedByUserName,
    String? mentionedByUserAvatar,
    String? contextTitle,
    String? contextPreview,
    String? contextImageUrl,
    bool? isRead,
    bool? isDeleted,
  }) {
    return ProfileMentionModel(
      id: id,
      userId: userId,
      mentionedByUserId: mentionedByUserId,
      mentionedByUserName: mentionedByUserName ?? this.mentionedByUserName,
      mentionedByUserAvatar:
          mentionedByUserAvatar ?? this.mentionedByUserAvatar,
      mentionType: mentionType,
      contextId: contextId,
      contextTitle: contextTitle ?? this.contextTitle,
      contextPreview: contextPreview ?? this.contextPreview,
      contextImageUrl: contextImageUrl ?? this.contextImageUrl,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  String get displayText {
    switch (mentionType) {
      case 'post':
        return '$mentionedByUserName mentioned you in a post';
      case 'comment':
        return '$mentionedByUserName mentioned you in a comment';
      case 'caption':
        return '$mentionedByUserName mentioned you in a caption';
      case 'bio':
        return '$mentionedByUserName mentioned you in their bio';
      default:
        return '$mentionedByUserName mentioned you';
    }
  }
}
