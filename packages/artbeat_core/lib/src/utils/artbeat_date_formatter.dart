import 'package:intl/intl.dart';

/// A utility class for consistent date formatting across the app
class ArtbeatDateFormatter {
  /// Format a date into a readable date string (e.g., "June 7, 2025")
  static String formatDate(DateTime date) {
    return DateFormat.yMMMMd().format(date);
  }

  /// Format a time into a readable time string (e.g., "2:30 PM")
  static String formatTime(DateTime time) {
    return DateFormat.jm().format(time);
  }

  /// Format a datetime into a readable date and time string (e.g., "June 7, 2025 2:30 PM")
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }

  /// Format a date range (e.g., "June 7-8, 2025" or "June 7 - July 8, 2025")
  static String formatDateRange(DateTime startDate, DateTime endDate) {
    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      // Same month and year
      return '${DateFormat.MMMM().format(startDate)} ${startDate.day}-${endDate.day}, ${startDate.year}';
    } else {
      // Different months
      return '${DateFormat.MMMMd().format(startDate)} - ${DateFormat.yMMMMd().format(endDate)}';
    }
  }

  /// Format elapsed time (e.g., "2 hours ago", "5 days ago")
  static String formatElapsedTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
