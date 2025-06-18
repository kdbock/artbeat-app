# ARTbeat Modular Architecture Guide

This document explains how to work with the new modular architecture of the ARTbeat app.

## Overview

The ARTbeat app has been organized into feature modules to improve maintainability, testability, and organization. Each module is responsible for a specific domain of functionality.

### Core Modules

- **artbeat_core**: Core functionality, shared models, utils, and services
- **artbeat_auth**: Authentication flows and screens
- **artbeat_artist**: Artist and gallery business functionality
- **artbeat_artwork**: Artwork management features
- **artbeat_art_walk**: Art walks and public art features
- **artbeat_community**: Social features like posts and comments
- **artbeat_profile**: User profiles and related features
- **artbeat_settings**: App settings and preferences
- **artbeat_calendar**: Events and calendar features
- **artbeat_capture**: Image capture and processing features

## Module Structure

Each module follows the same internal structure:

```
packages/artbeat_[module_name]/
├── lib/
│   ├── artbeat_[module_name].dart   # Main entry point
│   └── src/
│       ├── models/                  # Data models
│       │   └── models.dart          # Exports all models
│       ├── screens/                 # UI screens
│       │   └── screens.dart         # Exports all screens
│       ├── services/                # Business logic services
│       │   └── services.dart        # Exports all services
│       ├── utils/                   # Utility functions specific to this module
│       │   └── utils.dart           # Exports all utils
│       └── widgets/                 # Reusable UI components
│           └── widgets.dart         # Exports all widgets
└── pubspec.yaml                     # Package dependencies
```

## How to Use Modules

### Importing

To use features from a module, import its main entry point:

```dart
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_auth/artbeat_auth.dart';
```

### Adding New Files

When adding new files:

1. Create the file in the appropriate module and directory
2. Make sure the file is exported in the corresponding `[category].dart` file

Example for adding a new model:

```dart
// In packages/artbeat_artwork/lib/src/models/painting_model.dart
class PaintingModel {
  // implementation...
}

// Then update packages/artbeat_artwork/lib/src/models/models.dart
export 'artwork_model.dart';
export 'painting_model.dart'; // Add this line
```

### Module Dependencies

Modules can depend on other modules. The dependencies are specified in each module's `pubspec.yaml` file. Always follow these guidelines:

1. All modules depend on `artbeat_core`
2. Avoid circular dependencies
3. Be explicit about dependencies between modules

## Adding a New Module

To create a new module:

1. Create the directory structure:
   ```
   mkdir -p packages/artbeat_new_module/lib/src/{models,services,screens,widgets}
   ```

2. Create the entry point file:
   ```
   touch packages/artbeat_new_module/lib/artbeat_new_module.dart
   ```

3. Create the pubspec.yaml:
   ```yaml
   name: artbeat_new_module
   description: New module for ARTbeat app
   version: 0.1.0

   environment:
     sdk: '>=3.0.0 <4.0.0'
     flutter: ">=3.0.0"

   dependencies:
     flutter:
       sdk: flutter
     artbeat_core:
       path: ../artbeat_core
     # Other dependencies...
   ```

4. Update the main app's pubspec.yaml to include the new module:
   ```yaml
   artbeat_new_module:
     path: packages/artbeat_new_module
   ```

5. Run `flutter pub get` to update dependencies

## Best Practices

1. **Keep modules focused**: Each module should have a clear responsibility
2. **Minimize dependencies**: Modules should depend on as few other modules as possible
3. **Shared code goes in core**: If multiple modules need the same functionality, move it to `artbeat_core`
4. **Module public API**: Only expose what's necessary through the module's main entry point
5. **Use provider for cross-module communication**: Avoid direct dependencies between unrelated modules
6. **Follow consistent naming**: Use the naming conventions established in the existing codebase
7. **Unit tests per module**: Each module should have its own tests

## Troubleshooting

### Common Issues

1. **Import errors**: 
   - Make sure the file is exported in the module's entry point
   - Check that you've added the module as a dependency in pubspec.yaml
   - Run `flutter pub get` to update dependencies

2. **Missing files**:
   - Make sure files are in the correct module and directory
   - Check that the file is properly exported

3. **Runtime errors**:
   - Check for missing providers or services
   - Ensure all necessary dependencies are initialized

### Development Workflow

1. Make changes in the appropriate module
2. Test the module in isolation if possible
3. Test the integrated app to ensure everything works together
4. Update documentation if adding new features or making significant changes
