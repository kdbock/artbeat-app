/// Device activity model for tracking login sessions
/// Implementation Date: September 5, 2025
class DeviceActivityModel {
  final String deviceId;
  final String deviceName;
  final String deviceType; // mobile, web, desktop
  final String platform; // iOS, Android, Windows, macOS, Linux
  final String ipAddress;
  final String location;
  final DateTime lastActive;
  final DateTime firstLogin;
  final bool isCurrentDevice;
  final bool isTrusted;

  const DeviceActivityModel({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.platform,
    required this.ipAddress,
    this.location = '',
    required this.lastActive,
    required this.firstLogin,
    this.isCurrentDevice = false,
    this.isTrusted = false,
  });

  factory DeviceActivityModel.fromMap(Map<String, dynamic> map) {
    return DeviceActivityModel(
      deviceId: map['deviceId'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? '',
      deviceType: map['deviceType'] as String? ?? '',
      platform: map['platform'] as String? ?? '',
      ipAddress: map['ipAddress'] as String? ?? '',
      location: map['location'] as String? ?? '',
      lastActive: DateTime.parse(
        map['lastActive'] as String? ?? DateTime.now().toIso8601String(),
      ),
      firstLogin: DateTime.parse(
        map['firstLogin'] as String? ?? DateTime.now().toIso8601String(),
      ),
      isCurrentDevice: map['isCurrentDevice'] as bool? ?? false,
      isTrusted: map['isTrusted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'platform': platform,
      'ipAddress': ipAddress,
      'location': location,
      'lastActive': lastActive.toIso8601String(),
      'firstLogin': firstLogin.toIso8601String(),
      'isCurrentDevice': isCurrentDevice,
      'isTrusted': isTrusted,
    };
  }

  DeviceActivityModel copyWith({
    String? deviceId,
    String? deviceName,
    String? deviceType,
    String? platform,
    String? ipAddress,
    String? location,
    DateTime? lastActive,
    DateTime? firstLogin,
    bool? isCurrentDevice,
    bool? isTrusted,
  }) {
    return DeviceActivityModel(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      platform: platform ?? this.platform,
      ipAddress: ipAddress ?? this.ipAddress,
      location: location ?? this.location,
      lastActive: lastActive ?? this.lastActive,
      firstLogin: firstLogin ?? this.firstLogin,
      isCurrentDevice: isCurrentDevice ?? this.isCurrentDevice,
      isTrusted: isTrusted ?? this.isTrusted,
    );
  }

  bool isValid() => deviceId.isNotEmpty && deviceName.isNotEmpty;

  /// Get human readable last active time
  String get lastActiveFormatted {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else {
      return lastActive.toString().split(' ')[0]; // YYYY-MM-DD
    }
  }

  /// Check if device is active (used within last 30 days)
  bool get isActive {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return lastActive.isAfter(thirtyDaysAgo);
  }
}
