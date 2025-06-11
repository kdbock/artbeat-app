import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:artbeat/app.dart';
import 'package:artbeat_core/src/services/search/search_analytics.dart';
import 'package:artbeat_core/src/services/search/search_cache.dart';
import 'package:artbeat_core/src/services/search/search_history.dart';
import 'helpers/test_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Search Filter Integration Tests', () {
    setUpAll(() async {
      await TestConfig.setupTestFirebase();
    });

    tearDownAll(() async {
      await TestConfig.cleanupTestData();
    });

    testWidgets('Test artist type and medium filters', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Open filter sheet
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Select artist type filter
      await tester.tap(find.text('Artist Type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Painter'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Select medium filter
      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oil'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Verify filters are applied
      expect(find.text('Painter'), findsOneWidget);
      expect(find.text('Oil'), findsOneWidget);

      // Verify search history is updated
      final history = await SearchHistory().getSearchHistory();
      expect(history.length, 1);
      expect(history[0]['filters']['artistTypes'], contains('Painter'));
      expect(history[0]['filters']['artMediums'], contains('Oil'));
    });

    testWidgets('Test location and date filters', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Open filter sheet
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Set location filter
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'New York');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Set date range
      await tester.tap(find.text('Date Range'));
      await tester.pumpAndSettle();
      // Select today and a week from now
      await tester.tap(find.text(DateTime.now().day.toString()).first);
      await tester.tap(find
          .text((DateTime.now().add(const Duration(days: 7))).day.toString())
          .first);
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Verify filters are applied
      expect(find.text('New York'), findsOneWidget);
      expect(find.textContaining('Date Range:'), findsOneWidget);

      // Verify analytics tracked the search
      final analytics = SearchAnalytics();
      final popularSearches = await analytics.getPopularSearches(limit: 1);
      expect(popularSearches.isNotEmpty, true);
    });

    testWidgets('Test search result caching', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      final cache = SearchCache();
      const query = 'test query';
      final filters = {
        'artistTypes': ['Painter'],
        'artMediums': ['Oil']
      };

      // Cache some results
      cache.cacheResults(
        key: cache.generateCacheKey(query, filters),
        results: ['result1', 'result2'],
      );

      // Verify cache hit
      final results = cache.getResults(cache.generateCacheKey(query, filters));
      expect(results, isNotNull);
      expect(results?.length, 2);
    });
  });
}
