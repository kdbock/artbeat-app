import 'package:intl/intl.dart';

/// Utility functions for date handling
class DateUtils {
  static final DateFormat _dateFormatter = DateFormat('MMM d, y');
  static final DateFormat _timeFormatter = DateFormat('h:mm a');
  static final DateFormat _fullDateFormatter = DateFormat('MMM d, y h:mm a');

  /// Format date only: "Jan 1, 2025"
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  /// Format time only: "3:30 PM"
  static String formatTime(DateTime date) {
    return _timeFormatter.format(date);
  }

  /// Format full date and time: "Jan 1, 2025 3:30 PM"
  static String formatDateTime(DateTime date) {
    return _fullDateFormatter.format(date);
  }

  /// Get relative time description: "2 hours ago", "5 days ago", etc.
  static String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    }
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    }
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    }
    return 'Just now';
  }

  /// Calculate days remaining until a future date
  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    return date.difference(now).inDays;
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
}
