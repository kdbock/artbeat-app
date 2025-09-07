import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service for handling chat and message notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  FirebaseMessaging? _messaging;
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  FirebaseMessaging get messaging => _messaging ??= FirebaseMessaging.instance;
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;
  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _messaging = messaging,
       _firestore = firestore,
       _auth = auth;

  static const String _deviceTokensField = 'deviceTokens';
  static const String _usersCollection = 'users';
  static const String _notificationsCollection = 'notifications';

  /// Initialize notification settings and request permissions
  Future<void> initialize() async {
    try {
      // Initialize local notifications
      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInit =
          DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _localNotifications.initialize(initSettings);
      // Request permission for notifications
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        final token = await messaging.getToken();
        if (token != null) {
          await _saveDeviceToken(token);
        }

        // Listen for token refresh
        messaging.onTokenRefresh.listen(_saveDeviceToken);

        // Configure FCM handlers
        if (!kDebugMode) {
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
          FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
          FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler,
          );
        }

        // Start listening for new notifications to send push notifications
        _startNotificationListener();
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
      final userId = auth.currentUser?.uid;
      if (userId == null) return;

      final userRef = firestore.collection(_usersCollection).doc(userId);

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
      final userId = auth.currentUser?.uid;
      if (userId == null) return;

      await firestore
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
      final token = await messaging.getToken();
      final userId = auth.currentUser?.uid;
      if (token == null || userId == null) return;

      final userRef = firestore.collection(_usersCollection).doc(userId);
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
      final userId = auth.currentUser?.uid;
      if (userId == null) return;

      await firestore
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
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }

    return firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_notificationsCollection)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get count of unread notifications
  Stream<int> getUnreadNotificationsCount() {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_notificationsCollection)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Send a notification to a specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_notificationsCollection)
          .add({
            'title': title,
            'body': body,
            'data': data,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': data['type'] ?? 'message',
          });

      debugPrint('📱 Notification sent to user $userId: $title');
    } catch (e) {
      debugPrint('❌ Error sending notification to user $userId: $e');
      rethrow;
    }
  }

  /// Start listening for new notifications in Firestore to trigger push notifications
  void _startNotificationListener() {
    final userId = auth.currentUser?.uid;
    if (userId == null) return;

    try {
      firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_notificationsCollection)
          .where('isRead', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
            for (final doc in snapshot.docChanges) {
              if (doc.type == DocumentChangeType.added) {
                final data = doc.doc.data() as Map<String, dynamic>;
                _triggerLocalNotification(data);
              }
            }
          });
    } catch (e) {
      debugPrint('❌ Error starting notification listener: $e');
    }
  }

  /// Trigger a local notification for new messages
  void _triggerLocalNotification(Map<String, dynamic> notificationData) {
    try {
      final title = notificationData['title'] as String? ?? 'New Message';
      final body = notificationData['body'] as String? ?? '';
      final type = notificationData['type'] as String? ?? 'message';

      if (type == 'message') {
        debugPrint('📱 New message notification: $title - $body');
        _localNotifications.show(
          0,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'chat_messages',
              'Chat Messages',
              channelDescription: 'Notifications for new chat messages',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error triggering local notification: $e');
    }
  }

  // Phase 3: Enhanced Notification Features

  /// Schedule a notification for later delivery
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    int? id,
    String? payload,
  }) async {
    try {
      await _localNotifications.zonedSchedule(
        id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        _convertToTZDateTime(scheduledDate),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'scheduled_messages',
            'Scheduled Messages',
            channelDescription: 'Notifications for scheduled messages',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      rethrow;
    }
  }

  /// Configure notification preferences for a specific chat
  Future<void> configureChatNotifications({
    required String chatId,
    bool enableNotifications = true,
    bool enableSound = true,
    bool enableVibration = true,
    String? customSound,
  }) async {
    try {
      final userId = auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await firestore
          .collection('users')
          .doc(userId)
          .collection('chatNotificationSettings')
          .doc(chatId)
          .set({
            'enableNotifications': enableNotifications,
            'enableSound': enableSound,
            'enableVibration': enableVibration,
            'customSound': customSound,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error configuring chat notifications: $e');
      rethrow;
    }
  }

  /// Get notification preferences for a specific chat
  Future<Map<String, dynamic>?> getChatNotificationSettings(
    String chatId,
  ) async {
    try {
      final userId = auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('chatNotificationSettings')
          .doc(chatId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Error getting chat notification settings: $e');
      return null;
    }
  }

  /// Handle background messages with enhanced processing
  Future<void> handleBackgroundMessages() async {
    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle messages when app is terminated
      final RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        await _handleMessageClick(initialMessage);
      }

      // Handle messages when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);
    } catch (e) {
      debugPrint('Error setting up background message handling: $e');
    }
  }

  /// Handle message click actions
  Future<void> _handleMessageClick(RemoteMessage message) async {
    try {
      final data = message.data;
      final chatId = data['chatId'];
      final messageId = data['messageId'];

      if (chatId != null) {
        // Navigate to specific chat
        // This would typically be handled by the app's navigation system
        debugPrint('Navigate to chat: $chatId');

        if (messageId != null) {
          // Navigate to specific message
          debugPrint('Navigate to message: $messageId in chat: $chatId');
        }
      }
    } catch (e) {
      debugPrint('Error handling message click: $e');
    }
  }

  /// Set up notification categories and actions
  Future<void> setupNotificationCategories() async {
    try {
      // Define notification actions for iOS
      final DarwinNotificationCategory messageCategory =
          DarwinNotificationCategory(
            'MESSAGE_CATEGORY',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain(
                'reply',
                'Reply',
                options: <DarwinNotificationActionOption>{
                  DarwinNotificationActionOption.foreground,
                },
              ),
              DarwinNotificationAction.plain('mark_read', 'Mark as Read'),
            ],
            options: <DarwinNotificationCategoryOption>{
              DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
            },
          );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.initialize(
            DarwinInitializationSettings(
              notificationCategories: [messageCategory],
            ),
            onDidReceiveNotificationResponse: _onNotificationResponse,
          );
    } catch (e) {
      debugPrint('Error setting up notification categories: $e');
    }
  }

  /// Handle notification actions
  void _onNotificationResponse(NotificationResponse response) {
    try {
      final actionId = response.actionId;
      final payload = response.payload;

      switch (actionId) {
        case 'reply':
          debugPrint('Reply action triggered with payload: $payload');
          break;
        case 'mark_read':
          debugPrint('Mark as read action triggered with payload: $payload');
          break;
        default:
          debugPrint('Notification tapped with payload: $payload');
      }
    } catch (e) {
      debugPrint('Error handling notification response: $e');
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllScheduledNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling scheduled notifications: $e');
    }
  }

  /// Cancel a specific scheduled notification
  Future<void> cancelScheduledNotification(int notificationId) async {
    try {
      await _localNotifications.cancel(notificationId);
    } catch (e) {
      debugPrint('Error cancelling scheduled notification: $e');
    }
  }

  /// Helper method to convert DateTime to TZDateTime
  static tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    // This is a simplified implementation
    // In a real app, you'd want to use the timezone package properly
    return tz.TZDateTime.from(dateTime, tz.getLocation('UTC'));
  }
}

/// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  // No-op implementation - actual handling should be minimal as the app is not running
  return;
}
