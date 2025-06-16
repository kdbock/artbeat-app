// filepath: testable_artist_profile_service_fixed.dart
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
import 'testable_artist_profile_service_test.mocks.dart';

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

    // Set up auth mocks
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(testUserId);

    // Set up storage mocks
    when(mockStorage.ref()).thenReturn(mockStorageRef);
    when(mockStorageRef.child(any)).thenReturn(mockStorageRef);
    when(mockStorageRef.putFile(any)).thenReturn(mockUploadTask);
    when(mockUploadTask.snapshot).thenReturn(mockTaskSnapshot);
    when(mockStorageRef.getDownloadURL())
        .thenAnswer((_) async => 'https://example.com/image.jpg');

    // Initialize service - PROPERLY INITIALIZED HERE
    artistProfileService = TestableArtistProfileService(
      firestore: fakeFirestore,
      auth: mockAuth,
      storage: mockStorage,
      subscriptionService: mockSubscriptionService,
    );
  });

  group('ArtistProfileService Tests', () {
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
        'subscriptionTier': 'artistBasic',
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

      // Check profile was created correctly
      final docRef = fakeFirestore.collection('artistProfiles').doc(profileId);
      final docSnapshot = await docRef.get();
      final doc = docSnapshot.data();

      expect(doc, isNotNull);
      expect(doc!['userId'], testUserId);
      expect(doc['displayName'], displayName);
      expect(doc['bio'], bio);
      expect(doc['userType'], 'artist');
      expect(doc['location'], location);
      expect(doc['mediums'], mediums);
      expect(doc['styles'], styles);
      expect(doc['socialLinks']['instagram'], 'new_artist');
      expect(doc['socialLinks']['twitter'], '@newartist');
      expect(doc['subscriptionTier'], equals('artistBasic'));
    });

    test(
        'updateArtistProfile should update existing profile with new information',
        () async {
      // Arrange - Create initial profile
      final profileId = 'existing-profile';
      await fakeFirestore.collection('artistProfiles').doc(profileId).set({
        'userId': testUserId,
        'displayName': 'Original Name',
        'bio': 'Original bio',
        'userType': 'artist',
        'location': 'Original Location',
        'mediums': ['Original Medium'],
        'styles': ['Original Style'],
        'socialLinks': {'instagram': 'original_handle'},
      });

      // Act - Update profile
      await artistProfileService.updateArtistProfile(
        profileId: profileId,
        displayName: 'Updated Name',
        bio: 'Updated bio',
        location: 'Updated Location',
        mediums: ['Updated Medium'],
        styles: ['Updated Style'],
        socialLinks: {
          'instagram': 'updated_handle',
          'facebook': 'new_facebook'
        },
      );

      // Assert - Check profile was updated
      final docRef = fakeFirestore.collection('artistProfiles').doc(profileId);
      final docSnapshot = await docRef.get();
      final doc = docSnapshot.data();

      expect(doc, isNotNull);
      expect(doc!['displayName'], 'Updated Name');
      expect(doc['bio'], 'Updated bio');
      expect(doc['location'], 'Updated Location');
      expect(doc['mediums'][0], 'Updated Medium');
      expect(doc['styles'][0], 'Updated Style');
      expect(doc['socialLinks']['instagram'], 'updated_handle');
      expect(doc['socialLinks']['facebook'], 'new_facebook');

      // Original fields should remain unchanged
      expect(doc['userId'], testUserId);
      expect(doc['userType'], 'artist');
    });

    // Note: deleteArtistProfile method doesn't exist in the implementation
    // Tests for this method have been removed

    test(
        'updateArtistProfile should throw exception if user does not own profile',
        () async {
      // Arrange - Create profile owned by someone else
      final profileId = 'other-user-profile';
      await fakeFirestore.collection('artistProfiles').doc(profileId).set({
        'userId': 'other-user-id',
        'displayName': 'Other User',
      });

      // Act & Assert
      expect(
        () => artistProfileService.updateArtistProfile(
          profileId: profileId,
          displayName: 'New Name',
        ),
        throwsException,
      );
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

    test('searchArtistsByLocation should return filtered artist profiles',
        () async {
      // Arrange - Create artist profiles with different locations
      final artistProfiles = [
        {
          'userId': 'artist1',
          'displayName': 'Artist 1',
          'location': 'New York',
          'userType': 'artist',
        },
        {
          'userId': 'artist2',
          'displayName': 'Artist 2',
          'location': 'New York',
          'userType': 'artist',
        },
        {
          'userId': 'artist3',
          'displayName': 'Artist 3',
          'location': 'Los Angeles',
          'userType': 'artist',
        },
        {
          'userId': 'gallery1',
          'displayName': 'Gallery 1',
          'location': 'New York',
          'userType': 'gallery',
        },
      ];

      for (int i = 0; i < artistProfiles.length; i++) {
        await fakeFirestore
            .collection('artistProfiles')
            .doc('profile$i')
            .set(artistProfiles[i]);
      }

      // Act
      final results =
          await artistProfileService.searchArtistsByLocation('New York');

      // Assert
      expect(results.length, 2); // Should find 2 artists in New York
      expect(
          results.every((profile) =>
              profile['location'] == 'New York' &&
              profile['userType'] == 'artist'),
          isTrue);
    });

    test('searchGalleriesByLocation should return filtered gallery profiles',
        () async {
      // Arrange - Create gallery profiles with different locations
      final galleryProfiles = [
        {
          'userId': 'gallery1',
          'displayName': 'Gallery 1',
          'location': 'New York',
          'userType': 'gallery',
        },
        {
          'userId': 'gallery2',
          'displayName': 'Gallery 2',
          'location': 'New York',
          'userType': 'gallery',
        },
        {
          'userId': 'gallery3',
          'displayName': 'Gallery 3',
          'location': 'Los Angeles',
          'userType': 'gallery',
        },
        {
          'userId': 'artist1',
          'displayName': 'Artist 1',
          'location': 'New York',
          'userType': 'artist',
        },
      ];

      for (int i = 0; i < galleryProfiles.length; i++) {
        await fakeFirestore
            .collection('artistProfiles')
            .doc('profile$i')
            .set(galleryProfiles[i]);
      }

      // Act
      final results =
          await artistProfileService.searchGalleriesByLocation('New York');

      // Assert
      expect(results.length, 2); // Should find 2 galleries in New York
      expect(
          results.every((profile) =>
              profile['location'] == 'New York' &&
              profile['userType'] == 'gallery'),
          isTrue);
    });
  });
}
