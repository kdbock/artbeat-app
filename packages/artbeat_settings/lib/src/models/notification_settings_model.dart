/// Dedicated notification settings model for granular control
/// Implementation Date: September 5, 2025
class NotificationSettingsModel {
  final String userId;
  final EmailNotificationSettings email;
  final PushNotificationSettings push;
  final InAppNotificationSettings inApp;
  final QuietHoursSettings quietHours;
  final DateTime updatedAt;

  const NotificationSettingsModel({
    required this.userId,
    required this.email,
    required this.push,
    required this.inApp,
    required this.quietHours,
    required this.updatedAt,
  });

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      userId: map['userId'] as String? ?? '',
      email: EmailNotificationSettings.fromMap(
        map['email'] as Map<String, dynamic>? ?? {},
      ),
      push: PushNotificationSettings.fromMap(
        map['push'] as Map<String, dynamic>? ?? {},
      ),
      inApp: InAppNotificationSettings.fromMap(
        map['inApp'] as Map<String, dynamic>? ?? {},
      ),
      quietHours: QuietHoursSettings.fromMap(
        map['quietHours'] as Map<String, dynamic>? ?? {},
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email.toMap(),
      'push': push.toMap(),
      'inApp': inApp.toMap(),
      'quietHours': quietHours.toMap(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NotificationSettingsModel.defaultSettings(String userId) {
    return NotificationSettingsModel(
      userId: userId,
      email: EmailNotificationSettings.defaultSettings(),
      push: PushNotificationSettings.defaultSettings(),
      inApp: InAppNotificationSettings.defaultSettings(),
      quietHours: QuietHoursSettings.defaultSettings(),
      updatedAt: DateTime.now(),
    );
  }

  NotificationSettingsModel copyWith({
    String? userId,
    EmailNotificationSettings? email,
    PushNotificationSettings? push,
    InAppNotificationSettings? inApp,
    QuietHoursSettings? quietHours,
  }) {
    return NotificationSettingsModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      push: push ?? this.push,
      inApp: inApp ?? this.inApp,
      quietHours: quietHours ?? this.quietHours,
      updatedAt: DateTime.now(),
    );
  }

  // Firestore serialization methods
  factory NotificationSettingsModel.fromFirestore(Map<String, dynamic> data) {
    return NotificationSettingsModel.fromMap(data);
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  bool isValid() => userId.isNotEmpty;
}

/// Email notification settings
class EmailNotificationSettings {
  final bool enabled;
  final String frequency; // immediate, daily, weekly, never
  final NotificationTypes types;

  const EmailNotificationSettings({
    required this.enabled,
    required this.frequency,
    required this.types,
  });

  factory EmailNotificationSettings.fromMap(Map<String, dynamic> map) {
    return EmailNotificationSettings(
      enabled: map['enabled'] as bool? ?? true,
      frequency: map['frequency'] as String? ?? 'immediate',
      types: NotificationTypes.fromMap(
        map['types'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {'enabled': enabled, 'frequency': frequency, 'types': types.toMap()};
  }

  factory EmailNotificationSettings.defaultSettings() {
    return EmailNotificationSettings(
      enabled: true,
      frequency: 'immediate',
      types: NotificationTypes.defaultSettings(),
    );
  }

  EmailNotificationSettings copyWith({
    bool? enabled,
    String? frequency,
    NotificationTypes? types,
  }) {
    return EmailNotificationSettings(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      types: types ?? this.types,
    );
  }
}

/// Push notification settings
class PushNotificationSettings {
  final bool enabled;
  final NotificationTypes types;
  final bool allowSounds;
  final bool allowVibration;
  final bool allowBadges;

  const PushNotificationSettings({
    required this.enabled,
    required this.types,
    this.allowSounds = true,
    this.allowVibration = true,
    this.allowBadges = true,
  });

  factory PushNotificationSettings.fromMap(Map<String, dynamic> map) {
    return PushNotificationSettings(
      enabled: map['enabled'] as bool? ?? true,
      types: NotificationTypes.fromMap(
        map['types'] as Map<String, dynamic>? ?? {},
      ),
      allowSounds: map['allowSounds'] as bool? ?? true,
      allowVibration: map['allowVibration'] as bool? ?? true,
      allowBadges: map['allowBadges'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'types': types.toMap(),
      'allowSounds': allowSounds,
      'allowVibration': allowVibration,
      'allowBadges': allowBadges,
    };
  }

  factory PushNotificationSettings.defaultSettings() {
    return PushNotificationSettings(
      enabled: true,
      types: NotificationTypes.defaultSettings(),
      allowSounds: true,
      allowVibration: true,
      allowBadges: true,
    );
  }

  PushNotificationSettings copyWith({
    bool? enabled,
    NotificationTypes? types,
    bool? allowSounds,
    bool? allowVibration,
    bool? allowBadges,
  }) {
    return PushNotificationSettings(
      enabled: enabled ?? this.enabled,
      types: types ?? this.types,
      allowSounds: allowSounds ?? this.allowSounds,
      allowVibration: allowVibration ?? this.allowVibration,
      allowBadges: allowBadges ?? this.allowBadges,
    );
  }
}

/// In-app notification settings
class InAppNotificationSettings {
  final bool enabled;
  final NotificationTypes types;
  final int displayDuration; // seconds

  const InAppNotificationSettings({
    required this.enabled,
    required this.types,
    this.displayDuration = 5,
  });

  factory InAppNotificationSettings.fromMap(Map<String, dynamic> map) {
    return InAppNotificationSettings(
      enabled: map['enabled'] as bool? ?? true,
      types: NotificationTypes.fromMap(
        map['types'] as Map<String, dynamic>? ?? {},
      ),
      displayDuration: map['displayDuration'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'types': types.toMap(),
      'displayDuration': displayDuration,
    };
  }

  factory InAppNotificationSettings.defaultSettings() {
    return InAppNotificationSettings(
      enabled: true,
      types: NotificationTypes.defaultSettings(),
      displayDuration: 5,
    );
  }

  InAppNotificationSettings copyWith({
    bool? enabled,
    NotificationTypes? types,
    int? displayDuration,
  }) {
    return InAppNotificationSettings(
      enabled: enabled ?? this.enabled,
      types: types ?? this.types,
      displayDuration: displayDuration ?? this.displayDuration,
    );
  }
}

/// Notification types configuration
class NotificationTypes {
  final bool account;
  final bool security;
  final bool marketing;
  final bool social;
  final bool artwork;
  final bool events;
  final bool messages;
  final bool likes;
  final bool comments;
  final bool follows;

  const NotificationTypes({
    this.account = true,
    this.security = true,
    this.marketing = false,
    this.social = true,
    this.artwork = true,
    this.events = true,
    this.messages = true,
    this.likes = true,
    this.comments = true,
    this.follows = true,
  });

  factory NotificationTypes.fromMap(Map<String, dynamic> map) {
    return NotificationTypes(
      account: map['account'] as bool? ?? true,
      security: map['security'] as bool? ?? true,
      marketing: map['marketing'] as bool? ?? false,
      social: map['social'] as bool? ?? true,
      artwork: map['artwork'] as bool? ?? true,
      events: map['events'] as bool? ?? true,
      messages: map['messages'] as bool? ?? true,
      likes: map['likes'] as bool? ?? true,
      comments: map['comments'] as bool? ?? true,
      follows: map['follows'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'account': account,
      'security': security,
      'marketing': marketing,
      'social': social,
      'artwork': artwork,
      'events': events,
      'messages': messages,
      'likes': likes,
      'comments': comments,
      'follows': follows,
    };
  }

  factory NotificationTypes.defaultSettings() {
    return const NotificationTypes();
  }

  NotificationTypes copyWith({
    bool? account,
    bool? security,
    bool? marketing,
    bool? social,
    bool? artwork,
    bool? events,
    bool? messages,
    bool? likes,
    bool? comments,
    bool? follows,
  }) {
    return NotificationTypes(
      account: account ?? this.account,
      security: security ?? this.security,
      marketing: marketing ?? this.marketing,
      social: social ?? this.social,
      artwork: artwork ?? this.artwork,
      events: events ?? this.events,
      messages: messages ?? this.messages,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      follows: follows ?? this.follows,
    );
  }
}

/// Quiet hours settings
class QuietHoursSettings {
  final bool enabled;
  final String startTime; // HH:MM format
  final String endTime; // HH:MM format
  final String timezone;
  final List<String> allowedTypes; // Types that can bypass quiet hours

  const QuietHoursSettings({
    this.enabled = false,
    this.startTime = '22:00',
    this.endTime = '08:00',
    this.timezone = 'UTC',
    this.allowedTypes = const ['security', 'account'],
  });

  factory QuietHoursSettings.fromMap(Map<String, dynamic> map) {
    return QuietHoursSettings(
      enabled: map['enabled'] as bool? ?? false,
      startTime: map['startTime'] as String? ?? '22:00',
      endTime: map['endTime'] as String? ?? '08:00',
      timezone: map['timezone'] as String? ?? 'UTC',
      allowedTypes: List<String>.from(
        map['allowedTypes'] as List<dynamic>? ?? ['security', 'account'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'startTime': startTime,
      'endTime': endTime,
      'timezone': timezone,
      'allowedTypes': allowedTypes,
    };
  }

  factory QuietHoursSettings.defaultSettings() {
    return const QuietHoursSettings();
  }

  QuietHoursSettings copyWith({
    bool? enabled,
    String? startTime,
    String? endTime,
    String? timezone,
    List<String>? allowedTypes,
  }) {
    return QuietHoursSettings(
      enabled: enabled ?? this.enabled,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timezone: timezone ?? this.timezone,
      allowedTypes: allowedTypes ?? this.allowedTypes,
    );
  }
}
