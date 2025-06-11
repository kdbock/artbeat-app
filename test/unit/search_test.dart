import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/src/services/search/search_cache.dart';
import 'package:artbeat_core/src/services/search/search_history.dart';
import '../mocks/mock_analytics.dart';
import '../mocks/mock_shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Search Component Tests', () {
    late SearchCache cache;
    late SearchHistory history;
    late MockAnalytics mockAnalytics;

    setUpAll(() async {
      await setupMockSharedPreferences();
    });

    setUp(() async {
      cache = SearchCache();
      history = SearchHistory();
      mockAnalytics = getMockAnalytics();
    });

    tearDown(() async {
      await cache.clear();
      await history.clearHistory();
    });

    test('Search cache stores and retrieves results', () {
      const query = 'test query';
      final filters = {'type': 'artist'};
      final results = ['result1', 'result2'];

      cache.cacheResults(
        key: cache.generateCacheKey(query, filters),
        results: results,
      );

      final cachedResults =
          cache.getResults(cache.generateCacheKey(query, filters));
      expect(cachedResults, results);
    });

    test('Search history records searches', () async {
      const query = 'test artist';
      final filters = {'medium': 'oil'};

      await history.addSearch(query: query, filters: filters);
      final searches = await history.getSearchHistory();

      expect(searches.length, 1);
      expect(searches[0]['query'], query);
      expect(searches[0]['filters'], filters);
    });

    test('Search history limits size', () async {
      // Add more than max items
      for (var i = 0; i < 25; i++) {
        await history.addSearch(
          query: 'query$i',
          filters: {'index': i},
        );
      }

      final searches = await history.getSearchHistory();
      expect(searches.length, 20); // Max items limit
      expect(searches[0]['query'], 'query24'); // Most recent first
    });

    test('Search cache expires old results', () async {
      const query = 'test query';
      final filters = {'type': 'artist'};
      final results = ['result1', 'result2'];

      // Cache with very short TTL
      cache.cacheResults(
        key: cache.generateCacheKey(query, filters),
        results: results,
        ttl: const Duration(milliseconds: 100),
      );

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 150));

      final cachedResults =
          cache.getResults(cache.generateCacheKey(query, filters));
      expect(cachedResults, null);
    });

    test('Search analytics tracks searches', () async {
      const query = 'test query';
      final filters = {'type': 'artist'};

      await mockAnalytics.logSearch(
        searchTerm: query,
        parameters: {
          'filters': filters.toString(),
          'resultCount': 2,
          'userId': 'test_user',
        },
      );

      expect(mockAnalytics.searchLogs.length, 1);
      expect(mockAnalytics.searchLogs[0]['searchTerm'], query);
    });
  });
}
