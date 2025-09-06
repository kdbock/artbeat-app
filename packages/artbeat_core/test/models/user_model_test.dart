import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/src/models/user_model.dart';
import 'package:artbeat_core/src/models/user_type.dart';

void main() {
  group('UserModel Tests', () {
    test('should create UserModel with required fields', () {
      // Arrange & Act
      final user = UserModel(
        id: 'test-id',
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
        createdAt: DateTime.now(),
      );

      // Assert
      expect(user.id, equals('test-id'));
      expect(user.email, equals('test@example.com'));
      expect(user.username, equals('testuser'));
      expect(user.fullName, equals('Test User'));
      expect(user.userType, isNull);
      expect(user.profileImageUrl, equals(''));
      expect(user.bio, equals(''));
      expect(user.createdAt, isNotNull);
    });

    test('should create UserModel with all fields', () {
      // Arrange
      final createdAt = DateTime.now().subtract(const Duration(days: 30));
      final lastActive = DateTime.now();

      // Act
      final user = UserModel(
        id: 'test-id',
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
        userType: UserType.artist.value,
        profileImageUrl: 'https://example.com/image.jpg',
        bio: 'This is a test bio',
        location: 'Test Location',
        createdAt: createdAt,
        lastActive: lastActive,
        posts: ['post1', 'post2'],
        experiencePoints: 100,
        level: 5,
        zipCode: '12345',
      );

      // Assert
      expect(user.id, equals('test-id'));
      expect(user.email, equals('test@example.com'));
      expect(user.username, equals('testuser'));
      expect(user.fullName, equals('Test User'));
      expect(user.userType, equals(UserType.artist.value));
      expect(user.profileImageUrl, equals('https://example.com/image.jpg'));
      expect(user.bio, equals('This is a test bio'));
      expect(user.location, equals('Test Location'));
      expect(user.createdAt, equals(createdAt));
      expect(user.lastActive, equals(lastActive));
      expect(user.followersCount, equals(0)); // Default from EngagementStats
      expect(user.followingCount, equals(0)); // Hardcoded to 0 in the model
      expect(user.postsCount, equals(2));
      expect(user.experiencePoints, equals(100));
      expect(user.level, equals(5));
      expect(user.zipCode, equals('12345'));
    });

    test('should convert UserModel to JSON', () {
      // Arrange
      final user = UserModel(
        id: 'test-id',
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
        userType: UserType.regular.value,
        bio: 'Test bio',
        createdAt: DateTime.now(),
      );

      // Act
      final json = user.toJson();

      // Assert
      expect(json['email'], equals('test@example.com'));
      expect(json['username'], equals('testuser'));
      expect(json['fullName'], equals('Test User'));
      expect(json['userType'], equals(UserType.regular.value));
      expect(json['bio'], equals('Test bio'));
      expect(json['createdAt'], isNotNull);
      expect(json['lastActive'], isNull);
    });

    test('should create UserModel from JSON', () {
      // Arrange
      final json = {
        'id': 'test-id',
        'email': 'test@example.com',
        'username': 'testuser',
        'fullName': 'Test User',
        'userType': UserType.artist.value,
        'profileImageUrl': 'https://example.com/image.jpg',
        'bio': 'Test bio',
        'location': 'Test Location',
        'posts': ['post1'],
        'experiencePoints': 150,
        'level': 3,
        'followCount': 2, // This will be used by EngagementStats
        'createdAt': Timestamp.now(),
      };

      // Act
      final user = UserModel.fromJson(json);

      // Assert
      expect(user.id, equals('test-id'));
      expect(user.email, equals('test@example.com'));
      expect(user.username, equals('testuser'));
      expect(user.fullName, equals('Test User'));
      expect(user.userType, equals(UserType.artist.value));
      expect(user.profileImageUrl, equals('https://example.com/image.jpg'));
      expect(user.bio, equals('Test bio'));
      expect(user.location, equals('Test Location'));
      expect(user.followersCount, equals(2));
      expect(
        user.followingCount,
        equals(0),
      ); // This is hardcoded to 0 in the model
      expect(user.postsCount, equals(1));
      expect(user.experiencePoints, equals(150));
      expect(user.level, equals(3));
    });

    test('should handle null values in JSON conversion', () {
      // Arrange
      final json = {
        'id': 'test-id',
        'email': 'test@example.com',
        'username': 'testuser',
        'fullName': 'Test User',
      };

      // Act
      final user = UserModel.fromJson(json);

      // Assert
      expect(user.id, equals('test-id'));
      expect(user.email, equals('test@example.com'));
      expect(user.username, equals('testuser'));
      expect(user.fullName, equals('Test User'));
      expect(user.profileImageUrl, equals(''));
      expect(user.bio, equals(''));
      expect(user.location, equals(''));
      expect(user.userType, isNull);
      expect(user.followersCount, equals(0)); // Should default to 0
      expect(user.followingCount, equals(0)); // Should default to 0
      expect(user.postsCount, equals(0)); // Should default to 0
      expect(user.experiencePoints, equals(0)); // Should default to 0
      expect(user.level, equals(1)); // Should default to 1
    });

    test('should create copy of UserModel with updated fields', () {
      // Arrange
      final originalUser = UserModel(
        id: 'test-id',
        email: 'test@example.com',
        username: 'testuser',
        fullName: 'Test User',
        userType: UserType.regular.value,
        bio: 'Original bio',
        createdAt: DateTime.now(),
      );

      // Act
      final updatedUser = originalUser.copyWith(
        fullName: 'Updated User',
        bio: 'Updated bio',
        userType: UserType.artist.value,
      );

      // Assert
      expect(updatedUser.id, equals('test-id')); // Unchanged
      expect(updatedUser.email, equals('test@example.com')); // Unchanged
      expect(updatedUser.username, equals('testuser')); // Unchanged
      expect(updatedUser.fullName, equals('Updated User')); // Changed
      expect(updatedUser.bio, equals('Updated bio')); // Changed
      expect(updatedUser.userType, equals(UserType.artist.value)); // Changed
    });

    test('should check if user is artist', () {
      final artistUser = UserModel(
        id: 'test-id',
        email: 'artist@example.com',
        username: 'artistuser',
        fullName: 'Artist User',
        userType: UserType.artist.value,
        createdAt: DateTime.now(),
      );
      expect(artistUser.isArtist, isTrue);

      final regularUser = UserModel(
        id: 'test-id',
        email: 'user@example.com',
        username: 'regularuser',
        fullName: 'Regular User',
        userType: UserType.regular.value,
        createdAt: DateTime.now(),
      );
      expect(regularUser.isArtist, isFalse);
    });

    test('should check user types correctly', () {
      final galleryUser = UserModel(
        id: 'test-id',
        email: 'gallery@example.com',
        username: 'galleryuser',
        fullName: 'Gallery User',
        userType: UserType.gallery.value,
        createdAt: DateTime.now(),
      );
      expect(galleryUser.isGallery, isTrue);

      final moderatorUser = UserModel(
        id: 'test-id',
        email: 'mod@example.com',
        username: 'moduser',
        fullName: 'Mod User',
        userType: UserType.moderator.value,
        createdAt: DateTime.now(),
      );
      expect(moderatorUser.isModerator, isTrue);

      final adminUser = UserModel(
        id: 'test-id',
        email: 'admin@example.com',
        username: 'adminuser',
        fullName: 'Admin User',
        userType: UserType.admin.value,
        createdAt: DateTime.now(),
      );
      expect(adminUser.isAdmin, isTrue);
    });

    test('should use placeholder constructor correctly', () {
      final user = UserModel.placeholder('test-id');
      expect(user.id, equals('test-id'));
      expect(user.email, equals('placeholder@example.com'));
      expect(user.username, equals('placeholder_user'));
      expect(user.fullName, equals('Placeholder User'));
      expect(user.userType, equals(UserType.regular.value));
      expect(user.bio, equals('This is a placeholder bio for UI development'));
      expect(user.location, equals('San Francisco, CA'));
      expect(user.experiencePoints, equals(0));
      expect(user.level, equals(1));
      expect(user.zipCode, equals('94102'));
    });
  });

  group('UserType Tests', () {
    test('should convert UserType to string correctly', () {
      expect(UserType.regular.toString(), equals('user'));
      expect(UserType.artist.toString(), equals('artist'));
      expect(UserType.gallery.toString(), equals('business'));
      expect(UserType.moderator.toString(), equals('moderator'));
      expect(UserType.admin.toString(), equals('admin'));
    });

    test('should get UserType value correctly', () {
      expect(UserType.regular.value, equals('user'));
      expect(UserType.artist.value, equals('artist'));
      expect(UserType.gallery.value, equals('business'));
      expect(UserType.moderator.value, equals('moderator'));
      expect(UserType.admin.value, equals('admin'));
    });

    test('should parse UserType from string correctly', () {
      expect(UserType.fromString('artist'), equals(UserType.artist));
      expect(UserType.fromString('business'), equals(UserType.gallery));
      expect(UserType.fromString('moderator'), equals(UserType.moderator));
      expect(UserType.fromString('admin'), equals(UserType.admin));
      expect(
        UserType.fromString('invalid'),
        equals(UserType.regular),
      ); // Default
      expect(UserType.fromString('user'), equals(UserType.regular));
    });
  });
}
