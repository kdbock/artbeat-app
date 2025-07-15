import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/src/widgets/enhanced_bottom_nav.dart';

void main() {
  group('EnhancedBottomNav', () {
    testWidgets('should display correct number of navigation items', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            bottomNavigationBar: EnhancedBottomNav(
              currentIndex: 0,
              onTap: (index) {},
            ),
          ),
        ),
      );

      // Should have 5 navigation items
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Art Walk'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Capture'), findsOneWidget);
    });

    testWidgets('should handle tap on capture button', (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            bottomNavigationBar: EnhancedBottomNav(
              currentIndex: 0,
              onTap: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      // Tap on capture button (should be at index 2)
      await tester.tap(find.text('Capture'));
      await tester.pumpAndSettle();

      expect(tappedIndex, 2);
    });

    testWidgets('should handle tap on regular navigation items', (
      tester,
    ) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            bottomNavigationBar: EnhancedBottomNav(
              currentIndex: 0,
              onTap: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      // Tap on Art Walk (should be at index 1)
      await tester.tap(find.text('Art Walk'));
      await tester.pumpAndSettle();

      expect(tappedIndex, 1);
    });

    testWidgets('should not trigger tap for already selected item', (
      tester,
    ) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            bottomNavigationBar: EnhancedBottomNav(
              currentIndex: 0,
              onTap: (index) {
                tapCount++;
              },
            ),
          ),
        ),
      );

      // Tap on already selected Home item
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(tapCount, 0);
    });
  });
}
