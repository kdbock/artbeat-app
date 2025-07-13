# ARTbeat Testing Guide

This document provides comprehensive information about testing in the ARTbeat project.

## 🧪 Testing Overview

ARTbeat uses a comprehensive testing strategy that includes:

- **Unit Tests**: Test individual functions and classes
- **Widget Tests**: Test UI components
- **Integration Tests**: Test package interactions
- **Build Tests**: Ensure the app builds correctly
- **Security Tests**: Check for vulnerabilities and secrets
- **Performance Tests**: Monitor app performance

## 📁 Test Structure

```
artbeat/
├── test/                           # Main app tests
│   ├── unit/                       # Unit tests
│   ├── widget/                     # Widget tests
│   └── integration/                # Integration tests
├── packages/                       # Package-specific tests
│   ├── artbeat_core/test/          # Core functionality tests
│   ├── artbeat_auth/test/          # Authentication tests
│   ├── artbeat_profile/test/       # Profile management tests
│   ├── artbeat_artwork/test/       # Artwork handling tests
│   ├── artbeat_art_walk/test/      # Art walk feature tests
│   ├── artbeat_artist/test/        # Artist-specific tests
│   ├── artbeat_messaging/test/     # Messaging system tests
│   ├── artbeat_events/test/        # Events management tests
│   ├── artbeat_community/test/     # Community features tests
│   ├── artbeat_capture/test/       # Media capture tests
│   └── artbeat_settings/test/      # Settings management tests
├── scripts/
│   ├── run_all_tests.sh           # Run all tests
│   └── generate_test_report.sh    # Generate test reports
├── test_config.yaml               # Test configuration
└── TESTING.md                     # This file
```

## 🚀 Quick Start

### Run All Tests
```bash
# Run all tests with coverage
./scripts/run_all_tests.sh

# Skip certain checks
./scripts/run_all_tests.sh --skip-lint --skip-format
```

### Run Specific Tests
```bash
# Main app tests only
flutter test

# Specific package tests
cd packages/artbeat_core
flutter test

# Integration tests only
flutter test test/integration/

# With coverage
flutter test --coverage
```

### Generate Test Report
```bash
./scripts/generate_test_report.sh
```

## 📊 Test Coverage

We aim for the following coverage targets:

| Package Type | Coverage Target | Priority |
|--------------|----------------|----------|
| Core packages | 85%+ | High |
| Feature packages | 80%+ | Medium |
| UI packages | 75%+ | Medium |
| Utility packages | 70%+ | Low |

### View Coverage Reports
```bash
# Generate coverage
flutter test --coverage

# View HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 🔧 Writing Tests

### Test File Naming
- Test files should end with `_test.dart`
- Place tests in the `test/` directory of each package
- Mirror the structure of your `lib/` directory

### Example Test Structure
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('ClassName Tests', () {
    late ClassName instance;
    
    setUp(() {
      instance = ClassName();
    });
    
    test('should do something when condition is met', () {
      // Arrange
      final input = 'test input';
      
      // Act
      final result = instance.doSomething(input);
      
      // Assert
      expect(result, equals('expected output'));
    });
    
    test('should throw exception when invalid input', () {
      // Arrange
      final invalidInput = '';
      
      // Act & Assert
      expect(
        () => instance.doSomething(invalidInput),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
```

### Testing Best Practices

#### 1. **Arrange-Act-Assert Pattern**
```dart
test('should calculate total correctly', () {
  // Arrange
  final calculator = Calculator();
  final numbers = [1, 2, 3, 4, 5];
  
  // Act
  final total = calculator.sum(numbers);
  
  // Assert
  expect(total, equals(15));
});
```

#### 2. **Use Descriptive Test Names**
```dart
// Good
test('should return user profile when valid user ID is provided')

// Bad
test('get user test')
```

#### 3. **Test Edge Cases**
```dart
test('should handle empty list gracefully', () {
  final result = processItems([]);
  expect(result, isEmpty);
});

test('should handle null values appropriately', () {
  final result = processData(null);
  expect(result, isNull);
});
```

#### 4. **Mock External Dependencies**
```dart
@GenerateMocks([HttpClient, DatabaseService])
void main() {
  test('should fetch data from API', () async {
    // Arrange
    final mockClient = MockHttpClient();
    final service = ApiService(mockClient);
    
    when(mockClient.get(any))
        .thenAnswer((_) async => Response('{"data": "test"}', 200));
    
    // Act
    final result = await service.fetchData();
    
    // Assert
    expect(result.data, equals('test'));
    verify(mockClient.get(any)).called(1);
  });
}
```

## 🤖 Continuous Integration

### GitHub Actions
Our CI pipeline automatically runs:

1. **Code Quality Checks**
   - Linting (dart analyze)
   - Formatting (dart format)
   - Dependency analysis

2. **Test Execution**
   - Unit tests for all packages
   - Integration tests
   - Widget tests

3. **Build Verification**
   - Android debug build
   - Web build

4. **Security Checks**
   - Dependency vulnerabilities
   - Secret detection

