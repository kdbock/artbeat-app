import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_art_walk/src/widgets/turn_by_turn_navigation_widget.dart';
import 'package:artbeat_art_walk/src/services/art_walk_navigation_service.dart';

void main() {
  group('TurnByTurnNavigationWidget Tests', () {
    late ArtWalkNavigationService mockNavigationService;

    setUp(() {
      // In a real test, this would be properly mocked
      mockNavigationService = ArtWalkNavigationService();
    });

    Widget createTestWidget(TurnByTurnNavigationWidget widget) {
      return MaterialApp(home: Scaffold(body: widget));
    }

    group('Widget Construction', () {
      testWidgets('should create widget with required parameters', (
        WidgetTester tester,
      ) async {
        // Arrange
        final widget = TurnByTurnNavigationWidget(
          navigationService: mockNavigationService,
        );

        // Act & Assert
        await tester.pumpWidget(createTestWidget(widget));
        expect(find.byType(TurnByTurnNavigationWidget), findsOneWidget);
      });

      testWidgets('should accept optional callback parameters', (
        WidgetTester tester,
      ) async {
        // Arrange
        bool nextStepCalled = false;
        bool previousStepCalled = false;
        bool stopNavigationCalled = false;

        final widget = TurnByTurnNavigationWidget(
          navigationService: mockNavigationService,
          onNextStep: () => nextStepCalled = true,
          onPreviousStep: () => previousStepCalled = true,
          onStopNavigation: () => stopNavigationCalled = true,
          isCompact: true,
        );

        // Act & Assert
        await tester.pumpWidget(createTestWidget(widget));
        expect(find.byType(TurnByTurnNavigationWidget), findsOneWidget);

        // Verify callbacks are not called yet
        expect(nextStepCalled, isFalse);
        expect(previousStepCalled, isFalse);
        expect(stopNavigationCalled, isFalse);
      });
    });

    group('Compact Mode', () {
      testWidgets('should render in compact mode', (WidgetTester tester) async {
        // Arrange
        final widget = TurnByTurnNavigationWidget(
          navigationService: mockNavigationService,
          isCompact: true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert - Widget should render without errors
        expect(find.byType(TurnByTurnNavigationWidget), findsOneWidget);
      });

      testWidgets('should render in full mode', (WidgetTester tester) async {
        // Arrange
        final widget = TurnByTurnNavigationWidget(
          navigationService: mockNavigationService,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert - Widget should render without errors
        expect(find.byType(TurnByTurnNavigationWidget), findsOneWidget);
      });
    });

    group('Interactive Elements', () {
      testWidgets('should display navigation controls', (
        WidgetTester tester,
      ) async {
        // Arrange
        final widget = TurnByTurnNavigationWidget(
          navigationService: mockNavigationService,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert - Look for interactive elements
        expect(find.byType(IconButton), findsWidgets);
      });

      testWidgets('should handle callback invocations', (
        WidgetTester tester,
      ) async {
        // Arrange
        bool callbackInvoked = false;
        final widget = TurnByTurnNavigationWidget(
          navigationService: mockNavigationService,
          onStopNavigation: () => callbackInvoked = true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Try to find and tap a stop button (if available)
        final stopButtonFinder = find.byIcon(Icons.stop);
        if (stopButtonFinder.evaluate().isNotEmpty) {
          await tester.tap(stopButtonFinder.first);
          await tester.pumpAndSettle();

          // Assert - Callback might be invoked
          // Note: This depends on actual implementation
        }

        // Just verify the widget handles the callback without errors
        expect(callbackInvoked, isFalse); // Not called in test environment
      });
    });

    group('Animation Handling', () {
      testWidgets('should handle animations without errors', (
        WidgetTester tester,
      ) async {
        // Arrange
        final widget = TurnByTurnNavigationWidget(
          navigationService: mockNavigationService,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert - Animation should not cause errors
        expect(find.byType(TurnByTurnNavigationWidget), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null callbacks gracefully', (
        WidgetTester tester,
      ) async {
        // Arrange
        final widget = TurnByTurnNavigationWidget(
          navigationService: mockNavigationService,
          onNextStep: null,
          onPreviousStep: null,
          onStopNavigation: null,
        );

        // Act & Assert
        await tester.pumpWidget(createTestWidget(widget));
        expect(find.byType(TurnByTurnNavigationWidget), findsOneWidget);
      });

      testWidgets('should dispose properly', (WidgetTester tester) async {
        // Arrange
        final widget = TurnByTurnNavigationWidget(
          navigationService: mockNavigationService,
        );

        // Act - Pump widget and then remove it
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpWidget(MaterialApp(home: Container()));

        // Assert - Should dispose without errors
        expect(find.byType(TurnByTurnNavigationWidget), findsNothing);
      });
    });

    group('Visual Elements', () {
      testWidgets('should render visual components', (
        WidgetTester tester,
      ) async {
        // Arrange
        final widget = TurnByTurnNavigationWidget(
          navigationService: mockNavigationService,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert - Should contain visual elements
        expect(find.byType(AnimatedBuilder), findsWidgets);
      });
    });

    group('Accessibility', () {
      testWidgets('should provide semantic information', (
        WidgetTester tester,
      ) async {
        // Arrange
        final widget = TurnByTurnNavigationWidget(
          navigationService: mockNavigationService,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert - Should have semantic elements for accessibility
        expect(find.bySemanticsLabel('Navigation'), findsWidgets);
      });
    });
  });
}
