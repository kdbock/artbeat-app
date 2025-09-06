/// AdDuration enum for ad campaign length presets
enum AdDuration {
  oneDay, // 1 day
  threeDays, // 3 days
  oneWeek, // 7 days
  twoWeeks, // 14 days
  oneMonth, // 30 days
  custom, // Custom duration
}

extension AdDurationExtension on AdDuration {
  /// Get the number of days for this duration
  int get days {
    switch (this) {
      case AdDuration.oneDay:
        return 1;
      case AdDuration.threeDays:
        return 3;
      case AdDuration.oneWeek:
        return 7;
      case AdDuration.twoWeeks:
        return 14;
      case AdDuration.oneMonth:
        return 30;
      case AdDuration.custom:
        return 7; // Default for custom
    }
  }

  /// Get display name for this duration
  String get displayName {
    switch (this) {
      case AdDuration.oneDay:
        return '1 Day';
      case AdDuration.threeDays:
        return '3 Days';
      case AdDuration.oneWeek:
        return '1 Week';
      case AdDuration.twoWeeks:
        return '2 Weeks';
      case AdDuration.oneMonth:
        return '1 Month';
      case AdDuration.custom:
        return 'Custom';
    }
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() => {'type': index, 'days': days};

  /// Create from map
  static AdDuration fromMap(Map<String, dynamic> map) {
    final typeIndex = map['type'] as int? ?? 0;
    if (typeIndex >= 0 && typeIndex < AdDuration.values.length) {
      return AdDuration.values[typeIndex];
    }
    // Fallback: try to determine from days
    final days = map['days'] as int? ?? 7;
    switch (days) {
      case 1:
        return AdDuration.oneDay;
      case 3:
        return AdDuration.threeDays;
      case 7:
        return AdDuration.oneWeek;
      case 14:
        return AdDuration.twoWeeks;
      case 30:
        return AdDuration.oneMonth;
      default:
        return AdDuration.custom;
    }
  }
}
