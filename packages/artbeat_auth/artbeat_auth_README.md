# ARTbeat Authentication Module

The `artbeat_auth` package provides comprehensive authentication functionality for the ARTbeat Flutter application. This module handles user registration, login, password recovery, and authentication state management using Firebase Authentication and Cloud Firestore.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Services](#services)
- [Screens](#screens)
- [Widgets](#widgets)
- [Constants](#constants)
- [Testing](#testing)
- [Dependencies](#dependencies)
- [Usage Examples](#usage-examples)
- [Error Handling](#error-handling)
- [Security Considerations](#security-considerations)

## Overview

The authentication module is built as a standalone Flutter package that integrates seamlessly with Firebase services. It provides a complete authentication flow with modern UI components and robust error handling.

### Key Characteristics

- **Modular Design**: Self-contained package with clear boundaries
- **Firebase Integration**: Full Firebase Auth and Firestore integration
- **Testable Architecture**: Dependency injection support for testing
- **Modern UI**: Gradient backgrounds, animations, and responsive design
- **Location-Aware**: ZIP code collection for location-based features
- **Comprehensive Validation**: Form validation with user-friendly error messages

## Features

### Core Authentication Features

- ✅ **Email/Password Registration** with profile creation
- ✅ **Email/Password Login** with automatic profile verification
- ✅ **Password Recovery** via email reset
- ✅ **Email Verification** with automatic resend and cooldown
- ✅ **Authentication State Management** with real-time updates
- ✅ **Automatic Profile Creation** in Firestore during registration
- ✅ **Profile Verification** and fallback creation during login
- ✅ **Location Integration** with ZIP code collection
- ✅ **Terms of Service Agreement** during registration

### UI/UX Features

- ✅ **Animated Logo** with scaling animation
- ✅ **Gradient Backgrounds** with brand colors
- ✅ **Password Visibility Toggle** for better UX
- ✅ **Loading States** with progress indicators
- ✅ **Responsive Design** with maximum width constraints
- ✅ **Error Handling** with contextual error messages
- ✅ **Navigation Flow** with proper route management

### Security Features

- ✅ **Firebase Security Rules** compliance
- ✅ **Input Validation** and sanitization
- ✅ **Secure Password Handling** (no plain text storage)
- ✅ **Authentication State Persistence** across app restarts
- ✅ **Automatic Session Management** with Firebase

## Architecture

### Package Structure

```
artbeat_auth/
├── lib/
│   ├── artbeat_auth.dart          # Main export file
│   └── src/
│       ├── constants/
│       │   └── routes.dart        # Route constants
│       ├── models/
│       │   └── models.dart        # Model exports (empty)
│       ├── screens/
│       │   ├── login_screen.dart
│       │   ├── register_screen.dart
│       │   ├── forgot_password_screen.dart
│       │   ├── profile_create_screen.dart    # ✅ IMPLEMENTED
│       │   ├── email_verification_screen.dart # ✅ IMPLEMENTED
│       │   └── screens.dart       # Screen exports
│       ├── services/
│       │   ├── auth_service.dart
│       │   ├── auth_profile_service.dart
│       │   └── services.dart      # Service exports
│       └── widgets/
│           ├── auth_header.dart
│           └── widgets.dart       # Widget exports
├── test/                          # Unit and widget tests
├── assets/                        # Images and icons
└── pubspec.yaml                   # Package dependencies
```

### Current Implementation Status

- ✅ **Core Authentication**: Login, Register, Password Reset screens implemented
- ✅ **Email Verification**: Email verification screen with resend functionality
- ✅ **Profile Creation**: Profile creation screen (delegates to artbeat_profile package)
- ✅ **Services**: Auth service and profile management fully functional
- ✅ **UI Components**: Modern screens with animations, validation, and responsive design
- ✅ **Testing**: Comprehensive test coverage with mocked Firebase services
- ✅ **Complete Flow**: Full authentication flow from registration to dashboard

### Design Patterns

- **Service Layer Pattern**: Business logic separated into services
- **Dependency Injection**: Constructor injection for testability
- **State Management**: StatefulWidget with proper lifecycle management
- **Error Handling**: Try-catch with user-friendly error messages
- **Validation Pattern**: Form validation with custom validators

## Services

### AuthService

The core authentication service that handles Firebase Auth operations.

#### Key Methods

```dart
class AuthService {
  // Authentication state
  User? get currentUser
  bool get isLoggedIn
  bool get isEmailVerified
  Stream<User?> authStateChanges()

  // Authentication operations
  Future<UserCredential> signInWithEmailAndPassword(String email, String password)
  Future<UserCredential> registerWithEmailAndPassword(String email, String password, String fullName, {required String zipCode})
  Future<void> resetPassword(String email)
  Future<void> signOut()

  // Email verification
  Future<void> sendEmailVerification()
  Future<void> reloadUser()
}
```

#### Features

- **Constructor Injection**: Optional Firebase dependencies for testing
- **Automatic Profile Creation**: Creates Firestore user document during registration
- **Error Handling**: Comprehensive Firebase exception handling
- **Debug Logging**: Detailed logging for development and debugging
- **Fallback Handling**: Continues operation even if Firestore creation fails

#### Registration Process

1. Create Firebase Auth account with email/password
2. Set display name in Firebase Auth
3. Create user document in Firestore with:
   - User ID, full name, email, ZIP code
   - Timestamps (created/updated)
   - User type (default: 'regular')
   - Empty arrays for posts, followers, following, captures
   - Counter fields (followersCount, followingCount, etc.)
   - Verification status (default: false)

### AuthProfileService

A singleton service for authentication status checking and profile management.

#### Key Methods

```dart
class AuthProfileService {
  // Singleton pattern
  static final AuthProfileService _instance = AuthProfileService._internal();
  factory AuthProfileService() => _instance;

  // Authentication status
  bool get isAuthenticated
  User? get currentUser

  // Profile operations
  Future<String> checkAuthStatus({bool requireEmailVerification = false})
  Future<Map<String, dynamic>?> getUserProfile()
  Future<void> signOut()
}
```

#### Authentication Flow

1. **Check Authentication**: Verify Firebase Auth status
2. **Email Verification**: Check if email is verified (if required)
3. **Profile Verification**: Check if Firestore profile exists
4. **Route Determination**: Return appropriate route based on status:
   - Not authenticated → Login screen
   - Authenticated but email not verified → Email verification screen
   - Authenticated but no profile → Profile creation screen
   - Authenticated with profile → Dashboard

## Screens

### LoginScreen

Email/password login with automatic profile verification.

#### Features

- **Animated Logo**: Scaling animation on load
- **Form Validation**: Email and password validation
- **Password Toggle**: Show/hide password functionality
- **Loading States**: Progress indicator during authentication
- **Profile Verification**: Automatic Firestore profile creation if missing
- **Navigation Handling**: Smart navigation based on context
- **Error Handling**: Firebase exception handling with user-friendly messages

#### Key Components

```dart
class LoginScreen extends StatefulWidget {
  final AuthService? authService; // Optional for testing

  const LoginScreen({super.key, this.authService});
}
```

#### Login Process

1. Validate form inputs
2. Authenticate with Firebase Auth
3. Verify/create Firestore profile
4. Navigate to dashboard or return success

### RegisterScreen

User registration with profile creation and location collection.

#### Features

- **Multi-Field Form**: First name, last name, email, password, ZIP code
- **Location Integration**: Automatic ZIP code detection from GPS
- **Password Confirmation**: Confirm password field with validation
- **Terms Agreement**: Terms of Service and Privacy Policy agreement
- **Comprehensive Validation**: Email format, password strength, required fields
- **Profile Creation**: Automatic Firestore document creation
- **Error Handling**: Detailed error messages for registration failures

#### Key Components

```dart
class RegisterScreen extends StatefulWidget {
  final AuthService? authService; // Optional for testing

  const RegisterScreen({super.key, this.authService});
}
```

#### Registration Process

1. Validate all form fields
2. Check terms agreement
3. Create Firebase Auth account
4. Create Firestore user profile
5. Navigate to dashboard

#### Location Features

- **GPS Integration**: Automatic ZIP code detection
- **Manual Entry**: Fallback to manual ZIP code entry
- **Error Handling**: Location permission and service errors

### ForgotPasswordScreen

Password recovery via email reset.

#### Features

- **Email Validation**: Proper email format validation
- **Reset Confirmation**: Visual confirmation when reset email is sent
- **Error Handling**: User-friendly error messages
- **Clean UI**: Focused interface for password recovery
- **Navigation**: Easy return to login screen

#### Key Components

```dart
class ForgotPasswordScreen extends StatefulWidget {
  final AuthService? authService; // Optional for testing

  const ForgotPasswordScreen({super.key, this.authService});
}
```

#### Reset Process

1. Validate email format
2. Send password reset email via Firebase
3. Show confirmation message
4. Handle errors gracefully

### EmailVerificationScreen

Email verification with automatic checking and resend functionality.

#### Features

- **Automatic Verification Check**: Polls Firebase for email verification status
- **Resend Functionality**: Resend verification email with cooldown timer
- **Skip Option**: Allow users to skip verification temporarily
- **Real-time Updates**: Automatically redirects when email is verified
- **Error Handling**: Comprehensive error handling for verification failures
- **Loading States**: Visual feedback during verification operations

#### Key Components

```dart
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});
}
```

#### Verification Process

1. Check current user's email verification status
2. Start automatic polling for verification updates
3. Provide resend functionality with cooldown
4. Handle verification success and redirect
5. Allow skip option for optional verification

#### Features

- **Automatic Polling**: Checks verification status every 3 seconds
- **Resend Cooldown**: 60-second cooldown between resend attempts
- **Success Handling**: Automatic redirect to dashboard when verified
- **Skip Functionality**: Optional skip for non-critical flows

### ProfileCreateScreen

Profile creation screen that delegates to the comprehensive profile creation flow.

#### Features

- **Authentication Check**: Verifies user is authenticated before proceeding
- **Delegation Pattern**: Uses artbeat_profile package for comprehensive profile creation
- **Error Handling**: Redirects to login if no authenticated user
- **Seamless Integration**: Integrates with existing authentication flow

#### Key Components

```dart
class ProfileCreateScreen extends StatelessWidget {
  const ProfileCreateScreen({super.key});
}
```

#### Creation Process

1. Verify user authentication status
2. Redirect to login if not authenticated
3. Delegate to CreateProfileScreen from artbeat_profile
4. Handle profile creation completion

## Widgets

### AuthHeader

A specialized header widget for authentication screens.

#### Features

- **Brand Colors**: Custom color scheme (#46a8c3 background, #00bf63 text/icons)
- **Limelight Font**: Custom typography for branding
- **Navigation Support**: Back button and menu functionality
- **Action Buttons**: Search, chat, and developer tools
- **Package Menu**: Bottom sheet with auth-specific navigation
- **Developer Tools**: Debug utilities for development

#### Key Components

```dart
class AuthHeader extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final bool showSearch;
  final bool showChat;
  final bool showDeveloper;
  // ... callback functions
}
```

#### Menu Features

- **Package Navigation**: Quick access to auth screens
- **Developer Tools**: Auth cache clearing and flow testing
- **Responsive Design**: Adapts to different screen sizes

## Constants

### AuthRoutes

Centralized route management for authentication flows.

#### Route Definitions

```dart
class AuthRoutes {
  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';

  // Post-auth routes
  static const String dashboard = '/dashboard';
  static const String profileCreate = '/profile/create';
}
```

#### Helper Methods

- `isAuthRoute(String route)`: Check if route is auth-related
- `getDefaultPostAuthRoute()`: Get dashboard route
- `getProfileCreationRoute()`: Get profile creation route
- `getEmailVerificationRoute()`: Get email verification route
- `getDefaultUnauthenticatedRoute()`: Get login route

## Testing

### Test Coverage

The package includes comprehensive tests for both services and UI components.

#### Service Tests (`auth_service_test.dart`)

- **Mock Dependencies**: Firebase Auth and Firestore mocking
- **Authentication States**: Signed in/out state testing
- **Error Scenarios**: Invalid email, network errors, etc.
- **User Credential Testing**: Registration and login flows

#### Screen Tests (`auth_screens_test.dart`)

- **Widget Testing**: UI component rendering and interaction
- **Form Validation**: Input validation and error display
- **Navigation Testing**: Route transitions and navigation flows
- **Mock Services**: Service layer mocking for isolated testing

#### Test Setup

```dart
@GenerateMocks([FirebaseAuth, FirebaseFirestore, User, UserCredential])
void main() {
  // Test setup with mocked Firebase services
}
```

### Testing Best Practices

- **Dependency Injection**: Services accept optional dependencies for testing
- **Mock Generation**: Automated mock generation with Mockito
- **Widget Testing**: Comprehensive UI testing with flutter_test
- **Isolated Testing**: Each component tested in isolation

## Dependencies

### Core Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^4.0.0
  firebase_auth: ^6.0.1
  cloud_firestore: ^6.0.0

  # ARTbeat packages
  artbeat_core:
    path: ../artbeat_core
  artbeat_profile:
    path: ../artbeat_profile

  # Utilities
  provider: ^6.0.5
  intl: ^0.20.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  mockito: ^5.4.4
  build_runner: ^2.4.10
```

### Package Relationships

- **artbeat_core**: Shared models, services, and UI components
- **artbeat_profile**: Profile creation and management screens
- **Firebase Suite**: Authentication and database services
- **Provider**: State management (inherited from core)
- **Intl**: Internationalization support

## Usage Examples

### Basic Authentication Flow

```dart
import 'package:artbeat_auth/artbeat_auth.dart';

// Initialize auth service
final authService = AuthService();

// Check authentication status
final authProfileService = AuthProfileService();
final route = await authProfileService.checkAuthStatus();

// Navigate based on auth status
Navigator.pushReplacementNamed(context, route);
```

### Custom Login Implementation

```dart
// Use LoginScreen with custom auth service
class CustomLoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      authService: CustomAuthService(), // Optional custom service
    );
  }
}
```

### Registration with Location

```dart
// Register user with automatic location detection
final authService = AuthService();

try {
  final userCredential = await authService.registerWithEmailAndPassword(
    'user@example.com',
    'securePassword123',
    'John Doe',
    zipCode: '12345', // Can be auto-detected in RegisterScreen
  );

  // User registered and profile created
  print('User registered: ${userCredential.user?.uid}');
} catch (e) {
  // Handle registration error
  print('Registration failed: $e');
}
```

### Authentication State Listening

```dart
// Listen to authentication state changes
final authService = AuthService();

StreamBuilder<User?>(
  stream: authService.authStateChanges(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return DashboardScreen(); // User is authenticated
    } else {
      return LoginScreen(); // User is not authenticated
    }
  },
);
```

## Error Handling

### Firebase Exception Handling

The package provides comprehensive error handling for Firebase operations:

#### Login Errors

- `user-not-found`: No account with this email
- `wrong-password`: Incorrect password
- `invalid-email`: Invalid email format
- `user-disabled`: Account has been disabled
- `too-many-requests`: Too many failed attempts

#### Registration Errors

- `email-already-in-use`: Account already exists
- `invalid-email`: Invalid email format
- `weak-password`: Password doesn't meet requirements
- `operation-not-allowed`: Email/password auth not enabled

#### Password Reset Errors

- `user-not-found`: No account with this email
- `invalid-email`: Invalid email format

### Error Display

Errors are displayed using Material Design SnackBars with appropriate colors and durations:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(errorMessage),
    backgroundColor: Colors.red,
    duration: const Duration(seconds: 5),
  ),
);
```

## Security Considerations

### Authentication Security

- **Firebase Security**: Leverages Firebase's enterprise-grade security
- **Password Handling**: No plain text password storage
- **Session Management**: Automatic token refresh and validation
- **Input Sanitization**: All inputs are validated and sanitized

### Data Protection

- **Firestore Rules**: Proper security rules for user data access
- **Profile Privacy**: User data only accessible to authenticated users
- **Location Data**: ZIP code stored securely with user consent

### Best Practices

- **HTTPS Only**: All Firebase communication over HTTPS
- **Token Validation**: Automatic token validation and refresh
- **Error Handling**: No sensitive information in error messages
- **Audit Trail**: Firebase provides comprehensive audit logs

## Missing Components & Recommendations

### Critical Missing Screen ⚠️

#### **Profile Creation Screen** - IMMEDIATE ACTION REQUIRED

- **Status**: Route exists (`/profile/create`) but screen implementation is missing
- **Impact**: Navigation errors when `AuthProfileService.checkAuthStatus()` returns this route
- **Use Case**: Users with Firebase Auth account but no Firestore profile
- **Location**: Should be implemented at `/lib/src/screens/profile_create_screen.dart`

**Recommended Implementation:**

```dart
class ProfileCreateScreen extends StatefulWidget {
  // Collect missing profile information for authenticated users
  // Handle cases where Firebase Auth exists but Firestore profile doesn't
  // Fields: display name, bio, profile image, user preferences
}
```

### Recommended Additional Screens

#### **Email Verification Screen** 📧 **HIGH PRIORITY**

- **Current Gap**: No email verification flow implemented
- **Security Concern**: Users can register without verifying email addresses
- **Firebase Support**: Firebase Auth provides email verification methods
- **Route Suggestion**: `/email-verification`

**Benefits:**

- Enhanced security and account validation
- Reduced spam and fake accounts
- Better user trust and engagement

#### **Account Settings/Profile Management Screen** ⚙️ **MEDIUM PRIORITY**

- **Current Gap**: No way to update profile information after creation
- **User Need**: Update email, password, display name, profile image
- **Route Suggestion**: `/account/settings` or `/profile/settings`

**Features Should Include:**

- Change password functionality
- Update email address (with verification)
- Profile information management
- Account deletion option
- Privacy settings

#### **Two-Factor Authentication Setup Screen** 🔐 **LOW PRIORITY**

- **Enhancement**: Additional security layer for users
- **Firebase Support**: Phone number verification available
- **Route Suggestion**: `/auth/2fa-setup`

### Implementation Priority

1. **🚨 CRITICAL**: Profile Creation Screen (fixes broken authentication flow)
2. **📧 HIGH**: Email Verification Screen (security and UX improvement)
3. **⚙️ MEDIUM**: Account Settings Screen (user profile management)
4. **🔐 LOW**: Two-Factor Authentication (advanced security feature)

### Required Updates

#### Export Files

```dart
// Add to /lib/src/screens/screens.dart
export 'profile_create_screen.dart';
export 'email_verification_screen.dart';  // when implemented
export 'account_settings_screen.dart';    // when implemented

// Add to /lib/artbeat_auth.dart
export 'src/screens/profile_create_screen.dart';
```

#### Route Constants

```dart
// Consider adding to AuthRoutes class
static const String emailVerification = '/email-verification';
static const String accountSettings = '/account/settings';
static const String twoFactorSetup = '/auth/2fa-setup';
```

## Future Enhancements

### Planned Features

- **Biometric Authentication**: Fingerprint and Face ID support
- **Social Login**: Google, Apple, and Facebook authentication
- **Multi-Factor Authentication**: SMS and email verification
- **Account Linking**: Link multiple authentication providers
- **Advanced Security**: Device registration and suspicious activity detection

### UI/UX Improvements

- **Dark Mode**: Theme support for dark mode
- **Accessibility**: Enhanced accessibility features
- **Animations**: More sophisticated animations and transitions
- **Internationalization**: Multi-language support

### Testing Enhancements

- **Integration Tests**: End-to-end authentication flow testing
- **Performance Tests**: Authentication performance benchmarking
- **Security Tests**: Penetration testing and vulnerability assessment

---

## Summary & Action Items

### 🚨 **Immediate Action Required**

The **Profile Creation Screen** is critically missing and will cause navigation errors. This screen is referenced in the authentication flow but not implemented.

**Impact**: Users with Firebase Auth accounts but no Firestore profiles will encounter navigation failures.

**Solution**: Implement `ProfileCreateScreen` at `/lib/src/screens/profile_create_screen.dart`

### 📋 **Recommended Enhancements**

1. **Email Verification Screen** - Improve security and reduce fake accounts
2. **Account Settings Screen** - Allow users to manage their profiles and account settings
3. **Two-Factor Authentication** - Advanced security feature for the future

### ✅ **Current Strengths**

- Well-architected modular design with clear separation of concerns
- Comprehensive Firebase integration with proper error handling
- Modern UI with animations, gradients, and responsive design
- Excellent test coverage with dependency injection support
- Security-focused implementation following Firebase best practices

---

## Contributing

When contributing to the authentication module:

1. **Follow Architecture**: Maintain the service-screen-widget pattern
2. **Add Tests**: Include unit and widget tests for new features
3. **Update Documentation**: Keep this README updated with changes
4. **Security Review**: Have security-related changes reviewed
5. **Firebase Compliance**: Ensure Firebase best practices are followed

## Support

For issues related to the authentication module:

1. **Check Firebase Console**: Verify Firebase configuration
2. **Review Logs**: Check debug logs for detailed error information
3. **Test Environment**: Use Firebase emulators for testing
4. **Documentation**: Refer to Firebase Auth documentation for advanced features

---

_Last Updated: January 2025_
_Version: 0.0.2_
