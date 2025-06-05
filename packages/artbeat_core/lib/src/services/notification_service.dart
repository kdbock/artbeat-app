import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Enum representing different types of notifications
enum NotificationType {
  like,
  comment,
  follow,
  message,
  mention,
  artworkPurchase,
  subscription,
  subscriptionExpiration,
  galleryInvitation,
  invitationResponse,
  invitationCancelled,
}

/// Service for managing user notifications
class NotificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user's notifications
  Future<List<Map<String, dynamic>>> getUserNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting user notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Send notification to a user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      // Create a notification document
      final notification = {
        'userId': userId,
        'title': title,
        'message': message,
        'type': type.toString().split('.').last,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': data,
      };

      // Add notification to user's notifications collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification);

      // Here you would implement push notification sending using Firebase Cloud Messaging
      // This is a simplified version without the actual FCM integration
      debugPrint('Notification sent to user $userId: $title');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}
