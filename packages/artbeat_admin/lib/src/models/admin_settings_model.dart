import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin settings model
class AdminSettingsModel {
  // General settings
  final String appName;
  final String appDescription;
  final bool maintenanceMode;
  final bool registrationEnabled;

  // User settings
  final int maxUploadSizeMB;
  final int maxArtworksPerUser;
  final bool requireEmailVerification;
  final bool autoApproveContent;

  // Content settings
  final bool commentsEnabled;
  final bool ratingsEnabled;
  final bool reportingEnabled;
  final List<String> bannedWords;

  // Security settings
  final int maxLoginAttempts;
  final int loginAttemptWindow; // minutes
  final bool twoFactorEnabled;
  final bool ipBlockingEnabled;

  // System settings
  final bool analyticsEnabled;
  final bool errorLoggingEnabled;
  final bool performanceMonitoringEnabled;
  final int cacheDurationHours;

  // Notification settings
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool adminAlertsEnabled;

  // Maintenance settings
  final String maintenanceMessage;

  // Meta data
  final DateTime lastUpdated;
  final String updatedBy;

  AdminSettingsModel({
    required this.appName,
    required this.appDescription,
    required this.maintenanceMode,
    required this.registrationEnabled,
    required this.maxUploadSizeMB,
    required this.maxArtworksPerUser,
    required this.requireEmailVerification,
    required this.autoApproveContent,
    required this.commentsEnabled,
    required this.ratingsEnabled,
    required this.reportingEnabled,
    required this.bannedWords,
    required this.maxLoginAttempts,
    required this.loginAttemptWindow,
    required this.twoFactorEnabled,
    required this.ipBlockingEnabled,
    required this.analyticsEnabled,
    required this.errorLoggingEnabled,
    required this.performanceMonitoringEnabled,
    required this.cacheDurationHours,
    required this.pushNotificationsEnabled,
    required this.emailNotificationsEnabled,
    required this.adminAlertsEnabled,
    required this.maintenanceMessage,
    required this.lastUpdated,
    required this.updatedBy,
  });

