# ARTbeat Auth Module Tests

This directory contains tests for the authentication module of ARTbeat.

## Test Files

- **basic_auth_test.dart**: Basic verification tests for the auth module

## Running Tests

```bash
# Run all auth tests
flutter test

# Run a specific test file
flutter test test/basic_auth_test.dart
```

## Test Structure

Tests are organized by authentication feature:

1. **Basic Module Tests**: Simple verification tests

## Adding New Tests

When adding new tests:

1. Create separate test files for different authentication features:
   - Login functionality
   - Registration
   - Password recovery
   - Authentication persistence
2. Use mocks for Firebase Auth when testing authentication flows
3. For widget tests of auth screens, use WidgetTester to simulate user input
