import 'package:intl/intl.dart';

/// Utility functions for ARTbeat Ads
class AdUtils {
  /// Format price as currency
  static String formatPrice(double price) {
    final format = NumberFormat.simpleCurrency();
    return format.format(price);
  }

  /// Format ad duration as readable string
  static String formatDuration(int days) {
    return days == 1 ? '1 day' : '$days days';
  }

  /// Format date range for ad
  static String formatDateRange(DateTime start, DateTime end) {
    final df = DateFormat('MMM d, yyyy');
    return '${df.format(start)} - ${df.format(end)}';
  }
}
