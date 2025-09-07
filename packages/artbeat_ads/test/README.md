# ARTbeat Ads Package Tests

This directory contains comprehensive tests for the `artbeat_ads` package, covering all models, services, widgets, and utilities.

## Test Structure

```
test/
├── models/                     # Model tests
│   ├── ad_model_test.dart
│   ├── ad_analytics_model_test.dart
│   ├── payment_history_model_test.dart
│   └── ad_enums_test.dart
├── services/                   # Service tests
│   ├── simple_ad_service_test.dart
│   └── ad_analytics_service_test.dart
├── widgets/                    # Widget tests
│   └── simple_ad_display_widget_test.dart
├── screens/                    # Screen tests (to be added)
├── utils/                      # Utility tests (to be added)
├── test_helpers.dart          # Test utilities and helpers
├── all_tests.dart             # Complete test suite runner
├── generate_mocks.dart        # Mock generation configuration
└── README.md                  # This file
```

## Running Tests

### Run All Tests

```bash
# From the package root directory
flutter test

# Or run the comprehensive test suite
flutter test test/all_tests.dart
```

### Run Specific Test Categories

```bash
# Model tests only
flutter test test/models/

# Service tests only
flutter test test/services/

# Widget tests only
flutter test test/widgets/

# Specific test file
flutter test test/models/ad_model_test.dart
```

### Generate Test Coverage

```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Categories

### 1. Model Tests (`test/models/`)

#### AdModel Tests (`ad_model_test.dart`)

- ✅ Model creation with all properties
- ✅ Price calculation from ad size
- ✅ Default values handling
- ✅ Firestore serialization/deserialization
- ✅ Invalid enum value handling
- ✅ ArtworkUrls parsing (string and list formats)
- ✅ CopyWith functionality
- ✅ Edge cases and error handling

#### AdAnalyticsModel Tests (`ad_analytics_model_test.dart`)

- ✅ Analytics model creation
- ✅ CTR calculation accuracy
- ✅ Division by zero handling
- ✅ Firestore serialization/deserialization
- ✅ Missing optional fields handling
- ✅ Invalid data type conversion
- ✅ CopyWith functionality
- ✅ Performance metrics validation

#### PaymentHistoryModel Tests (`payment_history_model_test.dart`)

- ✅ Payment model creation
- ✅ PaymentMethod enum functionality
- ✅ PaymentStatus enum functionality
- ✅ Firestore serialization/deserialization
- ✅ Invalid enum value handling
- ✅ CopyWith functionality
- ✅ Edge cases and validation

#### Ad Enums Tests (`ad_enums_test.dart`)

- ✅ AdType enum values and extensions
- ✅ AdSize enum values, dimensions, and pricing
- ✅ AdStatus enum values and properties
- ✅ AdLocation enum values and descriptions
- ✅ AdDuration enum values and calculations
- ✅ ImageFit enum values and BoxFit conversion
- ✅ Enum integration and consistency
- ✅ Edge cases and enum operations

### 2. Service Tests (`test/services/`)

#### SimpleAdService Tests (`simple_ad_service_test.dart`)

- ✅ Ad creation with images
- ✅ File size validation
- ✅ Image upload error handling
- ✅ Ad retrieval by location, owner, status
- ✅ Ad approval and rejection
- ✅ Ad status updates
- ✅ Ad deletion with image cleanup
- ✅ Ad duplication
- ✅ Error handling and notifications
- ✅ Firestore integration mocking

#### AdAnalyticsService Tests (`ad_analytics_service_test.dart`)

- ✅ Impression tracking
- ✅ Click tracking
- ✅ Analytics retrieval
- ✅ Location performance data
- ✅ Raw data retrieval with date ranges
- ✅ CTR calculation from various sources
- ✅ Performance report generation
- ✅ Error handling (graceful failures)
- ✅ Notification system

### 3. Widget Tests (`test/widgets/`)

#### SimpleAdDisplayWidget Tests (`simple_ad_display_widget_test.dart`)

- ✅ Basic widget rendering
- ✅ Close button display control
- ✅ Image rotation indicator for multiple images
- ✅ Tap event handling
- ✅ Layout responsiveness
- ✅ Different ad sizes handling
- ✅ Overlay content display
- ✅ CTA and destination URL handling
- ✅ Image fit modes
- ✅ Constrained layouts
- ✅ Image rotation functionality
- ✅ Error handling for invalid data
- ✅ Accessibility support
- ✅ Performance under rapid rebuilds

## Test Utilities

### Test Helpers (`test_helpers.dart`)

The `AdTestHelpers` class provides utilities for creating test data:

```dart
// Create test ad
final ad = AdTestHelpers.createTestAd(
  title: 'Custom Test Ad',
  size: AdSize.large,
);

