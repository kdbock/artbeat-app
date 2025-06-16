# ARTbeat Core Module Tests

This directory contains tests for the core module of ARTbeat.

## Test Files

- **core_module_test.dart**: Main test runner that executes all tests in the core module
- **core_unified_test.dart**: Tests for models and basic services without Firebase dependencies
- **services/connectivity_service_test.dart**: Tests for the connectivity service
- **services/enhanced_connectivity_service_test.dart**: More comprehensive tests for connectivity service

## Running Tests

```bash
# Run all core tests
flutter test

# Run a specific test file
flutter test test/core_unified_test.dart
```

## Test Structure

Tests are organized into groups by model and service:

1. **User Model Tests**: Basic instantiation and property validation
2. **Subscription Model Tests**: Instance creation and tier validation
3. **Connectivity Service Tests**: Initialization and state changes

## Adding New Tests

When adding new tests:

1. Create a separate test file in the appropriate directory (`models/` or `services/`)
2. For Firebase-dependent tests, use proper mocks and fakes
3. Make sure to add any new test imports to `core_module_test.dart`
