# ArtBeat Tests

This directory contains tests for the main ArtBeat application.

## Current Test Structure

### widget_test.dart

Contains widget tests for core UI components that don't require Firebase:

- UserProgressCard widget tests
- ErrorBoundary widget tests
- Utility function tests (AppLogger, PerformanceMonitor)

### instant_discovery_test.dart

Contains unit tests for the Instant Discovery feature:

- Distance calculations
- Proximity messages
- Geohash generation
- XP calculations
- Radar positioning

## Important Notes

### Firebase-Dependent Tests

Tests that require Firebase initialization (like `MyApp` widget tests) are intentionally **not included** in unit tests because:

1. Firebase mocking in widget tests is complex and fragile
2. These are better tested through integration/E2E tests
3. CI/CD doesn't have access to real Firebase credentials

For Firebase-dependent functionality:

- Use `fake_cloud_firestore` package for unit testing Firebase services
- Use integration tests for full app flows
- Mock Firebase services at the service layer, not widget layer

## Future Test Structure

As the application develops, consider organizing tests as follows:

```
test/
├── unit/              # Unit tests for individual functions/classes
├── widget/            # Widget tests for UI components (non-Firebase)
├── integration/       # Integration tests for feature flows
├── helpers/           # Test helpers and utilities (test_helpers.dart)
└── mocks/             # Mock classes for testing
```

## Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart

# Run instant discovery tests
flutter test test/instant_discovery_test.dart

# Run tests in watch mode
flutter test --watch
```

## Adding New Tests

When adding tests:

1. Follow the existing naming convention: `*_test.dart`
2. Group related tests using `group()`
3. Use descriptive test names
4. Mock external dependencies (Firebase, APIs, etc.)
5. Keep tests isolated and independent
6. **Avoid** testing widgets that directly depend on Firebase initialization
7. Use `test_helpers.dart` for shared test utilities

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Firebase Testing with Fakes](https://pub.dev/packages/fake_cloud_firestore)
