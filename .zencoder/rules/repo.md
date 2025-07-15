# ARTbeat Repository Information

## Repository Summary
ARTbeat is a modular Flutter application for artists, galleries, and art enthusiasts. It provides a platform for creative content discovery, artist showcasing, and community engagement with features like authentication, profiles, art walks, messaging, and payment processing.

## Repository Structure
The repository follows a modular architecture with the main app and multiple feature-specific packages:

- **lib/**: Main application code
- **packages/**: Feature-specific modules (auth, profile, artwork, etc.)
- **functions/**: Firebase Cloud Functions
- **scripts/**: Build and utility scripts
- **assets/**: Images, fonts, and other resources
- **test/**: Test files for the main application

## Main Repository Components
- **Core App**: Main Flutter application that integrates all modules
- **Feature Modules**: Independent packages for specific functionality
- **Firebase Backend**: Cloud Functions for server-side logic
- **Build Scripts**: Scripts for building and deploying the application

## Projects

### Main Flutter Application
**Configuration File**: pubspec.yaml

#### Language & Runtime
**Language**: Dart
**Version**: SDK '^3.8.0'
**Framework**: Flutter '>=3.32.0'
**Package Manager**: pub (Flutter/Dart)

#### Dependencies
**Main Dependencies**:
- Firebase packages (auth, firestore, storage, analytics)
- Google Maps Flutter
- Provider for state management
- HTTP for API requests
- Image handling packages

#### Build & Installation
```bash
flutter pub get
flutter run
```

#### Testing
**Framework**: Flutter Test
**Test Location**: test/ directory
**Run Command**:
```bash
flutter test
```

### Feature Modules
Each module in the packages/ directory is an independent Flutter package:

#### artbeat_core
**Configuration File**: packages/artbeat_core/pubspec.yaml

**Language & Runtime**: Dart/Flutter
**Dependencies**:
- Firebase services
- Location services (geolocator, geocoding)
- State management (provider)
- Payment processing (flutter_stripe)

#### artbeat_auth
Authentication module handling user login, registration, and account management.

#### artbeat_profile
User profile management with editing capabilities and social features.

#### artbeat_artist
Artist-specific features including subscription tiers and gallery management.

#### artbeat_artwork
Artwork management, upload, and discovery features.

#### artbeat_art_walk
Interactive map-based discovery of public art with custom walking routes.

#### artbeat_community
Social features including feeds, following, and interactions.

#### artbeat_messaging
User-to-user messaging system.

#### artbeat_events
Event creation, management, and ticketing system.

### Firebase Functions
**Configuration File**: functions/package.json

#### Language & Runtime
**Language**: TypeScript/JavaScript
**Version**: Node.js 22
**Package Manager**: npm

#### Dependencies
**Main Dependencies**:
- firebase-admin: ^12.6.0
- firebase-functions: ^6.0.1
- @genkit-ai/firebase: ^1.13.0
- @genkit-ai/vertexai: ^1.13.0

#### Build & Installation
```bash
cd functions
npm install
npm run build
```

#### Testing
**Run Command**:
```bash
npm run serve  # Starts Firebase emulators
```

## CI/CD
**Framework**: GitHub Actions
**Configuration**: .github/workflows/tests.yml
**Test Strategy**: 
- Individual module tests
- Integration tests on pull requests to main branch
- Uses Flutter 3.19.0 on Ubuntu

## Build Process
**Android Build**:
```bash
./scripts/build_android.sh  # Builds debug APK and release bundle
```

**iOS Build**:
```bash
./scripts/build_ios.sh
```

## Security Features
- Firebase App Check integration
- Secure API key management
- Environment variable usage for sensitive information