# ARTbeat Modular Architecture Migration Guide

This guide explains how to effectively use and work with the modular architecture of the ARTbeat app.

## Using Modules in Your Code

### Importing from Modules

When working with modules, import the entire module rather than individual files:

```dart
// BEFORE (monolithic structure):
import 'package:artbeat/models/artwork_model.dart';
import 'package:artbeat/services/artwork_service.dart';

// AFTER (modular structure):
import 'package:artbeat_artwork/artbeat_artwork.dart';
```

### Accessing Components

All public components are exported through the module's main entry point:

```dart
// Create an instance of the artwork service
final artworkService = ArtworkService();

// Create an artwork model
final artwork = ArtworkModel(...);
```

## Navigation to Modularized Screens

You can still navigate to screens using named routes:

```dart
// Navigate to a screen in the artwork module
Navigator.pushNamed(context, '/artwork/browse');
```

## Working on Modules

When developing features or fixing bugs:

1. Identify which module contains the feature
2. Make changes within that module
3. Update the module's exports if needed
4. Test the module independently
5. Test the integration with the main app

## Adding New Features

To add a new feature:

1. Determine which module it belongs to
2. Create files in the appropriate module directories
3. Update module exports
4. Update the app's route table if it's a screen

## Cross-Module Dependencies

Some modules may depend on others. For example:

- `artbeat_artwork` depends on `artbeat_core` for models and services
- `artbeat_artist` depends on `artbeat_artwork` for artwork functionality

To use functionality from another module, add it as a dependency in your module's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  artbeat_core:
    path: ../artbeat_core
  artbeat_artwork:
    path: ../artbeat_artwork
```

## Testing in a Modular Architecture

When writing tests:

1. Unit tests should be placed within each module
2. Integration tests that involve multiple modules should be in the main app
3. Widget tests for screens should be in their respective modules

## Module Status

Current status of module migration:

| Module | Status |
|--------|--------|
| artbeat_core | ✅ Setup |
| artbeat_auth | ✅ Setup |
| artbeat_profile | ✅ Setup |
| artbeat_artist | ✅ Setup |
| artbeat_artwork | ✅ Setup, 🚧 Sample migration |
| artbeat_art_walk | ✅ Setup |
| artbeat_community | ✅ Setup |
| artbeat_settings | ✅ Setup |

## Migration Timeline

1. Phase 1 (Current): Setup module structure and migrate core components
2. Phase 2: Migrate authentication and profile features
3. Phase 3: Migrate artist and artwork features
4. Phase 4: Migrate art walk features
5. Phase 5: Migrate community features
6. Phase 6: Migrate settings features
7. Phase 7: Complete integration and testing
