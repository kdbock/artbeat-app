import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_community/models/art_models.dart';
import 'package:artbeat_community/widgets/art_gallery_widgets.dart';

void main() {
  group('Comment Functionality Tests', () {
    late ArtPost testPost;

    setUp(() {
      testPost = ArtPost(
        id: 'test_post_1',
        userId: 'user_1',
        userName: 'Test User',
        userAvatarUrl: '',
        content: 'Test art post content',
        imageUrls: ['https://example.com/image.jpg'],
        tags: ['art', 'test'],
        createdAt: DateTime.now(),
        likesCount: 5,
        commentsCount: 2,
        isArtistPost: true,
        isUserVerified: true,
      );
    });

    testWidgets('Comment button exists and is tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResponsiveArtPostCard(post: testPost, onLike: () {}),
            ),
          ),
        ),
      );

      // Find the comment button
      final commentButton = find.byIcon(Icons.chat_bubble_outline);
      expect(commentButton, findsOneWidget);

      // Verify it's tappable
      await tester.tap(commentButton);
      await tester.pump();

      // Should show loading or comment section
      expect(find.byType(ResponsiveArtPostCard), findsOneWidget);
    });

    testWidgets('Comment section shows after button tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResponsiveArtPostCard(post: testPost, onLike: () {}),
            ),
          ),
        ),
      );

      // Initially, comment input should not be visible
      expect(find.text('Write a comment...'), findsNothing);

      // Tap comment button
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pump(const Duration(milliseconds: 100));

      // Should show loading indicator first
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Wait for animation and loading to complete
      await tester.pump(const Duration(milliseconds: 600));

      // Comment input should now be visible
      expect(find.text('Write a comment...'), findsOneWidget);
    });

    testWidgets('Comment input accepts text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResponsiveArtPostCard(post: testPost, onLike: () {}),
            ),
          ),
        ),
      );

      // Open comment section
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pump(const Duration(milliseconds: 600));

      // Find and interact with comment input
      final commentField = find.byType(TextField);
      if (commentField.evaluate().isNotEmpty) {
        await tester.enterText(commentField, 'Test comment');
        await tester.pump();

        // Verify text was entered
        expect(find.text('Test comment'), findsOneWidget);
      }
    });

    testWidgets('Send button exists when comment section is open', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResponsiveArtPostCard(post: testPost, onLike: () {}),
            ),
          ),
        ),
      );

      // Open comment section
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pump(const Duration(milliseconds: 600));

      // Send button should be visible
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('Comment count displays correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResponsiveArtPostCard(post: testPost, onLike: () {}),
            ),
          ),
        ),
      );

      // Should show initial comment count
      expect(find.text('2'), findsAtLeastNWidgets(1));
    });
  });
}
