import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:artbeat_core/src/services/search/search_cache.dart';
import 'package:artbeat_core/src/services/search/search_history.dart';
import 'helpers/mock_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Search Functionality Tests', () {
    late SearchCache cache;
    late SearchHistory history;

    setUp(() async {
      cache = SearchCache();
      await cache.clear();
      history = SearchHistory();
      await history.clearHistory();
    });

    testWidgets('Search results are cached', (tester) async {
      await tester.pumpWidget(const MockSearchApp());
      await tester.pumpAndSettle();

      // Find and tap search bar
      final searchBar = find.byType(TextField);
      expect(searchBar, findsOneWidget);

      // Enter search text
      await tester.enterText(searchBar, 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Wait for results to be cached
      await tester.pump(const Duration(seconds: 1));

      // Verify results are cached
      final key = cache.generateCacheKey('test', {});
      final results = cache.getResults(key);
      expect(results, isNotNull);
    });

    testWidgets('Search history is maintained', (tester) async {
      await tester.pumpWidget(const MockSearchApp());
      await tester.pumpAndSettle();

      // Perform multiple searches
      final searchTerms = ['sculpture', 'gallery', 'art'];

      for (final term in searchTerms) {
        await tester.enterText(find.byType(TextField), term);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      }

      // Verify search history
      final searchHistory = await history.getSearchHistory();
      expect(searchHistory.length, equals(3));

      expect(searchHistory[0]['query'], equals('art'));
      expect(searchHistory[1]['query'], equals('gallery'));
      expect(searchHistory[2]['query'], equals('sculpture'));
    });

    testWidgets('Filter combinations work correctly', (tester) async {
      await tester.pumpWidget(const MockSearchApp());
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

      // Verify filter chip appears
      expect(find.text('Painter'), findsOneWidget);

      // Enter search text with filter
      await tester.enterText(find.byType(TextField), 'landscape');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Check cache has both search and filter params
      final key = cache.generateCacheKey('landscape', {
        'artistTypes': ['Painter']
      });
      final results = cache.getResults(key);
      expect(results, isNotNull);
    });
  });
}
