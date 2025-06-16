# ARTbeat Profile Module Tests

This directory contains tests for the profile module of ARTbeat.

## Test Files

- **basic_profile_test.dart**: Basic verification tests for the profile module
- **profile_module_test.dart**: Integration tests for the module as a whole
- **services/**
  - **capture_service_test.dart**: Tests for the CaptureService
  - **testable_capture_service_test.dart**: Tests for the testable version of CaptureService

## Running Tests

```bash
# Run all profile tests
flutter test

# Run a specific test file
flutter test test/basic_profile_test.dart
```

## Test Structure

Tests are organized by feature:

1. **Basic Module Tests**: Simple verification tests
2. **Service Tests**: Tests for profile-related services
3. **Integration Tests**: Tests for module exports and component interactions

## Testing Approach

The profile module tests follow these testing practices:

1. **Unit testing**: Services and models are tested in isolation
2. **Mocking**: Firebase dependencies are mocked using `mockito` and `fake_cloud_firestore`
3. **Integration testing**: Module exports and component interactions are tested
4. **Testability**: The `testable_capture_service.dart` demonstrates a dependency injection pattern for testing

## Adding New Tests

When adding new tests:

1. Create a separate test file for each widget, screen, or service
2. Group tests logically by feature
3. For widget tests, ensure proper rendering and interaction checks
