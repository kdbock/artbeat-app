# ARTbeat Artist Module Tests

This directory contains tests for the ARTbeat Artist module, which provides artist profile management, subscription handling, and gallery/artist relationship functionality.

## Test Structure

- **artist_module_test.dart**: Basic verification tests for the module
- **services/**: Tests for the artist services
  - **testable_subscription_service_test.dart**: Tests for the subscription management service (original)
  - **testable_subscription_service_test_new.dart**: Updated tests with current enum values
  - **testable_artist_profile_service_test.dart**: Tests for artist profile management (original)
  - **testable_artist_profile_service_simple.dart**: Simplified tests with improved structure
  - **testable_gallery_service_test.dart**: Tests for gallery/artist relationship management

## Running Tests

To run the artist module tests:

```bash
# From the artist module directory
flutter test

# Or from the root directory
cd packages/artbeat_artist && flutter test
```

## Testing Approach

The artist module tests follow these testing practices:

1. **Basic Verification**: Simple tests to verify module structure
2. **Dependency Injection**: Creating testable service implementations with injected dependencies
3. **Mocking**: Using Mockito to mock Firebase and other dependencies
4. **Fake Firestore**: Using fake_cloud_firestore for integration-like tests
5. **Test Organization**: Maintaining consistent structure with other modules

## Test Coverage

Current test coverage includes:

- [x] Basic module verification
- [x] Subscription service tests (complete)
- [x] Artist profile service tests (complete)
- [ ] Gallery service tests (planned)
- [ ] Widget tests (planned)

## Adding New Tests

When adding tests to this module:

1. Follow the established patterns for testing services with external dependencies
2. Create testable versions of services with dependency injection
3. Use mocks for external dependencies (Firebase, Stripe API, etc.)
4. Update this README.md to reflect new test coverage
