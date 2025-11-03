# ArtBeat Capture Package

The `artbeat_capture` package provides comprehensive art capture functionality for the ArtBeat ecosystem, including camera operations, offline support, content management, and community features.

## 🏗️ Architecture Overview

This package serves as the dedicated capture module for ArtBeat, handling:

- **Camera & Image Capture**: Native camera integration with quality controls
- **Offline-First Design**: Queue-based capture sync for unreliable networks
- **Content Management**: Upload, moderation, and metadata handling
- **Community Features**: Sharing, engagement, and discovery
- **Analytics & Safety**: Capture analytics and terms compliance

## 📱 Core Features

### Camera & Capture Services

- **CameraService**: Device camera availability and initialization
- **AdvancedCameraService**: Enhanced camera features and settings
- **CaptureService**: Full capture lifecycle management (1,389 lines)
- **StorageService**: Firebase Storage integration with retry logic

### Offline & Sync

- **OfflineQueueService**: Intelligent queue management for offline captures
- **OfflineDatabaseService**: Local SQLite storage for pending uploads
- **ConnectivityService**: Network state monitoring and auto-sync

### AI & Analytics

- **AIMLIntegrationService**: Machine learning for image processing
- **CaptureAnalyticsService**: Usage metrics and performance tracking
- **CaptureTermsService**: Terms compliance and safety guidelines

## 🖥️ Screen Components

### Main Capture Flows

- **EnhancedCaptureDashboardScreen**: Personalized capture hub (819 lines)
- **CaptureScreen**: Direct camera access with immediate processing
- **CaptureDetailScreen**: Metadata editing and enhancement
- **CaptureUploadScreen**: Upload progress and queue management

### Content Management

- **CapturesListScreen**: User's capture gallery
- **MyCapturesScreen**: Personal capture management
- **AdminContentModerationScreen**: Content review and moderation
- **CaptureViewScreen**: Full-screen capture viewing

### User Experience

- **CaptureEditScreen**: Post-capture editing capabilities
- **CaptureDetailViewerScreen**: Immersive capture viewing
- **TermsAndConditionsScreen**: Safety guidelines and compliance

## 🔧 Widget Library

### Interactive Components

- **CapturesGrid**: Responsive gallery layout
- **LikeButtonWidget**: Animated engagement control
- **CommentItemWidget** & **CommentsSectionWidget**: Community discussion
- **OfflineStatusWidget**: Network state indicator

### Utility Widgets

- **ArtistSearchDialog**: Artist discovery and tagging
- **MapPickerDialog**: Location selection interface
- **CaptureDrawer**: Navigation and quick actions
- **CaptureHeader**: Branded header with user context

## 🗄️ Data Models

### Core Models

```dart
// Re-exported from artbeat_core
CaptureModel // Central capture data structure

// Package-specific models
MediaCapture // Enhanced capture metadata
OfflineQueueItem // Sync queue management
```

### Utilities

- **CaptureHelper**: Common capture operations and validations

## 📦 Dependencies

### Core Dependencies

```yaml
# Firebase & Backend
cloud_firestore: ^6.0.0 # Firestore database
firebase_storage: ^13.0.0 # File storage
firebase_auth: ^6.0.1 # Authentication
firebase_core: ^4.0.0 # Firebase initialization

# Camera & Media
camera: ^0.11.1 # Native camera access
image_picker: ^1.0.7 # Image selection
cached_network_image: ^3.4.1 # Optimized image loading

# Location & Maps
geolocator: ^14.0.1 # GPS location services
geocoding: ^4.0.0 # Address resolution
google_maps_flutter: ^2.5.3 # Map integration

# Offline & Storage
sqflite: ^2.4.1 # Local database
shared_preferences: ^2.3.3 # Settings storage
path_provider: ^2.1.5 # File system access

# Networking & State
connectivity_plus: ^6.1.4 # Network monitoring
provider: ^6.1.2 # State management

# ArtBeat Packages
artbeat_core: # Core functionality
  path: ../artbeat_core
artbeat_ads: # Advertisement system
  path: ../artbeat_ads
artbeat_art_walk: # Art walk features
  path: ../artbeat_art_walk
```

