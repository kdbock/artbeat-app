/// Helper utilities for capture functionality
class CaptureHelper {
  static const List<String> validImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  static const List<String> validVideoExtensions = ['mp4', 'mov', 'avi', 'mkv'];

  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  /// Check if a file name has a valid image extension
  static bool isValidImageType(String fileName) {
    if (fileName.isEmpty) return false;
    final extension = getFileExtension(fileName).toLowerCase();
    return validImageExtensions.contains(extension);
  }

  /// Check if a file name has a valid video extension
  static bool isValidVideoType(String fileName) {
    if (fileName.isEmpty) return false;
    final extension = getFileExtension(fileName).toLowerCase();
    return validVideoExtensions.contains(extension);
  }

  /// Check if file size is within valid limits
  static bool isValidFileSize(int fileSizeBytes) {
    return fileSizeBytes >= 0 && fileSizeBytes <= maxFileSizeBytes;
  }

  /// Format file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes == 0) return '0 B';

    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    // For bytes, show as integer to avoid .0
    if (unitIndex == 0) {
      return '${size.toInt()} ${units[unitIndex]}';
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Extract file extension from file name
  static String getFileExtension(String fileName) {
    if (fileName.isEmpty || !fileName.contains('.')) return '';
    return fileName.split('.').last;
  }
}
