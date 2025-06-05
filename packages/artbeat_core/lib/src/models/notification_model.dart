import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of notification
enum NotificationModelType {
  like,
  comment,
  follow,
  message,
  mention,
  artworkPurchase,
  subscription,
  galleryInvitation,
  systemNotification,
}

/// Model class for notifications
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationModelType type;
  final DateTime createdAt;
  final bool read;
  final Map<String, dynamic> data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.read = false,
    this.data = const {},
  });

  /// Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      message: data['message'] as String,
      type: _parseNotificationType(data['type'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      read: data['read'] as bool? ?? false,
      data: data['data'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'createdAt': createdAt,
      'read': read,
      'data': data,
    };
  }

  /// Parse notification type from string
  static NotificationModelType _parseNotificationType(String typeStr) {
    try {
      return NotificationModelType.values.firstWhere(
        (type) => type.name == typeStr,
        orElse: () => NotificationModelType.systemNotification,
      );
    } catch (_) {
      return NotificationModelType.systemNotification;
    }
  }
}
