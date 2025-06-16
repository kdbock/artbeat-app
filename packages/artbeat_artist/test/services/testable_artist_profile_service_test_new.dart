import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show UserType, SubscriptionTier;
import 'package:artbeat_artist/src/services/testable_artist_profile_service.dart';

@GenerateMocks(
    [FirebaseAuth, User, FirebaseStorage, Reference, UploadTask, TaskSnapshot])
@GenerateNiceMocks([MockSpec<File>()])
import 'testable_artist_profile_service_test_new.mocks.dart';

// Mock subscription service
class MockSubscriptionService implements ISubscriptionServiceDependency {
  final SubscriptionTier _tier;

  MockSubscriptionService(this._tier);

  @override
  Future<SubscriptionTier> getCurrentTier() async {
    return _tier;
  }
}

void main() {
  const testUserId = 'test-user-id';

  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockFirebaseStorage mockStorage;
  late MockReference mockStorageRef;
  late MockUploadTask mockUploadTask;
  late MockTaskSnapshot mockTaskSnapshot;
  late MockFile mockFile;
  late MockSubscriptionService mockSubscriptionService;
  late TestableArtistProfileService artistProfileService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockStorage = MockFirebaseStorage();
    mockStorageRef = MockReference();
    mockUploadTask = MockUploadTask();
    mockTaskSnapshot = MockTaskSnapshot();
    mockFile = MockFile();
    mockSubscriptionService =
        MockSubscriptionService(SubscriptionTier.artistBasic);

    // Set up mock behaviors BEFORE creating the service
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(testUserId);

    // Set up storage mocks
    when(mockStorage.ref()).thenReturn(mockStorageRef);
    when(mockStorageRef.child(any)).thenReturn(mockStorageRef);
    when(mockFile.path).thenReturn('/path/to/image.jpg');
    when(mockStorageRef.putFile(any)).thenReturn(mockUploadTask);
    when(mockUploadTask.whenComplete(any))
        .thenAnswer((_) async => mockTaskSnapshot);
    when(mockStorageRef.getDownloadURL())
        .thenAnswer((_) async => 'https://example.com/image.jpg');

    // Create service with mocked dependencies
    artistProfileService = TestableArtistProfileService(
      firestore: fakeFirestore,
      auth: mockAuth,
      storage: mockStorage,
      subscriptionService: mockSubscriptionService,
    );
  });

  group('TestableArtistProfileService Tests', () {
    test('getCurrentUserId should return the current user ID', () {
      // Act
      final userId = artistProfileService.getCurrentUserId();

      // Assert
      expect(userId, testUserId);
    });

    test('getArtistProfileById should return null if profile does not exist',
        () async {
      // Act
      final profile =
          await artistProfileService.getArtistProfileById('non-existent-id');

      // Assert
      expect(profile, isNull);
    });

    test('getArtistProfileById should return profile data if it exists',
        () async {
      // Arrange
      final profileId = 'test-profile-id';
      final profileData = {
        'userId': testUserId,
        'displayName': 'Test Artist',
        'bio': 'Test bio',
        'userType': 'artist',
        'location': 'New York',
        'mediums': ['Oil', 'Acrylic'],
        'styles': ['Abstract', 'Impressionist'],
        'socialLinks': {'instagram': 'test_artist'},
        'profileImageUrl': 'https://example.com/profile.jpg',
        'isVerified': false,
        'isFeatured': false,
        'subscriptionTier': 'free', // Using the apiName value
      };

      await fakeFirestore
          .collection('artistProfiles')
          .doc(profileId)
          .set(profileData);

      // Act
      final profile =
          await artistProfileService.getArtistProfileById(profileId);

      // Assert
      expect(profile, isNotNull);
      expect(profile!['userId'], testUserId);
      expect(profile['displayName'], 'Test Artist');
      expect(profile['id'], profileId);
    });

    test(
        'getArtistProfileByUserId should return null if profile does not exist',
        () async {
      // Act
      final profile = await artistProfileService
          .getArtistProfileByUserId('non-existent-user');

      // Assert
      expect(profile, isNull);
    });

    test('getArtistProfileByUserId should return profile data if it exists',
        () async {
      // Arrange
      final profileId = 'test-profile-id';
      final profileData = {
        'userId': testUserId,
        'displayName': 'Test Artist',
        'bio': 'Test bio',
        'userType': 'artist',
      };

      await fakeFirestore
          .collection('artistProfiles')
          .doc(profileId)
          .set(profileData);

      // Act
      final profile =
          await artistProfileService.getArtistProfileByUserId(testUserId);

      // Assert
      expect(profile, isNotNull);
      expect(profile!['userId'], testUserId);
      expect(profile['displayName'], 'Test Artist');
      expect(profile['id'], profileId);
    });

    test('hasArtistProfile should return false if no profile exists', () async {
      // Act
      final hasProfile = await artistProfileService.hasArtistProfile();

      // Assert
      expect(hasProfile, isFalse);
    });

    test('hasArtistProfile should return true if profile exists', () async {
      // Arrange
      await fakeFirestore.collection('artistProfiles').add({
        'userId': testUserId,
        'displayName': 'Test Artist',
      });

      // Act
      final hasProfile = await artistProfileService.hasArtistProfile();

      // Assert
      expect(hasProfile, isTrue);
    });

    test('createArtistProfile should create new profile if none exists',
        () async {
      // Arrange
      final displayName = 'New Artist';
      final bio = 'Artist bio';
      final location = 'Los Angeles';
      final mediums = ['Digital', 'Photography'];
      final styles = ['Modern', 'Abstract'];
      final socialLinks = {'instagram': 'new_artist', 'twitter': '@newartist'};

      // Act
      final profileId = await artistProfileService.createArtistProfile(
        displayName: displayName,
        bio: bio,
        userType: UserType.artist,
        location: location,
        mediums: mediums,
        styles: styles,
        socialLinks: socialLinks,
      );

      // Assert
      expect(profileId, isNotEmpty);

      final doc =
          await fakeFirestore.collection('artistProfiles').doc(profileId).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['displayName'], equals(displayName));
      expect(doc.data()?['bio'], equals(bio));
      expect(doc.data()?['userType'], equals('artist'));
      expect(doc.data()?['location'], equals(location));
      expect(doc.data()?['mediums'], equals(mediums));
      expect(doc.data()?['styles'], equals(styles));
      expect(doc.data()?['socialLinks'], equals(socialLinks));
      expect(doc.data()?['userId'], equals(testUserId));
      expect(doc.data()?['subscriptionTier'],
          equals('free')); // Basic tier apiName is 'free'
    });

    test('uploadProfileImage should upload image and return URL', () async {
      // Act
      final imageUrl =
          await artistProfileService.uploadProfileImage(mockFile, testUserId);

      // Assert
      expect(imageUrl, equals('https://example.com/image.jpg'));

      // Verify storage interactions
      verify(mockStorage.ref()).called(1);
      verify(mockStorageRef
              .child('profile_images/$testUserId/profile_image.jpg'))
          .called(1);
      verify(mockStorageRef.putFile(mockFile)).called(1);
      verify(mockStorageRef.getDownloadURL()).called(1);
    });

    test('uploadCoverImage should upload image and return URL', () async {
      // Act
      final imageUrl =
          await artistProfileService.uploadCoverImage(mockFile, testUserId);

      // Assert
      expect(imageUrl, equals('https://example.com/image.jpg'));

      // Verify storage interactions
      verify(mockStorage.ref()).called(1);
      verify(mockStorageRef.child('profile_images/$testUserId/cover_image.jpg'))
          .called(1);
      verify(mockStorageRef.putFile(mockFile)).called(1);
      verify(mockStorageRef.getDownloadURL()).called(1);
    });
  });
}
