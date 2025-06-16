# ARTbeat Testing Guide

This document provides guidance for running tests across ARTbeat's modular architecture.

## Test Structure

Each module has its own test directory:
- `packages/artbeat_core/test/` - Core model and service tests
- `packages/artbeat_auth/test/` - Authentication feature tests
- `packages/artbeat_profile/test/` - Profile feature tests
- `packages/artbeat_artist/test/` - Artist feature tests (planned)
- `packages/artbeat_artwork/test/` - Artwork feature tests (planned)
- `packages/artbeat_art_walk/test/` - Art Walk feature tests (planned)
- `packages/artbeat_community/test/` - Community feature tests (planned)
- `packages/artbeat_settings/test/` - Settings feature tests (planned)
- `packages/artbeat_messaging/test/` - Messaging feature tests (planned)

Each module's test directory contains a README.md with module-specific testing information.

## Running Tests

### Generating Mocks

Before running tests for the first time, you need to generate mock files for modules that use them:

```bash
# Generate mocks for the core module
./scripts/generate_core_mocks.sh

# Generate mocks for the auth module
./scripts/generate_auth_mocks.sh

# Generate mocks for the profile module
./scripts/generate_profile_mocks.sh
```

### Using the Test Runner Script

The easiest way to run all tests is using the test runner script:

```bash
# Run tests for all modules
./scripts/run_tests.sh
```

### Run All Tests for a Module

```bash
# Run all tests for the core module
cd packages/artbeat_core && flutter test

# Run all tests for the profile module
cd packages/artbeat_profile && flutter test

# Run all tests for the auth module
cd packages/artbeat_auth && flutter test
```

### Run a Specific Test File

```bash
# Run a specific test file
cd packages/artbeat_core && flutter test test/core_unified_test.dart
```

## Test Types

1. **Unit Tests**: For models, services, utilities
   - Example: `packages/artbeat_core/test/core_unified_test.dart`
   - Example: `packages/artbeat_auth/test/services/auth_service_test.dart`

2. **Widget Tests**: For UI components
   - Example: We'll add these as we build more UI components

3. **Service Tests with Dependency Injection**:
   - Example: `packages/artbeat_profile/test/services/testable_capture_service_test.dart`
   
4. **Module Integration Tests**:
   - Example: `packages/artbeat_profile/test/profile_module_test.dart`

## Testing Best Practices

1. **Follow Dependency Injection Pattern**
   - Make services testable by accepting dependencies in constructor or setter methods
   - Example: `setDependenciesForTesting()` in AuthService

2. **Use Fake Firebase for Firestore Tests**
   - Use `fake_cloud_firestore` package for testing Firestore-dependent code
   - This allows for a completely in-memory database for testing

3. **Generate and Use Mocks**
   - Use `mockito` and `@GenerateMocks` annotation for Firebase classes
   - Remember to run the mock generation scripts before testing

4. **Test Module Exports**
   - Ensure public API components are properly exported
   - Test that expected components are available from the module

5. **Organize Tests Logically**
   - Group related tests with descriptive names
   - Separate tests by feature or component

6. **Create Testable Services**
   - Consider creating separate testable versions of services with DI
   - Example: `TestableCaptureService` for profile module
   - Example: `packages/artbeat_profile/test/widgets/profile_card_test.dart`

3. **Integration Tests**: For feature flows
   - In project root: `flutter test integration_test/auth_journey_test.dart`

## Test Dependencies

For mocking and testing we use:
- `mockito`: For mocking classes
- `fake_cloud_firestore`: For testing Firestore interactions
- `build_runner`: To generate mock classes

### Generating Mock Classes

Run the provided script to generate mock classes:

```bash
./scripts/generate_core_mocks.sh
```

## Current Test Coverage

| Module | Status | Coverage |
|--------|--------|----------|
| artbeat_core | ✅ Implemented | Basic model and service tests |
| artbeat_profile | ✅ Implemented | Basic verification tests |
| artbeat_auth | ✅ Implemented | Basic verification tests |
| artbeat_artwork | 🔄 Pending | Not implemented yet |
| artbeat_art_walk | 🔄 Pending | Not implemented yet |
| artbeat_community | 🔄 Pending | Not implemented yet |
| artbeat_settings | 🔄 Pending | Not implemented yet |

## Best Practices

1. Keep tests focused and isolated
2. Use descriptive test names
3. For Firebase-dependent tests, use fakes/mocks
4. Run tests before committing changes
5. Add tests for new features and bug fixes

## Troubleshooting Common Testing Issues

### Firebase-related Errors

When testing Firebase-dependent code:
1. Always initialize Firebase in tests with `setupFirebaseForTesting()`
2. Use `FakeFirebaseFirestore()` for Firestore operations
3. Mock `FirebaseAuth` using Mockito

### Widget Testing Errors

For widget testing issues:
1. Ensure `WidgetTester` is properly initialized
2. Wrap widgets in appropriate parent widgets (MaterialApp, etc.)
3. Use `pumpAndSettle()` to wait for animations

## Adding Tests to CI/CD

The project is configured to run tests automatically on pull requests using GitHub Actions.
See `.github/workflows/tests.yml` for configuration details.
