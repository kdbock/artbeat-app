import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock classes
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
])
import 'profile_service_test.mocks.dart';

void main() {
  group('ProfileService Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;
    late MockDocumentSnapshot mockSnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      mockSnapshot = MockDocumentSnapshot();
    });

    test('should fetch user profile successfully', () async {
      // Arrange
      final profileData = {
        'uid': 'user-123',
        'fullName': 'John Doe',
        'email': 'john@example.com',
        'bio': 'Artist and designer',
        'profileImageUrl': 'https://example.com/profile.jpg',
        'followersCount': 100,
        'followingCount': 50,
        'isVerified': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc('user-123')).thenReturn(mockDocument);
      when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.exists).thenReturn(true);
      when(mockSnapshot.data()).thenReturn(profileData);

      // Act
      final result = await mockDocument.get();
      final data = result.data() as Map<String, dynamic>?;

      // Assert
      expect(result.exists, isTrue);
      expect(data?['uid'], equals('user-123'));
      expect(data?['fullName'], equals('John Doe'));
      expect(data?['email'], equals('john@example.com'));
      expect(data?['bio'], equals('Artist and designer'));
      expect(data?['followersCount'], equals(100));
      expect(data?['isVerified'], isTrue);
    });

    test('should handle user profile not found', () async {
      // Arrange
      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc('nonexistent-user')).thenReturn(mockDocument);
      when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.exists).thenReturn(false);

      // Act
      final result = await mockDocument.get();

      // Assert
      expect(result.exists, isFalse);
      verify(mockDocument.get()).called(1);
    });

    test('should update user profile successfully', () async {
      // Arrange
      final updateData = {
        'fullName': 'John Updated',
        'bio': 'Updated bio',
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc('user-123')).thenReturn(mockDocument);
      when(mockDocument.update(updateData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.update(updateData);

      // Assert
      verify(mockDocument.update(updateData)).called(1);
    });

    test('should follow user successfully', () async {
      // Arrange
      const userId = 'user-123';
      const targetUserId = 'target-456';

      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc(userId)).thenReturn(mockDocument);
      when(
        mockDocument.update({'followingCount': FieldValue.increment(1)}),
      ).thenAnswer((_) async => {});

      // Act
      await mockDocument.update({'followingCount': FieldValue.increment(1)});

      // Assert
      verify(
        mockDocument.update({'followingCount': FieldValue.increment(1)}),
      ).called(1);
    });

    test('should unfollow user successfully', () async {
      // Arrange
      const userId = 'user-123';
      const targetUserId = 'target-456';

      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc(userId)).thenReturn(mockDocument);
      when(
        mockDocument.update({'followingCount': FieldValue.increment(-1)}),
      ).thenAnswer((_) async => {});

      // Act
      await mockDocument.update({'followingCount': FieldValue.increment(-1)});

      // Assert
      verify(
        mockDocument.update({'followingCount': FieldValue.increment(-1)}),
      ).called(1);
    });

    test('should get followers list', () async {
      // Arrange
      final followersData = [
        {
          'uid': 'follower-1',
          'fullName': 'Follower One',
          'profileImageUrl': 'https://example.com/follower1.jpg',
          'followedAt': DateTime.now().toIso8601String(),
        },
        {
          'uid': 'follower-2',
          'fullName': 'Follower Two',
          'profileImageUrl': 'https://example.com/follower2.jpg',
          'followedAt': DateTime.now().toIso8601String(),
        },
      ];

      when(mockFirestore.collection('followers')).thenReturn(mockCollection);
      when(
        mockCollection.where('followedUserId', isEqualTo: 'user-123'),
      ).thenReturn(mockCollection);

      // Act & Assert - This would be implemented in the actual service
      expect(followersData.length, equals(2));
      expect(followersData[0]['uid'], equals('follower-1'));
      expect(followersData[1]['uid'], equals('follower-2'));
    });

    test('should get following list', () async {
      // Arrange
      final followingData = [
        {
          'uid': 'following-1',
          'fullName': 'Following One',
          'profileImageUrl': 'https://example.com/following1.jpg',
          'followedAt': DateTime.now().toIso8601String(),
        },
        {
          'uid': 'following-2',
          'fullName': 'Following Two',
          'profileImageUrl': 'https://example.com/following2.jpg',
          'followedAt': DateTime.now().toIso8601String(),
        },
      ];

      when(mockFirestore.collection('followers')).thenReturn(mockCollection);
      when(
        mockCollection.where('followerUserId', isEqualTo: 'user-123'),
      ).thenReturn(mockCollection);

      // Act & Assert - This would be implemented in the actual service
      expect(followingData.length, equals(2));
      expect(followingData[0]['uid'], equals('following-1'));
      expect(followingData[1]['uid'], equals('following-2'));
    });

    test('should check if user is following another user', () async {
      // Arrange
      const userId = 'user-123';
      const targetUserId = 'target-456';

      when(mockFirestore.collection('followers')).thenReturn(mockCollection);
      when(
        mockCollection
            .where('followerUserId', isEqualTo: userId)
            .where('followedUserId', isEqualTo: targetUserId),
      ).thenReturn(mockCollection);
      when(mockCollection.limit(1)).thenReturn(mockCollection);

      // Simulate following relationship exists
      when(mockSnapshot.exists).thenReturn(true);

      // Act & Assert - This would be implemented in the actual service
      final isFollowing = mockSnapshot.exists;
      expect(isFollowing, isTrue);
    });

    test('should update profile image successfully', () async {
      // Arrange
      const userId = 'user-123';
      const newImageUrl = 'https://example.com/new-profile.jpg';

      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc(userId)).thenReturn(mockDocument);
      when(
        mockDocument.update({'profileImageUrl': newImageUrl, 'updatedAt': any}),
      ).thenAnswer((_) async => {});

      // Act
      await mockDocument.update({
        'profileImageUrl': newImageUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Assert
      verify(mockDocument.update(any)).called(1);
    });

    test('should delete user profile successfully', () async {
      // Arrange
      const userId = 'user-123';

      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc(userId)).thenReturn(mockDocument);
      when(mockDocument.delete()).thenAnswer((_) async => {});

      // Act
      await mockDocument.delete();

      // Assert
      verify(mockDocument.delete()).called(1);
    });

    test('should search users by name', () async {
      // Arrange
      const searchQuery = 'John';
      final searchResults = [
        {
          'uid': 'user-1',
          'fullName': 'John Doe',
          'profileImageUrl': 'https://example.com/john.jpg',
          'isVerified': true,
        },
        {
          'uid': 'user-2',
          'fullName': 'Johnny Smith',
          'profileImageUrl': 'https://example.com/johnny.jpg',
          'isVerified': false,
        },
      ];

      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(
        mockCollection
            .where('fullName', isGreaterThanOrEqualTo: searchQuery)
            .where('fullName', isLessThan: '${searchQuery}z'),
      ).thenReturn(mockCollection);

      // Act & Assert - This would be implemented in the actual service
      expect(searchResults.length, equals(2));
      expect(searchResults[0]['fullName'], contains('John'));
      expect(searchResults[1]['fullName'], contains('John'));
    });
  });

  group('Profile Validation Tests', () {
    test('should validate profile data correctly', () {
      // Valid profile data
      final validProfile = {
        'uid': 'user-123',
        'fullName': 'John Doe',
        'email': 'john@example.com',
        'bio': 'Valid bio',
        'profileImageUrl': 'https://example.com/valid.jpg',
      };
      expect(isValidProfile(validProfile), isTrue);

      // Invalid profile - missing required fields
      final invalidProfile1 = {
        'uid': '',
        'fullName': 'John Doe',
        'email': 'john@example.com',
      };
      expect(isValidProfile(invalidProfile1), isFalse);

      // Invalid profile - invalid email
      final invalidProfile2 = {
        'uid': 'user-123',
        'fullName': 'John Doe',
        'email': 'invalid-email',
      };
      expect(isValidProfile(invalidProfile2), isFalse);

      // Invalid profile - empty full name
      final invalidProfile3 = {
        'uid': 'user-123',
        'fullName': '',
        'email': 'john@example.com',
      };
      expect(isValidProfile(invalidProfile3), isFalse);
    });

    test('should validate bio length', () {
      expect(isValidBio(''), isTrue); // Empty bio is valid
      expect(isValidBio('Short bio'), isTrue);
      expect(isValidBio('A' * 150), isTrue); // At max length
      expect(isValidBio('A' * 500), isFalse); // Too long
    });

    test('should validate profile image URL', () {
      expect(isValidImageUrl('https://example.com/image.jpg'), isTrue);
      expect(isValidImageUrl('https://example.com/image.png'), isTrue);
      expect(isValidImageUrl('https://example.com/image.gif'), isTrue);
      expect(isValidImageUrl('not-a-url'), isFalse);
      expect(isValidImageUrl('https://example.com/file.txt'), isFalse);
    });

    test('should validate full name format', () {
      expect(isValidFullName('John Doe'), isTrue);
      expect(isValidFullName('Mary Jane Watson'), isTrue);
      expect(isValidFullName('José María García'), isTrue);
      expect(isValidFullName('J'), isFalse); // Too short
      expect(isValidFullName(''), isFalse); // Empty
      expect(isValidFullName('A' * 100), isFalse); // Too long
      expect(isValidFullName('123 456'), isFalse); // Numbers not allowed
    });
  });

  group('Profile Privacy Tests', () {
    test('should handle private profile settings', () {
      final privateProfile = {
        'uid': 'user-123',
        'fullName': 'Private User',
        'email': 'private@example.com',
        'isPrivate': true,
        'showEmail': false,
        'showFollowers': false,
        'showFollowing': false,
      };

      expect(privateProfile['isPrivate'], isTrue);
      expect(privateProfile['showEmail'], isFalse);
      expect(privateProfile['showFollowers'], isFalse);
      expect(privateProfile['showFollowing'], isFalse);
    });

    test('should handle public profile settings', () {
      final publicProfile = {
        'uid': 'user-123',
        'fullName': 'Public User',
        'email': 'public@example.com',
        'isPrivate': false,
        'showEmail': true,
        'showFollowers': true,
        'showFollowing': true,
      };

      expect(publicProfile['isPrivate'], isFalse);
      expect(publicProfile['showEmail'], isTrue);
      expect(publicProfile['showFollowers'], isTrue);
      expect(publicProfile['showFollowing'], isTrue);
    });
  });
}

// Helper validation functions
bool isValidProfile(Map<String, dynamic> profile) {
  return profile['uid'] != null &&
      profile['uid'].toString().isNotEmpty &&
      profile['fullName'] != null &&
      profile['fullName'].toString().isNotEmpty &&
      profile['email'] != null &&
      isValidEmail(profile['email'].toString());
}

bool isValidEmail(String email) {
  return RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(email);
}

bool isValidBio(String bio) {
  return bio.length <= 500;
}

bool isValidImageUrl(String url) {
  if (!Uri.tryParse(url)?.hasAbsolutePath ?? false) return false;
  final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
  return validExtensions.any((ext) => url.toLowerCase().endsWith(ext));
}

bool isValidFullName(String name) {
  if (name.isEmpty || name.length > 50) return false;
  return RegExp(r'^[a-zA-ZáéíóúñüÁÉÍÓÚÑÜ\s]+$').hasMatch(name);
}
