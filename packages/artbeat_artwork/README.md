# ARTbeat Artwork Package

A Flutter package that provides comprehensive artwork management functionality for the ARTbeat application, including discovery algorithms, moderation systems, and artwork lifecycle management.

## Features

### ✅ Discovery Algorithms

- **Similar Artwork Recommendations**: Content-based similarity scoring using tags, styles, medium, and location
- **Trending Artwork Detection**: Algorithm combining view counts, recency, and engagement metrics
- **Personalized Discovery Feed**: User preference-based recommendations using interaction history

### ✅ Moderation System

- Content moderation with approval workflow
- Flagging system for inappropriate content
- Moderation notes and status tracking

### ✅ Artwork Management

- Upload and management of artwork with metadata
- Image storage integration with Firebase
- Pricing and sales status management
- Tag and categorization system

## Architecture

### Services

- `ArtworkService`: Core artwork CRUD operations
- `ArtworkDiscoveryService`: Discovery and recommendation algorithms
- `ArtworkModerationService`: Content moderation functionality

### Models

- `ArtworkModel`: Main artwork data structure
- `ArtworkModerationStatus`: Moderation workflow states

### Widgets

- `ArtworkDiscoveryWidget`: UI for displaying discovery recommendations
- `ArtworkModerationWidget`: Moderation interface components

### Screens

- `ArtworkDiscoveryScreen`: Full-screen discovery experience
- `ArtworkModerationScreen`: Moderation dashboard

## Discovery Algorithms

### Similar Artwork Recommendations

```dart
// Get artworks similar to a specific piece
final similarArtworks = await discoveryService.getSimilarArtworks(
  artworkId: 'artwork-123',
  limit: 10,
);
```

**Algorithm**: Content-based filtering using:

- Tag overlap scoring
- Style similarity
- Medium matching
- Location proximity
- Price range similarity

### Trending Artwork Detection

```dart
// Get currently trending artworks
final trendingArtworks = await discoveryService.getTrendingArtworks(
  limit: 20,
);
```

**Algorithm**: Trending score calculation:

- View count (40% weight)
- Recency factor (30% weight)
- Engagement score (30% weight)
- Score = (views × recency_factor) + (likes × 2) + (comments × 3) + (shares × 5)

### Personalized Recommendations

```dart
// Get personalized recommendations for a user
final personalizedArtworks = await discoveryService.getPersonalizedRecommendations(
  userId: 'user-123',
  limit: 15,
);
```

**Algorithm**: User preference analysis:

- Liked artwork patterns
- Viewed artwork history
- Purchase behavior
- Location preferences
- Price sensitivity

### Discovery Feed

```dart
// Get combined discovery feed
final discoveryFeed = await discoveryService.getDiscoveryFeed(
  userId: 'user-123',
  limit: 25,
);
```

**Algorithm**: Multi-source combination:

- 40% personalized recommendations
- 30% trending content
- 20% similar to recently viewed
- 10% location-based content

## Usage

### Basic Setup

```dart
import 'package:artbeat_artwork/artbeat_artwork.dart';

// Initialize services
final discoveryService = ArtworkDiscoveryService();

// Get discovery recommendations
final recommendations = await discoveryService.getDiscoveryFeed(
  userId: currentUserId,
  limit: 20,
);
```

### UI Integration

```dart
import 'package:artbeat_artwork/artbeat_artwork.dart';

// Use the discovery widget
ArtworkDiscoveryWidget(
  artworks: recommendations,
  onArtworkTap: (artwork) => navigateToDetail(artwork),
)
```

## Testing

Run the test suite:

```bash
flutter test test/artwork_discovery_test.dart
```

## Dependencies

- `artbeat_core`: Core models and utilities
- `cloud_firestore`: Firebase database
- `firebase_storage`: Image storage
- `firebase_auth`: User authentication

## Contributing

1. Implement new discovery algorithms in `ArtworkDiscoveryService`
2. Add corresponding UI components in `widgets/`
3. Update tests in `test/`
4. Update this README with new features

## Status

- ✅ Similar artwork recommendations
- ✅ Trending artwork detection
- ✅ Personalized discovery feeds
- ✅ Moderation system
- ✅ Basic artwork management
- ✅ Test coverage</content>
  <parameter name="filePath">/Users/kristybock/artbeat/packages/artbeat_artwork/README.md
