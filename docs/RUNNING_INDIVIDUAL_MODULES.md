# Running Individual Modules

This document explains how to run each ARTbeat module independently for development and testing.

## Overview

ARTbeat is built using a modular architecture where each feature is encapsulated in its own module. While the modules are designed to work together in the main app, they can also be run independently for faster development and testing.

## Benefits of Running Modules Independently

1. **Faster Development Cycles**: Focus on a single feature without loading the entire application
2. **Isolated Testing**: Test modules in isolation for better coverage
3. **Cleaner Development**: Prevent unintended side effects from other modules
4. **Improved Performance**: Development builds are faster to compile and run
5. **Focused Debugging**: Simpler debugging with fewer moving parts

## How to Run Individual Modules

### Using the Convenience Script

We've created a helper script that makes it easy to run any module:

```bash
./scripts/run_module.sh [module_name]
```

For example:
```bash
./scripts/run_module.sh artbeat_auth
```

If the module doesn't have a standalone entry point yet, the script will create a template for you.

### Manually Running a Module

Each module includes a standalone entry point in `lib/bin/main.dart`. To run a module manually:

```bash
# Navigate to the module directory
cd packages/[module_name]

# Run the module with Flutter
flutter run -t lib/bin/main.dart
```

For example, to run the Authentication module:

```bash
cd packages/artbeat_auth
flutter run -t lib/bin/main.dart
```

## Available Modules

Here are the available modules and their key features:

### 1. **artbeat_core** (`artbeat_core`)

This is the foundation module containing shared functionality used by all other modules:

- Data models
- Base services
- Common utilities
- Firebase configuration helpers

Since this is primarily a utility module, it doesn't have a standalone UI. Running it independently is mainly useful for testing.

### 2. **Authentication Module** (`artbeat_auth`)

Features available in standalone mode:
- Email/password login
- User registration
- Password recovery
- Authentication state management

**Example screens in standalone mode:**
- Login Screen
- Register Screen 
- Forgot Password Screen

### 3. **Profile Module** (`artbeat_profile`)

Features available in standalone mode:
- Profile viewing
- Profile editing
- Followers/following management
- Favorites collection

**Example screens in standalone mode:**
- Profile View Screen
- Edit Profile Screen
- Followers/Following List Screens
- Favorites Screen

### 4. **Artist Module** (`artbeat_artist`) 

Features available in standalone mode:
- Artist profile management
- Gallery dashboards
- Subscription management
- Analytics dashboard

**Example screens in standalone mode:**
- Artist Dashboard Screen
- Artist Public Profile Screen
- Gallery Management Screen
- Subscription Screen

### 5. **Artwork Module** (`artbeat_artwork`)

Features available in standalone mode:
- Artwork uploads and management
- Artwork browsing with filters
- Sales and commission tracking

**Example screens in standalone mode:**
- Artwork Upload Screen
- Artwork Browse Screen
- Artwork Detail Screen

### 6. **Art Walk Module** (`artbeat_art_walk`)

Features available in standalone mode:
- Art walk creation and browsing
- Google Maps integration
- Location-based art discovery

**Example screens in standalone mode:**
- Art Walk Map Screen
- Art Walk List Screen
- Create Art Walk Screen

### 7. **Community Module** (`artbeat_community`)

Features available in standalone mode:
- Social feed
- Post creation
- Comments system
- Content moderation

**Example screens in standalone mode:**
- Social Feed Screen
- Create Post Screen
- Comments Screen
- Trending Content Screen

### 8. **Messaging Module** (`artbeat_messaging`)

Features available in standalone mode:
- Direct messaging
- Chat interface
- Message notifications

**Example screens in standalone mode:**
- Conversation List Screen
- Chat Detail Screen
- New Message Screen

### 9. **Settings Module** (`artbeat_settings`)

Features available in standalone mode:
- Account settings
- Privacy controls
- Notification preferences
- Security settings

**Example screens in standalone mode:**
- Settings Screen
- Account Settings Screen
- Privacy Settings Screen
- Notification Settings Screen

## Module Dependencies

Modules have dependencies according to the following hierarchy:

- `artbeat_core` - No dependencies (foundational)
- All other modules depend on `artbeat_core`
- Cross-module dependencies:
  - `artbeat_artist` depends on `artbeat_artwork`
  - `artbeat_art_walk` depends on `artbeat_artwork`
  - `artbeat_community` may reference `artbeat_profile`

## Firebase Configuration

Each module uses a default Firebase configuration for development purposes, defined in the standalone entry point:

```dart
final mockFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyAWORLK8SxG6IKkaA5CaY2s3J2OIJ_36TA',
  appId: '1:665020451634:android:70aaba9b305fa17b78652b',
  messagingSenderId: '665020451634',
  projectId: 'wordnerd-artbeat',
  storageBucket: 'wordnerd-artbeat.appspot.com',
);
```

In production, these would be replaced with the appropriate configuration for each environment.

For local development, you may want to use Firebase emulators:

```bash
# Start Firebase emulators
firebase emulators:start

# Run the module with emulator connection
flutter run -t lib/bin/main.dart --dart-define=USE_FIREBASE_EMULATOR=true
```

## Creating and Running Tests for Individual Modules

Each module should have its own tests in its `test/` directory:

```
packages/
└── artbeat_auth/
    ├── lib/
    └── test/
        ├── services/
        │   └── auth_service_test.dart
        └── widgets/
            └── login_screen_test.dart
```

To run tests for a specific module:

```bash
# Run all tests in a module
flutter test packages/artbeat_auth

# Run a specific test file
flutter test packages/artbeat_auth/test/services/auth_service_test.dart
```

## Creating a New Module

To create a new module:

1. Create a directory in `packages/` with your module name
2. Set up the standard Flutter package structure
3. Create a main entry point at `lib/bin/main.dart`
4. Define your module's public API in the barrel file (`lib/artbeat_module_name.dart`)

You can use our script to run it, which will create a template if it doesn't exist:

```bash
./scripts/run_module.sh artbeat_new_feature
```

## Troubleshooting

### Common Issues

1. **Firebase initialization errors**:
   - For debugging, the module template continues without Firebase in debug mode
   - Check Firebase configuration and internet connectivity

2. **Missing dependencies**:
   - Ensure all required packages are in the module's `pubspec.yaml`
   - Run `flutter pub get` in the module directory

3. **Cross-module dependency issues**:
   - Make sure all referenced modules are properly exported
   - Check import paths in your code

### Getting Help

If you encounter issues running modules independently, check:
1. The module's README.md file for module-specific instructions
2. The central testing documentation in `/docs/TESTING_IMPLEMENTATION_GUIDE.md`
