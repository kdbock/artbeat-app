import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';

// Simple test implementation of ContentEngagementService
class TestContentEngagementService extends ChangeNotifier
    implements ContentEngagementService {
  @override
  Future<bool> hasUserEngaged({
    required String contentId,
    required EngagementType engagementType,
    String? userId,
  }) async {
    return false; // Always return false for tests
  }

  @override
  Future<bool> toggleEngagement({
    required String contentId,
    required String contentType,
    required EngagementType engagementType,
    Map<String, dynamic>? metadata,
  }) async {
    return true; // Always return true for tests
  }

  // Minimal implementations for other required methods
  @override
  Future<EngagementStats> getEngagementStats({
    required String contentId,
    required String contentType,
  }) async {
    return EngagementStats(lastUpdated: DateTime.now());
  }

  @override
  Future<List<EngagementModel>> getEngagements({
    required String contentId,
    required EngagementType engagementType,
    int limit = 50,
  }) async {
    return [];
  }

  @override
  Future<void> trackSeenEngagement({
    required String contentId,
    required String contentType,
  }) async {
    // Do nothing in tests
  }

  @override
  Future<List<String>> getUserFollowers(String userId) async {
    return [];
  }

  @override
  Future<List<String>> getUserFollowing(String userId) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getRatings({
    required String contentId,
    required String contentType,
  }) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getReviews({
    required String contentId,
    required String contentType,
  }) async {
    return [];
  }

  @override
  Future<double> getAverageRating({
    required String contentId,
    required String contentType,
  }) async {
    return 0.0;
  }

  @override
  Future<bool> likeContent(String contentId, String contentType) async {
    return true;
  }

  @override
  Future<bool> unlikeContent(String contentId, String contentType) async {
    return true;
  }

  @override
  Future<String> addComment({
    required String contentId,
    required String contentType,
    required String comment,
    String? parentCommentId,
    Map<String, dynamic>? metadata,
  }) async {
    return 'test-comment-id';
  }

  @override
  Future<bool> shareContent({
    required String contentId,
    required String contentType,
    String? platform,
    String? message,
    Map<String, dynamic>? metadata,
  }) async {
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> getComments({
    required String contentId,
    required String contentType,
    String? parentCommentId,
    int limit = 50,
  }) async {
    return [];
  }

  @override
  Future<bool> deleteComment(String commentId) async {
    return true;
  }

  @override
  Future<bool> hasUserLiked(String contentId, String contentType) async {
    return false;
  }

  @override
  Future<Map<String, bool>> getUserEngagementStatus({
    required String contentId,
    required String contentType,
  }) async {
    return {};
  }
}

void main() {
  late TestContentEngagementService testEngagementService;

  setUp(() {
    testEngagementService = TestContentEngagementService();
  });

  group('UniversalContentCard', () {
    testWidgets('displays basic content correctly', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testTitle = 'Test Art Piece';
      const testAuthor = 'Test Artist';
      final testDate = DateTime.now();

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ContentEngagementService>.value(
              value: testEngagementService,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: UniversalContentCard(
                contentId: 'test-id',
                contentType: 'artwork',
                title: testTitle,
                authorName: testAuthor,
                createdAt: testDate,
                engagementStats: EngagementStats(lastUpdated: DateTime.now()),
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(testTitle), findsOneWidget);
      expect(find.text(testAuthor), findsOneWidget);
      expect(find.byType(UniversalContentCard), findsOneWidget);
    });

    testWidgets('handles tap interaction', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ContentEngagementService>.value(
              value: testEngagementService,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: UniversalContentCard(
                contentId: 'test-id',
                contentType: 'artwork',
                title: 'Test Title',
                authorName: 'Test Author',
                createdAt: DateTime.now(),
                engagementStats: EngagementStats(lastUpdated: DateTime.now()),
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(UniversalContentCard));
      await tester.pump();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('displays without image when not provided', (
      WidgetTester tester,
    ) async {
      // Arrange - Test without imageUrl to avoid cache manager issues

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ContentEngagementService>.value(
              value: testEngagementService,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: UniversalContentCard(
                contentId: 'test-id',
                contentType: 'artwork',
                title: 'Test Title',
                authorName: 'Test Author',
                createdAt: DateTime.now(),
                engagementStats: EngagementStats(lastUpdated: DateTime.now()),
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Author'), findsOneWidget);
      expect(find.byType(UniversalContentCard), findsOneWidget);
    });
  });
}
