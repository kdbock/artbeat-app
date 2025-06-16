# ARTbeat Artist Module Testing Implementation Plan

## Overview

This document outlines the plan for implementing comprehensive tests for the ARTbeat Artist module, following the established patterns used in the Core, Auth, Profile, and Artwork modules.

## Test Directory Structure

```
packages/artbeat_artist/test/
  ├── artist_module_test.dart            # Basic module verification test
  ├── README.md                          # Documentation for artist module tests
  └── services/                          # Tests for artist services
      ├── testable_subscription_service_test.dart
      ├── testable_artist_profile_service_test.dart
      └── testable_gallery_service_test.dart
```

## Implementation Steps

1. **Create Basic Module Tests**
   - Create a simple `artist_module_test.dart` for basic verification
   - Set up the test README.md with structure documentation

2. **Create Testable Services**
   - Implement testable versions of core services with dependency injection:
     - `TestableSubscriptionService`: For subscription management tests
     - `TestableArtistProfileService`: For artist profile management tests
     - `TestableGalleryService`: For gallery relationship management tests

3. **Generate Mocks**
   - Create a `generate_artist_mocks.sh` script
   - Set up proper annotations for generating mocks for:
     - Firebase Auth
     - Firestore
     - Storage
     - HTTP clients for external payment APIs

4. **Implement Service Tests**
   - Write comprehensive tests for each testable service
   - Cover both success and error scenarios
   - Test permission handling and subscription limitations

5. **Update Testing Infrastructure**
   - Update run_tests.sh to include the artist module
   - Update GitHub Actions workflow to run artist module tests

## Test Coverage Goals

Tests should cover:

1. **Subscription Management**
   - Subscription creation, retrieval, and updating
   - Subscription tier validation
   - Payment handling via Stripe (mocked)
   - Subscription expiration handling

2. **Artist Profile Management**
   - Profile creation and updates
   - Profile validation
   - Permission checking

3. **Gallery Management**
   - Gallery-artist relationships
   - Commission calculations
   - Invitation system

4. **Analytics**
   - Artist performance metrics calculation
   - Gallery commission reports

## Dependencies

- Mockito for mocking
- fake_cloud_firestore for Firestore testing
- http_mock_adapter for mocking HTTP calls to Stripe API

## Timeline

1. Setup and basic tests: June 13, 2025
2. Testable services implementation: June 14, 2025
3. Subscription service tests: June 15, 2025
4. Artist profile and gallery tests: June 16, 2025
5. Documentation and integration: June 17, 2025
