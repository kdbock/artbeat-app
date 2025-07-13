import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

// Generate mocks
@GenerateMocks([FirebaseAuth, User, UserMetadata])
import 'auth_service_test.mocks.dart';

void main() {
  group('Core AuthService Tests', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
    });

    test('should return current user when authenticated', () {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-uid');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.displayName).thenReturn('Test User');

      // Act
      final user = mockFirebaseAuth.currentUser;

      // Assert
      expect(user, isNotNull);
      expect(user!.uid, equals('test-uid'));
      expect(user.email, equals('test@example.com'));
      expect(user.displayName, equals('Test User'));
    });

    test('should return null when not authenticated', () {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      // Act
      final user = mockFirebaseAuth.currentUser;

      // Assert
      expect(user, isNull);
    });

    test('should handle auth state changes stream', () {
      // Arrange
      final streamController = StreamController<User?>();
      when(
        mockFirebaseAuth.authStateChanges(),
      ).thenAnswer((_) => streamController.stream);

      // Act
      final stream = mockFirebaseAuth.authStateChanges();

      // Assert
      expect(stream, isA<Stream<User?>>());

      // Cleanup
      streamController.close();
    });

    test('should handle user changes stream', () {
      // Arrange
      final streamController = StreamController<User?>();
      when(
        mockFirebaseAuth.userChanges(),
      ).thenAnswer((_) => streamController.stream);

      // Act
      final stream = mockFirebaseAuth.userChanges();

      // Assert
      expect(stream, isA<Stream<User?>>());

      // Cleanup
      streamController.close();
    });

    test('should handle sign out', () async {
      // Arrange
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async => {});

      // Act
      await mockFirebaseAuth.signOut();

      // Assert
      verify(mockFirebaseAuth.signOut()).called(1);
    });

    test('should handle user token refresh', () async {
      // Arrange
      when(
        mockUser.getIdToken(true),
      ).thenAnswer((_) async => 'refreshed-token');

      // Act
      final token = await mockUser.getIdToken(true);

      // Assert
      expect(token, equals('refreshed-token'));
      verify(mockUser.getIdToken(true)).called(1);
    });

    test('should handle user reload', () async {
      // Arrange
      when(mockUser.reload()).thenAnswer((_) async => {});

      // Act
      await mockUser.reload();

      // Assert
      verify(mockUser.reload()).called(1);
    });
  });

  group('User State Management Tests', () {
    late MockUser mockUser;

    setUp(() {
      mockUser = MockUser();
    });

    test('should handle user metadata', () {
      // Arrange
      final mockMetadata = MockUserMetadata();
      when(mockUser.metadata).thenReturn(mockMetadata);
      when(mockMetadata.creationTime).thenReturn(DateTime.parse('2023-01-01'));
      when(
        mockMetadata.lastSignInTime,
      ).thenReturn(DateTime.parse('2023-12-01'));

      // Act
      final metadata = mockUser.metadata;

      // Assert
      expect(metadata, isNotNull);
      expect(metadata.creationTime, equals(DateTime.parse('2023-01-01')));
      expect(metadata.lastSignInTime, equals(DateTime.parse('2023-12-01')));
    });

    test('should handle user email verification status', () {
      // Arrange
      when(mockUser.emailVerified).thenReturn(false);

      // Act
      final isVerified = mockUser.emailVerified;

      // Assert
      expect(isVerified, isFalse);
    });

    test('should handle anonymous user', () {
      // Arrange
      when(mockUser.isAnonymous).thenReturn(true);

      // Act
      final isAnonymous = mockUser.isAnonymous;

      // Assert
      expect(isAnonymous, isTrue);
    });

    test('should handle user provider data', () {
      // Arrange
      final mockProviderData = <UserInfo>[];
      when(mockUser.providerData).thenReturn(mockProviderData);

      // Act
      final providerData = mockUser.providerData;

      // Assert
      expect(providerData, isA<List<UserInfo>>());
      expect(providerData.isEmpty, isTrue);
    });
  });
}
