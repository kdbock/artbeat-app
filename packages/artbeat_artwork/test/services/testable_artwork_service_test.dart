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
@GenerateMocks([
  FirebaseAuth,
  User,
  FirebaseStorage,
  Reference,
  UploadTask,
  TaskSnapshot,
  AggregateQuery,
  AggregateQuerySnapshot
])
@GenerateNiceMocks([MockSpec<File>()])
import 'testable_artwork_service_test.mocks.dart';

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

  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockFirebaseStorage mockStorage;
  late MockReference mockStorageRef;
  late MockUploadTask mockUploadTask;
  late MockTaskSnapshot mockTaskSnapshot;
  late MockFile mockImageFile;
  late TestableArtworkService artworkService;
  late MockSubscriptionService mockSubscriptionService;
  late MockAggregateQuery mockAggregateQuery;
  late MockAggregateQuerySnapshot mockAggregateQuerySnapshot;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockStorage = MockFirebaseStorage();
    mockStorageRef = MockReference();
    mockUploadTask = MockUploadTask();
    mockTaskSnapshot = MockTaskSnapshot();
    mockImageFile = MockFile();
    mockAggregateQuery = MockAggregateQuery();
    mockAggregateQuerySnapshot = MockAggregateQuerySnapshot();

    // Set up user auth mock
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(testUserId);

    // Set up file mock
    when(mockImageFile.path).thenReturn('/path/to/test_image.jpg');

    // Set up storage mocks
    when(mockStorage.ref()).thenReturn(mockStorageRef);
    when(mockStorageRef.child(any)).thenReturn(mockStorageRef);
    when(mockStorageRef.putFile(any)).thenAnswer((_) => mockUploadTask);
    when(mockUploadTask.whenComplete(any))
        .thenAnswer((_) async => mockTaskSnapshot);
    when(mockStorageRef.getDownloadURL())
        .thenAnswer((_) async => 'https://example.com/test_image.jpg');

    // Set up subscription mocks
    mockSubscriptionService = MockSubscriptionService(
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
      storage: mockStorage,
      subscriptionService: mockSubscriptionService,
    );
  });

  group('TestableArtworkService Tests', () {
    test('getCurrentUserId should return the current user ID', () {
      // Act
      final userId = artworkService.getCurrentUserId();

      // Assert
      expect(userId, testUserId);
    });

    test('uploadArtwork should create a new artwork document with correct data',
        () async {
      // Arrange
      final styles = ['Abstract', 'Modern'];
      final title = 'Test Artwork';

      // Set up mocked query for artwork count check (Basic tier limit)
      when(fakeFirestore
              .collection('artwork')
              .where('userId', isEqualTo: testUserId)
              .count())
          .thenReturn(mockAggregateQuery);
      when(mockAggregateQuery.get())
          .thenAnswer((_) async => mockAggregateQuerySnapshot);
      when(mockAggregateQuerySnapshot.count).thenReturn(3); // Under the 5 limit

      // Act
      final artworkId = await artworkService.uploadArtwork(
        imageFile: mockImageFile,
        title: title,
        description: 'Test description',
        medium: 'Oil',
        styles: styles,
        location: 'New York',
        price: 100.0,
        isForSale: true,
      );

      // Assert
      expect(artworkId, isNotEmpty);

      // Verify artwork document was created correctly
      final artworkDoc =
          await fakeFirestore.collection('artwork').doc(artworkId).get();
      expect(artworkDoc.exists, isTrue);
      expect(artworkDoc.data()?['title'], equals(title));
      expect(artworkDoc.data()?['userId'], equals(testUserId));
      expect(artworkDoc.data()?['artistId'], equals(testArtistProfileId));
      expect(artworkDoc.data()?['medium'], equals('Oil'));
      expect(artworkDoc.data()?['styles'], equals(styles));
      expect(artworkDoc.data()?['price'], equals(100.0));
      expect(artworkDoc.data()?['isForSale'], equals(true));
      expect(artworkDoc.data()?['verificationStatus'], equals('pending'));
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
      // Arrange
      final nonExistentId = 'non-existent-id';

      // Act
      final result = await artworkService.getArtworkById(nonExistentId);

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
      // Arrange
      final nonExistentId = 'non-existent-id';

      // Act & Assert
      expect(
          () => artworkService.updateArtwork(
                artworkId: nonExistentId,
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
      // Arrange
      final nonExistentId = 'non-existent-id';

      // Act & Assert
      expect(
          () => artworkService.deleteArtwork(nonExistentId), throwsException);
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