5. **Performance Monitoring**
   - Bundle size analysis
   - Performance test execution

### Pre-commit Hooks
Set up pre-commit hooks to run tests locally:

```bash
# Add to .git/hooks/pre-commit
#!/bin/bash
dart format --set-exit-if-changed .
flutter analyze
flutter test --no-coverage
```

## 📋 Test Categories

### Unit Tests
Test individual functions, methods, and classes in isolation.

**Location**: `test/unit/` and `packages/*/test/`

**Examples**:
- Model validation
- Utility functions
- Business logic
- Data transformations

### Widget Tests
Test Flutter widgets and UI components.

**Location**: `test/widget/`

**Examples**:
- Custom widgets
- Screen layouts
- User interactions
- State management

### Integration Tests
Test interactions between multiple components or packages.

**Location**: `test/integration/`

**Examples**:
- Authentication flow
- Data persistence
- API integrations
- Package communications

## 🛠️ Testing Tools

### Core Testing Libraries
- `flutter_test`: Flutter's testing framework
- `mockito`: Mocking framework
- `test`: Dart testing package
- `integration_test`: Integration testing

### Useful Testing Packages
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6
  test: ^1.24.6
  integration_test:
    sdk: flutter
  fake_async: ^1.3.1
  clock: ^1.1.1
```

### Mock Generation
Generate mocks automatically:

```bash
# Generate mocks for a package
cd packages/artbeat_core
flutter packages pub run build_runner build
```

## 🐛 Debugging Tests

### Common Issues

#### 1. **Test Timeout**
```dart
test('long running test', () async {
  // Increase timeout for slow tests
}, timeout: Timeout(Duration(minutes: 2)));
```

#### 2. **Async Test Issues**
```dart
test('async test', () async {
  // Always use async/await properly
  final result = await someAsyncFunction();
  expect(result, isNotNull);
});
```

#### 3. **Widget Test Pumping**
```dart
testWidgets('widget test', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pump(); // Trigger a frame
  await tester.pumpAndSettle(); // Wait for animations
});
```

### Running Specific Tests
```bash
# Run tests matching pattern
flutter test --plain-name "user authentication"

# Run specific test file
flutter test test/user_service_test.dart

# Run tests with verbose output
flutter test --reporter expanded
```

## 📈 Monitoring Test Health

### Key Metrics
- **Test Coverage**: Aim for 80%+ overall coverage
- **Test Execution Time**: Keep under 5 minutes for full suite
- **Test Stability**: Less than 1% flaky test rate
- **Code Quality**: Zero linting errors

### Regular Maintenance
- Review and update tests with code changes
- Remove obsolete tests
- Add tests for new features
- Refactor tests to reduce duplication

## 🔍 Test Data Management

### Test Data Location
```
test/
├── fixtures/          # Test data files
│   ├── user_data.json
│   ├── artwork_data.json
│   └── mock_responses.json
└── helpers/           # Test helper functions
    ├── test_data.dart
    └── mock_builders.dart
```

### Creating Test Data
```dart
// test/helpers/test_data.dart
class TestData {
  static UserModel createTestUser({
    String? uid,
    String? email,
    UserType? userType,
  }) {
    return UserModel(
      uid: uid ?? 'test-user-123',
      email: email ?? 'test@example.com',
      fullName: 'Test User',
      userType: userType ?? UserType.user,
    );
  }
  
  static ArtworkModel createTestArtwork({
    String? id,
    String? artistId,
  }) {
    return ArtworkModel(
      id: id ?? 'test-artwork-123',
      title: 'Test Artwork',
      artistId: artistId ?? 'test-artist-123',
      artistName: 'Test Artist',
      imageUrl: 'https://example.com/test.jpg',
      description: 'Test artwork description',
      price: 100.0,
      category: ArtworkCategory.painting,
    );
  }
}
```

## 📚 Additional Resources

### Documentation
- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Integration Testing](https://flutter.dev/docs/testing/integration-tests)

### Tools
- [Very Good CLI](https://cli.vgv.dev/) - Testing templates
- [Coverage Gutters](https://marketplace.visualstudio.com/items?itemName=ryanluker.vscode-coverage-gutters) - VS Code extension
- [Test Runner](https://marketplace.visualstudio.com/items?itemName=Dart-Code.dart-code) - Dart/Flutter extension

## 🎯 Testing Checklist

Before submitting code, ensure:

- [ ] All new code has corresponding tests
- [ ] Tests pass locally (`./scripts/run_all_tests.sh`)
- [ ] Code coverage meets package requirements
- [ ] No linting errors (`flutter analyze`)
- [ ] Code is properly formatted (`dart format .`)
- [ ] Integration tests pass
- [ ] No security issues detected

## 🆘 Getting Help

If you need help with testing:

1. Check this documentation first
2. Look at existing test examples in the codebase
3. Review Flutter's official testing documentation
4. Ask team members for guidance

Remember: **Good tests prevent bugs and save time in the long run!**

---

*Last updated: $(date)*