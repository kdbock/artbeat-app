# ArtBeat Core

The core package for the ArtBeat application, providing shared functionality, widgets, and services used across all other packages.

## Features

### Widgets

- **EnhancedBottomNav**: Advanced bottom navigation with badges and special buttons
- **Achievement System**: Progress tracking and gamification widgets
  - `AchievementRunner`: Animated progress bars with level tracking
  - `AchievementBadge`: Individual achievement cards
  - `AchievementBadgeList`: Scrollable achievement collections
- **SecureNetworkImage**: Secure image loading with validation
- **Common UI Components**: Reusable widgets for consistent design

### Services

- **ImageManagementService**: Secure image handling and validation
- **PresenceService**: User online status tracking
- **LocationService**: Location-based features and geolocation

### Providers

- **CommunityProvider**: Community-related state management
- **Various state providers**: Shared state management across packages

### Screens

- **AdvancedAnalyticsDashboard**: Comprehensive analytics and insights
- **Dashboard**: Main user dashboard with achievements and activity
- **Profile screens**: User profile management

### Models

- **User models**: User data structures
- **Achievement models**: Achievement and progress tracking
- **Common data models**: Shared data structures

## Usage

Add to your `pubspec.yaml`:

```yaml
dependencies:
  artbeat_core:
    path: ../packages/artbeat_core
```

Import in your Dart code:

```dart
import 'package:artbeat_core/artbeat_core.dart';
```

## Key Components

### Enhanced Bottom Navigation

```dart
EnhancedBottomNav(
  currentIndex: 0,
  onTap: (index) => handleNavigation(index),
  showLabels: true,
)
```

### Achievement System

```dart
AchievementRunner(
  progress: 0.7,
  currentLevel: 3,
  experiencePoints: 350,
  levelTitle: 'Art Connoisseur',
)
```

### Secure Image Loading

```dart
SecureNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 200,
  height: 200,
)
```

## Testing

Run tests with:

```bash
flutter test
```

### Test Status: ✅ All 69 tests passing

The package includes comprehensive unit and widget tests covering:

- **2025 Optimization Implementation** (32 tests): Subscription tiers, feature limits, overage pricing, usage tracking
- **AuthService** (11 tests): Authentication state management, user operations, token handling
- **AI Features Service** (4 tests): Feature availability and credit cost calculations
- **UserModel** (14 tests): Model operations, JSON serialization, user type validation
- **Widget Tests** (8 tests): UniversalContentCard and EnhancedBottomNav functionality

**Test Coverage**: Comprehensive coverage of all major components including business logic, data models, and UI widgets.

## Dependencies

- Flutter SDK
- Firebase services (Auth, Firestore, Storage)
- Provider for state management
- Various utility packages

## Architecture

The core package follows clean architecture principles:

- **Models**: Data structures and entities
- **Services**: Business logic and external integrations
- **Providers**: State management
- **Widgets**: UI components
- **Screens**: Complete screen implementations

This package serves as the foundation for all other ArtBeat packages and should maintain backward compatibility.
