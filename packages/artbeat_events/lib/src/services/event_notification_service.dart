import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:logger/logger.dart';
import '../models/artbeat_event.dart';

/// Service for handling event notifications and reminders
class EventNotificationService {
  static const String _channelId = 'event_reminders';
  static const String _channelName = 'Event Reminders';
  static const String _channelDescription = 'Notifications for upcoming events';

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();

  static final EventNotificationService _instance = EventNotificationService._internal();
  factory EventNotificationService() => _instance;
  EventNotificationService._internal();

  /// Initialize notification services
  Future<void> initialize() async {
    try {
      await _initializeLocalNotifications();
      await _initializeAwesomeNotifications();
      _logger.i('Notification service initialized');
    } catch (e) {
      _logger.e('Error initializing notification service: $e');
    }
  }

  /// Initialize flutter_local_notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Initialize awesome_notifications
  Future<void> _initializeAwesomeNotifications() async {
    await AwesomeNotifications().initialize(
      null, // Use default app icon
      [
        NotificationChannel(
          channelKey: _channelId,
          channelName: _channelName,
          channelDescription: _channelDescription,
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
    );
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      // Request permissions for awesome_notifications
      final awesomePermission = await AwesomeNotifications()
          .isNotificationAllowed();
      
      if (!awesomePermission) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }

      // Request permissions for local_notifications on iOS
      final localPermission = await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      _logger.i('Notification permissions requested');
      return awesomePermission && (localPermission ?? true);
    } catch (e) {
      _logger.e('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Schedule event reminder notification
  Future<void> scheduleEventReminder(ArtbeatEvent event) async {
    if (!event.reminderEnabled) return;

    try {
      // Schedule 1 hour before event
      final reminderTime = event.dateTime.subtract(const Duration(hours: 1));
      
      // Don't schedule if the reminder time is in the past
      if (reminderTime.isBefore(DateTime.now())) {
        _logger.w('Event reminder time is in the past: ${event.title}');
        return;
      }

      // Schedule with awesome_notifications for better cross-platform support
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: event.id.hashCode,
          channelKey: _channelId,
          title: 'Event Reminder: ${event.title}',
          body: 'Your event starts in 1 hour at ${event.location}',
          bigPicture: event.eventBannerUrl.isNotEmpty ? event.eventBannerUrl : null,
          notificationLayout: event.eventBannerUrl.isNotEmpty 
              ? NotificationLayout.BigPicture 
              : NotificationLayout.Default,
          payload: {
            'eventId': event.id,
            'type': 'event_reminder',
          },
        ),
        schedule: NotificationCalendar.fromDate(date: reminderTime),
      );

      _logger.i('Event reminder scheduled for: ${event.title}');
    } catch (e) {
      _logger.e('Error scheduling event reminder: $e');
    }
  }

  /// Schedule multiple reminders for an event
  Future<void> scheduleEventReminders(ArtbeatEvent event) async {
    if (!event.reminderEnabled) return;

    try {
      final eventTime = event.dateTime;
      final now = DateTime.now();

      // Schedule 24 hours before (if applicable)
      final dayBeforeTime = eventTime.subtract(const Duration(days: 1));
      if (dayBeforeTime.isAfter(now)) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: '${event.id}_day'.hashCode,
            channelKey: _channelId,
            title: 'Tomorrow: ${event.title}',
            body: 'Don\'t forget about your event tomorrow at ${event.location}',
            payload: {
              'eventId': event.id,
              'type': 'event_reminder_day',
            },
          ),
          schedule: NotificationCalendar.fromDate(date: dayBeforeTime),
        );
      }

