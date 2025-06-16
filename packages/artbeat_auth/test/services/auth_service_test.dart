import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

// Import the generated mocks
import 'auth_service_test.mocks.dart';

// Generate mocks for Firebase classes
@GenerateMocks([
  FirebaseAuth,
  UserCredential,
  User,
])
void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late AuthService authService;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();
    
    // Set up the AuthService with mocked dependencies
    authService = AuthService();
    authService.setDependenciesForTesting(mockFirebaseAuth, fakeFirestore);
  });

  group('AuthService Tests', () {
    test('isLoggedIn returns true when user is authenticated', () {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      
      // Act & Assert
      expect(authService.isLoggedIn, isTrue);
    });

    test('isLoggedIn returns false when no user is authenticated', () {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(null);
      
      // Act & Assert
      expect(authService.isLoggedIn, isFalse);
    });

    test('getCurrentUser returns the authenticated user', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      
      // Act
      final result = await authService.getCurrentUser();
      
      // Assert
      expect(result, equals(mockUser));
    });

    test('signInWithEmailAndPassword returns UserCredential on success', () async {
      // Arrange
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => mockUserCredential);
      
      // Act
      final result = await authService.signInWithEmailAndPassword(
        'test@example.com',
        'password123',
      );
      
      // Assert
      expect(result, equals(mockUserCredential));
      verify(mockFirebaseAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    test('registerWithEmailAndPassword creates user and updates profile', () async {
      // Arrange
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: 'new@example.com',
        password: 'newpassword123',
      )).thenAnswer((_) async => mockUserCredential);
      when(mockUserCredential.user).thenReturn(mockUser);
      
      // Act
      final result = await authService.registerWithEmailAndPassword(
        'new@example.com',
        'newpassword123',
        'New User',
        zipCode: '12345',
      );
      
      // Assert
      expect(result, equals(mockUserCredential));
      verify(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: 'new@example.com',
        password: 'newpassword123',
      )).called(1);
      verify(mockUser.updateDisplayName('New User')).called(1);
      
      // Verify user document was created in Firestore
      when(mockUser.uid).thenReturn('test-user-id');
      final userDoc = await fakeFirestore.collection('users').doc('test-user-id').get();
      expect(userDoc.exists, isTrue);
      expect(userDoc.data()?['fullName'], equals('New User'));
      expect(userDoc.data()?['zipCode'], equals('12345'));
    });

    test('resetPassword sends password reset email', () async {
      // Arrange
      when(mockFirebaseAuth.sendPasswordResetEmail(
        email: 'reset@example.com',
      )).thenAnswer((_) async => {});
      
      // Act
      await authService.resetPassword('reset@example.com');
      
      // Assert
      verify(mockFirebaseAuth.sendPasswordResetEmail(
        email: 'reset@example.com',
      )).called(1);
    });

    test('signOut signs out the current user', () async {
      // Arrange
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async => {});
      
      // Act
      await authService.signOut();
      
      // Assert
      verify(mockFirebaseAuth.signOut()).called(1);
    });

    test('authStateChanges returns stream of auth state changes', () {
      // Arrange
      final authStateStream = Stream<User?>.fromIterable([mockUser, null]);
      when(mockFirebaseAuth.authStateChanges()).thenAnswer((_) => authStateStream);
      
      // Act & Assert
      expect(authService.authStateChanges(), emitsInOrder([mockUser, null]));
      verify(mockFirebaseAuth.authStateChanges()).called(1);
    });
  });
}
