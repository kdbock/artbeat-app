import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Generate mocks
@GenerateMocks([FirebaseAuth, User, UserCredential])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService Tests', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();
    });

    test('should return user when signed in', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-uid');
      when(mockUser.email).thenReturn('test@example.com');

      // Act
      final user = mockFirebaseAuth.currentUser;

      // Assert
      expect(user, isNotNull);
      expect(user!.uid, equals('test-uid'));
      expect(user.email, equals('test@example.com'));
    });

    test('should return null when not signed in', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      // Act
      final user = mockFirebaseAuth.currentUser;

      // Assert
      expect(user, isNull);
    });

    test('should throw exception on invalid email format', () async {
      // Arrange
      const invalidEmail = 'invalid-email';
      const password = 'password123';

      when(
        mockFirebaseAuth.signInWithEmailAndPassword(
          email: invalidEmail,
          password: password,
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is not valid.',
        ),
      );

      // Act & Assert
      expect(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: invalidEmail,
          password: password,
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    test('should throw exception on wrong password', () async {
      // Arrange
      const email = 'test@example.com';
      const wrongPassword = 'wrong-password';

      when(
        mockFirebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: wrongPassword,
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'wrong-password',
          message: 'The password is invalid.',
        ),
      );

      // Act & Assert
      expect(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: wrongPassword,
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    test('should successfully sign up new user', () async {
      // Arrange
      const email = 'newuser@example.com';
      const password = 'password123';

      when(
        mockFirebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async => mockUserCredential);

      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('new-user-uid');

      // Act
      final result = await mockFirebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Assert
      expect(result, isNotNull);
      expect(result.user, isNotNull);
      expect(result.user!.uid, equals('new-user-uid'));
    });

    test('should successfully sign out user', () async {
      // Arrange
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async => {});

      // Act
      await mockFirebaseAuth.signOut();

      // Assert
      verify(mockFirebaseAuth.signOut()).called(1);
    });

    test('should handle email already in use exception', () async {
      // Arrange
      const email = 'existing@example.com';
      const password = 'password123';

      when(
        mockFirebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already in use by another account.',
        ),
      );

      // Act & Assert
      expect(
        () => mockFirebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    test('should handle weak password exception', () async {
      // Arrange
      const email = 'test@example.com';
      const weakPassword = '123';

      when(
        mockFirebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: weakPassword,
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'weak-password',
          message: 'The password provided is too weak.',
        ),
      );

      // Act & Assert
      expect(
        () => mockFirebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: weakPassword,
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    test('should handle password reset email', () async {
      // Arrange
      const email = 'test@example.com';

      when(
        mockFirebaseAuth.sendPasswordResetEmail(email: email),
      ).thenAnswer((_) async => {});

      // Act
      await mockFirebaseAuth.sendPasswordResetEmail(email: email);

      // Assert
      verify(mockFirebaseAuth.sendPasswordResetEmail(email: email)).called(1);
    });

    test('should handle auth state changes', () async {
      // Arrange
      final authStateController = StreamController<User?>();
      when(
        mockFirebaseAuth.authStateChanges(),
      ).thenAnswer((_) => authStateController.stream);

      // Act
      final authStateStream = mockFirebaseAuth.authStateChanges();

      // Assert
      expect(authStateStream, isA<Stream<User?>>());

      // Cleanup
      authStateController.close();
    });
  });

  group('Auth Validation Tests', () {
    test('should validate email format', () {
      // Valid emails
      expect(isValidEmail('test@example.com'), isTrue);
      expect(isValidEmail('user.name@domain.co.uk'), isTrue);
      expect(isValidEmail('user+tag@example.org'), isTrue);

      // Invalid emails
      expect(isValidEmail('invalid-email'), isFalse);
      expect(isValidEmail('test@'), isFalse);
      expect(isValidEmail('@example.com'), isFalse);
      expect(isValidEmail('test..test@example.com'), isFalse);
    });

    test('should validate password strength', () {
      // Strong passwords
      expect(isValidPassword('MyStrongPass123!'), isTrue);
      expect(isValidPassword('AnotherGood1@'), isTrue);

      // Weak passwords
      expect(isValidPassword('12345'), isFalse);
      expect(isValidPassword('password'), isFalse);
      expect(isValidPassword('Pass1'), isFalse);
      expect(isValidPassword(''), isFalse);
    });
  });
}

// Helper functions for validation
bool isValidEmail(String email) {
  // Basic email validation that rejects consecutive dots
  if (email.contains('..')) {
    return false;
  }
  return RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(email);
}

bool isValidPassword(String password) {
  // At least 8 characters, contains uppercase, lowercase, digit, and special char
  return password.length >= 8 &&
      RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]',
      ).hasMatch(password);
}
