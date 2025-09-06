import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing user notification preferences for messaging
class NotificationPreferencesModel {
  final String id;
  final String userId;
  final bool globalNotificationsEnabled;
  final bool messageNotificationsEnabled;
  final bool groupMessageNotificationsEnabled;
  final bool mentionNotificationsEnabled;
  final bool replyNotificationsEnabled;
  final bool reactionNotificationsEnabled;
  final String defaultNotificationSound;
  final bool vibrationEnabled;
  final bool showMessagePreview;
  final bool notifyOnlyWhenOffline;
  final List<String> mutedChats;
  final Map<String, String> chatNotificationSounds;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool quietHoursEnabled;
  final List<String> allowedDuringQuietHours;
  final bool ledNotificationEnabled;
  final String ledColor;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreferencesModel({
    required this.id,
    required this.userId,
    this.globalNotificationsEnabled = true,
    this.messageNotificationsEnabled = true,
    this.groupMessageNotificationsEnabled = true,
    this.mentionNotificationsEnabled = true,
    this.replyNotificationsEnabled = true,
    this.reactionNotificationsEnabled = true,
    this.defaultNotificationSound = 'default',
    this.vibrationEnabled = true,
    this.showMessagePreview = true,
    this.notifyOnlyWhenOffline = false,
    this.mutedChats = const [],
    this.chatNotificationSounds = const {},
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    this.quietHoursEnabled = false,
    this.allowedDuringQuietHours = const [],
    this.ledNotificationEnabled = true,
    this.ledColor = 'blue',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory NotificationPreferencesModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationPreferencesModel(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      globalNotificationsEnabled:
          (data['globalNotificationsEnabled'] as bool?) ?? true,
      messageNotificationsEnabled:
          (data['messageNotificationsEnabled'] as bool?) ?? true,
      groupMessageNotificationsEnabled:
          (data['groupMessageNotificationsEnabled'] as bool?) ?? true,
      mentionNotificationsEnabled:
          (data['mentionNotificationsEnabled'] as bool?) ?? true,
      replyNotificationsEnabled:
          (data['replyNotificationsEnabled'] as bool?) ?? true,
      reactionNotificationsEnabled:
          (data['reactionNotificationsEnabled'] as bool?) ?? true,
      defaultNotificationSound:
          (data['defaultNotificationSound'] as String?) ?? 'default',
      vibrationEnabled: (data['vibrationEnabled'] as bool?) ?? true,
      showMessagePreview: (data['showMessagePreview'] as bool?) ?? true,
      notifyOnlyWhenOffline: (data['notifyOnlyWhenOffline'] as bool?) ?? false,
      mutedChats: List<String>.from(data['mutedChats'] as List? ?? []),
      chatNotificationSounds: Map<String, String>.from(
        data['chatNotificationSounds'] as Map? ?? {},
      ),
      quietHoursStart: (data['quietHoursStart'] as String?) ?? '22:00',
      quietHoursEnd: (data['quietHoursEnd'] as String?) ?? '08:00',
      quietHoursEnabled: (data['quietHoursEnabled'] as bool?) ?? false,
      allowedDuringQuietHours: List<String>.from(
        data['allowedDuringQuietHours'] as List? ?? [],
      ),
      ledNotificationEnabled: (data['ledNotificationEnabled'] as bool?) ?? true,
      ledColor: (data['ledColor'] as String?) ?? 'blue',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create from Map
  factory NotificationPreferencesModel.fromMap(Map<String, dynamic> map) {
    return NotificationPreferencesModel(
      id: (map['id'] as String?) ?? '',
      userId: (map['userId'] as String?) ?? '',
      globalNotificationsEnabled:
          (map['globalNotificationsEnabled'] as bool?) ?? true,
      messageNotificationsEnabled:
          (map['messageNotificationsEnabled'] as bool?) ?? true,
      groupMessageNotificationsEnabled:
          (map['groupMessageNotificationsEnabled'] as bool?) ?? true,
      mentionNotificationsEnabled:
          (map['mentionNotificationsEnabled'] as bool?) ?? true,
      replyNotificationsEnabled:
          (map['replyNotificationsEnabled'] as bool?) ?? true,
      reactionNotificationsEnabled:
          (map['reactionNotificationsEnabled'] as bool?) ?? true,
      defaultNotificationSound:
          (map['defaultNotificationSound'] as String?) ?? 'default',
      vibrationEnabled: (map['vibrationEnabled'] as bool?) ?? true,
      showMessagePreview: (map['showMessagePreview'] as bool?) ?? true,
      notifyOnlyWhenOffline: (map['notifyOnlyWhenOffline'] as bool?) ?? false,
      mutedChats: List<String>.from(map['mutedChats'] as List? ?? []),
      chatNotificationSounds: Map<String, String>.from(
        map['chatNotificationSounds'] as Map? ?? {},
      ),
      quietHoursStart: (map['quietHoursStart'] as String?) ?? '22:00',
      quietHoursEnd: (map['quietHoursEnd'] as String?) ?? '08:00',
      quietHoursEnabled: (map['quietHoursEnabled'] as bool?) ?? false,
      allowedDuringQuietHours: List<String>.from(
        map['allowedDuringQuietHours'] as List? ?? [],
      ),
      ledNotificationEnabled: (map['ledNotificationEnabled'] as bool?) ?? true,
      ledColor: (map['ledColor'] as String?) ?? 'blue',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              (map['createdAt'] as String?) ?? DateTime.now().toIso8601String(),
            ),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(
              (map['updatedAt'] as String?) ?? DateTime.now().toIso8601String(),
            ),
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'globalNotificationsEnabled': globalNotificationsEnabled,
      'messageNotificationsEnabled': messageNotificationsEnabled,
      'groupMessageNotificationsEnabled': groupMessageNotificationsEnabled,
      'mentionNotificationsEnabled': mentionNotificationsEnabled,
      'replyNotificationsEnabled': replyNotificationsEnabled,
      'reactionNotificationsEnabled': reactionNotificationsEnabled,
      'defaultNotificationSound': defaultNotificationSound,
      'vibrationEnabled': vibrationEnabled,
      'showMessagePreview': showMessagePreview,
      'notifyOnlyWhenOffline': notifyOnlyWhenOffline,
      'mutedChats': mutedChats,
      'chatNotificationSounds': chatNotificationSounds,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'quietHoursEnabled': quietHoursEnabled,
      'allowedDuringQuietHours': allowedDuringQuietHours,
      'ledNotificationEnabled': ledNotificationEnabled,
      'ledColor': ledColor,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create default preferences for a user
  factory NotificationPreferencesModel.createDefault({required String userId}) {
    final now = DateTime.now();
    return NotificationPreferencesModel(
      id: userId,
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Check if notifications should be shown for a specific chat
  bool shouldNotifyForChat(String chatId, {bool isGroupChat = false}) {
    if (!globalNotificationsEnabled) return false;
    if (mutedChats.contains(chatId)) return false;

    if (isGroupChat && !groupMessageNotificationsEnabled) return false;
    if (!isGroupChat && !messageNotificationsEnabled) return false;

    if (quietHoursEnabled && _isInQuietHours()) {
      return allowedDuringQuietHours.contains(chatId);
    }

    return true;
  }

  /// Check if currently in quiet hours
  bool _isInQuietHours() {
    final now = TimeOfDay.fromDateTime(DateTime.now());
    final start = TimeOfDay.parse(quietHoursStart);
    final end = TimeOfDay.parse(quietHoursEnd);

    if (start.hour < end.hour) {
      // Same day range (e.g., 22:00 to 23:00)
      return now.hour >= start.hour && now.hour < end.hour;
    } else {
      // Cross-day range (e.g., 22:00 to 08:00)
      return now.hour >= start.hour || now.hour < end.hour;
    }
  }

  /// Mute a chat
  NotificationPreferencesModel muteChat(String chatId) {
    if (mutedChats.contains(chatId)) return this;
    return copyWith(
      mutedChats: [...mutedChats, chatId],
      updatedAt: DateTime.now(),
    );
  }

  /// Unmute a chat
  NotificationPreferencesModel unmuteChat(String chatId) {
    if (!mutedChats.contains(chatId)) return this;
    return copyWith(
      mutedChats: mutedChats.where((id) => id != chatId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Set custom notification sound for a chat
  NotificationPreferencesModel setChatNotificationSound(
    String chatId,
    String sound,
  ) {
    final updatedSounds = Map<String, String>.from(chatNotificationSounds);
    updatedSounds[chatId] = sound;
    return copyWith(
      chatNotificationSounds: updatedSounds,
      updatedAt: DateTime.now(),
    );
  }

  /// Get notification sound for a chat
  String getNotificationSoundForChat(String chatId) {
    return chatNotificationSounds[chatId] ?? defaultNotificationSound;
  }

  /// Update quiet hours settings
  NotificationPreferencesModel updateQuietHours({
    String? start,
    String? end,
    bool? enabled,
    List<String>? allowedChats,
  }) {
    return copyWith(
      quietHoursStart: start,
      quietHoursEnd: end,
      quietHoursEnabled: enabled,
      allowedDuringQuietHours: allowedChats,
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  NotificationPreferencesModel copyWith({
    String? id,
    String? userId,
    bool? globalNotificationsEnabled,
    bool? messageNotificationsEnabled,
    bool? groupMessageNotificationsEnabled,
    bool? mentionNotificationsEnabled,
    bool? replyNotificationsEnabled,
    bool? reactionNotificationsEnabled,
    String? defaultNotificationSound,
    bool? vibrationEnabled,
    bool? showMessagePreview,
    bool? notifyOnlyWhenOffline,
    List<String>? mutedChats,
    Map<String, String>? chatNotificationSounds,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? quietHoursEnabled,
    List<String>? allowedDuringQuietHours,
    bool? ledNotificationEnabled,
    String? ledColor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreferencesModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      globalNotificationsEnabled:
          globalNotificationsEnabled ?? this.globalNotificationsEnabled,
      messageNotificationsEnabled:
          messageNotificationsEnabled ?? this.messageNotificationsEnabled,
      groupMessageNotificationsEnabled:
          groupMessageNotificationsEnabled ??
          this.groupMessageNotificationsEnabled,
      mentionNotificationsEnabled:
          mentionNotificationsEnabled ?? this.mentionNotificationsEnabled,
      replyNotificationsEnabled:
          replyNotificationsEnabled ?? this.replyNotificationsEnabled,
      reactionNotificationsEnabled:
          reactionNotificationsEnabled ?? this.reactionNotificationsEnabled,
      defaultNotificationSound:
          defaultNotificationSound ?? this.defaultNotificationSound,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      showMessagePreview: showMessagePreview ?? this.showMessagePreview,
      notifyOnlyWhenOffline:
          notifyOnlyWhenOffline ?? this.notifyOnlyWhenOffline,
      mutedChats: mutedChats ?? this.mutedChats,
      chatNotificationSounds:
          chatNotificationSounds ?? this.chatNotificationSounds,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      allowedDuringQuietHours:
          allowedDuringQuietHours ?? this.allowedDuringQuietHours,
      ledNotificationEnabled:
          ledNotificationEnabled ?? this.ledNotificationEnabled,
      ledColor: ledColor ?? this.ledColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'NotificationPreferencesModel(id: $id, userId: $userId, globalEnabled: $globalNotificationsEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationPreferencesModel &&
        other.id == id &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode;
  }
}

/// Helper class for parsing time strings
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  factory TimeOfDay.parse(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