  /// Create from Firestore document
  factory AdminSettingsModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AdminSettingsModel(
      appName: (data['appName'] as String?) ?? 'ARTbeat',
      appDescription: (data['appDescription'] as String?) ??
          'Art discovery and community platform',
      maintenanceMode: (data['maintenanceMode'] as bool?) ?? false,
      registrationEnabled: (data['registrationEnabled'] as bool?) ?? true,
      maxUploadSizeMB: (data['maxUploadSizeMB'] as int?) ?? 10,
      maxArtworksPerUser: (data['maxArtworksPerUser'] as int?) ?? 100,
      requireEmailVerification:
          (data['requireEmailVerification'] as bool?) ?? true,
      autoApproveContent: (data['autoApproveContent'] as bool?) ?? false,
      commentsEnabled: (data['commentsEnabled'] as bool?) ?? true,
      ratingsEnabled: (data['ratingsEnabled'] as bool?) ?? true,
      reportingEnabled: (data['reportingEnabled'] as bool?) ?? true,
      bannedWords: List<String>.from((data['bannedWords'] as List?) ?? []),
      maxLoginAttempts: (data['maxLoginAttempts'] as int?) ?? 5,
      loginAttemptWindow: (data['loginAttemptWindow'] as int?) ?? 15,
      twoFactorEnabled: (data['twoFactorEnabled'] as bool?) ?? false,
      ipBlockingEnabled: (data['ipBlockingEnabled'] as bool?) ?? true,
      analyticsEnabled: (data['analyticsEnabled'] as bool?) ?? true,
      errorLoggingEnabled: (data['errorLoggingEnabled'] as bool?) ?? true,
      performanceMonitoringEnabled:
          (data['performanceMonitoringEnabled'] as bool?) ?? true,
      cacheDurationHours: (data['cacheDurationHours'] as int?) ?? 24,
      pushNotificationsEnabled:
          (data['pushNotificationsEnabled'] as bool?) ?? true,
      emailNotificationsEnabled:
          (data['emailNotificationsEnabled'] as bool?) ?? true,
      adminAlertsEnabled: (data['adminAlertsEnabled'] as bool?) ?? true,
      maintenanceMessage: (data['maintenanceMessage'] as String?) ??
          'System under maintenance. Please try again later.',
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: (data['updatedBy'] as String?) ?? '',
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toDocument() {
    return {
      'appName': appName,
      'appDescription': appDescription,
      'maintenanceMode': maintenanceMode,
      'registrationEnabled': registrationEnabled,
      'maxUploadSizeMB': maxUploadSizeMB,
      'maxArtworksPerUser': maxArtworksPerUser,
      'requireEmailVerification': requireEmailVerification,
      'autoApproveContent': autoApproveContent,
      'commentsEnabled': commentsEnabled,
      'ratingsEnabled': ratingsEnabled,
      'reportingEnabled': reportingEnabled,
      'bannedWords': bannedWords,
      'maxLoginAttempts': maxLoginAttempts,
      'loginAttemptWindow': loginAttemptWindow,
      'twoFactorEnabled': twoFactorEnabled,
      'ipBlockingEnabled': ipBlockingEnabled,
      'analyticsEnabled': analyticsEnabled,
      'errorLoggingEnabled': errorLoggingEnabled,
      'performanceMonitoringEnabled': performanceMonitoringEnabled,
      'cacheDurationHours': cacheDurationHours,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'adminAlertsEnabled': adminAlertsEnabled,
      'maintenanceMessage': maintenanceMessage,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'updatedBy': updatedBy,
    };
  }

  /// Create a copy with updated fields
  AdminSettingsModel copyWith({
    String? appName,
    String? appDescription,
    bool? maintenanceMode,
    bool? registrationEnabled,
    int? maxUploadSizeMB,
    int? maxArtworksPerUser,
    bool? requireEmailVerification,
    bool? autoApproveContent,
    bool? commentsEnabled,
    bool? ratingsEnabled,
    bool? reportingEnabled,
    List<String>? bannedWords,
    int? maxLoginAttempts,
    int? loginAttemptWindow,
    bool? twoFactorEnabled,
    bool? ipBlockingEnabled,
    bool? analyticsEnabled,
    bool? errorLoggingEnabled,
    bool? performanceMonitoringEnabled,
    int? cacheDurationHours,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? adminAlertsEnabled,
    String? maintenanceMessage,
    DateTime? lastUpdated,
    String? updatedBy,
  }) {
    return AdminSettingsModel(
      appName: appName ?? this.appName,
      appDescription: appDescription ?? this.appDescription,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      registrationEnabled: registrationEnabled ?? this.registrationEnabled,
      maxUploadSizeMB: maxUploadSizeMB ?? this.maxUploadSizeMB,
      maxArtworksPerUser: maxArtworksPerUser ?? this.maxArtworksPerUser,
      requireEmailVerification:
          requireEmailVerification ?? this.requireEmailVerification,
      autoApproveContent: autoApproveContent ?? this.autoApproveContent,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      ratingsEnabled: ratingsEnabled ?? this.ratingsEnabled,
      reportingEnabled: reportingEnabled ?? this.reportingEnabled,
      bannedWords: bannedWords ?? this.bannedWords,
      maxLoginAttempts: maxLoginAttempts ?? this.maxLoginAttempts,
      loginAttemptWindow: loginAttemptWindow ?? this.loginAttemptWindow,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      ipBlockingEnabled: ipBlockingEnabled ?? this.ipBlockingEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      errorLoggingEnabled: errorLoggingEnabled ?? this.errorLoggingEnabled,
      performanceMonitoringEnabled:
          performanceMonitoringEnabled ?? this.performanceMonitoringEnabled,
      cacheDurationHours: cacheDurationHours ?? this.cacheDurationHours,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      adminAlertsEnabled: adminAlertsEnabled ?? this.adminAlertsEnabled,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  /// Create default settings
  factory AdminSettingsModel.defaultSettings() {
    return AdminSettingsModel(
      appName: 'ARTbeat',
      appDescription: 'Art discovery and community platform',
      maintenanceMode: false,
      registrationEnabled: true,
      maxUploadSizeMB: 10,
      maxArtworksPerUser: 100,
      requireEmailVerification: true,
      autoApproveContent: false,
      commentsEnabled: true,
      ratingsEnabled: true,
      reportingEnabled: true,
      bannedWords: [],
      maxLoginAttempts: 5,
      loginAttemptWindow: 15,
      twoFactorEnabled: false,
      ipBlockingEnabled: true,
      analyticsEnabled: true,
      errorLoggingEnabled: true,
      performanceMonitoringEnabled: true,
      cacheDurationHours: 24,
      pushNotificationsEnabled: true,
      emailNotificationsEnabled: true,
      adminAlertsEnabled: true,
      maintenanceMessage: 'System under maintenance. Please try again later.',
      lastUpdated: DateTime.now(),
      updatedBy: 'system',
    );
  }
}
