import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../lib/src/models/artwork_model.dart' as artwork_model;

void main() {
  group('ArtworkModel Tests', () {
    test('ArtworkModel can be created with valid data', () {
      final artwork = artwork_model.ArtworkModel(
        id: 'test-id',
        userId: 'user-id',
        artistProfileId: 'artist-profile-id',
        title: 'Test Artwork',
        description: 'A test artwork',
        imageUrl: 'https://example.com/image.jpg',
        medium: 'Oil on Canvas',
        styles: ['abstract', 'modern'],
        isForSale: true,
        price: 1000.0,
        tags: ['abstract', 'modern'],
        location: 'New York',
        viewCount: 150,
        engagementStats: EngagementStats(lastUpdated: DateTime.now()),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(artwork.id, 'test-id');
      expect(artwork.title, 'Test Artwork');
      expect(artwork.isForSale, true);
      expect(artwork.price, 1000.0);
      expect(artwork.styles, ['abstract', 'modern']);
    });

    test('ArtworkModel handles null price correctly', () {
      final artwork = artwork_model.ArtworkModel(
        id: 'test-id',
        userId: 'user-id',
        artistProfileId: 'artist-profile-id',
        title: 'Test Artwork',
        description: 'A test artwork',
        imageUrl: 'https://example.com/image.jpg',
        medium: 'Digital',
        styles: ['digital', 'modern'],
        isForSale: false,
        price: null,
        tags: ['digital', 'modern'],
        location: 'Online',
        viewCount: 50,
        engagementStats: EngagementStats(lastUpdated: DateTime.now()),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(artwork.price, null);
      expect(artwork.isForSale, false);
      expect(artwork.styles, ['digital', 'modern']);
    });

    test('ArtworkModel has correct default values', () {
      final now = DateTime.now();
      final artwork = artwork_model.ArtworkModel(
        id: 'test-id',
        userId: 'user-id',
        artistProfileId: 'artist-profile-id',
        title: 'Test Artwork',
        description: 'A test artwork',
        imageUrl: 'https://example.com/image.jpg',
        medium: 'Mixed Media',
        styles: ['contemporary'],
        isForSale: true,
        createdAt: now,
        updatedAt: now,
        engagementStats: EngagementStats(lastUpdated: now),
      );

      expect(artwork.viewCount, 0);
      expect(artwork.isPublic, true);
      expect(artwork.isFeatured, false);
      expect(artwork.moderationStatus,
          artwork_model.ArtworkModerationStatus.approved);
      expect(artwork.flagged, false);
    });
  });

  group('Artwork Discovery Algorithm Tests', () {
    test('ArtworkModel supports discovery features', () {
      final artwork = artwork_model.ArtworkModel(
        id: 'discovery-test',
        userId: 'user-id',
        artistProfileId: 'artist-profile-id',
        title: 'Discovery Test Artwork',
        description: 'Testing discovery algorithms',
        imageUrl: 'https://example.com/discovery.jpg',
        medium: 'Photography',
        styles: ['street', 'documentary'],
        isForSale: true,
        price: 500.0,
        tags: ['urban', 'street photography'],
        location: 'Los Angeles',
        viewCount: 250,
        engagementStats: EngagementStats(
          likeCount: 45,
          commentCount: 12,
          shareCount: 8,
          seenCount: 15,
          lastUpdated: DateTime.now(),
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now(),
      );

      // Test that artwork has all necessary data for discovery algorithms
      expect(artwork.tags, isNotNull);
      expect(artwork.tags!.length, greaterThan(0));
      expect(artwork.styles.length, greaterThan(0));
      expect(artwork.viewCount, greaterThan(0));
      expect(artwork.engagementStats.likeCount, greaterThan(0));
      expect(artwork.location, isNotNull);
    });
  });
}
