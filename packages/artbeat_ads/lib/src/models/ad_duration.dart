/// AdDuration enum for ad campaign length presets
enum AdDuration {
  oneDay, // 1 day
  threeDays, // 3 days
  oneWeek, // 7 days
  twoWeeks, // 14 days
  oneMonth, // 30 days
  daily, // 1 Day
  weekly, // 1 Week
  monthly, // 1 Month
  custom, // Custom duration
}

extension AdDurationExtension on AdDuration {
  double calculateTotalCost(double pricePerDay) {
    return days * pricePerDay;
  }

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
      case AdDuration.daily:
        return 1;
      case AdDuration.weekly:
        return 7;
      case AdDuration.monthly:
        return 30;
      case AdDuration.custom:
        return 0; // Custom duration has variable days
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
      case AdDuration.daily:
        return '1 Day';
      case AdDuration.weekly:
        return '1 Week';
      case AdDuration.monthly:
        return '1 Month';
      case AdDuration.custom:
        return 'Custom';
    }
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() => {'type': name, 'days': days};

  /// Create from map
  static AdDuration fromMap(Map<String, dynamic> map) {
    final type = map['type'];
    if (type is String) {
      // Try to find by name
      try {
        return AdDuration.values.firstWhere((e) => e.name == type);
      } catch (_) {
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
            return AdDuration.daily; // Default fallback
        }
      }
    } else if (type is int) {
      // Legacy support for index
      if (type >= 0 && type < AdDuration.values.length) {
        return AdDuration.values[type];
      }
    }
    // Default fallback
    return AdDuration.daily;
  }
}
