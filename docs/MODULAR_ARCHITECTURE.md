# ARTbeat Modular Architecture

This README explains the modular architecture implemented for the ARTbeat app to improve maintainability, testability, and developer experience.

## Overview

ARTbeat has been structured into feature-based modules to provide separation of concerns and better organization. Each module is a standalone Flutter package that can be developed, tested, and maintained independently.

## Module Structure

The application is divided into the following modules:

### 1. `artbeat_core`
Core shared functionality used across all modules.
- Models
- Core services
- Utility functions
- Common widgets

### 2. `artbeat_auth`
Authentication-related functionality.
- Login/Register screens
- Password recovery
- Authentication services

### 3. `artbeat_profile`
User profile management.
- Profile viewing and editing
- Followers/Following management
- Achievements and favorites

### 4. `artbeat_artist`
Artist and gallery features.
- Artist profiles
- Gallery management
- Subscription management
- Artist analytics

### 5. `artbeat_artwork`
Artwork management.
- Artwork uploads
- Artwork browsing
- Artwork details

### 6. `artbeat_art_walk`
Art walk and public art features.
- Art walk creation and viewing
- Map integration
- Public art discovery

### 7. `artbeat_community`
Social and community features.
- Posts and comments
- Social feed
- Community interactions

### 8. `artbeat_settings`
User settings and preferences.
- Account settings
- Privacy settings
- Notification preferences
- Security settings

## Benefits of Modular Architecture

1. **Maintainability**: Each module can be maintained independently, making it easier to update specific features without affecting the entire app.

2. **Team Development**: Different team members can work on different modules simultaneously with minimal conflicts.

3. **Testing**: Each module can be tested in isolation, leading to more robust unit and integration tests.

4. **Feature Development**: New features can be developed as separate modules and integrated when ready.

5. **Reusability**: Core functionality is centralized and reusable across modules.

6. **Code Organization**: Clear separation of concerns makes the codebase more navigable and understandable.

## How to Add a New Feature

1. Identify which module the feature belongs to
2. Add screens, services, and models to the appropriate module
3. Export public components from the module's entry point
4. Update the main app to use the new feature

## How to Create a New Module

If a feature doesn't fit into existing modules, you can create a new module:

1. Create a new directory in the `packages` folder
2. Create the module structure (lib/src/screens, lib/src/services, etc.)
3. Create a pubspec.yaml file with necessary dependencies
4. Create the module entry point (lib/[module_name].dart)
5. Add the module to the main app's pubspec.yaml

## Development Guidelines

1. **Module Dependencies**: Keep module dependencies minimal. All modules depend on `artbeat_core`, but should avoid depending on each other when possible.

2. **Shared Code**: Place shared functionality in the `artbeat_core` module.

3. **Public API**: Export only what needs to be public from each module's entry point.

4. **Module Testing**: Write tests for each module independently.

5. **Import Conventions**:
   - Import from other modules using package imports: `import 'package:artbeat_core/artbeat_core.dart';`
   - Use relative imports within a module: `import '../services/my_service.dart';`
