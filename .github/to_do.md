# ARTbeat To-Do List

## Create testing environments for each package and run tests in them.
- [x] `artbeat_core` - Created unit tests for models and services (UserModel, SubscriptionModel, ConnectivityService)
- [x] `artbeat_auth` - Created comprehensive tests for AuthService with mocks and TestableAuthService
- [x] `artbeat_profile` - Created tests for CaptureService with dependency injection pattern
- [x] `artbeat_artwork` - Comprehensive tests for TestableImageModerationService and TestableArtworkService with dependency injection
- [x] `artbeat_artist` - Fixed and implemented tests for TestableSubscriptionService and TestableArtistProfileService with proper mocking patterns
- [x] `artbeat_art_walk` - Created testable GoogleMapsService with dependency injection and implemented 9 tests covering core functionality
- [x] `artbeat_community` - Implemented TestableCommunityService with dependency injection and added 10 tests for posts, comments, and applause features
- [x] `artbeat_messaging` - Created TestableChatService with dependency injection and implemented tests for chat creation and management
- [x] `artbeat_settings` - Created SettingsServiceForTesting with dependency injection and comprehensive tests for account, privacy, notifications, security, and user blocking features

## Improve Testing Infrastructure (June 2025)
- [x] Create TESTING_IMPLEMENTATION_GUIDE.md with patterns and best practices
- [x] Create TESTING_TROUBLESHOOTING.md with solutions for common testing issues
- [x] Update tests to use current SubscriptionTier enum values (basic, standard, premium, none)
- [x] Fix mock initialization sequence issues
- [x] Create consistent dependency injection pattern across all modules
- [x] Implement simplified testing approach to avoid complex Firebase mocking issues
- [x] Set up test runners (all_tests.dart) for each module
- [x] Create detailed testing documentation for each module
- [ ] Implement widget tests for key UI components across modules
- [ ] Set up test coverage reporting to identify gaps in coverage
- [ ] Configure GitHub Actions for automated testing
- [ ] Create reusable test helpers for common testing operations
- [ ] Implement test fixture generation for consistent test data

## Future Module-Specific Test Improvements (July 2025)

### Art Walk Module
- [ ] Add integration tests for map interactions
- [ ] Create widget tests for map UI components
- [ ] Implement more test scenarios for achievement service

### Community Module
- [ ] Add tests for post filtering functionality
- [ ] Create tests for content moderation features
- [ ] Implement tests for community guidelines enforcement

### Messaging Module
- [ ] Add tests for message delivery status tracking
- [ ] Create tests for chat archiving functionality
- [ ] Implement tests for message search features

### Settings Module
- [ ] Add widget tests for settings screens
- [ ] Create integration tests for settings persistence
- [ ] Implement tests for account deletion process