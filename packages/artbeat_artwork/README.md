# ARTbeat Artwork Module

This module contains all artwork-related functionality for the ARTbeat app.

## Features

- Artwork model and repository
- Artwork browsing and filtering
- Artwork detail viewing
- Artwork upload and management
- Artwork interaction (likes, comments)

## Components

### Models

- `ArtworkModel`: Represents an artwork with all its metadata

### Services

- `ArtworkService`: Handles all artwork-related operations including:
  - Fetching artwork
  - Creating new artwork
  - Updating existing artwork
  - Deleting artwork
  - Like functionality
  - View counting

### Screens

- `ArtworkBrowseScreen`: For browsing and filtering artwork
- `ArtworkDetailScreen`: For viewing detailed information about an artwork
- `ArtworkUploadScreen`: For uploading and editing artwork

### Widgets

- `LocalArtworkRowWidget`: For displaying artwork in a horizontal scrollable row

## Usage

```dart
import 'package:artbeat_artwork/artbeat_artwork.dart';

// Use the artwork service
final artworkService = ArtworkService();
final artworks = await artworkService.getUserArtwork();

// Navigate to artwork screens
Navigator.pushNamed(context, '/artwork/browse');
```

## Dependencies

- artbeat_core: For shared models and services
- Firebase services (Firestore, Storage)

## Firebase Collections Used

- `artwork`: Stores artwork data
- `artwork_likes`: Stores user likes on artwork
