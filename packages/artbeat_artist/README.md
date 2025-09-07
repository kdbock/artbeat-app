# ArtBeat Artist

The artist and gallery management package for the ArtBeat application, providing comprehensive business account functionality, subscription management, and professional tools.

## Features

### Artist Profile Management

- **ArtistService**: Complete artist profile operations
  - Artist profile creation and management
  - Subscription tier management (Basic, Pro, Gallery)
  - Commission rate tracking and updates
  - Specialty management (add/remove artistic specialties)
  - Social media link management
  - Professional portfolio management

### Subscription System

- **Subscription Tiers**:
  - **Artist Basic** (Free): Basic profile, up to 5 artworks, basic analytics
  - **Artist Pro** ($9.99/month): Unlimited artworks, featured placement, advanced analytics
  - **Gallery Plan** ($49.99/month): Multi-artist management, business tools, priority support

### Error Monitoring & Logging

- **ErrorMonitoringService**: Production-ready error tracking
  - Crashlytics integration for error reporting
  - User context tracking for debugging
  - Event logging for analytics
  - Safe execution wrapper for error handling
  - Sensitive data sanitization

### Input Validation & Security

- **InputValidator**: Comprehensive input validation
  - User ID validation with security checks
  - Email format validation
  - Payment amount validation
  - Text sanitization and length enforcement
  - URL validation for external links
  - Subscription tier validation
  - Strict mode for enhanced security

### Commission Management

- **Commission Tracking**: Gallery-artist commission system
  - Variable commission rates per artist
  - Commission status tracking (pending, active, cancelled)
  - Rate calculation and management
  - Performance analytics

## Usage

Add to your `pubspec.yaml`:

```yaml
dependencies:
  artbeat_artist:
    path: ../packages/artbeat_artist
```

Import in your Dart code:

```dart
import 'package:artbeat_artist/artbeat_artist.dart';
```

## Key Components

### Artist Service

```dart
final artistService = ArtistService();

// Create artist profile
await artistService.createArtistProfile(
  userId: 'user123',
  displayName: 'John Artist',
  bio: 'Professional painter and sculptor',
  specialties: ['Painting', 'Sculpture'],
);

// Update subscription tier
await artistService.updateSubscriptionTier(
  userId: 'user123',
  tier: SubscriptionTier.artistPro,
);

// Update commission rates
await artistService.updateCommissionRates(
  userId: 'user123',
  rates: {'gallery1': 0.15, 'gallery2': 0.20},
);
```

### Error Monitoring

```dart
final errorService = ErrorMonitoringService();

// Record error with context
await errorService.recordError(
  error: exception,
  context: {'screen': 'artwork_upload', 'user_id': userId},
  isFatal: false,
);

// Set user context for debugging
await errorService.setUserContext(
  userId: userId,
  email: userEmail,
  displayName: userName,
);

// Safe execution with fallback
final result = await errorService.safeExecute<String>(
  operation: () => riskyOperation(),
  fallbackValue: 'default_value',
  context: {'operation': 'data_fetch'},
);
```

### Input Validation

```dart
final validator = InputValidator();

// Validate email
final emailResult = validator.validateEmail('user@example.com');
if (!emailResult.isValid) {
  print('Email error: ${emailResult.errorMessage}');
}

// Validate and sanitize text
final textResult = validator.validateText(
  userInput,
  maxLength: 500,
  required: true,
  strictMode: true,
);

// Validate payment amount
final paymentResult = validator.validatePaymentAmount(29.99);
```

## Models

### ArtistProfile

```dart
final artistProfile = ArtistProfile(
  userId: 'user123',
  displayName: 'John Artist',
  bio: 'Professional artist specializing in modern art',
  specialties: ['Painting', 'Digital Art'],
  subscriptionTier: SubscriptionTier.artistPro,
  commissionRates: {'gallery1': 0.15},
  socialMediaLinks: {
    'instagram': 'https://instagram.com/johnartist',
    'website': 'https://johnartist.com',
  },
);
```

### Subscription Tiers

```dart
// Get tier benefits
final benefits = SubscriptionTier.artistPro.benefits;

// Convert to/from string
final tierString = SubscriptionTier.gallery.toString();
final tier = SubscriptionTier.fromString('artist_basic');
```

## Testing

Run tests with:

```bash
flutter test
```

### Test Status: ✅ All 78 tests passing

The package includes comprehensive unit and widget tests covering:

- **ErrorMonitoringService Tests** (8 tests): Error recording, user context management, network/auth error handling, safe execution
- **InputValidator Tests** (30 tests): User ID, email, payment, text, URL, and subscription tier validation with sanitization and security checks
- **ArtistService Tests** (25 tests): Artist profile creation, subscription management, commission tracking, specialty management, social media updates
- **Artist Model Tests** (8 tests): Profile data validation, JSON serialization, commission calculations, and business logic
- **Subscription Tier Tests** (4 tests): Tier conversion, parsing, and benefit management
- **Commission Status Tests** (3 tests): Status conversion, parsing, and display name handling

**Test Coverage**: Complete coverage of all business logic, error handling, input validation, subscription management, and data models.

## Dependencies

- Flutter SDK
- Firebase services (Auth, Firestore, Crashlytics)
- ArtBeat Core package
- Provider for state management

## Architecture

The artist package follows clean architecture principles:

- **Services**: Business logic and external integrations
- **Models**: Data structures and business entities
- **Validators**: Input validation and security
- **Utils**: Logging and utility functions

## Security Features

- Comprehensive input validation and sanitization
- Sensitive data protection in error reporting
- Secure user context management
- Payment validation with fraud protection
- Strict mode validation for enhanced security

## Business Features

- Multi-tier subscription system with feature gating
- Commission tracking and rate management
- Professional portfolio management
- Analytics and performance tracking
- Gallery partnership tools
- Social media integration
