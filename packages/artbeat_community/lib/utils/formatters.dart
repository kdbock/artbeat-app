import 'package:intl/intl.dart';

class Formatters {
  // Format a timestamp into a readable date
  static String formatDate(DateTime date) {
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  // Format a timestamp into a readable time
  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  // Format a number into currency
  static String formatCurrency(double amount) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    return currencyFormatter.format(amount);
  }

  // Format a string to capitalize the first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Truncate a string to a specific length
  static String truncate(String text, int length) {
    if (text.length <= length) return text;
    return '${text.substring(0, length)}...';
  }
}
