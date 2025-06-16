import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show SubscriptionTier;
import 'package:artbeat_artwork/src/services/testable_artwork_service.dart';

// Create mocks for dependencies
@GenerateMocks(
    [FirebaseAuth, User, FirebaseStorage, Reference, UploadTask, TaskSnapshot])
@GenerateNiceMocks([
  MockSpec<File>(),
  MockSpec<AggregateQuery>(),
  MockSpec<AggregateQuerySnapshot>()
])
import 'testable_artwork_service_simple.mocks.dart';

// Create a mock subscription service
class MockSubscriptionService implements ISubscriptionService {
  final SubscriptionData? _subscriptionData;
  final ArtistProfileData? _artistProfileData;

  MockSubscriptionService({
    SubscriptionData? subscriptionData,
    ArtistProfileData? artistProfileData,
  })  : _subscriptionData = subscriptionData,
        _artistProfileData = artistProfileData;

  @override
  Future<SubscriptionData?> getUserSubscription() async {
    return _subscriptionData;
  }

  @override
  Future<ArtistProfileData?> getArtistProfileByUserId(String userId) async {
    return _artistProfileData;
  }
}

void main() {
  const testUserId = 'test-user-id';
  const testArtistProfileId = 'test-artist-profile-id';

  group('TestableArtworkService Basic Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late TestableArtworkService artworkService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      // Set up user auth mock
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn(testUserId);

      // Create mock subscription service
      final mockSubscriptionService = MockSubscriptionService(
        subscriptionData: SubscriptionData(tier: SubscriptionTier.artistBasic),
        artistProfileData: ArtistProfileData(
          id: testArtistProfileId,
          name: 'Test Artist',
        ),
      );

      // Create service with mocked dependencies
      artworkService = TestableArtworkService(
        firestore: fakeFirestore,
        auth: mockAuth,
        storage:
            MockFirebaseStorage(), // We're not testing storage functionality here
        subscriptionService: mockSubscriptionService,
      );
    });

    test('getCurrentUserId should return the current user ID', () {
      final userId = artworkService.getCurrentUserId();
      expect(userId, testUserId);
    });

    test('getArtworkById should return artwork data if it exists', () async {
      // Arrange
      final artworkId = 'test-artwork-id';
      final artworkData = {
        'id': artworkId,
        'title': 'Test Artwork',
        'description': 'A test artwork',
        'userId': testUserId,
      };

      await fakeFirestore.collection('artwork').doc(artworkId).set(artworkData);

      // Act
      final result = await artworkService.getArtworkById(artworkId);

      // Assert
      expect(result, isNotNull);
      expect(result?['title'], equals('Test Artwork'));
      expect(result?['userId'], equals(testUserId));
    });

    test('getArtworkById should return null if artwork does not exist',
        () async {
      // Act
      final result = await artworkService.getArtworkById('non-existent-id');

      // Assert
      expect(result, isNull);
    });

    test('updateArtwork should update specified fields', () async {
      // Arrange
      final artworkId = 'test-artwork-id';
      final artworkData = {
        'id': artworkId,
        'title': 'Original Title',
        'description': 'Original description',
        'userId': testUserId,
        'medium': 'Acrylic',
        'price': 50.0,
      };

      await fakeFirestore.collection('artwork').doc(artworkId).set(artworkData);

      // Act
      await artworkService.updateArtwork(
        artworkId: artworkId,
        title: 'Updated Title',
        price: 75.0,
      );

      // Assert
      final updatedDoc =
          await fakeFirestore.collection('artwork').doc(artworkId).get();
      expect(updatedDoc.data()?['title'], equals('Updated Title'));
      expect(updatedDoc.data()?['price'], equals(75.0));
      expect(updatedDoc.data()?['description'],
          equals('Original description')); // Unchanged
      expect(updatedDoc.data()?['medium'], equals('Acrylic')); // Unchanged
    });

    test('updateArtwork should throw exception if artwork does not exist',
        () async {
      // Act & Assert
      expect(
          () => artworkService.updateArtwork(
                artworkId: 'non-existent-id',
                title: 'Updated Title',
              ),
          throwsException);
    });

    test(
        'updateArtwork should throw exception if user does not own the artwork',
        () async {
      // Arrange
      final artworkId = 'test-artwork-id';
      final artworkData = {
        'id': artworkId,
        'title': 'Original Title',
        'userId': 'different-user-id', // Different user
      };

      await fakeFirestore.collection('artwork').doc(artworkId).set(artworkData);

      // Act & Assert
      expect(
          () => artworkService.updateArtwork(
                artworkId: artworkId,
                title: 'Updated Title',
              ),
          throwsException);
    });

    test('deleteArtwork should delete the artwork document', () async {
      // Arrange
      final artworkId = 'test-artwork-id';
      final artworkData = {
        'id': artworkId,
        'title': 'Artwork to delete',
        'userId': testUserId,
      };

      await fakeFirestore.collection('artwork').doc(artworkId).set(artworkData);

      // Act
      await artworkService.deleteArtwork(artworkId);

      // Assert
      final deletedDoc =
          await fakeFirestore.collection('artwork').doc(artworkId).get();
      expect(deletedDoc.exists, isFalse);
    });

    test('deleteArtwork should throw exception if artwork does not exist',
        () async {
      // Act & Assert
      expect(() => artworkService.deleteArtwork('non-existent-id'),
          throwsException);
    });

    test(
        'deleteArtwork should throw exception if user does not own the artwork',
        () async {
      // Arrange
      final artworkId = 'test-artwork-id';
      final artworkData = {
        'id': artworkId,
        'title': 'Artwork to delete',
        'userId': 'different-user-id', // Different user
      };

      await fakeFirestore.collection('artwork').doc(artworkId).set(artworkData);

      // Act & Assert
      expect(() => artworkService.deleteArtwork(artworkId), throwsException);
    });

    test('getArtworkList should return filtered artwork list', () async {
      // Arrange - Create several artwork documents
      final artworks = [
        {
          'id': 'artwork1',
          'title': 'Sunset',
          'userId': testUserId,
          'medium': 'Oil',
          'location': 'New York',
          'isPublic': true,
        },
        {
          'id': 'artwork2',
          'title': 'Mountains',
          'userId': testUserId,
          'medium': 'Watercolor',
          'location': 'New York',
          'isPublic': true,
        },
        {
          'id': 'artwork3',
          'title': 'Forest',
          'userId': 'other-user-id',
          'medium': 'Oil',
          'location': 'Boston',
          'isPublic': true,
        },
        {
          'id': 'artwork4',
          'title': 'Private Artwork',
          'userId': testUserId,
          'medium': 'Oil',
          'location': 'New York',
          'isPublic': false,
        },
      ];

      for (final artwork in artworks) {
        await fakeFirestore
            .collection('artwork')
            .doc(artwork['id'] as String)
            .set(artwork);
      }

      // Act - Test different filter combinations
      final userArtworks =
          await artworkService.getArtworkList(userId: testUserId);
      final locationArtworks =
          await artworkService.getArtworkList(location: 'New York');
      final mediumArtworks = await artworkService.getArtworkList(medium: 'Oil');
      final userMediumArtworks = await artworkService.getArtworkList(
        userId: testUserId,
        medium: 'Oil',
      );
      final allArtworksIncludePrivate =
          await artworkService.getArtworkList(onlyPublic: false);

      // Assert
      expect(userArtworks.length, 2); // User's public artworks
      expect(locationArtworks.length, 2); // Public artworks in New York
      expect(mediumArtworks.length, 2); // Public Oil artworks
      expect(userMediumArtworks.length, 1); // User's public Oil artworks
      expect(allArtworksIncludePrivate.length,
          4); // All artworks including private
    });
  });
}
