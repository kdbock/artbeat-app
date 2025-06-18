import 'package:flutter/foundation.dart';

class SearchPerformanceMonitor {
  static final SearchPerformanceMonitor _instance =
      SearchPerformanceMonitor._internal();
  factory SearchPerformanceMonitor() => _instance;
  SearchPerformanceMonitor._internal();

  final List<SearchMetrics> _metrics = [];

  void recordSearch({
    required String query,
    required Map<String, dynamic> filters,
    required int resultCount,
    required Duration searchDuration,
  }) {
    final metrics = SearchMetrics(
      query: query,
      filters: filters,
      resultCount: resultCount,
      searchDuration: searchDuration,
      timestamp: DateTime.now(),
    );

    _metrics.add(metrics);
    _logMetrics(metrics);
  }

  void _logMetrics(SearchMetrics metrics) {
    if (kDebugMode) {
      print('''
Search Performance Metrics:
- Query: ${metrics.query}
- Filters: ${metrics.filters}
- Results: ${metrics.resultCount}
- Duration: ${metrics.searchDuration.inMilliseconds}ms
''');
    }
  }

  List<SearchMetrics> getRecentMetrics({int limit = 100}) {
    return _metrics.take(limit).toList();
  }

  double getAverageSearchDuration() {
    if (_metrics.isEmpty) return 0;
    final totalDuration = _metrics
        .map((m) => m.searchDuration.inMilliseconds)
        .reduce((a, b) => a + b);
    return totalDuration / _metrics.length;
  }

  void clearMetrics() {
    _metrics.clear();
  }
}

class SearchMetrics {
  final String query;
  final Map<String, dynamic> filters;
  final int resultCount;
  final Duration searchDuration;
  final DateTime timestamp;

  SearchMetrics({
    required this.query,
    required this.filters,
    required this.resultCount,
    required this.searchDuration,
    required this.timestamp,
  });
}
