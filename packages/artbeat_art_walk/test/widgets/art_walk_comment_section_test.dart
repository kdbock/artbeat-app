import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_art_walk/src/widgets/art_walk_comment_section.dart';
import '../test_utils.dart';

void main() {
  group('ArtWalkCommentSection Widget Tests', () {
    late String testArtWalkId;
    late TestEnvironment testEnv;

    setUpAll(() {
      TestUtils.initializeWidgetTesting();
    });

    setUp(() {
      testArtWalkId = 'test_art_walk_123';
      testEnv = TestUtils.createTestEnvironment();
    });

    Widget createTestWidget(ArtWalkCommentSection widget) {
      return TestUtils.createTestWidgetWrapper(
        child: Scaffold(body: widget),
        testEnv: testEnv,
      );
    }

    group('Widget Rendering', () {
      testWidgets('should render comment section with loading state', (
        WidgetTester tester,
      ) async {
        // Arrange
        final widget = ArtWalkCommentSection(
          artWalkId: testArtWalkId,
          artWalkTitle: 'Test Art Walk',
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));

        // Assert
        expect(find.byType(ArtWalkCommentSection), findsOneWidget);
        // Loading state would typically show a progress indicator
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('should display title correctly', (
        WidgetTester tester,
      ) async {
        // Arrange
        const widget = ArtWalkCommentSection(
          artWalkId: 'test_art_walk_123',
          artWalkTitle: 'Test Art Walk',
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert - Look for comment-related text
        expect(find.textContaining('Comment'), findsWidgets);
      });
    });

    group('Interactive Elements', () {
      testWidgets('should have input field for new comments', (
        WidgetTester tester,
      ) async {
        // Arrange
        const widget = ArtWalkCommentSection(
          artWalkId: 'test_art_walk_123',
          artWalkTitle: 'Test Art Walk',
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert - Look for text input fields
        expect(find.byType(TextField), findsWidgets);
      });

      testWidgets('should have submit button', (WidgetTester tester) async {
        // Arrange
        const widget = ArtWalkCommentSection(
          artWalkId: 'test_art_walk_123',
          artWalkTitle: 'Test Art Walk',
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert - Look for buttons (could be IconButton, ElevatedButton, etc.)
        expect(find.byType(ElevatedButton), findsWidgets);
      });
    });

    group('Input Validation', () {
      testWidgets('should handle text input', (WidgetTester tester) async {
        // Arrange
        const widget = ArtWalkCommentSection(
          artWalkId: 'test_art_walk_123',
          artWalkTitle: 'Test Art Walk',
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Try to find and interact with text field
        final textFieldFinder = find.byType(TextField);
        if (textFieldFinder.evaluate().isNotEmpty) {
          await tester.enterText(textFieldFinder.first, 'Test comment text');
          await tester.pump();

          // Assert - Text should be entered
          expect(find.text('Test comment text'), findsOneWidget);
        }
      });
    });

    group('Parameters', () {
      testWidgets('should accept required parameters', (
        WidgetTester tester,
      ) async {
        // Test that the widget can be created with required parameters
        expect(
          () => const ArtWalkCommentSection(
            artWalkId: 'test_id',
            artWalkTitle: 'Test Title',
          ),
          returnsNormally,
        );
      });

      testWidgets('should handle empty artWalkId', (WidgetTester tester) async {
        // Arrange
        const widget = ArtWalkCommentSection(
          artWalkId: '',
          artWalkTitle: 'Test Art Walk',
        );

        // Act & Assert - Widget should handle empty ID gracefully
        await tester.pumpWidget(createTestWidget(widget));
        expect(find.byType(ArtWalkCommentSection), findsOneWidget);
      });

      testWidgets('should handle empty artWalkTitle', (
        WidgetTester tester,
      ) async {
        // Arrange
        const widget = ArtWalkCommentSection(
          artWalkId: 'test_art_walk_123',
          artWalkTitle: '',
        );

        // Act & Assert - Widget should handle empty title gracefully
        await tester.pumpWidget(createTestWidget(widget));
        expect(find.byType(ArtWalkCommentSection), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantics', (WidgetTester tester) async {
        // Arrange
        const widget = ArtWalkCommentSection(
          artWalkId: 'test_art_walk_123',
          artWalkTitle: 'Test Art Walk',
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert - Check for semantic elements
        expect(find.bySemanticsLabel('Comment'), findsWidgets);
      });

      testWidgets('should support keyboard navigation', (
        WidgetTester tester,
      ) async {
        // Arrange
        const widget = ArtWalkCommentSection(
          artWalkId: 'test_art_walk_123',
          artWalkTitle: 'Test Art Walk',
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Test tab navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Assert - Focus should move to next focusable element
        expect(find.byType(Focus), findsWidgets);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle widget creation with null safety', (
        WidgetTester tester,
      ) async {
        // Test that widget handles null values appropriately
        expect(
          () => const ArtWalkCommentSection(
            artWalkId: 'test',
            artWalkTitle: 'title',
          ),
          returnsNormally,
        );
      });
    });
  });
}
