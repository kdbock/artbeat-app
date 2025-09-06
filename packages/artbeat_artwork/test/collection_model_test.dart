import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_artwork/src/models/collection_model.dart';

void main() {
  group('CollectionModel', () {
    test('should create CollectionModel with required properties', () {
      final now = DateTime.now();
      final collection = CollectionModel(
        id: 'test_id',
        userId: 'user_123',
        artistProfileId: 'artist_456',
        title: 'Test Collection',
        description: 'A test collection',
        artworkIds: ['artwork1', 'artwork2'],
        tags: ['test', 'collection'],
        type: CollectionType.personal,
        visibility: CollectionVisibility.public,
        createdAt: now,
        updatedAt: now,
      );

      expect(collection.id, 'test_id');
      expect(collection.userId, 'user_123');
      expect(collection.artistProfileId, 'artist_456');
      expect(collection.title, 'Test Collection');
      expect(collection.description, 'A test collection');
      expect(collection.artworkIds, ['artwork1', 'artwork2']);
      expect(collection.tags, ['test', 'collection']);
      expect(collection.type, CollectionType.personal);
      expect(collection.visibility, CollectionVisibility.public);
      expect(collection.createdAt, now);
      expect(collection.updatedAt, now);
      expect(collection.viewCount, 0);
      expect(collection.isFeatured, false);
      expect(collection.isPortfolio, false);
      expect(collection.sortOrder, 0);
      expect(collection.metadata, <String, dynamic>{});
    });

    test('should create CollectionModel with optional properties', () {
      final now = DateTime.now();
      final collection = CollectionModel(
        id: 'test_id',
        userId: 'user_123',
        artistProfileId: 'artist_456',
        title: 'Portfolio Collection',
        description: 'My main portfolio',
        coverImageUrl: 'https://example.com/cover.jpg',
        artworkIds: ['artwork1', 'artwork2', 'artwork3'],
        tags: ['portfolio', 'best'],
        type: CollectionType.portfolio,
        visibility: CollectionVisibility.public,
        createdAt: now,
        updatedAt: now,
        viewCount: 100,
        isFeatured: true,
        isPortfolio: true,
        sortOrder: 1,
        metadata: {'featured_at': '2025-09-01'},
      );

      expect(collection.coverImageUrl, 'https://example.com/cover.jpg');
      expect(collection.viewCount, 100);
      expect(collection.isFeatured, true);
      expect(collection.isPortfolio, true);
      expect(collection.sortOrder, 1);
      expect(collection.metadata, {'featured_at': '2025-09-01'});
    });

    test('should implement copyWith correctly', () {
      final original = CollectionModel(
        id: 'test_id',
        userId: 'user_123',
        artistProfileId: 'artist_456',
        title: 'Original Title',
        description: 'Original description',
        artworkIds: ['artwork1'],
        tags: ['original'],
        type: CollectionType.personal,
        visibility: CollectionVisibility.private,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        viewCount: 50,
        isFeatured: true,
      );

      expect(updated.id, 'test_id'); // unchanged
      expect(updated.userId, 'user_123'); // unchanged
      expect(updated.title, 'Updated Title'); // changed
      expect(updated.description, 'Original description'); // unchanged
      expect(updated.viewCount, 50); // changed
      expect(updated.isFeatured, true); // changed
      expect(updated.type, CollectionType.personal); // unchanged
    });

    test('should convert to Firestore document correctly', () {
      final now = DateTime.now();
      final collection = CollectionModel(
        id: 'test_id',
        userId: 'user_123',
        artistProfileId: 'artist_456',
        title: 'Test Collection',
        description: 'A test collection',
        coverImageUrl: 'https://example.com/cover.jpg',
        artworkIds: ['artwork1', 'artwork2'],
        tags: ['test', 'collection'],
        type: CollectionType.portfolio,
        visibility: CollectionVisibility.public,
        createdAt: now,
        updatedAt: now,
        viewCount: 42,
        isFeatured: true,
        isPortfolio: true,
        sortOrder: 2,
        metadata: {'custom': 'data'},
      );

      final firestoreData = collection.toFirestore();

      expect(firestoreData['userId'], 'user_123');
      expect(firestoreData['artistProfileId'], 'artist_456');
      expect(firestoreData['title'], 'Test Collection');
      expect(firestoreData['description'], 'A test collection');
      expect(firestoreData['coverImageUrl'], 'https://example.com/cover.jpg');
      expect(firestoreData['artworkIds'], ['artwork1', 'artwork2']);
      expect(firestoreData['tags'], ['test', 'collection']);
      expect(firestoreData['type'], 'portfolio');
      expect(firestoreData['visibility'], 'public');
      expect(firestoreData['createdAt'], isA<Timestamp>());
      expect(firestoreData['updatedAt'], isA<Timestamp>());
      expect(firestoreData['viewCount'], 42);
      expect(firestoreData['isFeatured'], true);
      expect(firestoreData['isPortfolio'], true);
      expect(firestoreData['sortOrder'], 2);
      expect(firestoreData['metadata'], {'custom': 'data'});
    });

    test('should implement equality correctly', () {
      final collection1 = CollectionModel(
        id: 'test_id',
        userId: 'user_123',
        artistProfileId: 'artist_456',
        title: 'Test Collection',
        description: 'A test collection',
        artworkIds: ['artwork1'],
        tags: ['test'],
        type: CollectionType.personal,
        visibility: CollectionVisibility.public,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final collection2 = CollectionModel(
        id: 'test_id', // Same ID
        userId: 'different_user',
        artistProfileId: 'different_artist',
        title: 'Different Title',
        description: 'Different description',
        artworkIds: ['different_artwork'],
        tags: ['different'],
        type: CollectionType.curated,
        visibility: CollectionVisibility.private,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final collection3 = CollectionModel(
        id: 'different_id', // Different ID
        userId: 'user_123',
        artistProfileId: 'artist_456',
        title: 'Test Collection',
        description: 'A test collection',
        artworkIds: ['artwork1'],
        tags: ['test'],
        type: CollectionType.personal,
        visibility: CollectionVisibility.public,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(collection1, equals(collection2)); // Same ID
      expect(collection1, isNot(equals(collection3))); // Different ID
      expect(collection1.hashCode, equals(collection2.hashCode)); // Same hash
      expect(collection1.hashCode,
          isNot(equals(collection3.hashCode))); // Different hash
    });

    test('should provide meaningful toString', () {
      final collection = CollectionModel(
        id: 'test_id',
        userId: 'user_123',
        artistProfileId: 'artist_456',
        title: 'My Portfolio',
        description: 'Best works',
        artworkIds: ['artwork1', 'artwork2', 'artwork3'],
        tags: ['portfolio'],
        type: CollectionType.portfolio,
        visibility: CollectionVisibility.public,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final string = collection.toString();

      expect(string, contains('test_id'));
      expect(string, contains('My Portfolio'));
      expect(string, contains('portfolio'));
      expect(string, contains('3')); // artwork count
    });
  });

  group('CollectionType', () {
    test('should provide correct display names', () {
      expect(CollectionType.personal.displayName, 'Personal Collection');
      expect(CollectionType.portfolio.displayName, 'Portfolio');
      expect(CollectionType.curated.displayName, 'Curated Gallery');
      expect(CollectionType.exhibition.displayName, 'Virtual Exhibition');
      expect(CollectionType.series.displayName, 'Artwork Series');
      expect(
          CollectionType.collaborative.displayName, 'Collaborative Collection');
    });

    test('should provide correct descriptions', () {
      expect(CollectionType.personal.description,
          'Your personal artwork collection');
      expect(CollectionType.portfolio.description, 'Showcase your best work');
      expect(CollectionType.curated.description, 'Curated by gallery or admin');
      expect(
          CollectionType.exhibition.description, 'Virtual gallery exhibition');
      expect(CollectionType.series.description, 'Related artworks in a series');
      expect(CollectionType.collaborative.description,
          'Multiple artists collaboration');
    });
  });

  group('CollectionVisibility', () {
    test('should provide correct display names', () {
      expect(CollectionVisibility.public.displayName, 'Public');
      expect(CollectionVisibility.private.displayName, 'Private');
      expect(CollectionVisibility.unlisted.displayName, 'Unlisted');
      expect(CollectionVisibility.subscribers.displayName, 'Subscribers Only');
    });

    test('should provide correct descriptions', () {
      expect(CollectionVisibility.public.description, 'Visible to everyone');
      expect(CollectionVisibility.private.description, 'Only visible to you');
      expect(CollectionVisibility.unlisted.description,
          'Accessible via direct link');
      expect(CollectionVisibility.subscribers.description,
          'Only for your subscribers');
    });
  });
}
