import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_artwork/src/models/artwork_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('ArtworkModel Tests', () {
    test('should create ArtworkModel with required fields', () {
      // Arrange
      final now = DateTime.now();

      // Act
      final artwork = ArtworkModel(
        id: 'artwork-1',
        userId: 'user-1',
        artistProfileId: 'artist-profile-1',
        title: 'Beautiful Painting',
        description: 'A beautiful painting',
        imageUrl: 'https://example.com/artwork.jpg',
        medium: 'Oil on canvas',
        styles: ['Abstract', 'Modern'],
        isForSale: true,
        createdAt: now,
        updatedAt: now,
      );

      // Assert
      expect(artwork.id, equals('artwork-1'));
      expect(artwork.userId, equals('user-1'));
      expect(artwork.artistProfileId, equals('artist-profile-1'));
      expect(artwork.title, equals('Beautiful Painting'));
      expect(artwork.description, equals('A beautiful painting'));
      expect(artwork.imageUrl, equals('https://example.com/artwork.jpg'));
      expect(artwork.medium, equals('Oil on canvas'));
      expect(artwork.styles, equals(['Abstract', 'Modern']));
      expect(artwork.isForSale, isTrue);
      expect(artwork.createdAt, equals(now));
      expect(artwork.updatedAt, equals(now));
      // Test default values
      expect(artwork.additionalImageUrls, isEmpty);
      expect(artwork.videoUrls, isEmpty);
      expect(artwork.audioUrls, isEmpty);
      expect(artwork.isSold, isFalse);
      expect(artwork.isFeatured, isFalse);
      expect(artwork.isPublic, isTrue);
      expect(artwork.viewCount, equals(0));
      expect(artwork.likeCount, equals(0));
      expect(artwork.commentCount, equals(0));
    });

    test('should create ArtworkModel with all optional fields', () {
      // Arrange
      final createdAt = DateTime.now().subtract(const Duration(days: 7));
      final updatedAt = DateTime.now();
      final tags = ['abstract', 'modern', 'colorful'];

      // Act
      final artwork = ArtworkModel(
        id: 'artwork-1',
        userId: 'user-1',
        artistProfileId: 'artist-profile-1',
        title: 'Complex Artwork',
        description: 'A complex artwork with multiple elements',
        imageUrl: 'https://example.com/artwork.jpg',
        additionalImageUrls: [
          'https://example.com/art2.jpg',
          'https://example.com/art3.jpg'
        ],
        videoUrls: ['https://example.com/video1.mp4'],
        audioUrls: ['https://example.com/audio1.mp3'],
        medium: 'Oil on canvas',
        styles: ['Abstract', 'Modern'],
        dimensions: '100 x 80 x 5 cm',
        materials: 'Canvas, Oil Paint, Wood Frame',
        location: 'New York, NY',
        tags: tags,
        hashtags: ['#art', '#painting'],
        keywords: ['abstract', 'colorful', 'modern'],
        price: 2500.0,
        isForSale: false,
        isSold: false,
        yearCreated: 2023,
        commissionRate: 15.0,
        isFeatured: true,
        isPublic: true,
        externalLink: 'https://artist-website.com/artwork',
        viewCount: 1200,
        likeCount: 150,
        commentCount: 25,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      // Assert
      expect(artwork.id, equals('artwork-1'));
      expect(artwork.title, equals('Complex Artwork'));
      expect(artwork.additionalImageUrls.length, equals(2));
      expect(artwork.videoUrls.length, equals(1));
      expect(artwork.audioUrls.length, equals(1));
      expect(artwork.tags, equals(tags));
      expect(artwork.hashtags, equals(['#art', '#painting']));
      expect(artwork.keywords, equals(['abstract', 'colorful', 'modern']));
      expect(artwork.dimensions, equals('100 x 80 x 5 cm'));
      expect(artwork.materials, equals('Canvas, Oil Paint, Wood Frame'));
      expect(artwork.medium, equals('Oil on canvas'));
      expect(artwork.yearCreated, equals(2023));
      expect(artwork.location, equals('New York, NY'));
      expect(artwork.price, equals(2500.0));
      expect(artwork.commissionRate, equals(15.0));
      expect(artwork.isForSale, isFalse);
      expect(artwork.isFeatured, isTrue);
      expect(artwork.isPublic, isTrue);
      expect(artwork.isSold, isFalse);
      expect(
          artwork.externalLink, equals('https://artist-website.com/artwork'));
      expect(artwork.likeCount, equals(150));
      expect(artwork.viewCount, equals(1200));
      expect(artwork.commentCount, equals(25));
      expect(artwork.createdAt, equals(createdAt));
      expect(artwork.updatedAt, equals(updatedAt));
    });

    test('should convert ArtworkModel to Firestore data', () {
      // Arrange
      final now = DateTime.now();
      final artwork = ArtworkModel(
        id: 'artwork-1',
        userId: 'user-1',
        artistProfileId: 'artist-profile-1',
        title: 'Test Artwork',
        description: 'Test description',
        imageUrl: 'https://example.com/artwork.jpg',
        medium: 'Oil on canvas',
        styles: ['Abstract'],
        tags: ['test', 'artwork'],
        price: 500.0,
        isForSale: true,
        isFeatured: false,
        createdAt: now,
        updatedAt: now,
      );

      // Act
      final data = artwork.toFirestore();

      // Assert
      expect(data['userId'], equals('user-1'));
      expect(data['artistProfileId'], equals('artist-profile-1'));
      expect(data['title'], equals('Test Artwork'));
      expect(data['description'], equals('Test description'));
      expect(data['imageUrl'], equals('https://example.com/artwork.jpg'));
      expect(data['medium'], equals('Oil on canvas'));
      expect(data['styles'], equals(['Abstract']));
      expect(data['tags'], equals(['test', 'artwork']));
      expect(data['price'], equals(500.0));
      expect(data['isForSale'], isTrue);
      expect(data['isFeatured'], isFalse);
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('should create copy of ArtworkModel with updated fields', () {
      // Arrange
      final now = DateTime.now();
      final originalArtwork = ArtworkModel(
        id: 'artwork-1',
        userId: 'user-1',
        artistProfileId: 'artist-profile-1',
        title: 'Original Title',
        description: 'Original description',
        imageUrl: 'https://example.com/original.jpg',
        medium: 'Oil on canvas',
        styles: ['Abstract'],
        price: 100.0,
        isForSale: true,
        likeCount: 10,
        viewCount: 50,
        createdAt: now,
        updatedAt: now,
      );

      // Act
      final updatedArtwork = originalArtwork.copyWith(
        title: 'Updated Title',
        description: 'Updated description',
        price: 200.0,
        likeCount: 20,
        viewCount: 100,
      );

      // Assert
      expect(updatedArtwork.id, equals('artwork-1')); // Unchanged
      expect(updatedArtwork.userId, equals('user-1')); // Unchanged
      expect(updatedArtwork.artistProfileId,
          equals('artist-profile-1')); // Unchanged
      expect(updatedArtwork.title, equals('Updated Title')); // Changed
      expect(
          updatedArtwork.description, equals('Updated description')); // Changed
      expect(updatedArtwork.price, equals(200.0)); // Changed
      expect(updatedArtwork.likeCount, equals(20)); // Changed
      expect(updatedArtwork.viewCount, equals(100)); // Changed
      expect(updatedArtwork.medium, equals('Oil on canvas')); // Unchanged
      expect(updatedArtwork.styles, equals(['Abstract'])); // Unchanged
    });

    test('should maintain consistent property values', () {
      // Arrange
      final now = DateTime.now();

      final artwork = ArtworkModel(
        id: 'artwork-1',
        userId: 'user-1',
        artistProfileId: 'artist-profile-1',
        title: 'Test Artwork',
        description: 'Testing property consistency',
        imageUrl: 'https://example.com/artwork.jpg',
        medium: 'Oil on canvas',
        styles: ['Abstract', 'Modern'],
        tags: ['test', 'consistent'],
        isForSale: true,
        createdAt: now,
        updatedAt: now,
      );

      // Assert - Properties should have expected values
      expect(artwork.styles, equals(['Abstract', 'Modern']));
      expect(artwork.tags, equals(['test', 'consistent']));
      expect(artwork.title, equals('Test Artwork'));
      expect(artwork.isForSale, isTrue);
    });

    test(
        'should protect against external list modification (defensive copying)',
        () {
      // Arrange - Create mutable lists that we'll try to modify later
      final originalStyles = ['Abstract', 'Modern'];
      final originalTags = ['test', 'painting'];
      final originalImageUrls = ['https://example.com/image1.jpg'];
      final now = DateTime.now();

      // Create artwork with these lists
      final artwork = ArtworkModel(
        id: 'artwork-1',
        userId: 'user-1',
        artistProfileId: 'artist-profile-1',
        title: 'Protected Artwork',
        description: 'Testing defensive copying',
        imageUrl: 'https://example.com/artwork.jpg',
        medium: 'Oil on canvas',
        styles: originalStyles,
        tags: originalTags,
        additionalImageUrls: originalImageUrls,
        isForSale: true,
        createdAt: now,
        updatedAt: now,
      );

      // Record what the artwork contained originally
      final expectedStyles = ['Abstract', 'Modern'];
      final expectedTags = ['test', 'painting'];
      final expectedImageUrls = ['https://example.com/image1.jpg'];

      // Act - Try to modify the original lists (this should NOT affect the artwork)
      originalStyles.add('Contemporary');
      originalStyles.clear();
      originalTags.add('sculpture');
      originalImageUrls.add('https://example.com/image2.jpg');

      // Assert - The artwork's data should be unchanged
      expect(artwork.styles, equals(expectedStyles),
          reason: 'Styles should not change when original list is modified');
      expect(artwork.tags, equals(expectedTags),
          reason: 'Tags should not change when original list is modified');
      expect(artwork.additionalImageUrls, equals(expectedImageUrls),
          reason:
              'Image URLs should not change when original list is modified');

      // Verify the original lists were actually modified (proves our test is valid)
      expect(originalStyles, isEmpty,
          reason: 'Original styles list should be empty (we cleared it)');
      expect(originalTags, equals(['test', 'painting', 'sculpture']),
          reason: 'Original tags should have the new item we added');
      expect(originalImageUrls, hasLength(2),
          reason: 'Original image URLs should have 2 items now');
    });

    test('should create unmodifiable lists (cannot modify artwork data)', () {
      // Arrange
      final now = DateTime.now();
      final artwork = ArtworkModel(
        id: 'artwork-1',
        userId: 'user-1',
        artistProfileId: 'artist-profile-1',
        title: 'Immutable Artwork',
        description: 'Testing immutability',
        imageUrl: 'https://example.com/artwork.jpg',
        medium: 'Oil on canvas',
        styles: ['Abstract'],
        tags: ['test'],
        isForSale: true,
        createdAt: now,
        updatedAt: now,
      );

      // Act & Assert - Trying to modify the artwork's lists should throw errors
      expect(
        () => artwork.styles.add('NewStyle'),
        throwsA(isA<UnsupportedError>()),
        reason: 'Should not be able to modify styles list',
      );

      expect(
        () => artwork.tags?.add('new-tag'),
        throwsA(isA<UnsupportedError>()),
        reason: 'Should not be able to modify tags list',
      );

      expect(
        () => artwork.additionalImageUrls.add('new-url'),
        throwsA(isA<UnsupportedError>()),
        reason: 'Should not be able to modify additional image URLs list',
      );
    });
  });
}
