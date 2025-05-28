import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of notification
enum NotificationType {
  like,
  comment,
  follow,
  mention,
  message,
  subscriptionRenewal,
  paymentSuccess,
  paymentFailed,
  tierUpgrade,
  tierDowngrade,
  subscriptionCancelled,
  artworkLimitReached,
  eventReminder,
  galleryInvite,
}

/// Model class for notifications
class NotificationModel {
  final String id;
  final String userId; // User who receives the notification
  final NotificationType type;
  final String?
      sourceUserId; // User who triggered the notification (null for system notifications)
  final String? sourceUserName;
  final String? sourceUserPhoto;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  // IDs for related entities
  final String? postId;
  final String? commentId;
  final String? subscriptionId;
  final String? paymentId;
  final String? eventId;
  final String? artworkId;

  // Additional data that might be specific to certain notification types
  final Map<String, dynamic>? additionalData;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    this.sourceUserId,
    this.sourceUserName,
    this.sourceUserPhoto,
    required this.content,
    required this.createdAt,
    required this.isRead,
    this.postId,
    this.commentId,
    this.subscriptionId,
    this.paymentId,
    this.eventId,
    this.artworkId,
    this.additionalData,
  });

  /// Convert Firestore document to NotificationModel
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] as String,
      type: _typeFromString(data['type'] as String),
      sourceUserId: data['sourceUserId'] as String?,
      sourceUserName: data['sourceUserName'] as String?,
      sourceUserPhoto: data['sourceUserPhoto'] as String?,
      content: data['content'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] as bool,
      postId: data['postId'] as String?,
      commentId: data['commentId'] as String?,
      subscriptionId: data['subscriptionId'] as String?,
      paymentId: data['paymentId'] as String?,
      eventId: data['eventId'] as String?,
      artworkId: data['artworkId'] as String?,
      additionalData: data['additionalData'] as Map<String, dynamic>?,
    );
  }

  /// Convert NotificationModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': _typeToString(type),
      'sourceUserId': sourceUserId,
      'sourceUserName': sourceUserName,
      'sourceUserPhoto': sourceUserPhoto,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      if (postId != null) 'postId': postId,
      if (commentId != null) 'commentId': commentId,
      if (subscriptionId != null) 'subscriptionId': subscriptionId,
      if (paymentId != null) 'paymentId': paymentId,
      if (eventId != null) 'eventId': eventId,
      if (artworkId != null) 'artworkId': artworkId,
      if (additionalData != null) 'additionalData': additionalData,
    };
  }

  /// Helper to convert string type to enum
  static NotificationType _typeFromString(String type) {
    switch (type) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'mention':
        return NotificationType.mention;
      case 'message':
        return NotificationType.message;
      case 'subscriptionRenewal':
        return NotificationType.subscriptionRenewal;
      case 'paymentSuccess':
        return NotificationType.paymentSuccess;
      case 'paymentFailed':
        return NotificationType.paymentFailed;
      case 'tierUpgrade':
        return NotificationType.tierUpgrade;
      case 'tierDowngrade':
        return NotificationType.tierDowngrade;
      case 'subscriptionCancelled':
        return NotificationType.subscriptionCancelled;
      case 'artworkLimitReached':
        return NotificationType.artworkLimitReached;
      case 'eventReminder':
        return NotificationType.eventReminder;
      case 'galleryInvite':
        return NotificationType.galleryInvite;
      default:
        return NotificationType.message;
    }
  }

  /// Helper to convert enum type to string
  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return 'like';
      case NotificationType.comment:
        return 'comment';
      case NotificationType.follow:
        return 'follow';
      case NotificationType.mention:
        return 'mention';
      case NotificationType.message:
        return 'message';
      case NotificationType.subscriptionRenewal:
        return 'subscriptionRenewal';
      case NotificationType.paymentSuccess:
        return 'paymentSuccess';
      case NotificationType.paymentFailed:
        return 'paymentFailed';
      case NotificationType.tierUpgrade:
        return 'tierUpgrade';
      case NotificationType.tierDowngrade:
        return 'tierDowngrade';
      case NotificationType.subscriptionCancelled:
        return 'subscriptionCancelled';
      case NotificationType.artworkLimitReached:
        return 'artworkLimitReached';
      case NotificationType.eventReminder:
        return 'eventReminder';
      case NotificationType.galleryInvite:
        return 'galleryInvite';
    }
  }

  /// Create a copy of the notification model with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? sourceUserId,
    String? sourceUserName,
    String? sourceUserPhoto,
    String? content,
    DateTime? createdAt,
    bool? isRead,
    String? postId,
    String? commentId,
    String? subscriptionId,
    String? paymentId,
    String? eventId,
    String? artworkId,
    Map<String, dynamic>? additionalData,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      sourceUserId: sourceUserId ?? this.sourceUserId,
      sourceUserName: sourceUserName ?? this.sourceUserName,
      sourceUserPhoto: sourceUserPhoto ?? this.sourceUserPhoto,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      paymentId: paymentId ?? this.paymentId,
      eventId: eventId ?? this.eventId,
      artworkId: artworkId ?? this.artworkId,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
