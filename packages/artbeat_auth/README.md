# ArtBeat Auth

The authentication package for the ArtBeat application, providing secure user authentication and authorization functionality.

## Features

### Authentication Services

- **AuthService**: Core authentication operations
  - User sign-in and sign-up
  - Password reset functionality
  - Auth state management
  - User session handling
  - Token refresh and validation

### Authentication Screens

- **LoginScreen**: User login interface with email/password
- **RegisterScreen**: New user registration with validation
- **ForgotPasswordScreen**: Password recovery interface

### Form Validation

- **Email Validation**: Comprehensive email format checking
- **Password Strength**: Password complexity validation
- **Input Sanitization**: Secure input handling
- **Real-time Validation**: Live form validation feedback

### Security Features

- **Firebase Auth Integration**: Secure authentication backend
- **Error Handling**: Comprehensive error management
- **Input Validation**: Protection against malicious inputs
- **Session Management**: Secure user session handling

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

### Authentication Service

```dart
final authService = AuthService();

// Sign in user
await authService.signInWithEmailAndPassword(email, password);

// Register new user
await authService.createUserWithEmailAndPassword(email, password);

// Reset password
await authService.sendPasswordResetEmail(email);
```

### Login Screen

```dart
LoginScreen(
  onLoginSuccess: () => Navigator.pushReplacementNamed(context, '/dashboard'),
  onNavigateToRegister: () => Navigator.pushNamed(context, '/register'),
)
```

### Form Validation

```dart
// Email validation
final emailError = validateEmail(email);

// Password validation
final passwordError = validatePassword(password);
```

## Testing

Run tests with:

```bash
flutter test
```

### Test Status: ✅ All 28 tests passing

The package includes comprehensive unit and widget tests covering:

- **AuthService Tests** (12 tests): Sign-in/out, user management, error handling, auth state changes
- **Auth Validation Tests** (3 tests): Email format and password strength validation
- **Auth Screens Tests** (13 tests): Login, register, and forgot password screen functionality
  - Form element display and validation
  - Navigation between screens
  - Password visibility toggle
  - Error handling and user feedback

**Test Coverage**: Complete coverage of authentication flows, form validation, screen navigation, and error scenarios.

## Dependencies

- Flutter SDK
- Firebase Auth
- ArtBeat Core package
- Form validation utilities

## Architecture

The auth package follows clean architecture principles:

- **Services**: Authentication business logic
- **Screens**: Complete authentication UI flows
- **Validators**: Input validation and sanitization
- **Models**: Authentication data structures

## Security Considerations

- All user inputs are validated and sanitized
- Passwords are handled securely through Firebase Auth
- Error messages are user-friendly but don't expose sensitive information
- Session management follows security best practices
