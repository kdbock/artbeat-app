import 'dart:async';

class SearchCache {
  static final SearchCache _instance = SearchCache._internal();
  factory SearchCache() => _instance;
  SearchCache._internal();

  final Map<String, _CachedSearchResult> _cache = {};
  final Duration _defaultTtl = const Duration(minutes: 15);

  void cacheResults({
    required String key,
    required List<dynamic> results,
    Duration? ttl,
  }) {
    _cache[key] = _CachedSearchResult(
      results: results,
      timestamp: DateTime.now(),
      ttl: ttl ?? _defaultTtl,
    );

    // Schedule cleanup
    Timer(ttl ?? _defaultTtl, () => _cleanupCache());
  }

  List<dynamic>? getResults(String key) {
    final cached = _cache[key];
    if (cached == null) return null;

    if (DateTime.now().difference(cached.timestamp) > cached.ttl) {
      _cache.remove(key);
      return null;
    }

    return cached.results;
  }

  String generateCacheKey(String query, Map<String, dynamic> filters) {
    return '$query-${filters.toString()}';
  }

  void _cleanupCache() {
    final now = DateTime.now();
    _cache.removeWhere(
      (key, value) => now.difference(value.timestamp) > value.ttl,
    );
  }

  Future<void> clear() async {
    _cache.clear();
  }
}

class _CachedSearchResult {
  final List<dynamic> results;
  final DateTime timestamp;
  final Duration ttl;

  _CachedSearchResult({
    required this.results,
    required this.timestamp,
    required this.ttl,
  });
}