## 🔄 Dependency Architecture

### Package Relationships

```
artbeat_capture
├── artbeat_core (shared models, services, theme)
├── artbeat_ads (monetization integration)
└── artbeat_art_walk (rewards and achievements)
```

✅ **Circular Dependency Resolution (November 2025)**:

**Problem**: Circular dependencies between `artbeat_core` and `artbeat_capture`

- `artbeat_core` imported `CaptureService` from `artbeat_capture`
- `artbeat_capture` depended on `artbeat_core` for models and services

**Solution Implemented**:

- ✅ Created `CaptureServiceInterface` in `artbeat_core` for abstraction
- ✅ Implemented all required interface methods (`getAllCaptures`, `getCapturesForUser`, `searchCaptures`)
- ✅ Removed redundant basic `CaptureService` from `artbeat_core`
- ✅ Updated `CaptureService` in capture package to implement interface
- ✅ Removed `artbeat_capture` dependency from `artbeat_core/pubspec.yaml`
- ✅ Updated all core components to use interface instead of direct imports

**Architecture Benefits**:

- 🏗️ Clean separation of concerns
- 📦 Independent package building
- 🔄 Proper dependency flow (core → capture, not bidirectional)
- 🧪 Improved testability with interface mocking

## 🔧 Recent Updates & Bug Fixes

### Navigation Improvements (November 2025)

✅ **Dashboard "Explore All" Button Fix**:

**Problem**: Users clicking "Explore All" in dashboard captures section received "Page not found" error

**Solution Implemented**:

- Fixed navigation route from `/captures-list` (non-existent) to `/capture/browse` (existing route)
- Updated `DashboardCapturesSection` to use proper route mapping
- Route correctly displays `CapturesListScreen` showing all available captures

### User Experience Enhancements (November 2025)

✅ **Terms and Conditions Accessibility**:

**Problem**: Users required to accept terms and conditions during capture upload but no way to view them

**Solution Implemented**:

- Added `/capture/terms` route in app router
- Made "terms and conditions" text clickable in `CaptureDetailScreen`
- Implemented `RichText` with `TapGestureRecognizer` for proper link styling
- Users can now tap to view full terms before agreeing

**Technical Implementation**:

```dart
// Before: Simple text
title: const Text('I accept the terms and conditions'),

// After: Clickable link
title: RichText(
  text: TextSpan(
    children: [
      const TextSpan(text: 'I accept the '),
      TextSpan(
        text: 'terms and conditions',
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => Navigator.pushNamed(context, '/capture/terms'),
      ),
    ],
  ),
),
```

## 🚀 Usage Examples

### Basic Capture Flow

```dart
import 'package:artbeat_capture/artbeat_capture.dart';

// Initialize capture service
final captureService = CaptureService();

// Create and save capture
final capture = CaptureModel(
  id: 'capture_id',
  userId: 'user_id',
  imageUrl: 'path/to/image.jpg',
  createdAt: DateTime.now(),
);

final captureId = await captureService.saveCapture(capture);
```

### Offline-First Capture

```dart
// Save with offline support
final captureId = await captureService.saveCaptureWithOfflineSupport(
  capture: capture,
  localImagePath: '/local/path/image.jpg',
);

// Monitor sync status
final offlineService = OfflineQueueService();
offlineService.syncEvents.listen((event) {
  print('Sync status: ${event.type}');
});
```

### Camera Integration

```dart
// Check camera availability
final cameraService = CameraService();
final isAvailable = await cameraService.isCameraAvailable();

if (isAvailable) {
  // Navigate to capture screen
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => CaptureScreen()),
  );
}
```

## 📊 Performance & Optimization

