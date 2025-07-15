import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:artbeat_auth/src/screens/login_screen.dart';
import 'package:artbeat_auth/src/screens/register_screen.dart';
import 'package:artbeat_auth/src/screens/forgot_password_screen.dart';
import 'package:artbeat_auth/src/services/auth_service.dart';
import 'package:artbeat_core/artbeat_core.dart' show ArtbeatButton;

// Import generated mocks
import 'auth_screens_test.mocks.dart';

@GenerateMocks([FirebaseAuth, FirebaseFirestore, User, UserCredential])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseFirestore mockFirebaseFirestore;
  // Removed unused mockUser and mockUserCredential
  late AuthService authService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final binding = TestDefaultBinaryMessengerBinding.instance;

    // Mock firebase_core
    const coreChannel = MethodChannel('plugins.flutter.io/firebase_core');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(coreChannel, (
      methodCall,
    ) async {
      if (methodCall.method == 'Firebase#initializeCore') {
        return [
          {
            'name': 'default',
            'options': {
              'apiKey': 'test',
              'appId': 'test',
              'messagingSenderId': 'test',
              'projectId': 'test',
            },
            'pluginConstants': <String, Object?>{},
          },
        ];
      }
      if (methodCall.method == 'Firebase#initializeApp') {
        return {
          'name': methodCall.arguments['name'],
          'options': methodCall.arguments['options'],
          'pluginConstants': <String, Object?>{},
        };
      }
      return null;
    });

    // Mock pigeon channel for firebase_core (used by newer Firebase)
    const pigeonCoreChannel = MethodChannel('flutter.firebase/core');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(pigeonCoreChannel, (
      methodCall,
    ) async {
      if (methodCall.method == 'initializeCore') {
        return [
          {
            'name': 'default',
            'options': {
              'apiKey': 'test',
              'appId': 'test',
              'messagingSenderId': 'test',
              'projectId': 'test',
            },
            'pluginConstants': <String, Object?>{},
          },
        ];
      }
      if (methodCall.method == 'initializeApp') {
        return {
          'name': methodCall.arguments['name'],
          'options': methodCall.arguments['options'],
          'pluginConstants': <String, Object?>{},
        };
      }
      return null;
    });

    // Mock firebase_auth
    const authChannel = MethodChannel('plugins.flutter.io/firebase_auth');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(authChannel, (
      methodCall,
    ) async {
      // Return null for all calls to avoid platform exceptions
      return null;
    });

    // Mock cloud_firestore
    const firestoreChannel = MethodChannel(
      'plugins.flutter.io/cloud_firestore',
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(firestoreChannel, (
      methodCall,
    ) async {
      // Return null for all calls to avoid platform exceptions
      return null;
    });

    await Firebase.initializeApp();
  });

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirebaseFirestore = MockFirebaseFirestore();

    // Create AuthService with mocked dependencies via constructor
    authService = AuthService(
      auth: mockFirebaseAuth,
      firestore: mockFirebaseFirestore,
    );
  });

  group('Login Screen Tests', () {
    testWidgets('should display login form elements', (
      WidgetTester tester,
    ) async {
      // Setup mock behavior
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(authService: authService)),
      );

      // Check if the login form elements are present
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.widgetWithText(ArtbeatButton, 'Login'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('should show validation errors for empty fields', (
      WidgetTester tester,
    ) async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(authService: authService)),
      );

      // Find and tap the login button without entering credentials
      final loginButton = find.widgetWithText(ArtbeatButton, 'Login');
      await tester.tap(loginButton);
      await tester.pump();

      // Check for validation messages
      expect(find.text('Please enter your email.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets('should show error for invalid email format', (
      WidgetTester tester,
    ) async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(authService: authService)),
      );

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Tap login button
      await tester.tap(find.widgetWithText(ArtbeatButton, 'Login'));
      await tester.pump();

      // Check for email validation error
      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('should navigate to forgot password screen', (
      WidgetTester tester,
    ) async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: authService),
          routes: {
            '/forgot-password': (context) =>
                ForgotPasswordScreen(authService: authService),
          },
        ),
      );

      // Tap forgot password link
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Check if we navigated to forgot password screen
      expect(find.text('Reset Password'), findsWidgets);
    });

    testWidgets('should toggle password visibility', (
      WidgetTester tester,
    ) async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(authService: authService)),
      );

      // Find password field
      final passwordField = find.byType(TextFormField).last;

      // Check if password field exists
      expect(passwordField, findsOneWidget);

      // Check if visibility toggle icon exists
      final visibilityToggle = find.byIcon(Icons.visibility);
      final visibilityOffToggle = find.byIcon(Icons.visibility_off);

      // At least one visibility icon should be present
      expect(
        visibilityToggle.evaluate().isNotEmpty ||
            visibilityOffToggle.evaluate().isNotEmpty,
        isTrue,
      );
    });
  });

  group('Register Screen Tests', () {
    testWidgets('should display register form elements', (
      WidgetTester tester,
    ) async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(home: RegisterScreen(authService: authService)),
      );

      // Check if the register form elements are present
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.widgetWithText(ArtbeatButton, 'Register'), findsOneWidget);
      expect(find.text('Already have an account? Log in'), findsOneWidget);
    });

    testWidgets('should show validation errors for empty fields', (
      WidgetTester tester,
    ) async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(home: RegisterScreen(authService: authService)),
      );

      // Find and tap the register button without entering data
      final registerButton = find.widgetWithText(ArtbeatButton, 'Register');
      await tester.tap(registerButton);
      await tester.pump();

      // Check for validation messages
      expect(find.text('Please enter your email.'), findsOneWidget);
      expect(find.text('Please enter a password.'), findsOneWidget);
      expect(find.text('Please confirm your password.'), findsOneWidget);
    });

    testWidgets('should show error for password mismatch', (
      WidgetTester tester,
    ) async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(home: RegisterScreen(authService: authService)),
      );

      // Enter different passwords
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'John Doe');
      await tester.enterText(textFields.at(1), 'john@example.com');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), 'different456');

      // Tap register button
      await tester.tap(find.widgetWithText(ArtbeatButton, 'Register'));
      await tester.pump();

      // Check for password mismatch error
      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('should show error for weak password', (
      WidgetTester tester,
    ) async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(home: RegisterScreen(authService: authService)),
      );

      // Enter weak password
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'John Doe');
      await tester.enterText(textFields.at(1), 'john@example.com');
      await tester.enterText(textFields.at(2), '123');
      await tester.enterText(textFields.at(3), '123');

      // Tap register button
      await tester.tap(find.widgetWithText(ArtbeatButton, 'Register'));
      await tester.pump();

      // Check for weak password error
      expect(
        find.text('Password must be at least 8 characters.'),
        findsOneWidget,
      );
    });
  });

  group('Forgot Password Screen Tests', () {
    testWidgets('should display forgot password form elements', (
      WidgetTester tester,
    ) async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(home: ForgotPasswordScreen(authService: authService)),
      );

      // Check if the forgot password form elements are present
      expect(find.text('Reset Password'), findsWidgets);
      expect(find.text('Email'), findsOneWidget);
      expect(
        find.widgetWithText(ArtbeatButton, 'Reset Password'),
        findsOneWidget,
      );
      expect(find.text('Back to Login'), findsOneWidget);
    });

    testWidgets('should show validation error for empty email', (
      WidgetTester tester,
    ) async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(home: ForgotPasswordScreen(authService: authService)),
      );

      // Tap reset password button without entering email
      await tester.tap(find.widgetWithText(ArtbeatButton, 'Reset Password'));
      await tester.pump();

      // Check for validation error
      expect(find.text('Please enter your email.'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email', (
      WidgetTester tester,
    ) async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(home: ForgotPasswordScreen(authService: authService)),
      );

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField), 'invalid-email');

      // Tap reset password button
      await tester.tap(find.widgetWithText(ArtbeatButton, 'Reset Password'));
      await tester.pump();

      // Check for validation error
      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('should navigate back to login screen', (
      WidgetTester tester,
    ) async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: ForgotPasswordScreen(authService: authService),
          routes: {
            '/login': (context) => LoginScreen(authService: authService),
          },
        ),
      );

      // Tap back to login button
      await tester.tap(find.text('Back to Login'));
      await tester.pumpAndSettle();

      // Check if we navigated back to login screen (check for login button)
      expect(find.widgetWithText(ArtbeatButton, 'Login'), findsOneWidget);
    });
  });

  group('Form Validation Tests', () {
    test('should validate email format correctly', () {
      // Valid emails
      expect(isValidEmail('test@example.com'), isTrue);
      expect(isValidEmail('user.name@domain.co.uk'), isTrue);
      expect(isValidEmail('user+tag@example.org'), isTrue);

      // Invalid emails
      expect(isValidEmail('invalid-email'), isFalse);
      expect(isValidEmail('test@'), isFalse);
      expect(isValidEmail('@example.com'), isFalse);
      expect(isValidEmail(''), isFalse);
    });

    test('should validate password strength correctly', () {
      // Valid passwords
      expect(isValidPassword('MyStrongPass123!'), isTrue);
      expect(isValidPassword('AnotherGood1@'), isTrue);

      // Invalid passwords
      expect(isValidPassword('12345'), isFalse);
      expect(isValidPassword('password'), isFalse);
      expect(isValidPassword('Pass1'), isFalse);
      expect(isValidPassword(''), isFalse);
    });

    test('should validate full name correctly', () {
      // Valid names
      expect(isValidFullName('John Doe'), isTrue);
      expect(isValidFullName('Jane Smith'), isTrue);
      expect(isValidFullName('Mary Jane Watson'), isTrue);

      // Invalid names
      expect(isValidFullName(''), isFalse);
      expect(isValidFullName('   '), isFalse);
      expect(
        isValidFullName('John'),
        isFalse,
      ); // Should require at least first and last name
    });
  });
}

// Helper validation functions
bool isValidEmail(String email) {
  return RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(email);
}

bool isValidPassword(String password) {
  return password.length >= 8 &&
      RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]',
      ).hasMatch(password);
}

bool isValidFullName(String name) {
  final trimmedName = name.trim();
  return trimmedName.isNotEmpty && trimmedName.split(' ').length >= 2;
}
