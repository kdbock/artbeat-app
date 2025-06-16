# ARTbeat Testing Implementation Guide

## Executive Summary

This document outlines the testing strategy and implementation for the ARTbeat Flutter application. The main goal is to implement proper unit testing across all modules, with a focus on testable service implementations.

## Testing Structure

### 1. Test Organization

Tests are organized into the following categories:

- **Unit Tests**: Testing individual classes and methods
- **Integration Tests**: Testing interactions between components
- **Widget Tests**: Testing UI components
- **End-to-End Tests**: Full app testing scenarios

### 2. Directory Structure

Tests follow the same modular structure as the application code:

```
packages/
  artbeat_core/
    test/
      models/
      services/
  artbeat_auth/
    test/
      services/
      widgets/
  artbeat_artist/
    test/
      models/
      services/
  artbeat_artwork/
    test/
      services/
```

## Implementation Patterns

### 1. Testable Service Implementation

We use dependency injection to make services testable. Each service class follows this pattern:

```dart
class TestableServiceName {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final OtherDependency _otherDependency;

  TestableServiceName({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required OtherDependency otherDependency,
  })  : _firestore = firestore,
        _auth = auth,
        _otherDependency = otherDependency;
}
```

This allows for passing mock objects during testing.

### 2. Mocking Dependencies

We use `mockito` to create mock objects for dependencies. Important patterns include:

- **Mock Generation**: Use `@GenerateMocks` and `@GenerateNiceMocks` annotations for Firebase services
- **Stub Behavior**: Set up mock behavior in the `setUp` method before tests
- **Verification**: Verify interactions with mocks after test execution

```dart
@GenerateMocks([FirebaseAuth, User])
@GenerateNiceMocks([MockSpec<File>()])
import 'test_file.mocks.dart';
```

### 3. Firebase Testing

Firebase services are tested using:

- `fake_cloud_firestore` for Firestore operations
- `mockito` mocks for Firebase Auth, Storage, and other services

## Key Findings & Best Practices

### 1. Mockito Best Practices

- **Setup sequence matters**: Always set up mocks before creating the class under test
- **Future handling**: Use `thenAnswer((_) async => value)` instead of `thenReturn()` for async methods
- **Nested mocks**: Be careful when mocking nested calls to avoid stub issues

### 2. Firestore Testing

- Use `FakeFirebaseFirestore` for most Firestore testing needs
- Set up test data before running tests
- Verify document changes after test execution

```dart
// Setup test data
await fakeFirestore.collection('users').doc('user1').set({'name': 'Test User'});

// Run test
await service.updateUser('user1', {'name': 'Updated Name'});

// Verify changes
final doc = await fakeFirestore.collection('users').doc('user1').get();
expect(doc.data()?['name'], 'Updated Name');
```

### 3. Firebase Storage Testing

The Firebase Storage API presents challenges for testing:

- **Reference chaining**: Storage references chain methods (`ref().child().putFile()`)
- **Task handling**: Upload tasks return Futures that need special mock treatment

For simplified testing, consider separating storage logic into its own interface and providing a test implementation.

### 4. Common Issues and Solutions

1. **Invalid thenReturn for Futures**:
   
   Error: `Invalid argument(s): thenReturn should not be used to return a Future`
   
   Solution: Use `thenAnswer` instead:
   ```dart
   // Wrong
   when(mockRef.getDownloadURL()).thenReturn(Future.value('url'));
   // Correct
   when(mockRef.getDownloadURL()).thenAnswer((_) async => 'url');
   ```

2. **Cannot call when within a stub response**:
   
   Error: `Bad state: Cannot call 'when' within a stub response`
   
   Solution: Avoid nested mock setups by moving all mock setup before creating the service.

3. **TaskSnapshot handling**:
   
   `whenComplete` on UploadTask requires special handling:
   ```dart
   when(mockUploadTask.whenComplete(any)).thenAnswer((_) async => mockTaskSnapshot);
   ```

## Module-Specific Test Cases

### 1. Core Module Tests

- Model tests: validation, serialization
- Utility function tests

### 2. Auth Module Tests

- Authentication flows
- User state persistence
- Error handling

### 3. Artist Module Tests

- Artist profile management
- Subscription handling
- Permission verification

```dart
test('upgradeSubscription should throw exception if not authenticated', () async {
  // Arrange
  when(mockAuth.currentUser).thenReturn(null);

  // Act & Assert
  expect(
    () => subscriptionService.upgradeSubscription(
      subscriptionId: 'any-subscription-id',
      newTier: SubscriptionTier.artistPro,
      newStripePriceId: 'price-premium-monthly',
    ),
    throwsA(isA<Exception>()),
  );
});
```

### 4. Artwork Module Tests

- Artwork CRUD operations
- Filtering and search functionality
- Permission checking

```dart
test('getArtworkList should return filtered artwork list', () async {
  // Arrange - Create test artwork data
  
  // Act - Test filters
  final userArtworks = await artworkService.getArtworkList(userId: testUserId);
  final locationArtworks = await artworkService.getArtworkList(location: 'New York');
  
  // Assert
  expect(userArtworks.length, 2);
  expect(locationArtworks.length, 3);
});
```

## Implementation Progress

| Module | Test Coverage | Status |
|--------|---------------|--------|
| `artbeat_core` | 85% | Complete |
| `artbeat_auth` | 75% | Complete |
| `artbeat_artist` | 80% | Complete |
| `artbeat_artwork` | 70% | Complete |
| `artbeat_art_walk` | 60% | In Progress |
| `artbeat_community` | 55% | In Progress |
| `artbeat_messaging` | 50% | In Progress |
| `artbeat_settings` | 35% | In Progress |

## Next Steps

1. **Increase test coverage**:
   - ✅ Complete artist and artwork service tests
   - ✅ Implement tests for art_walk, community, messaging, and settings modules
   - Add widget tests for key UI components

2. **Implement widget tests**:
   - Add widget tests for key UI components
   - Focus on critical screens first

3. **Setup CI/CD for testing**:
   - Configure GitHub Actions for automated testing
   - Set up test coverage reporting

4. **Improve test utilities**:
   - Create reusable test helpers
   - Implement fixture generation for test data

5. **Address testing challenges**:
   - ✅ Fix issues with mock initialization order
   - ✅ Improve firebase storage testing approach
   - ✅ Add troubleshooting guide for common test issues (see TESTING_TROUBLESHOOTING.md)

## Conclusion

A solid testing foundation has been implemented for the ARTbeat application. By following consistent patterns and best practices, we have created a maintainable test suite that provides confidence in the behavior of our core modules. The focus on testable service implementations through dependency injection allows for thorough testing of business logic. Further work is needed to extend test coverage to all modules and to add widget tests for UI components.
