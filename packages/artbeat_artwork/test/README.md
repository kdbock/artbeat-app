# ARTbeat Artwork Module Tests

This directory contains tests for the ARTbeat Artwork module, which provides artwork management, image moderation, and related functionality.

## Test Structure

- **artwork_module_test.dart**: Basic verification tests for the module
- **services/**: Tests for the artwork services
  - **simple_image_moderation_test.dart**: Basic tests for ImageModerationService
  - **testable_image_moderation_service_test.dart**: Comprehensive tests for TestableImageModerationService
  - **testable_artwork_service_test.dart**: Original tests for TestableArtworkService
  - **testable_artwork_service_simple.dart**: Simplified tests without AggregateQuery complexity

## Running Tests

To run the artwork module tests:

```bash
# From the artwork module directory
flutter test

# Or from the root directory
cd packages/artbeat_artwork && flutter test
```

## Testing Approach

The artwork module tests follow these testing practices:

1. **Basic Verification**: Simple tests to verify module structure
2. **Service Testing**: Basic service instantiation tests
3. **Testable Services**: Creating testable service implementations with dependency injection
4. **Mocking**: Using Mockito to mock Firebase and other dependencies
5. **Fake Firestore**: Using fake_cloud_firestore for integration-like tests

## Test Coverage

Current test coverage includes:

- [x] Basic module verification
- [x] Image moderation service instantiation
- [x] Image moderation service functionality tests
- [x] Artwork service tests (CRUD operations)
- [x] Subscription limit enforcement tests
- [x] Permission validation for artwork operations
- [x] Artwork filtering functionality
- [ ] Widget tests for artwork components (pending)

## Adding New Tests

When adding tests to this module:

1. Follow the established patterns for testing services with external dependencies
2. Create testable versions of services with dependency injection
3. Use mocks for external dependencies (Firebase, HTTP clients, etc.)
4. Update this README.md to reflect new test coverage
