import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_community/models/art_models.dart';
import 'package:artbeat_community/widgets/art_gallery_widgets.dart';

void main() {
  group('Comment Widget Tests', () {
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

    testWidgets('Comment button toggles comment section', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveArtPostCard(post: testPost, onLike: () {}),
          ),
        ),
      );

      // Initially, comment section should not be visible
      expect(find.text('Write a comment...'), findsNothing);

      // Find and tap the comment button
      final commentButton = find.byIcon(Icons.chat_bubble_outline);
      expect(commentButton, findsOneWidget);

      await tester.tap(commentButton);
      await tester.pumpAndSettle();

      // Comment section should now be visible
      expect(find.text('Write a comment...'), findsOneWidget);

      // Comment button icon should change to filled
      expect(find.byIcon(Icons.chat_bubble), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
    });

    testWidgets('Comment input and posting works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveArtPostCard(post: testPost, onLike: () {}),
          ),
        ),
      );

      // Open comment section
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      // Find the comment input field
      final commentField = find.byType(TextField);
      expect(commentField, findsOneWidget);

      // Enter a comment
      await tester.enterText(commentField, 'This is a test comment!');
      await tester.pump();

      // Find and tap the send button
      final sendButton = find.byIcon(Icons.send);
      expect(sendButton, findsOneWidget);

      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Comment should appear in the list
      expect(find.text('This is a test comment!'), findsOneWidget);
      expect(find.text('You'), findsOneWidget); // Username for posted comment

      // Input field should be cleared
      expect(
        find.text('This is a test comment!'),
        findsOneWidget,
      ); // Only in the comment list now
    });

    testWidgets('Mock comments are loaded when section opens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveArtPostCard(post: testPost, onLike: () {}),
          ),
        ),
      );

      // Open comment section
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pump(); // Don't settle yet to see loading state

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Mock comments should be loaded
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Bob Smith'), findsOneWidget);
      expect(
        find.text(
          'This is absolutely beautiful! Love the colors and composition.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Amazing work! What technique did you use for this?'),
        findsOneWidget,
      );
    });

    testWidgets('Comment count updates when new comment is added', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveArtPostCard(post: testPost, onLike: () {}),
          ),
        ),
      );

      // Initially shows the post's comment count
      expect(find.text('2'), findsOneWidget); // Original comment count

      // Open comment section and wait for mock comments to load
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      // Should now show the actual loaded comment count
      expect(find.text('2'), findsOneWidget); // Mock comments count

      // Add a new comment
      await tester.enterText(find.byType(TextField), 'New test comment');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Comment count should update
      expect(find.text('3'), findsOneWidget); // Updated count
    });
  });
}
