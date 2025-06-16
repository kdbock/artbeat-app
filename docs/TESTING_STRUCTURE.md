# ARTbeat Testing Structure

This document provides an overview of the testing structure and approach for the ARTbeat application.

## Module Testing Structure

Each module in our modular Flutter architecture has its own test directory structure:

```
packages/
  artbeat_core/
    test/
      core_unified_test.dart
      services/
        connectivity_service_test.dart
      README.md
  artbeat_auth/
    test/
      basic_auth_test.dart
      auth_module_test.dart
      services/
        auth_service_test.dart
      README.md
  artbeat_profile/
    test/
      basic_profile_test.dart
      profile_module_test.dart
      services/
        capture_service_test.dart
        testable_capture_service_test.dart
      README.md
```

## Testing Approach

1. **Unit Tests**: For individual components like services and models
   - Example: ConnectivityService tests in Core module

2. **Mock-Based Tests**: For components with external dependencies
   - Example: AuthService tests with mocked Firebase Auth

3. **Dependency Injection for Testing**: For services with external dependencies
   - Example: TestableCaptureService in Profile module

4. **Simple Verification Tests**: For basic module checks
   - Example: Basic math tests in all modules for quick verification

## Generated Mocks

Each module that requires mocking uses Mockito and build_runner:

1. Auth Module:
   - Mocks: FirebaseAuth, UserCredential, User
   - Generation: `generate_auth_mocks.sh`

2. Core Module:
   - Mocks: Various repository classes
   - Generation: `generate_core_mocks.sh`

3. Profile Module:
   - Mocks: Document references and other Firestore classes
   - Generation: `generate_profile_mocks.sh`

## Testing Best Practices

1. **Firebase Dependencies**: Use `fake_cloud_firestore` for Firestore testing
2. **Service Testing**: Create testable versions with dependency injection
3. **UI Components**: Use widget testing (to be added)
4. **Navigation**: Use integration tests for navigation flows
5. **Error Scenarios**: Test both happy and error paths
6. **CI/CD Integration**: All tests are included in the GitHub Actions workflow

## Adding New Tests

When adding new tests to a module:

1. Update the module's test README.md
2. Follow the established patterns for mocking and dependency injection
3. Add the new test files to the appropriate directory
4. Update the model's test documentation as needed

## Next Steps

1. Add comprehensive widget testing for UI components
2. Add integration tests for key user flows
3. Extend testing to all remaining modules
4. Set up test coverage reporting