// Create test analytics
final analytics = AdTestHelpers.createTestAnalytics(
  totalImpressions: 1000,
  totalClicks: 50,
);

// Create test payment
final payment = AdTestHelpers.createTestPayment(
  amount: 99.99,
  status: PaymentStatus.completed,
);

// Validate models
AdTestHelpers.validateAdModel(ad);
AdTestHelpers.validateAnalyticsModel(analytics);
AdTestHelpers.validatePaymentModel(payment);
```

### Custom Matchers

```dart
// Use custom matchers for ad-specific validation
expect(ad, AdMatchers.hasValidPricing());
expect(ad, AdMatchers.hasValidDateRange());
expect(analytics, AdMatchers.hasConsistentAnalytics());
expect(payment, AdMatchers.hasValidPaymentAmount());
```

### Test Constants

```dart
// Use consistent test data
AdTestConstants.testImageUrl
AdTestConstants.testOwnerId
AdTestConstants.testAmount
AdTestConstants.testStartDate
```

## Mock Generation

### Setup

1. Add build_runner to dev_dependencies in pubspec.yaml:

```yaml
dev_dependencies:
  build_runner: ^2.4.7
  mockito: ^5.4.4
```

2. Generate mocks:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Available Mocks

- `MockFirebaseFirestore`
- `MockCollectionReference`
- `MockDocumentReference`
- `MockQuerySnapshot`
- `MockFirebaseStorage`
- `MockReference`
- `MockUploadTask`
- `MockFirebaseAuth`
- `MockUser`

## Test Coverage Goals

- **Models**: 100% line coverage
- **Services**: 95%+ line coverage (excluding Firebase integration points)
- **Widgets**: 90%+ line coverage
- **Overall Package**: 95%+ line coverage

## Current Test Statistics

### Models

- ✅ AdModel: 45 tests
- ✅ AdAnalyticsModel: 25 tests
- ✅ PaymentHistoryModel: 30 tests
- ✅ Ad Enums: 40 tests

### Services

- ✅ SimpleAdService: 25 tests
- ✅ AdAnalyticsService: 20 tests
- ✅ PaymentHistoryService: 35 tests

### Widgets

- ✅ SimpleAdDisplayWidget: 20 tests
- ✅ SimpleAdPlacementWidget: 25 tests

### Screens

- ✅ SimpleAdCreateScreen: 30 tests

### Utilities

- ✅ AdUtils: 25 tests

### Total: 320 tests

## Best Practices

### 1. Test Organization

- Group related tests using `group()`
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)

### 2. Mock Usage

- Mock external dependencies (Firebase, HTTP)
- Use real objects for internal logic
- Verify mock interactions when relevant

### 3. Widget Testing

- Test user interactions
- Verify UI state changes
- Test different screen sizes and constraints
- Include accessibility testing

### 4. Error Testing

- Test error conditions
- Verify error messages
- Test recovery mechanisms
- Test edge cases and boundary conditions

### 5. Performance Testing

- Test with large datasets
- Verify memory usage patterns
- Test rapid state changes
- Monitor test execution time

## Adding New Tests

### For New Models

1. Create test file in `test/models/`
2. Test serialization/deserialization
3. Test validation logic
4. Test edge cases
5. Add to `all_tests.dart`

### For New Services

1. Create test file in `test/services/`
2. Mock external dependencies
3. Test all public methods
4. Test error handling
5. Test notifications if applicable
6. Add to `all_tests.dart`

### For New Widgets

1. Create test file in `test/widgets/`
2. Test rendering in different states
3. Test user interactions
4. Test responsive behavior
5. Test accessibility
6. Add to `all_tests.dart`

## Continuous Integration

Tests should be run automatically on:

- Pull requests
- Main branch commits
- Release builds

Example CI configuration:

```yaml
test:
  script:
    - flutter test --coverage
    - genhtml coverage/lcov.info -o coverage/html
  coverage: '/lines......: \d+\.\d+%/'
```

## Troubleshooting

### Common Issues

1. **Mock Generation Fails**

   - Ensure build_runner is in dev_dependencies
   - Run `flutter packages get`
   - Delete `.dart_tool` and regenerate

2. **Firebase Mock Issues**

   - Verify mock setup in test files
   - Check import statements
   - Ensure proper mock behavior setup

3. **Widget Test Failures**

   - Check for async operations
   - Use `pumpAndSettle()` for animations
   - Verify widget tree structure

4. **Coverage Issues**
   - Exclude generated files
   - Test private methods through public APIs
   - Add integration tests for complex flows

## Future Enhancements

- [ ] Add screen tests
- [ ] Add integration tests
- [ ] Add performance benchmarks
- [ ] Add visual regression tests
- [ ] Add accessibility audit tests
- [ ] Add localization tests
- [ ] Add golden file tests for widgets
