import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for profile activity tracking
class ProfileActivityModel {
  final String id;
  final String userId;
  final String
  activityType; // 'profile_view', 'follow', 'unfollow', 'like', 'comment'
  final String? targetUserId; // User who performed the activity
  final String? targetUserName;
  final String? targetUserAvatar;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final bool isRead;

  ProfileActivityModel({
    required this.id,
    required this.userId,
    required this.activityType,
    this.targetUserId,
    this.targetUserName,
    this.targetUserAvatar,
    this.description,
    this.metadata,
    required this.createdAt,
    this.isRead = false,
  });

  factory ProfileActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileActivityModel(
      id: doc.id,
      userId: data['userId'] as String,
      activityType: data['activityType'] as String,
      targetUserId: data['targetUserId'] as String?,
      targetUserName: data['targetUserName'] as String?,
      targetUserAvatar: data['targetUserAvatar'] as String?,
      description: data['description'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: (data['isRead'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'activityType': activityType,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'targetUserAvatar': targetUserAvatar,
      'description': description,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  ProfileActivityModel copyWith({
    String? targetUserName,
    String? targetUserAvatar,
    String? description,
    Map<String, dynamic>? metadata,
    bool? isRead,
  }) {
    return ProfileActivityModel(
      id: id,
      userId: userId,
      activityType: activityType,
      targetUserId: targetUserId,
      targetUserName: targetUserName ?? this.targetUserName,
      targetUserAvatar: targetUserAvatar ?? this.targetUserAvatar,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  String get activityDisplayText {
    switch (activityType) {
      case 'profile_view':
        return '${targetUserName ?? 'Someone'} viewed your profile';
      case 'follow':
        return '${targetUserName ?? 'Someone'} started following you';
      case 'unfollow':
        return '${targetUserName ?? 'Someone'} unfollowed you';
      case 'like':
        return '${targetUserName ?? 'Someone'} liked your post';
      case 'comment':
        return '${targetUserName ?? 'Someone'} commented on your post';
      default:
        return description ?? 'New activity';
    }
  }
}
