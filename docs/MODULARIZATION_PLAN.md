# ARTbeat Modularization Migration Plan

This document outlines the step-by-step process for migrating ARTbeat from a monolithic structure to a modular architecture.

## Migration Overview

The migration will be done in phases to minimize disruption to ongoing development:

1. **Phase 1: Core Setup and Planning** (Current)
   - Create module directory structure
   - Setup module pubspec.yaml files
   - Create module entry point files
   - Plan migration of specific components

2. **Phase 2: Core Module Migration**
   - Migrate core models
   - Migrate essential services
   - Migrate utility functions
   - Test core functionality

3. **Phase 3: Feature Module Migration**
   - Migrate one feature module at a time (Auth → Profile → Artist → etc.)
   - Test each module after migration
   - Update imports in main app to use modules

4. **Phase 4: Main App Integration**
   - Update main.dart to use modules
   - Test complete app functionality
   - Address any cross-module dependencies

5. **Phase 5: Cleanup & Optimization**
   - Remove duplicated code
   - Optimize module dependencies
   - Document module APIs

## Migration Steps for Each Module

### For each module:

1. Identify all components (models, screens, services) belonging to the module
2. Copy files to the appropriate directories in the module
3. Update imports to use relative paths within the module
4. Update imports for dependencies from other modules
5. Export all public components from the module's entry point file
6. Test the module independently
7. Update the main app to use the module

## File Migration Mapping

### Core Module
- Models:
  - `lib/models/user_model.dart` → `packages/artbeat_core/lib/src/models/user_model.dart`
  - `lib/models/subscription_model.dart` → `packages/artbeat_core/lib/src/models/subscription_model.dart`
  - etc.

- Services:
  - `lib/services/user_service.dart` → `packages/artbeat_core/lib/src/services/user_service.dart`
  - `lib/services/analytics_service.dart` → `packages/artbeat_core/lib/src/services/analytics_service.dart`
  - etc.

- Utils:
  - `lib/utils/connectivity_utils.dart` → `packages/artbeat_core/lib/src/utils/connectivity_utils.dart`
  - etc.

### Auth Module
- Screens:
  - `lib/screens/authentication/login_screen.dart` → `packages/artbeat_auth/lib/src/screens/login_screen.dart`
  - `lib/screens/authentication/register_screen.dart` → `packages/artbeat_auth/lib/src/screens/register_screen.dart`
  - `lib/screens/authentication/forgot_password_screen.dart` → `packages/artbeat_auth/lib/src/screens/forgot_password_screen.dart`
  - `lib/screens/splash_screen.dart` → `packages/artbeat_auth/lib/src/screens/splash_screen.dart`

### Profile Module
- Screens:
  - `lib/screens/profile/profile_view_screen.dart` → `packages/artbeat_profile/lib/src/screens/profile_view_screen.dart`
  - `lib/screens/profile/edit_profile_screen.dart` → `packages/artbeat_profile/lib/src/screens/edit_profile_screen.dart`
  - etc.

### Artist Module
- Screens:
  - `lib/screens/artist/artist_dashboard_screen.dart` → `packages/artbeat_artist/lib/src/screens/artist_dashboard_screen.dart`
  - `lib/screens/artist/artist_profile_edit_screen.dart` → `packages/artbeat_artist/lib/src/screens/artist_profile_edit_screen.dart`
  - etc.
- Services:
  - `lib/services/subscription_service.dart` → `packages/artbeat_artist/lib/src/services/subscription_service.dart`
  
### Art Walk Module
- Screens:
  - `lib/screens/art_walk/art_walk_map_screen.dart` → `packages/artbeat_art_walk/lib/src/screens/art_walk_map_screen.dart`
  - etc.
- Services:
  - `lib/services/art_walk_service.dart` → `packages/artbeat_art_walk/lib/src/services/art_walk_service.dart`

### Community Module
- Screens:
  - `lib/screens/community/community_feed_screen.dart` → `packages/artbeat_community/lib/src/screens/community_feed_screen.dart`
  - etc.
- Services:
  - `lib/services/community_service.dart` → `packages/artbeat_community/lib/src/services/community_service.dart`

### Settings Module
- Screens:
  - `lib/screens/settings/settings_screen.dart` → `packages/artbeat_settings/lib/src/screens/settings_screen.dart`
  - etc.

## Implementation Strategy

To minimize disruption while migrating, follow these steps:

1. Create a new branch for the modular architecture
2. Keep the original code structure intact during migration
3. Migrate one module at a time
4. Test each module independently before integrating
5. Gradually update the main app to use modules
6. Once all modules are working, remove duplicated code

## Testing Strategy

- Unit test each module independently
- Integration test module interactions
- End-to-end test complete workflows
- UI test key screens and features

## Rollout Plan

1. Development phase: Test on development devices
2. Internal testing: Share with team members
3. Beta testing: Deploy to beta testers
4. Production rollout: Update production app
