import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:artbeat/app.dart';
import 'helpers/test_config_new.dart' as config;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile Search Integration Tests', () {
    tearDown(() async {
      await config.TestConfig.cleanupTestEnvironment();
    });
    testWidgets('Basic Search with Filter', (tester) async {
      // Initialize test environment
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Login and initialize test environment
      await config.TestConfig.performTestLogin(tester);
      await tester.pumpAndSettle();

      // Initialize test environment
      await config.TestConfig.setupTestEnvironment();

      // Open search (assuming we have a search icon in the app bar)
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField).first, 'abstract art');
      await tester.pump(const Duration(milliseconds: 300)); // Debounce time

      // Open filter sheet
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Select art medium filter
      await tester.tap(find.text('Oil Paint').first);
      await tester.pumpAndSettle();

      // Apply filter
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Wait for search results
      await tester.pump(const Duration(seconds: 2));

      // Verify results are displayed
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Search History Test', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      await config.TestConfig.performTestLogin(tester);
      await tester.pumpAndSettle();

      // Initialize test environment
      await config.TestConfig.setupTestEnvironment();

      // Perform multiple searches
      final searches = ['abstract', 'portrait', 'landscape'];

      for (final searchTerm in searches) {
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, searchTerm);
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      }

      // Open search again
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Verify history is displayed
      for (final searchTerm in searches) {
        expect(find.text(searchTerm), findsOneWidget);
      }
    });

    testWidgets('Location-based Search Test', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      await config.TestConfig.performTestLogin(tester);
      await tester.pumpAndSettle();

      // Initialize test environment
      await config.TestConfig.setupTestEnvironment();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Open filter
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Select location filter
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Enter location
      await tester.enterText(find.byType(TextField).last, 'New York');
      await tester.pump(const Duration(milliseconds: 300));

      // Apply filter
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Verify results contain location
      expect(find.textContaining('New York'), findsAtLeastNWidgets(1));
    });
  });
}
