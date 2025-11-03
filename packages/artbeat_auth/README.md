# ArtBeat Auth

The authentication package for the ArtBeat application, providing secure user authentication and authorization functionality with Firebase backend integration.

## Features

### Authentication Services

- **AuthService**: Core authentication operations

  - Email/password authentication (sign-in and registration)
  - Google Sign-In integration with credential handling
  - Apple Sign-In integration with secure nonce generation
  - Password reset via email
  - Email verification sending and status checking
  - User session management and auth state monitoring
  - Automatic Firestore user document creation

- **AuthProfileService**: Profile and authentication status management
  - Authentication status checking with route determination
  - User profile data retrieval from Firestore
  - Email verification requirement handling
  - Centralized sign-out functionality

### Authentication Screens

- **LoginScreen**: Complete login interface

  - Email/password authentication
  - Google Sign-In button
  - Apple Sign-In button (iOS)
  - Form validation and error handling
  - Loading states and user feedback

- **RegisterScreen**: User registration with comprehensive data collection

  - First name and last name collection
  - Email/password creation with confirmation
  - Terms of service agreement checkbox
  - Form validation and error handling
  - Automatic user document creation in Firestore

- **ForgotPasswordScreen**: Password recovery interface

  - Email-based password reset
  - Success confirmation messaging
  - Form validation and error handling

- **EmailVerificationScreen**: Email verification management

  - Automatic verification status checking (3-second intervals)
  - Resend verification email with cooldown
  - Auto-navigation upon verification completion
  - User-friendly progress indicators

- **ProfileCreateScreen**: Profile creation bridge
  - Delegates to comprehensive artbeat_profile package
  - Handles authentication flow routing
  - Post-creation navigation management

### Additional Components

