# ArtBeat

ArtBeat is a comprehensive Flutter application for art discovery, capture, and community engagement. The app allows users to explore art, participate in art walks, capture and share their own artwork, and connect with other art enthusiasts.

## Architecture

This project follows a modular architecture with separate packages for different features:

### Core Packages

- **artbeat_core**: Core functionality, widgets, and shared components
- **artbeat_capture**: Photo/video capture and artwork submission
- **artbeat_community**: Social features, messaging, and user interactions
- **artbeat_settings**: User preferences and app configuration

### Key Features

- 🎨 **Art Discovery**: Browse and discover artwork from various artists
- 📸 **Art Capture**: Take photos and videos of artwork with metadata
- 🚶 **Art Walks**: Guided tours and location-based art exploration
- 💬 **Community**: Chat, messaging, and social interactions
- 🏆 **Achievements**: Gamified experience with progress tracking
- ⚙️ **Settings**: Comprehensive user preferences and configuration

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Firebase project setup
- iOS/Android development environment

### Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd artbeat
```

2. Install dependencies:

```bash
flutter pub get
```

3. Configure Firebase:

   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update Firebase configuration in the app

4. Run the app:

```bash
flutter run
```

## Project Structure

```
artbeat/
├── lib/                    # Main app code
├── packages/              # Feature packages
│   ├── artbeat_core/      # Core functionality
│   ├── artbeat_capture/   # Capture features
│   ├── artbeat_community/ # Community features
│   └── artbeat_settings/  # Settings features
├── test/                  # App-level tests
├── integration_test/      # Integration tests
└── assets/               # App assets
```

## Testing

### Unit Tests

```bash
# Run all tests
flutter test

# Run tests for specific package
cd packages/artbeat_core
flutter test
```

### Widget Tests

```bash
# Run widget tests
flutter test test/widgets/
```

### Integration Tests

```bash
# Run integration tests (requires device/simulator)
flutter test integration_test/
```

## Development

### Code Style

- Follow Dart/Flutter style guidelines
- Use meaningful variable and function names
- Add documentation for public APIs
- Write tests for new features

### Package Development

Each package is self-contained with its own:

- `pubspec.yaml` for dependencies
- `lib/` directory for source code
- `test/` directory for tests
- Documentation

### Adding New Features

1. Determine which package the feature belongs to
2. Create necessary models, services, and widgets
3. Add comprehensive tests
4. Update documentation
5. Test integration with other packages

## Firebase Services Used

- **Authentication**: User login and registration
- **Firestore**: Data storage for artwork, users, and community features
- **Storage**: Image and video file storage
- **Cloud Functions**: Server-side logic
- **Analytics**: Usage tracking and insights

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Ensure all tests pass
5. Submit a pull request

## License

[Add your license information here]

## Support

For support and questions, please [add contact information or issue tracker link].