### Caching Strategy

- **Image Caching**: `CachedNetworkImage` with intelligent preloading
- **Data Caching**: 5-minute cache timeout for capture lists
- **Offline Storage**: SQLite for reliable local persistence

### Memory Management

- **Lazy Loading**: On-demand screen and service initialization
- **Image Optimization**: Automatic quality adjustment (85% default)
- **Background Processing**: Non-blocking upload queue

### Network Efficiency

- **Connectivity Monitoring**: Automatic retry on network restoration
- **Batch Operations**: Grouped uploads for efficiency
- **Progressive Sync**: Priority-based queue processing

## 🔐 Security & Privacy

### Data Protection

- **Firebase Security Rules**: Server-side access control
- **Local Encryption**: Sensitive data protection at rest
- **Network Security**: TLS encryption for all communications

### Content Safety

- **Moderation Pipeline**: Automated and manual content review
- **Terms Compliance**: Built-in safety guideline enforcement
- **Privacy Controls**: User data management and deletion

## 🧪 Testing Strategy

### Unit Tests

```bash
# Run capture package tests
flutter test packages/artbeat_capture/test/
```

### Integration Tests

- Camera functionality on device
- Offline sync reliability
- Upload queue processing
- UI flow validation

## 🚀 Development Setup

### Prerequisites

- Flutter SDK >=3.0.0
- Dart SDK >=3.8.0
- Firebase project configured
- iOS/Android development environment

### Installation

```bash
# Get dependencies
flutter pub get

# Run code generation (if needed)
flutter pub run build_runner build
```

### Configuration

1. **Firebase Setup**: Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are configured
2. **API Keys**: Configure Google Maps API key in platform-specific files
3. **Permissions**: Camera and location permissions must be configured in platform manifests

## 📈 Roadmap & Future Features

### Planned Enhancements

- [ ] **AR Capture**: Augmented reality art identification
- [ ] **Collaborative Captures**: Multi-user capture sessions
- [ ] **Advanced Editing**: In-app image enhancement tools
- [ ] **Live Streaming**: Real-time capture broadcasting
- [ ] **Blockchain Integration**: NFT creation and verification

### Technical Improvements

- [x] **Resolve Circular Dependency**: ✅ Completed - Restructured core/capture relationship with interface pattern
- [x] **Service Consolidation**: ✅ Completed - Removed duplicate CaptureService from core
- [x] **Navigation Bug Fixes**: ✅ Completed - Fixed dashboard "Explore All" routing
- [x] **User Experience**: ✅ Completed - Added clickable terms and conditions link
- [ ] **Performance Optimization**: Reduce memory footprint
- [ ] **Test Coverage**: Achieve 90%+ test coverage
- [ ] **Documentation**: Add comprehensive API documentation

## 🤝 Contributing

### Code Style

- Follow Flutter/Dart conventions
- Use meaningful variable and function names
- Add comprehensive documentation for public APIs
- Maintain backwards compatibility where possible

### Pull Request Process

1. Create feature branch from `main`
2. Implement changes with tests
3. Update documentation as needed
4. Submit PR with detailed description

## 📄 License

This package is part of the ArtBeat ecosystem and follows the project's licensing terms.

---

## 🆘 Support

For issues, feature requests, or questions:

- Create GitHub issue in main ArtBeat repository
- Contact development team through project channels
- Refer to main project documentation for broader context

**Package Version**: 0.0.2  
**Last Updated**: November 1, 2025  
**Maintained By**: ArtBeat Development Team

---

### 🔄 Recent Changes Summary

- ✅ **Architecture**: Resolved circular dependencies with interface pattern
- ✅ **Navigation**: Fixed dashboard "Explore All" button routing
- ✅ **UX**: Added clickable terms and conditions link in capture flow
- ✅ **Compliance**: Improved legal compliance with accessible terms viewing
- ✅ **Code Quality**: Enhanced maintainability and testability
