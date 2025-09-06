import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing per-chat customization settings
class ChatSettingsModel {
  final String id;
  final String chatId;
  final String userId;
  final bool notificationsEnabled;
  final String notificationSound;
  final bool showPreview;
  final String? customWallpaper;
  final String messageTextSize;
  final bool showTimestamps;
  final bool showReadReceipts;
  final bool autoDownloadMedia;
  final bool vibrationEnabled;
  final String chatTheme;
  final Map<String, dynamic> customColors;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSettingsModel({
    required this.id,
    required this.chatId,
    required this.userId,
    this.notificationsEnabled = true,
    this.notificationSound = 'default',
    this.showPreview = true,
    this.customWallpaper,
    this.messageTextSize = 'medium',
    this.showTimestamps = true,
    this.showReadReceipts = true,
    this.autoDownloadMedia = true,
    this.vibrationEnabled = true,
    this.chatTheme = 'default',
    this.customColors = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory ChatSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatSettingsModel(
      id: doc.id,
      chatId: (data['chatId'] as String?) ?? '',
      userId: (data['userId'] as String?) ?? '',
      notificationsEnabled: (data['notificationsEnabled'] as bool?) ?? true,
      notificationSound: (data['notificationSound'] as String?) ?? 'default',
      showPreview: (data['showPreview'] as bool?) ?? true,
      customWallpaper: data['customWallpaper'] as String?,
      messageTextSize: (data['messageTextSize'] as String?) ?? 'medium',
      showTimestamps: (data['showTimestamps'] as bool?) ?? true,
      showReadReceipts: (data['showReadReceipts'] as bool?) ?? true,
      autoDownloadMedia: (data['autoDownloadMedia'] as bool?) ?? true,
      vibrationEnabled: (data['vibrationEnabled'] as bool?) ?? true,
      chatTheme: (data['chatTheme'] as String?) ?? 'default',
      customColors: Map<String, dynamic>.from(
        data['customColors'] as Map? ?? {},
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create from Map
  factory ChatSettingsModel.fromMap(Map<String, dynamic> map) {
    return ChatSettingsModel(
      id: (map['id'] as String?) ?? '',
      chatId: (map['chatId'] as String?) ?? '',
      userId: (map['userId'] as String?) ?? '',
      notificationsEnabled: (map['notificationsEnabled'] as bool?) ?? true,
      notificationSound: (map['notificationSound'] as String?) ?? 'default',
      showPreview: (map['showPreview'] as bool?) ?? true,
      customWallpaper: map['customWallpaper'] as String?,
      messageTextSize: (map['messageTextSize'] as String?) ?? 'medium',
      showTimestamps: (map['showTimestamps'] as bool?) ?? true,
      showReadReceipts: (map['showReadReceipts'] as bool?) ?? true,
      autoDownloadMedia: (map['autoDownloadMedia'] as bool?) ?? true,
      vibrationEnabled: (map['vibrationEnabled'] as bool?) ?? true,
      chatTheme: (map['chatTheme'] as String?) ?? 'default',
      customColors: Map<String, dynamic>.from(
        map['customColors'] as Map? ?? {},
      ),
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
      'chatId': chatId,
      'userId': userId,
      'notificationsEnabled': notificationsEnabled,
      'notificationSound': notificationSound,
      'showPreview': showPreview,
      'customWallpaper': customWallpaper,
      'messageTextSize': messageTextSize,
      'showTimestamps': showTimestamps,
      'showReadReceipts': showReadReceipts,
      'autoDownloadMedia': autoDownloadMedia,
      'vibrationEnabled': vibrationEnabled,
      'chatTheme': chatTheme,
      'customColors': customColors,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create default settings for a chat
  factory ChatSettingsModel.createDefault({
    required String chatId,
    required String userId,
  }) {
    final now = DateTime.now();
    return ChatSettingsModel(
      id: '${chatId}_$userId',
      chatId: chatId,
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update notification settings
  ChatSettingsModel updateNotificationSettings({
    bool? enabled,
    String? sound,
    bool? showPreview,
    bool? vibration,
  }) {
    return copyWith(
      notificationsEnabled: enabled,
      notificationSound: sound,
      showPreview: showPreview,
      vibrationEnabled: vibration,
      updatedAt: DateTime.now(),
    );
  }

  /// Update appearance settings
  ChatSettingsModel updateAppearance({
    String? wallpaper,
    String? textSize,
    String? theme,
    Map<String, dynamic>? colors,
  }) {
    return copyWith(
      customWallpaper: wallpaper,
      messageTextSize: textSize,
      chatTheme: theme,
      customColors: colors,
      updatedAt: DateTime.now(),
    );
  }

  /// Update privacy settings
  ChatSettingsModel updatePrivacySettings({
    bool? showTimestamps,
    bool? showReadReceipts,
  }) {
    return copyWith(
      showTimestamps: showTimestamps,
      showReadReceipts: showReadReceipts,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if notifications are fully enabled
  bool get hasNotificationsEnabled => notificationsEnabled;

  /// Get text size multiplier
  double get textSizeMultiplier {
    switch (messageTextSize.toLowerCase()) {
      case 'small':
        return 0.9;
      case 'large':
        return 1.1;
      case 'extra_large':
        return 1.2;
      default:
        return 1.0; // medium
    }
  }

  /// Check if custom theme is applied
  bool get hasCustomTheme => chatTheme != 'default' || customColors.isNotEmpty;

  /// Create a copy with updated fields
  ChatSettingsModel copyWith({
    String? id,
    String? chatId,
    String? userId,
    bool? notificationsEnabled,
    String? notificationSound,
    bool? showPreview,
    String? customWallpaper,
    String? messageTextSize,
    bool? showTimestamps,
    bool? showReadReceipts,
    bool? autoDownloadMedia,
    bool? vibrationEnabled,
    String? chatTheme,
    Map<String, dynamic>? customColors,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatSettingsModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      userId: userId ?? this.userId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationSound: notificationSound ?? this.notificationSound,
      showPreview: showPreview ?? this.showPreview,
      customWallpaper: customWallpaper ?? this.customWallpaper,
      messageTextSize: messageTextSize ?? this.messageTextSize,
      showTimestamps: showTimestamps ?? this.showTimestamps,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      autoDownloadMedia: autoDownloadMedia ?? this.autoDownloadMedia,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      chatTheme: chatTheme ?? this.chatTheme,
      customColors: customColors ?? this.customColors,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ChatSettingsModel(id: $id, chatId: $chatId, userId: $userId, theme: $chatTheme)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatSettingsModel &&
        other.id == id &&
        other.chatId == chatId &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ chatId.hashCode ^ userId.hashCode;
  }
}
