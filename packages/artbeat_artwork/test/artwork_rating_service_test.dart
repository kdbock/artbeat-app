import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_artwork/src/models/artwork_rating_model.dart';

void main() {
  group('ArtworkRatingModel Tests', () {
    test('should create ArtworkRatingModel correctly', () {
      // Arrange
      final now = Timestamp.now();

      // Act
      final rating = ArtworkRatingModel(
        id: 'rating_123',
        artworkId: 'artwork_123',
        userId: 'user_123',
        userName: 'Test User',
        userAvatarUrl: 'https://example.com/avatar.jpg',
        rating: 5,
        reviewText: 'Amazing artwork!',
        createdAt: now,
        updatedAt: now,
        isVerifiedPurchaser: true,
        purchaseId: 'purchase_123',
      );

      // Assert
      expect(rating.id, 'rating_123');
      expect(rating.artworkId, 'artwork_123');
      expect(rating.userId, 'user_123');
      expect(rating.userName, 'Test User');
      expect(rating.rating, 5);
      expect(rating.reviewText, 'Amazing artwork!');
      expect(rating.isVerifiedPurchaser, true);
      expect(rating.purchaseId, 'purchase_123');
    });

    test('should create copy with updated values', () {
      // Arrange
      final originalRating = ArtworkRatingModel(
        id: 'rating_123',
        artworkId: 'artwork_123',
        userId: 'user_123',
        userName: 'Test User',
        userAvatarUrl: '',
        rating: 4,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      // Act
      final updatedRating = originalRating.copyWith(
        rating: 5,
        reviewText: 'Updated review!',
      );

      // Assert
      expect(updatedRating.id, originalRating.id);
      expect(updatedRating.rating, 5);
      expect(updatedRating.reviewText, 'Updated review!');
      expect(updatedRating.userName, originalRating.userName); // Unchanged
    });

    test('should convert to and from Firestore correctly', () {
      // Arrange
      final now = Timestamp.now();
      final rating = ArtworkRatingModel(
        id: 'rating_123',
        artworkId: 'artwork_123',
        userId: 'user_123',
        userName: 'Test User',
        userAvatarUrl: '',
        rating: 5,
        reviewText: 'Great!',
        createdAt: now,
        updatedAt: now,
      );

      // Act - Convert to Firestore
      final firestoreData = rating.toFirestore();

      // Assert - Check Firestore data
      expect(firestoreData['artworkId'], 'artwork_123');
      expect(firestoreData['userId'], 'user_123');
      expect(firestoreData['rating'], 5);
      expect(firestoreData['reviewText'], 'Great!');

      // Note: Cannot test fromFirestore without a DocumentSnapshot mock
    });

    test('should handle equality correctly', () {
      // Arrange
      final rating1 = ArtworkRatingModel(
        id: 'rating_123',
        artworkId: 'artwork_123',
        userId: 'user_123',
        userName: 'Test User',
        userAvatarUrl: '',
        rating: 5,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      final rating2 = ArtworkRatingModel(
        id: 'rating_123',
        artworkId: 'different_artwork',
        userId: 'different_user',
        userName: 'Different User',
        userAvatarUrl: '',
        rating: 3,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      final rating3 = ArtworkRatingModel(
        id: 'different_rating',
        artworkId: 'artwork_123',
        userId: 'user_123',
        userName: 'Test User',
        userAvatarUrl: '',
        rating: 5,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      // Act & Assert
      expect(rating1 == rating2, true); // Same ID
      expect(rating1 == rating3, false); // Different ID
      expect(rating1.hashCode, rating2.hashCode); // Same hash for same ID
    });
  });

  group('ArtworkRatingStats Tests', () {
    test('should create empty stats correctly', () {
      // Act
      final stats = ArtworkRatingStats.empty();

      // Assert
      expect(stats.averageRating, 0.0);
      expect(stats.totalRatings, 0);
      expect(stats.ratingDistribution[1], 0);
      expect(stats.ratingDistribution[2], 0);
      expect(stats.ratingDistribution[3], 0);
      expect(stats.ratingDistribution[4], 0);
      expect(stats.ratingDistribution[5], 0);
      expect(stats.oneStarCount, 0);
      expect(stats.fiveStarCount, 0);
    });

    test('should calculate stats from ratings list correctly', () {
      // Arrange
      final now = Timestamp.now();
      final ratings = [
        ArtworkRatingModel(
          id: '1',
          artworkId: 'art1',
          userId: 'user1',
          userName: 'User 1',
          userAvatarUrl: '',
          rating: 5,
          createdAt: now,
          updatedAt: now,
        ),
        ArtworkRatingModel(
          id: '2',
          artworkId: 'art1',
          userId: 'user2',
          userName: 'User 2',
          userAvatarUrl: '',
          rating: 4,
          createdAt: now,
          updatedAt: now,
        ),
        ArtworkRatingModel(
          id: '3',
          artworkId: 'art1',
          userId: 'user3',
          userName: 'User 3',
          userAvatarUrl: '',
          rating: 5,
          createdAt: now,
          updatedAt: now,
        ),
        ArtworkRatingModel(
          id: '4',
          artworkId: 'art1',
          userId: 'user4',
          userName: 'User 4',
          userAvatarUrl: '',
          rating: 3,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Act
      final stats = ArtworkRatingStats.fromRatings(ratings);

      // Assert
      expect(stats.totalRatings, 4);
      expect(stats.averageRating, 4.25); // (5+4+5+3)/4 = 4.25
      expect(stats.fiveStarCount, 2);
      expect(stats.fourStarCount, 1);
      expect(stats.threeStarCount, 1);
      expect(stats.twoStarCount, 0);
      expect(stats.oneStarCount, 0);
      expect(stats.ratingDistribution[5], 2);
      expect(stats.ratingDistribution[4], 1);
      expect(stats.ratingDistribution[3], 1);
    });

    test('should handle empty ratings list', () {
      // Act
      final stats = ArtworkRatingStats.fromRatings([]);

      // Assert
      expect(stats.averageRating, 0.0);
      expect(stats.totalRatings, 0);
      expect(stats.fiveStarCount, 0);
    });

    test('should calculate single rating correctly', () {
      // Arrange
      final rating = ArtworkRatingModel(
        id: '1',
        artworkId: 'art1',
        userId: 'user1',
        userName: 'User 1',
        userAvatarUrl: '',
        rating: 3,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      // Act
      final stats = ArtworkRatingStats.fromRatings([rating]);

      // Assert
      expect(stats.totalRatings, 1);
      expect(stats.averageRating, 3.0);
      expect(stats.threeStarCount, 1);
      expect(stats.oneStarCount, 0);
      expect(stats.fiveStarCount, 0);
    });
  });
}
