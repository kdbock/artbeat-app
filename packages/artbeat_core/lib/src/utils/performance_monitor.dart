import 'package:flutter/foundation.dart';

/// Simple performance monitoring utility for tracking app startup and navigation times
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, Duration> _durations = {};

  /// Start timing an operation
  static void startTimer(String operation) {
    if (kDebugMode) {
      _startTimes[operation] = DateTime.now();
      debugPrint('⏱️ Started timing: $operation');
    }
  }

  /// End timing an operation and log the duration
  static void endTimer(String operation) {
    if (kDebugMode && _startTimes.containsKey(operation)) {
      final duration = DateTime.now().difference(_startTimes[operation]!);
      _durations[operation] = duration;
      debugPrint('⏱️ $operation completed in ${duration.inMilliseconds}ms');
      _startTimes.remove(operation);
    }
  }

  /// Get the duration of a completed operation
  static Duration? getDuration(String operation) {
    return _durations[operation];
  }

  /// Log all recorded durations
  static void logAllDurations() {
    if (kDebugMode && _durations.isNotEmpty) {
      debugPrint('📊 Performance Summary:');
      _durations.forEach((operation, duration) {
        debugPrint('  $operation: ${duration.inMilliseconds}ms');
      });
    }
  }

  /// Clear all recorded data
  static void clear() {
    _startTimes.clear();
    _durations.clear();
  }
}
