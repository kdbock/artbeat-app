/// Security settings model for user security controls
/// Implementation Date: September 5, 2025
class SecuritySettingsModel {
  final String userId;
  final TwoFactorSettings twoFactor;
  final LoginSettings login;
  final PasswordSettings password;
  final DeviceSettings devices;
  final DateTime updatedAt;

  const SecuritySettingsModel({
    required this.userId,
    required this.twoFactor,
    required this.login,
    required this.password,
    required this.devices,
    required this.updatedAt,
  });

  factory SecuritySettingsModel.fromMap(Map<String, dynamic> map) {
    return SecuritySettingsModel(
      userId: map['userId'] as String? ?? '',
      twoFactor: TwoFactorSettings.fromMap(
        map['twoFactor'] as Map<String, dynamic>? ?? {},
      ),
      login: LoginSettings.fromMap(map['login'] as Map<String, dynamic>? ?? {}),
      password: PasswordSettings.fromMap(
        map['password'] as Map<String, dynamic>? ?? {},
      ),
      devices: DeviceSettings.fromMap(
        map['devices'] as Map<String, dynamic>? ?? {},
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'twoFactor': twoFactor.toMap(),
      'login': login.toMap(),
      'password': password.toMap(),
      'devices': devices.toMap(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SecuritySettingsModel.defaultSettings(String userId) {
    return SecuritySettingsModel(
      userId: userId,
      twoFactor: TwoFactorSettings.defaultSettings(),
      login: LoginSettings.defaultSettings(),
      password: PasswordSettings.defaultSettings(),
      devices: DeviceSettings.defaultSettings(),
      updatedAt: DateTime.now(),
    );
  }

  SecuritySettingsModel copyWith({
    String? userId,
    TwoFactorSettings? twoFactor,
    LoginSettings? login,
    PasswordSettings? password,
    DeviceSettings? devices,
  }) {
    return SecuritySettingsModel(
      userId: userId ?? this.userId,
      twoFactor: twoFactor ?? this.twoFactor,
      login: login ?? this.login,
      password: password ?? this.password,
      devices: devices ?? this.devices,
      updatedAt: DateTime.now(),
    );
  }

  bool isValid() => userId.isNotEmpty;
}

/// Two-factor authentication settings
class TwoFactorSettings {
  final bool enabled;
  final String method; // sms, authenticator, email
  final String phoneNumber;
  final bool backupCodesGenerated;
  final List<String> backupCodes;
  final DateTime? lastUsed;

  const TwoFactorSettings({
    this.enabled = false,
    this.method = 'sms',
    this.phoneNumber = '',
    this.backupCodesGenerated = false,
    this.backupCodes = const <String>[],
    this.lastUsed,
  });

  factory TwoFactorSettings.fromMap(Map<String, dynamic> map) {
    return TwoFactorSettings(
      enabled: map['enabled'] as bool? ?? false,
      method: map['method'] as String? ?? 'sms',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      backupCodesGenerated: map['backupCodesGenerated'] as bool? ?? false,
      backupCodes: List<String>.from(
        map['backupCodes'] as List<dynamic>? ?? <String>[],
      ),
      lastUsed: map['lastUsed'] != null
          ? DateTime.parse(map['lastUsed'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'method': method,
      'phoneNumber': phoneNumber,
      'backupCodesGenerated': backupCodesGenerated,
      'backupCodes': backupCodes,
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }

  factory TwoFactorSettings.defaultSettings() {
    return const TwoFactorSettings();
  }

  TwoFactorSettings copyWith({
    bool? enabled,
    String? method,
    String? phoneNumber,
    bool? backupCodesGenerated,
    List<String>? backupCodes,
    DateTime? lastUsed,
  }) {
    return TwoFactorSettings(
      enabled: enabled ?? this.enabled,
      method: method ?? this.method,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      backupCodesGenerated: backupCodesGenerated ?? this.backupCodesGenerated,
      backupCodes: backupCodes ?? this.backupCodes,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}

/// Login security settings
class LoginSettings {
  final bool requireEmailVerification;
  final bool allowLoginAlerts;
  final int sessionTimeout; // days
  final bool rememberDevice;
  final List<String> trustedDevices;

  const LoginSettings({
    this.requireEmailVerification = true,
    this.allowLoginAlerts = true,
    this.sessionTimeout = 30,
    this.rememberDevice = true,
    this.trustedDevices = const <String>[],
  });

  factory LoginSettings.fromMap(Map<String, dynamic> map) {
    return LoginSettings(
      requireEmailVerification:
          map['requireEmailVerification'] as bool? ?? true,
      allowLoginAlerts: map['allowLoginAlerts'] as bool? ?? true,
      sessionTimeout: map['sessionTimeout'] as int? ?? 30,
      rememberDevice: map['rememberDevice'] as bool? ?? true,
      trustedDevices: List<String>.from(
        map['trustedDevices'] as List<dynamic>? ?? <String>[],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requireEmailVerification': requireEmailVerification,
      'allowLoginAlerts': allowLoginAlerts,
      'sessionTimeout': sessionTimeout,
      'rememberDevice': rememberDevice,
      'trustedDevices': trustedDevices,
    };
  }

  factory LoginSettings.defaultSettings() {
    return const LoginSettings();
  }

  LoginSettings copyWith({
    bool? requireEmailVerification,
    bool? allowLoginAlerts,
    int? sessionTimeout,
    bool? rememberDevice,
    List<String>? trustedDevices,
  }) {
    return LoginSettings(
      requireEmailVerification:
          requireEmailVerification ?? this.requireEmailVerification,
      allowLoginAlerts: allowLoginAlerts ?? this.allowLoginAlerts,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      rememberDevice: rememberDevice ?? this.rememberDevice,
      trustedDevices: trustedDevices ?? this.trustedDevices,
    );
  }
}

/// Password security settings
class PasswordSettings {
  final bool requireComplexPassword;
  final bool requirePasswordChange;
  final int minPasswordLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumbers;
  final bool requireSpecialChars;
  final DateTime? lastChanged;
  final int passwordChangeInterval; // days, 0 = never

  const PasswordSettings({
    this.requireComplexPassword = true,
    this.requirePasswordChange = false,
    this.minPasswordLength = 8,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireNumbers = true,
    this.requireSpecialChars = false,
    this.lastChanged,
    this.passwordChangeInterval = 0,
  });

  factory PasswordSettings.fromMap(Map<String, dynamic> map) {
    return PasswordSettings(
      requireComplexPassword: map['requireComplexPassword'] as bool? ?? true,
      requirePasswordChange: map['requirePasswordChange'] as bool? ?? false,
      minPasswordLength: map['minPasswordLength'] as int? ?? 8,
      requireUppercase: map['requireUppercase'] as bool? ?? true,
      requireLowercase: map['requireLowercase'] as bool? ?? true,
      requireNumbers: map['requireNumbers'] as bool? ?? true,
      requireSpecialChars: map['requireSpecialChars'] as bool? ?? false,
      lastChanged: map['lastChanged'] != null
          ? DateTime.parse(map['lastChanged'] as String)
          : null,
      passwordChangeInterval: map['passwordChangeInterval'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requireComplexPassword': requireComplexPassword,
      'requirePasswordChange': requirePasswordChange,
      'minPasswordLength': minPasswordLength,
      'requireUppercase': requireUppercase,
      'requireLowercase': requireLowercase,
      'requireNumbers': requireNumbers,
      'requireSpecialChars': requireSpecialChars,
      'lastChanged': lastChanged?.toIso8601String(),
      'passwordChangeInterval': passwordChangeInterval,
    };
  }

  factory PasswordSettings.defaultSettings() {
    return const PasswordSettings();
  }

  PasswordSettings copyWith({
    bool? requireComplexPassword,
    bool? requirePasswordChange,
    int? minPasswordLength,
    bool? requireUppercase,
    bool? requireLowercase,
    bool? requireNumbers,
    bool? requireSpecialChars,
    DateTime? lastChanged,
    int? passwordChangeInterval,
  }) {
    return PasswordSettings(
      requireComplexPassword:
          requireComplexPassword ?? this.requireComplexPassword,
      requirePasswordChange:
          requirePasswordChange ?? this.requirePasswordChange,
      minPasswordLength: minPasswordLength ?? this.minPasswordLength,
      requireUppercase: requireUppercase ?? this.requireUppercase,
      requireLowercase: requireLowercase ?? this.requireLowercase,
      requireNumbers: requireNumbers ?? this.requireNumbers,
      requireSpecialChars: requireSpecialChars ?? this.requireSpecialChars,
      lastChanged: lastChanged ?? this.lastChanged,
      passwordChangeInterval:
          passwordChangeInterval ?? this.passwordChangeInterval,
    );
  }

  /// Check if password change is required
  bool get isPasswordChangeRequired {
    if (!requirePasswordChange || passwordChangeInterval <= 0) return false;
    if (lastChanged == null) return true;

    final daysSinceChange = DateTime.now().difference(lastChanged!).inDays;
    return daysSinceChange >= passwordChangeInterval;
  }

  /// Validate password against requirements
  bool validatePassword(String password) {
    if (password.length < minPasswordLength) return false;
    if (requireUppercase && !password.contains(RegExp(r'[A-Z]'))) return false;
    if (requireLowercase && !password.contains(RegExp(r'[a-z]'))) return false;
    if (requireNumbers && !password.contains(RegExp(r'[0-9]'))) return false;
    if (requireSpecialChars &&
        !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))
      return false;
    return true;
  }
}

/// Device management settings
class DeviceSettings {
  final bool allowMultipleSessions;
  final int maxActiveSessions;
  final bool trackDeviceLocation;
  final bool requireDeviceApproval;
  final List<String> approvedDevices;

  const DeviceSettings({
    this.allowMultipleSessions = true,
    this.maxActiveSessions = 5,
    this.trackDeviceLocation = false,
    this.requireDeviceApproval = false,
    this.approvedDevices = const <String>[],
  });

  factory DeviceSettings.fromMap(Map<String, dynamic> map) {
    return DeviceSettings(
      allowMultipleSessions: map['allowMultipleSessions'] as bool? ?? true,
      maxActiveSessions: map['maxActiveSessions'] as int? ?? 5,
      trackDeviceLocation: map['trackDeviceLocation'] as bool? ?? false,
      requireDeviceApproval: map['requireDeviceApproval'] as bool? ?? false,
      approvedDevices: List<String>.from(
        map['approvedDevices'] as List<dynamic>? ?? <String>[],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allowMultipleSessions': allowMultipleSessions,
      'maxActiveSessions': maxActiveSessions,
      'trackDeviceLocation': trackDeviceLocation,
      'requireDeviceApproval': requireDeviceApproval,
      'approvedDevices': approvedDevices,
    };
  }

  factory DeviceSettings.defaultSettings() {
    return const DeviceSettings();
  }

  DeviceSettings copyWith({
    bool? allowMultipleSessions,
    int? maxActiveSessions,
    bool? trackDeviceLocation,
    bool? requireDeviceApproval,
    List<String>? approvedDevices,
  }) {
    return DeviceSettings(
      allowMultipleSessions:
          allowMultipleSessions ?? this.allowMultipleSessions,
      maxActiveSessions: maxActiveSessions ?? this.maxActiveSessions,
      trackDeviceLocation: trackDeviceLocation ?? this.trackDeviceLocation,
      requireDeviceApproval:
          requireDeviceApproval ?? this.requireDeviceApproval,
      approvedDevices: approvedDevices ?? this.approvedDevices,
    );
  }
}
