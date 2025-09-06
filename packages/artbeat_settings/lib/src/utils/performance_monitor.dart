import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Performance monitoring utility for settings module
/// Implementation Date: September 5, 2025
class SettingsPerformanceMonitor {
  static final SettingsPerformanceMonitor _instance =
      SettingsPerformanceMonitor._internal();
  factory SettingsPerformanceMonitor() => _instance;
  SettingsPerformanceMonitor._internal();

  final Map<String, List<int>> _operationTimes = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, DateTime> _operationStartTimes = {};

  int _totalMemoryAllocations = 0;
  int _cacheHitCount = 0;
  int _cacheMissCount = 0;

  /// Start timing an operation
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
    developer.Timeline.startSync(operationName);
  }

  /// End timing an operation
  void endOperation(String operationName) {
    final startTime = _operationStartTimes.remove(operationName);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      _operationTimes.putIfAbsent(operationName, () => []);
      _operationTimes[operationName]!.add(duration);

      _operationCounts[operationName] =
          (_operationCounts[operationName] ?? 0) + 1;

      // Log slow operations in debug mode
      if (kDebugMode && duration > 1000) {
        developer.log(
          'Slow operation detected: $operationName took ${duration}ms',
          name: 'SettingsPerformance',
        );
      }
    }
    developer.Timeline.finishSync();
  }

  /// Record a cache hit
  void recordCacheHit() {
    _cacheHitCount++;
  }

  /// Record a cache miss
  void recordCacheMiss() {
    _cacheMissCount++;
  }

  /// Record memory allocation
  void recordMemoryAllocation() {
    _totalMemoryAllocations++;
  }

  /// Get average operation time in milliseconds
  double getAverageOperationTime(String operationName) {
    final times = _operationTimes[operationName];
    if (times == null || times.isEmpty) return 0;

    return times.reduce((a, b) => a + b) / times.length;
  }

  /// Get operation count
  int getOperationCount(String operationName) {
    return _operationCounts[operationName] ?? 0;
  }

  /// Get cache hit ratio
  double getCacheHitRatio() {
    final total = _cacheHitCount + _cacheMissCount;
    if (total == 0) return 0;
    return _cacheHitCount / total;
  }

  /// Get comprehensive performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    final metrics = <String, dynamic>{
      'cacheHitRatio': getCacheHitRatio(),
      'totalCacheHits': _cacheHitCount,
      'totalCacheMisses': _cacheMissCount,
      'totalMemoryAllocations': _totalMemoryAllocations,
      'operationMetrics': <String, dynamic>{},
    };

    // Add operation-specific metrics
    for (final operation in _operationTimes.keys) {
      final times = _operationTimes[operation]!;
      metrics['operationMetrics'][operation] = {
        'averageTime': getAverageOperationTime(operation),
        'totalExecutions': getOperationCount(operation),
        'minTime': times.isEmpty ? 0 : times.reduce((a, b) => a < b ? a : b),
        'maxTime': times.isEmpty ? 0 : times.reduce((a, b) => a > b ? a : b),
        'totalTime': times.isEmpty ? 0 : times.reduce((a, b) => a + b),
      };
    }

    return metrics;
  }

  /// Get performance recommendations
  List<String> getPerformanceRecommendations() {
    final recommendations = <String>[];
    final metrics = getPerformanceMetrics();

    // Cache hit ratio recommendations
    final cacheHitRatio = metrics['cacheHitRatio'] as double;
    if (cacheHitRatio < 0.7) {
      recommendations.add(
        'Consider increasing cache expiry time or preloading more data',
      );
    }

    // Operation time recommendations
    final operationMetrics =
        metrics['operationMetrics'] as Map<String, dynamic>;
    for (final entry in operationMetrics.entries) {
      final opMetrics = entry.value as Map<String, dynamic>;
      final avgTime = opMetrics['averageTime'] as double;

      if (avgTime > 2000) {
        recommendations.add(
          'Operation "${entry.key}" is slow (${avgTime.toInt()}ms average). Consider optimization.',
        );
      }
    }

    // Memory recommendations
    final memoryAllocations = metrics['totalMemoryAllocations'] as int;
    if (memoryAllocations > 1000) {
      recommendations.add(
        'High memory allocation count ($memoryAllocations). Consider object pooling.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add('Performance is within acceptable ranges');
    }

    return recommendations;
  }

  /// Reset all performance metrics
  void reset() {
    _operationTimes.clear();
    _operationCounts.clear();
    _operationStartTimes.clear();
    _totalMemoryAllocations = 0;
    _cacheHitCount = 0;
    _cacheMissCount = 0;
  }

  /// Log performance summary
  void logPerformanceSummary() {
    if (!kDebugMode) return;

    final metrics = getPerformanceMetrics();
    final buffer = StringBuffer();
    buffer.writeln('=== Settings Performance Summary ===');
    buffer.writeln(
      'Cache Hit Ratio: ${(metrics['cacheHitRatio'] * 100).toStringAsFixed(1)}%',
    );
    buffer.writeln('Total Cache Hits: ${metrics['totalCacheHits']}');
    buffer.writeln('Total Cache Misses: ${metrics['totalCacheMisses']}');
    buffer.writeln('Memory Allocations: ${metrics['totalMemoryAllocations']}');

    final operationMetrics =
        metrics['operationMetrics'] as Map<String, dynamic>;
    if (operationMetrics.isNotEmpty) {
      buffer.writeln('\nOperation Performance:');
      for (final entry in operationMetrics.entries) {
        final opMetrics = entry.value as Map<String, dynamic>;
        buffer.writeln('  ${entry.key}:');
        buffer.writeln(
          '    Avg: ${(opMetrics['averageTime'] as double).toInt()}ms',
        );
        buffer.writeln('    Count: ${opMetrics['totalExecutions']}');
        buffer.writeln(
          '    Range: ${opMetrics['minTime']}ms - ${opMetrics['maxTime']}ms',
        );
      }
    }

    final recommendations = getPerformanceRecommendations();
    if (recommendations.isNotEmpty) {
      buffer.writeln('\nRecommendations:');
      for (final rec in recommendations) {
        buffer.writeln('  - $rec');
      }
    }

    developer.log(buffer.toString(), name: 'SettingsPerformance');
  }
}

/// Mixin for easy performance monitoring integration
mixin PerformanceTrackingMixin {
  final _monitor = SettingsPerformanceMonitor();

  /// Measure the performance of a future operation
  Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    _monitor.startOperation(operationName);
    try {
      final result = await operation();
      return result;
    } finally {
      _monitor.endOperation(operationName);
    }
  }

  /// Measure the performance of a synchronous operation
  T measureSync<T>(String operationName, T Function() operation) {
    _monitor.startOperation(operationName);
    try {
      return operation();
    } finally {
      _monitor.endOperation(operationName);
    }
  }

  void recordCacheHit() => _monitor.recordCacheHit();
  void recordCacheMiss() => _monitor.recordCacheMiss();
  void recordMemoryAllocation() => _monitor.recordMemoryAllocation();
}
