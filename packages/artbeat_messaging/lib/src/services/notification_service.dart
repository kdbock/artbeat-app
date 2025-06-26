import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Service for handling chat and message notifications
class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  static const String _deviceTokensField = 'deviceTokens';
  static const String _usersCollection = 'users';
  static const String _notificationsCollection = 'notifications';

  /// Initialize notification settings and request permissions
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        final token = await _messaging.getToken();
        if (token != null) {
          await _saveDeviceToken(token);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_saveDeviceToken);

        // Configure FCM handlers
        if (!kDebugMode) {
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
          FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
          FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;

      if (notification != null) {
        await _storeNotification(
          title: notification.title ?? 'New Message',
          body: notification.body ?? '',
          data: data,
        );
      }
    } catch (e) {
      debugPrint('❌ Error handling foreground message: $e');
    }
  }

  /// Handle when user taps on notification to open app
  void _handleMessageOpenedApp(RemoteMessage message) async {
    try {
      final data = message.data;
      if (data['chatId'] != null) {
        // Navigate to chat using provided callback
        // This will be handled by the app's navigation system
      }
    } catch (e) {
      debugPrint('❌ Error handling opened notification: $e');
    }
  }

  /// Save FCM device token to user's document
  Future<void> _saveDeviceToken(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final userRef = _firestore.collection(_usersCollection).doc(userId);

      // Add token to array if it doesn't exist
      await userRef.set({
        _deviceTokensField: FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Error saving device token: $e');
    }
  }

  /// Store notification in Firestore for history
  Future<void> _storeNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_notificationsCollection)
          .add({
            'title': title,
            'body': body,
            'data': data,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
    } catch (e) {
      debugPrint('❌ Error storing notification: $e');
    }
  }

  /// Remove device token when user logs out
  Future<void> removeDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      final userId = _auth.currentUser?.uid;
      if (token == null || userId == null) return;

      final userRef = _firestore.collection(_usersCollection).doc(userId);
      await userRef.update({
        _deviceTokensField: FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      debugPrint('❌ Error removing device token: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// Get user's notification history
  Stream<QuerySnapshot> getNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_notificationsCollection)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get count of unread notifications
  Stream<int> getUnreadNotificationsCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_notificationsCollection)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

/// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  // No-op implementation - actual handling should be minimal as the app is not running
  return;
}
