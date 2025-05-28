import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:artbeat/models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling user notifications
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  // For local notifications
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<NotificationModel> _selectedNotificationSubject =
      BehaviorSubject<NotificationModel>();

  // Collection references
  final CollectionReference _notificationsCollection =
      FirebaseFirestore.instance.collection('notifications');

  /// Stream of selected notifications
  Stream<NotificationModel> get notificationSelected =>
      _selectedNotificationSubject.stream;

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
  String _typeToString(NotificationType type) {
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

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Initialize notification service
  Future<void> init() async {
    // Initialize local notifications
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Request permissions for iOS
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // iOS foreground notification handling is now managed by the plugin automatically

  /// Handle notification tap
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      try {
        // Parse the notification model from the payload
        final data = Map<String, dynamic>.from(
            (response.payload ?? '') as Map<String, dynamic>);

        final NotificationModel notification = NotificationModel(
          id: data['id'] as String,
          userId: data['userId'] as String,
          type: NotificationService._typeFromString(data['type'] as String),
          content: data['content'] as String,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          isRead: data['isRead'] as bool,
        );

        _selectedNotificationSubject.add(notification);
      } catch (e) {
        _logger.e('Error parsing notification payload: $e');
      }
    }
  }

  /// Get notifications for the current user
  Stream<List<NotificationModel>> getUserNotifications({int limit = 50}) {
    final userId = getCurrentUserId();
    if (userId == null) {
      return Stream.value([]);
    }

    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get unread notification count
  Stream<int> getUnreadNotificationCount() {
    final userId = getCurrentUserId();
    if (userId == null) {
      return Stream.value(0);
    }

    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Verify ownership of notification before updating
    final notificationDoc =
        await _notificationsCollection.doc(notificationId).get();

    if (!notificationDoc.exists) {
      throw Exception('Notification not found');
    }

    final notificationData = notificationDoc.data() as Map<String, dynamic>;
    if (notificationData['userId'] != userId) {
      throw Exception('Not authorized to update this notification');
    }

    await _notificationsCollection.doc(notificationId).update({'isRead': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final batch = _firestore.batch();
    final snapshot = await _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Verify ownership of notification before deleting
    final notificationDoc =
        await _notificationsCollection.doc(notificationId).get();

    if (!notificationDoc.exists) {
      throw Exception('Notification not found');
    }

    final notificationData = notificationDoc.data() as Map<String, dynamic>;
    if (notificationData['userId'] != userId) {
      throw Exception('Not authorized to delete this notification');
    }

    await _notificationsCollection.doc(notificationId).delete();
  }

  /// Clear all notifications for user
  Future<void> clearAllNotifications() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final batch = _firestore.batch();
    final snapshot =
        await _notificationsCollection.where('userId', isEqualTo: userId).get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Create a notification for subscription-related events
  Future<void> createSubscriptionNotification({
    required String userId,
    required NotificationType type,
    required String content,
    String? subscriptionId,
    String? paymentId,
    Map<String, dynamic>? additionalData,
  }) async {
    final notificationData = {
      'userId': userId,
      'type': _typeToString(type),
      'sourceUserId': null, // System notification
      'sourceUserName': null,
      'sourceUserPhoto': null,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      if (subscriptionId != null) 'subscriptionId': subscriptionId,
      if (paymentId != null) 'paymentId': paymentId,
      if (additionalData != null) 'additionalData': additionalData,
    };

    await _notificationsCollection.add(notificationData);

    // Send a local notification if user preferences allow it
    final shouldSendLocalNotification =
        await _shouldSendLocalNotification(type);
    if (shouldSendLocalNotification) {
      _showLocalNotification(
        title: _getNotificationTitle(type),
        body: content,
        payload: notificationData,
      );
    }
  }

  /// Send a notification to a user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Convert the string type to a NotificationType
      final notificationType = _typeFromString(type);

      // Create the notification using the existing createSubscriptionNotification method
      await createSubscriptionNotification(
        userId: userId,
        type: notificationType,
        content: body,
        additionalData: {
          'title': title,
          ...?data,
        },
      );
    } catch (e) {
      _logger.e('Error sending notification: $e');
    }
  }

  /// Show a local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'subscription_channel',
      'Subscription Notifications',
      channelDescription: 'Notifications for subscription events',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload.toString(),
    );
  }

  /// Get appropriate title for notification based on type
  String _getNotificationTitle(NotificationType type) {
    switch (type) {
      case NotificationType.subscriptionRenewal:
        return 'Subscription Renewed';
      case NotificationType.paymentSuccess:
        return 'Payment Successful';
      case NotificationType.paymentFailed:
        return 'Payment Failed';
      case NotificationType.tierUpgrade:
        return 'Subscription Upgraded';
      case NotificationType.tierDowngrade:
        return 'Subscription Downgraded';
      case NotificationType.subscriptionCancelled:
        return 'Subscription Cancelled';
      case NotificationType.artworkLimitReached:
        return 'Artwork Limit Reached';
      case NotificationType.eventReminder:
        return 'Event Reminder';
      case NotificationType.galleryInvite:
        return 'Gallery Invitation';
      default:
        return 'WordNerd Notification';
    }
  }

  /// Check if local notification should be shown based on user preferences
  Future<bool> _shouldSendLocalNotification(NotificationType type) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = getCurrentUserId();
    if (userId == null) return false;

    // Default to true if preference doesn't exist
    bool notificationsEnabled =
        prefs.getBool('$userId:notificationsEnabled') ?? true;
    if (!notificationsEnabled) return false;

    // Check specific notification types
    switch (type) {
      case NotificationType.subscriptionRenewal:
        return prefs.getBool('$userId:notifyOnSubscriptionRenewal') ?? true;
      case NotificationType.paymentSuccess:
      case NotificationType.paymentFailed:
        return prefs.getBool('$userId:notifyOnPaymentEvents') ?? true;
      case NotificationType.tierUpgrade:
      case NotificationType.tierDowngrade:
        return prefs.getBool('$userId:notifyOnSubscriptionChanges') ?? true;
      case NotificationType.subscriptionCancelled:
        return prefs.getBool('$userId:notifyOnSubscriptionCancelled') ?? true;
      case NotificationType.artworkLimitReached:
        return prefs.getBool('$userId:notifyOnArtworkLimitReached') ?? true;
      case NotificationType.eventReminder:
        return prefs.getBool('$userId:notifyOnEventReminder') ?? true;
      case NotificationType.galleryInvite:
        return prefs.getBool('$userId:notifyOnGalleryInvite') ?? true;
      default:
        return true;
    }
  }

  /// Save user notification preferences to SharedPreferences
  Future<void> saveNotificationPreferences({
    required bool notificationsEnabled,
    required bool notifyOnSubscriptionRenewal,
    required bool notifyOnPaymentEvents,
    required bool notifyOnSubscriptionChanges,
    required bool notifyOnSubscriptionCancelled,
    required bool notifyOnArtworkLimitReached,
    required bool notifyOnEventReminder,
    required bool notifyOnGalleryInvite,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$userId:notificationsEnabled', notificationsEnabled);
    await prefs.setBool(
        '$userId:notifyOnSubscriptionRenewal', notifyOnSubscriptionRenewal);
    await prefs.setBool('$userId:notifyOnPaymentEvents', notifyOnPaymentEvents);
    await prefs.setBool(
        '$userId:notifyOnSubscriptionChanges', notifyOnSubscriptionChanges);
    await prefs.setBool(
        '$userId:notifyOnSubscriptionCancelled', notifyOnSubscriptionCancelled);
    await prefs.setBool(
        '$userId:notifyOnArtworkLimitReached', notifyOnArtworkLimitReached);
    await prefs.setBool('$userId:notifyOnEventReminder', notifyOnEventReminder);
    await prefs.setBool('$userId:notifyOnGalleryInvite', notifyOnGalleryInvite);

    // Also save to Firestore for server-side use
    await _firestore.collection('users').doc(userId).set({
      'notificationPreferences': {
        'notificationsEnabled': notificationsEnabled,
        'notifyOnSubscriptionRenewal': notifyOnSubscriptionRenewal,
        'notifyOnPaymentEvents': notifyOnPaymentEvents,
        'notifyOnSubscriptionChanges': notifyOnSubscriptionChanges,
        'notifyOnSubscriptionCancelled': notifyOnSubscriptionCancelled,
        'notifyOnArtworkLimitReached': notifyOnArtworkLimitReached,
        'notifyOnEventReminder': notifyOnEventReminder,
        'notifyOnGalleryInvite': notifyOnGalleryInvite,
      }
    }, SetOptions(merge: true));
  }

  /// Load user notification preferences from SharedPreferences
  Future<Map<String, bool>> loadNotificationPreferences() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final prefs = await SharedPreferences.getInstance();

    // Try to get from Firestore first
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData != null && userData.containsKey('notificationPreferences')) {
        final notificationPrefs =
            userData['notificationPreferences'] as Map<String, dynamic>;

        // Update local SharedPreferences with Firestore data
        for (final entry in notificationPrefs.entries) {
          if (entry.value is bool) {
            await prefs.setBool('$userId:${entry.key}', entry.value as bool);
          }
        }

        return Map<String, bool>.from(notificationPrefs);
      }
    } catch (e) {
      _logger.e('Error loading notification preferences from Firestore: $e');
      // Continue with SharedPreferences as fallback
    }

    // Get from SharedPreferences
    return {
      'notificationsEnabled':
          prefs.getBool('$userId:notificationsEnabled') ?? true,
      'notifyOnSubscriptionRenewal':
          prefs.getBool('$userId:notifyOnSubscriptionRenewal') ?? true,
      'notifyOnPaymentEvents':
          prefs.getBool('$userId:notifyOnPaymentEvents') ?? true,
      'notifyOnSubscriptionChanges':
          prefs.getBool('$userId:notifyOnSubscriptionChanges') ?? true,
      'notifyOnSubscriptionCancelled':
          prefs.getBool('$userId:notifyOnSubscriptionCancelled') ?? true,
      'notifyOnArtworkLimitReached':
          prefs.getBool('$userId:notifyOnArtworkLimitReached') ?? true,
      'notifyOnEventReminder':
          prefs.getBool('$userId:notifyOnEventReminder') ?? true,
      'notifyOnGalleryInvite':
          prefs.getBool('$userId:notifyOnGalleryInvite') ?? true,
    };
  }
}
