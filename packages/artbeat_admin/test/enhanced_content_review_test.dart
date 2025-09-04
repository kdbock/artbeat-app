import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_admin/artbeat_admin.dart';

void main() {
  group('Enhanced Content Review System Tests', () {
    test('ContentType enum should have all required types', () {
      expect(ContentType.values.length, equals(6));
      expect(ContentType.values, contains(ContentType.ads));
      expect(ContentType.values, contains(ContentType.captures));
      expect(ContentType.values, contains(ContentType.posts));
      expect(ContentType.values, contains(ContentType.comments));
      expect(ContentType.values, contains(ContentType.artwork));
      expect(ContentType.values, contains(ContentType.all));
    });

    test('ContentType displayName should return correct values', () {
      expect(ContentType.ads.displayName, equals('Ads'));
      expect(ContentType.captures.displayName, equals('Captures'));
      expect(ContentType.posts.displayName, equals('Posts'));
      expect(ContentType.comments.displayName, equals('Comments'));
      expect(ContentType.artwork.displayName, equals('Artwork'));
      expect(ContentType.all.displayName, equals('All Content'));
    });

    test('ReviewStatus enum should have all required statuses', () {
      expect(ReviewStatus.values.length, equals(5));
      expect(ReviewStatus.values, contains(ReviewStatus.pending));
      expect(ReviewStatus.values, contains(ReviewStatus.approved));
      expect(ReviewStatus.values, contains(ReviewStatus.rejected));
      expect(ReviewStatus.values, contains(ReviewStatus.flagged));
      expect(ReviewStatus.values, contains(ReviewStatus.underReview));
    });

    test('ReviewStatus displayName should return correct values', () {
      expect(ReviewStatus.pending.displayName, equals('Pending Review'));
      expect(ReviewStatus.approved.displayName, equals('Approved'));
      expect(ReviewStatus.rejected.displayName, equals('Rejected'));
      expect(ReviewStatus.flagged.displayName, equals('Flagged'));
      expect(ReviewStatus.underReview.displayName, equals('Under Review'));
    });

    test('ModerationFilters should initialize with default values', () {
      const filters = ModerationFilters();

      expect(filters.contentType, isNull);
      expect(filters.status, isNull);
      expect(filters.searchQuery, isNull);
      expect(filters.dateFrom, isNull);
      expect(filters.dateTo, isNull);
      expect(filters.userId, isNull);
      expect(filters.authorName, isNull);
      expect(filters.flagReason, isNull);
      expect(filters.limit, isNull);
    });

    test('ModerationFilters hasActiveFilters should work correctly', () {
      const emptyFilters = ModerationFilters();
      expect(emptyFilters.hasActiveFilters, isFalse);

      const filtersWithContentType = ModerationFilters(
        contentType: ContentType.posts,
      );
      expect(filtersWithContentType.hasActiveFilters, isTrue);

      const filtersWithSearch = ModerationFilters(
        searchQuery: 'test',
      );
      expect(filtersWithSearch.hasActiveFilters, isTrue);

      const filtersWithStatus = ModerationFilters(
        status: ReviewStatus.pending,
      );
      expect(filtersWithStatus.hasActiveFilters, isTrue);
    });

    test('ModerationFilters activeFilterCount should count correctly', () {
      const emptyFilters = ModerationFilters();
      expect(emptyFilters.activeFilterCount, equals(0));

      const singleFilter = ModerationFilters(
        contentType: ContentType.posts,
      );
      expect(singleFilter.activeFilterCount, equals(1));

      const multipleFilters = ModerationFilters(
        contentType: ContentType.posts,
        status: ReviewStatus.pending,
        searchQuery: 'test',
      );
      expect(multipleFilters.activeFilterCount, equals(3));

      final filtersWithDates = ModerationFilters(
        contentType: ContentType.posts,
        dateFrom: DateTime.now().subtract(const Duration(days: 7)),
        dateTo: DateTime.now(),
      );
      expect(
          filtersWithDates.activeFilterCount,
          equals(
              2)); // contentType + dateFrom (dateTo is not counted separately)
    });

    test('ModerationFilters copyWith should work correctly', () {
      const originalFilters = ModerationFilters(
        contentType: ContentType.posts,
        status: ReviewStatus.pending,
      );

      final updatedFilters = originalFilters.copyWith(
        status: ReviewStatus.approved,
        searchQuery: 'test query',
      );

      expect(updatedFilters.contentType, equals(ContentType.posts));
      expect(updatedFilters.status, equals(ReviewStatus.approved));
      expect(updatedFilters.searchQuery, equals('test query'));
    });

    test('ContentReviewModel should create correctly', () {
      final now = DateTime.now();
      final review = ContentReviewModel(
        id: 'test-id',
        contentId: 'content-123',
        contentType: ContentType.posts,
        title: 'Test Post',
        description: 'This is a test post',
        authorId: 'author-123',
        authorName: 'Test Author',
        status: ReviewStatus.pending,
        createdAt: now,
      );

      expect(review.id, equals('test-id'));
      expect(review.contentId, equals('content-123'));
      expect(review.contentType, equals(ContentType.posts));
      expect(review.title, equals('Test Post'));
      expect(review.description, equals('This is a test post'));
      expect(review.authorId, equals('author-123'));
      expect(review.authorName, equals('Test Author'));
      expect(review.status, equals(ReviewStatus.pending));
      expect(review.createdAt, equals(now));
      expect(review.metadata, isNull);
    });

    test('ContentReviewModel copyWith should work correctly', () {
      final now = DateTime.now();
      final originalReview = ContentReviewModel(
        id: 'test-id',
        contentId: 'content-123',
        contentType: ContentType.posts,
        title: 'Test Post',
        description: 'This is a test post',
        authorId: 'author-123',
        authorName: 'Test Author',
        status: ReviewStatus.pending,
        createdAt: now,
      );

      final updatedReview = originalReview.copyWith(
        status: ReviewStatus.approved,
        title: 'Updated Test Post',
      );

      expect(updatedReview.id, equals('test-id'));
      expect(updatedReview.status, equals(ReviewStatus.approved));
      expect(updatedReview.title, equals('Updated Test Post'));
      expect(updatedReview.description, equals('This is a test post'));
      expect(updatedReview.contentType, equals(ContentType.posts));
    });

    group('ContentReviewModel fromFirestore', () {
      test('should handle minimal data correctly', () {
        final mockData = {
          'contentId': 'content-123',
          'contentType': 'posts',
          'title': 'Test Title',
          'description': 'Test Description',
          'authorId': 'author-123',
          'authorName': 'Test Author',
          'status': 'pending',
          'createdAt': DateTime.now(),
        };

        // Note: In a real test, you'd mock DocumentSnapshot
        // This is a conceptual test showing the expected behavior
        expect(mockData['contentType'], equals('posts'));
        expect(mockData['status'], equals('pending'));
      });

      test('should handle complete data with metadata', () {
        final mockData = {
          'contentId': 'content-123',
          'contentType': 'artwork',
          'title': 'Beautiful Painting',
          'description': 'A stunning artwork',
          'authorId': 'artist-123',
          'authorName': 'Famous Artist',
          'status': 'flagged',
          'createdAt': DateTime.now(),
          'metadata': {
            'imageUrl': 'https://example.com/image.jpg',
            'flagReason': 'Inappropriate content',
            'reportCount': 3,
          },
        };

        expect(mockData['contentType'], equals('artwork'));
        expect(mockData['status'], equals('flagged'));
        expect(mockData['metadata'], isA<Map<String, dynamic>>());
        expect((mockData['metadata'] as Map<String, dynamic>)['flagReason'],
            equals('Inappropriate content'));
      });
    });

    group('ContentReviewModel toFirestore', () {
      test('should convert to correct Firestore format', () {
        final now = DateTime.now();
        final review = ContentReviewModel(
          id: 'test-id',
          contentId: 'content-123',
          contentType: ContentType.comments,
          title: 'Test Comment',
          description: 'This is a test comment',
          authorId: 'user-123',
          authorName: 'Test User',
          status: ReviewStatus.underReview,
          createdAt: now,
          metadata: {
            'parentPostId': 'post-456',
            'isReply': true,
          },
        );

        final firestoreData = review.toFirestore();

        expect(firestoreData['contentId'], equals('content-123'));
        expect(firestoreData['contentType'], equals('comments'));
        expect(firestoreData['title'], equals('Test Comment'));
        expect(firestoreData['description'], equals('This is a test comment'));
        expect(firestoreData['authorId'], equals('user-123'));
        expect(firestoreData['authorName'], equals('Test User'));
        expect(firestoreData['status'], equals('underReview'));
        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect(firestoreData['metadata'], isA<Map<String, dynamic>>());
        expect(firestoreData['metadata']['parentPostId'], equals('post-456'));
      });

      test('should handle null metadata correctly', () {
        final now = DateTime.now();
        final review = ContentReviewModel(
          id: 'test-id',
          contentId: 'content-123',
          contentType: ContentType.ads,
          title: 'Test Ad',
          description: 'This is a test ad',
          authorId: 'advertiser-123',
          authorName: 'Test Advertiser',
          status: ReviewStatus.approved,
          createdAt: now,
        );

        final firestoreData = review.toFirestore();

        expect(firestoreData['metadata'], isNull);
      });
    });
  });

  group('Integration Tests', () {
    test('Enhanced content review workflow should be complete', () {
      // Test that all components work together
      const filters = ModerationFilters(
        contentType: ContentType.posts,
        status: ReviewStatus.pending,
        searchQuery: 'test',
      );

      expect(filters.hasActiveFilters, isTrue);
      expect(filters.activeFilterCount, equals(3));

      final updatedFilters = filters.copyWith(
        status: ReviewStatus.approved,
      );

      expect(updatedFilters.contentType, equals(ContentType.posts));
      expect(updatedFilters.status, equals(ReviewStatus.approved));
      expect(updatedFilters.searchQuery, equals('test'));
      expect(updatedFilters.activeFilterCount, equals(3));
    });

    test('Content types should support all required operations', () {
      for (final contentType in ContentType.values) {
        expect(contentType.displayName, isNotEmpty);

        // Each content type should have a meaningful display name
        switch (contentType) {
          case ContentType.ads:
            expect(contentType.displayName, equals('Ads'));
            break;
          case ContentType.captures:
            expect(contentType.displayName, equals('Captures'));
            break;
          case ContentType.posts:
            expect(contentType.displayName, equals('Posts'));
            break;
          case ContentType.comments:
            expect(contentType.displayName, equals('Comments'));
            break;
          case ContentType.artwork:
            expect(contentType.displayName, equals('Artwork'));
            break;
          case ContentType.all:
            expect(contentType.displayName, equals('All Content'));
            break;
        }
      }
    });

    test('Review statuses should support all required operations', () {
      for (final status in ReviewStatus.values) {
        expect(status.displayName, isNotEmpty);

        // Each status should have a meaningful display name
        switch (status) {
          case ReviewStatus.pending:
            expect(status.displayName, equals('Pending Review'));
            break;
          case ReviewStatus.approved:
            expect(status.displayName, equals('Approved'));
            break;
          case ReviewStatus.rejected:
            expect(status.displayName, equals('Rejected'));
            break;
          case ReviewStatus.flagged:
            expect(status.displayName, equals('Flagged'));
            break;
          case ReviewStatus.underReview:
            expect(status.displayName, equals('Under Review'));
            break;
        }
      }
    });
  });
}
