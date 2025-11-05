# 🔧 Firebase Test Configuration Setup Guide

## 📋 Overview

This guide shows you how to set up Firebase test configuration for your ArtBeat authentication widget tests, allowing your automated tests to run without Firebase initialization errors.

## 🎯 What We've Set Up

### 1. **Dependencies Added**

```yaml
dev_dependencies:
  firebase_auth_mocks: ^0.15.1 # Mock Firebase Auth
  fake_cloud_firestore: ^4.0.0 # Mock Firestore (already had)
```

### 2. **Firebase Test Setup** (`test/firebase_test_setup.dart`)

- Initializes Firebase with test configuration
- Provides mock FirebaseAuth and Firestore instances
- Manages test user authentication state
- Handles cleanup between tests

### 3. **Updated Test File** (`test/auth_onboarding_firebase_test.dart`)

- Uses Firebase test setup for all auth screens
- Tests UI components with real Firebase instances (mocked)
- Includes authentication state testing
- Covers form interactions and button taps

## 🚀 How to Use

### Step 1: Run the Firebase-Enabled Tests

```bash
# Run the new Firebase-enabled test file
flutter test test/auth_onboarding_firebase_test.dart

# Run with verbose output
flutter test test/auth_onboarding_firebase_test.dart --verbose

# Run all tests (including Firebase ones)
flutter test
```

### Step 2: Using Firebase Test Setup in Your Own Tests

```dart
import 'firebase_test_setup.dart';

void main() {
  group('Your Test Group', () {

    setUpAll(() async {
      // Initialize Firebase for all tests
      await FirebaseTestSetup.initializeFirebaseForTesting();
    });

    tearDownAll(() async {
      // Clean up Firebase after all tests
      await FirebaseTestSetup.cleanup();
    });

    setUp(() async {
      // Reset Firebase state before each test
      await FirebaseTestSetup.reset();
    });

    testWidgets('Your widget test', (tester) async {
      // Create auth service with mocked Firebase
      final authService = AuthService(
        auth: FirebaseTestSetup.mockAuth,
        firestore: FirebaseTestSetup.fakeFirestore,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: YourAuthScreen(authService: authService),
        ),
      );

      await tester.pump();

      // Your test assertions here
      expect(find.byType(YourAuthScreen), findsOneWidget);
    });
  });
}
```

### Step 3: Testing Authentication States

```dart
testWidgets('Test authenticated user state', (tester) async {
  // Sign in a test user
  await FirebaseTestSetup.signInTestUser(
    uid: 'test-user-123',
    email: 'test@example.com',
    displayName: 'Test User',
  );

  // Now test your widget with authenticated state
  expect(FirebaseTestSetup.mockAuth.currentUser, isNotNull);

  // Your widget test here...
});

testWidgets('Test unauthenticated state', (tester) async {
  // Ensure user is signed out
  await FirebaseTestSetup.signOutTestUser();

  // Test your widget with unauthenticated state
  expect(FirebaseTestSetup.mockAuth.currentUser, isNull);

  // Your widget test here...
});
```

## 🧪 What This Enables

### ✅ **Widget Tests That Now Work**

- SplashScreen (no more Firebase initialization errors)
- LoginScreen (with mocked AuthService)
- RegisterScreen (with mocked AuthService)
- ForgotPasswordScreen (with mocked AuthService)
- EmailVerificationScreen
- ProfileCreateScreen

### ✅ **Authentication Flow Testing**

- User sign-in/sign-out state changes
- Session persistence testing
- Authentication status checking
- Form validation with Firebase backend

### ✅ **Service Integration Testing**

- AuthService with mocked Firebase
- Firestore operations with fake data
- Error handling with controlled responses

## 🎯 Test Coverage Achieved

| Feature                | Test Type   | Status |
| ---------------------- | ----------- | ------ |
| Splash screen display  | Widget Test | ✅     |
| Login screen UI        | Widget Test | ✅     |
| Registration screen UI | Widget Test | ✅     |
| Forgot password UI     | Widget Test | ✅     |
| Form text input        | Integration | ✅     |
| Button interactions    | Integration | ✅     |
| Authentication states  | Unit Test   | ✅     |
| Session management     | Unit Test   | ✅     |
| Service instantiation  | Unit Test   | ✅     |

## 🔄 Running Tests

### Quick Test Commands

```bash
# Run Firebase-enabled auth tests
flutter test test/auth_onboarding_firebase_test.dart

# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test group
flutter test test/auth_onboarding_firebase_test.dart --plain-name "Form Interaction"
```

### Expected Results

When you run the Firebase-enabled tests, you should see:

- ✅ All widget tests pass without Firebase errors
- ✅ UI components render correctly
- ✅ Form interactions work properly
- ✅ Authentication state changes work
- ✅ Services can be instantiated with mocked Firebase

## 🛠️ Troubleshooting

### Common Issues

1. **"Firebase already initialized" error**

   ```dart
   // Solution: Check if already initialized
   if (Firebase.apps.isEmpty) {
     await Firebase.initializeApp(options: testOptions);
   }
   ```

2. **Mock user not working**

   ```dart
   // Ensure you're creating the user correctly
   await FirebaseTestSetup.signInTestUser();
   expect(FirebaseTestSetup.mockAuth.currentUser, isNotNull);
   ```

3. **Widget not finding elements**
   ```dart
   // Add pump calls to allow widget to build
   await tester.pumpWidget(widget);
   await tester.pump(); // Allow async operations to complete
   ```

## 🎉 Benefits

### ✅ **Reliable Testing**

- No more Firebase initialization failures
- Consistent test results across environments
- Faster test execution (no network calls)

### ✅ **Better Coverage**

- Test authentication flows without real Firebase
- Mock different user states easily
- Test error conditions safely

### ✅ **Developer Experience**

- Tests run offline
- No need for Firebase test project setup
- Easy to debug and maintain

## 📈 Next Steps

1. **Add More Test Scenarios**

   - Network error simulation
   - Different user types (Artist/Collector)
   - Edge cases and error conditions

2. **Integration Tests**

   - End-to-end authentication flows
   - Multi-screen navigation testing
   - Real Firebase integration testing

3. **Performance Tests**
   - Widget rendering performance
   - Authentication speed testing
   - Memory usage monitoring

---

**Result**: Your authentication tests now work properly with Firebase! 🎉

Run `flutter test test/auth_onboarding_firebase_test.dart` to see all your authentication features being tested successfully.