      // Schedule 1 hour before
      final hourBeforeTime = eventTime.subtract(const Duration(hours: 1));
      if (hourBeforeTime.isAfter(now)) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: '${event.id}_hour'.hashCode,
            channelKey: _channelId,
            title: 'Event Starting Soon: ${event.title}',
            body: 'Your event starts in 1 hour at ${event.location}',
            bigPicture: event.eventBannerUrl.isNotEmpty ? event.eventBannerUrl : null,
            payload: {
              'eventId': event.id,
              'type': 'event_reminder_hour',
            },
          ),
          schedule: NotificationCalendar.fromDate(date: hourBeforeTime),
        );
      }

      _logger.i('Multiple event reminders scheduled for: ${event.title}');
    } catch (e) {
      _logger.e('Error scheduling event reminders: $e');
    }
  }

  /// Cancel event reminders
  Future<void> cancelEventReminders(String eventId) async {
    try {
      // Cancel awesome_notifications
      await AwesomeNotifications().cancel(eventId.hashCode);
      await AwesomeNotifications().cancel('${eventId}_day'.hashCode);
      await AwesomeNotifications().cancel('${eventId}_hour'.hashCode);

      // Cancel local notifications
      await _localNotifications.cancel(eventId.hashCode);

      _logger.i('Event reminders cancelled for: $eventId');
    } catch (e) {
      _logger.e('Error cancelling event reminders: $e');
    }
  }

  /// Send immediate notification for ticket purchase confirmation
  Future<void> sendTicketPurchaseConfirmation({
    required String eventTitle,
    required int quantity,
    required String ticketType,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch,
          channelKey: _channelId,
          title: 'Tickets Purchased!',
          body: 'You\'ve successfully purchased $quantity $ticketType ticket${quantity > 1 ? 's' : ''} for $eventTitle',
          notificationLayout: NotificationLayout.Default,
          payload: {
            'type': 'ticket_purchase_confirmation',
          },
        ),
      );

      _logger.i('Ticket purchase confirmation sent');
    } catch (e) {
      _logger.e('Error sending ticket purchase confirmation: $e');
    }
  }

  /// Send refund confirmation notification
  Future<void> sendRefundConfirmation({
    required String eventTitle,
    required double refundAmount,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch,
          channelKey: _channelId,
          title: 'Refund Processed',
          body: 'Your refund of \$${refundAmount.toStringAsFixed(2)} for $eventTitle has been processed',
          notificationLayout: NotificationLayout.Default,
          payload: {
            'type': 'refund_confirmation',
          },
        ),
      );

      _logger.i('Refund confirmation sent');
    } catch (e) {
      _logger.e('Error sending refund confirmation: $e');
    }
  }

  /// Send event update notification
  Future<void> sendEventUpdateNotification({
    required String eventTitle,
    required String updateMessage,
    required String eventId,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch,
          channelKey: _channelId,
          title: 'Event Update: $eventTitle',
          body: updateMessage,
          notificationLayout: NotificationLayout.Default,
          payload: {
            'eventId': eventId,
            'type': 'event_update',
          },
        ),
      );

      _logger.i('Event update notification sent');
    } catch (e) {
      _logger.e('Error sending event update notification: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      _logger.i('Notification tapped with payload: $payload');
      
      // TODO: Navigate to appropriate screen based on payload
      // This would typically involve using a navigation service
      // or app-level navigation handler
    }
  }

  /// Set up listener for awesome_notifications
  void setupNotificationListener() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceived,
      onNotificationCreatedMethod: _onNotificationCreated,
      onNotificationDisplayedMethod: _onNotificationDisplayed,
      onDismissActionReceivedMethod: _onDismissActionReceived,
    );
  }

  /// Handle notification action received
  static Future<void> _onActionReceived(ReceivedAction receivedAction) async {
    final payload = receivedAction.payload;
    if (payload != null) {
      final logger = Logger();
      logger.i('Notification action received with payload: $payload');
      
      // TODO: Handle navigation based on payload
    }
  }

  /// Handle notification created
  static Future<void> _onNotificationCreated(ReceivedNotification receivedNotification) async {
    // Optional: Handle when notification is created
  }

  /// Handle notification displayed
  static Future<void> _onNotificationDisplayed(ReceivedNotification receivedNotification) async {
    // Optional: Handle when notification is displayed
  }

  /// Handle notification dismissed
  static Future<void> _onDismissActionReceived(ReceivedAction receivedAction) async {
    // Optional: Handle when notification is dismissed
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  /// Get scheduled notifications
  Future<List<NotificationModel>> getScheduledNotifications() async {
    return await AwesomeNotifications().listScheduledNotifications();
  }
}