- **AuthHeader**: Custom authentication UI header

  - Branded color scheme (#46a8c3 background, #00bf63 accent)
  - Configurable navigation elements
  - Search, chat, and developer mode toggles
  - Limelight font integration

- **Route Constants**: Centralized route management
  - Pre-defined authentication routes
  - Route validation utilities
  - Post-authentication routing helpers

### Security Features

- **Firebase Integration**: Complete Firebase Auth and Firestore backend
- **Social Authentication**: Secure Google and Apple sign-in flows
- **Input Validation**: Built-in form validation for all inputs
- **Error Handling**: Comprehensive error management with user-friendly messages
- **Nonce Generation**: Cryptographically secure nonce for Apple Sign-In
- **Session Management**: Automatic auth state monitoring and management

## Usage

Add to your `pubspec.yaml`:

```yaml
dependencies:
  artbeat_auth:
    path: ../packages/artbeat_auth
```

Import in your Dart code:

```dart
import 'package:artbeat_auth/artbeat_auth.dart';
```

## Key Components

### AuthService - Core Authentication

```dart
final authService = AuthService();

// Email/password authentication
await authService.signInWithEmailAndPassword(email, password);

// Register new user
await authService.registerWithEmailAndPassword(
  email,
  password,
  fullName,
);

// Social authentication
await authService.signInWithGoogle();
await authService.signInWithApple(); // iOS only

// Email verification
await authService.sendEmailVerification();
bool isVerified = authService.isEmailVerified;
await authService.reloadUser(); // Refresh verification status

// Password reset
await authService.resetPassword(email);

// Auth state management
Stream<User?> authState = authService.authStateChanges();
User? currentUser = authService.currentUser;
await authService.signOut();
```

### AuthProfileService - Profile Management

```dart
final profileService = AuthProfileService();

// Check authentication status and get appropriate route
String route = await profileService.checkAuthStatus(
  requireEmailVerification: true,
);

// Get user profile data from Firestore
Map<String, dynamic>? profile = await profileService.getUserProfile();

// Check authentication state
bool isAuth = profileService.isAuthenticated;
User? user = profileService.currentUser;
```

### Authentication Screens

```dart
// Login screen with social authentication
LoginScreen()

// Registration with full user data collection
RegisterScreen()

// Password recovery
ForgotPasswordScreen()

// Email verification with auto-checking
EmailVerificationScreen()

// Profile creation bridge
ProfileCreateScreen()
```

### Route Management

```dart
// Use predefined route constants
Navigator.pushNamed(context, AuthRoutes.login);
Navigator.pushNamed(context, AuthRoutes.register);
Navigator.pushNamed(context, AuthRoutes.emailVerification);

// Route validation helpers
bool isAuthRoute = AuthRoutes.isAuthRoute('/login');
String defaultRoute = AuthRoutes.getDefaultPostAuthRoute();
```

## Implementation Details

### Validation and Error Handling

Form validation is handled through Flutter's built-in form validation system:

- **Email Validation**: Standard email format validation using TextFormField validators
- **Password Confirmation**: Real-time password matching validation
- **Required Fields**: All registration fields are validated for completeness
- **Terms Agreement**: Required checkbox for terms of service acceptance

### Firebase Integration

- **Authentication**: Uses Firebase Auth for secure user management
- **User Documents**: Automatic creation in Firestore with complete user profiles
- **Social Sign-In**: Integrated Google and Apple authentication with fallback handling
- **Error Handling**: Comprehensive Firebase error catching with user-friendly messages

### Platform Support

- **iOS**: Full support including Apple Sign-In
- **Android**: Full support including Google Sign-In
- **Web**: Firebase Auth compatibility (social sign-in may have limitations)

## Testing

The package is designed for testing with:

```bash
flutter test packages/artbeat_auth
```

### Testability Features

- **Dependency Injection**: AuthService accepts Firebase instances for mocking
- **Optional Parameters**: All screens accept optional AuthService for testing
- **Comprehensive Logging**: AppLogger integration for debugging and testing
- **Error Simulation**: Proper error handling allows for error condition testing

## Dependencies

Core dependencies from `pubspec.yaml`:

```yaml
dependencies:
  # Firebase
  firebase_core: ^4.0.0
  firebase_auth: ^6.0.1
  cloud_firestore: ^6.0.0

  # Social Authentication
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^6.1.2
  crypto: ^3.0.3

  # ArtBeat Packages
  artbeat_core: (local)
  artbeat_profile: (local)

  # Utilities
  provider: ^6.0.5
  easy_localization: ^3.0.7
```

## Architecture

The package follows a feature-based architecture:

```
lib/
├── artbeat_auth.dart           # Main export file
├── src/
│   ├── services/
│   │   ├── auth_service.dart           # Core authentication
│   │   └── auth_profile_service.dart   # Profile management
│   ├── screens/
│   │   ├── login_screen.dart           # Login interface
│   │   ├── register_screen.dart        # Registration
│   │   ├── forgot_password_screen.dart # Password recovery
│   │   ├── email_verification_screen.dart # Email verification
│   │   └── profile_create_screen.dart  # Profile creation bridge
│   ├── widgets/
│   │   └── auth_header.dart           # Custom auth header
│   └── constants/
│       └── routes.dart                # Route definitions
```

### Design Principles

- **Separation of Concerns**: Services handle business logic, screens handle UI
- **Dependency Injection**: Services can be injected for testing
- **Single Responsibility**: Each screen has a focused purpose
- **Reusability**: Common components like AuthHeader are extracted
- **Centralized Configuration**: Routes and constants are centralized

## Security Considerations

- **Firebase Security Rules**: All user data protected by Firestore security rules
- **Input Validation**: Client-side validation prevents malformed data
- **Social Auth Security**: Proper nonce generation for Apple Sign-In
- **Error Message Safety**: Errors don't expose sensitive system information
- **Session Management**: Firebase handles secure token management
- **Password Security**: Passwords never stored locally, handled by Firebase Auth
- **User Document Protection**: User documents created with proper permissions
