# Art Walk Feature Documentation

## Overview
The Art Walk feature allows users to discover, document, and share public art throughout their city. Users can capture images of public art, tag them with metadata including location, create curated walks between art pieces, and share their walks with others.

## Key Features
1. **Public Art Capture**
   - Take photos of public art through the app's capture feature
   - Add metadata like artist name, art type, and description
   - Automatically capture location data and address

2. **Art Discovery**
   - Browse all public art on an interactive map
   - See art pieces near your current location
   - View detailed information about each art piece
   - Filter art by type, artist, or tags

3. **Custom Art Walks**
   - Create personalized art walk routes
   - Add multiple art pieces to a single walk
   - Set title, description, and cover image for walks
   - Save private or public walks

4. **Art Walk Sharing**
   - Share your created walks with friends
   - Discover popular walks created by other users
   - Get navigation guidance between art pieces

## Data Models

### PublicArtModel
Represents a single piece of public art with location data.
```dart
PublicArtModel({
  required String id,
  required String userId,
  required String title,
  required String description,
  required String imageUrl,
  String? artistName,
  required GeoPoint location,
  String? address,
  required List<String> tags,
  String? artType,
  bool isVerified = false,
  int viewCount = 0,
  int likeCount = 0,
  required List<String> usersFavorited,
  required Timestamp createdAt,
  Timestamp? updatedAt,
});
```

### ArtWalkModel
Represents a collection of public art pieces organized as a walk.
```dart
ArtWalkModel({
  required String id,
  required String userId,
  required String title,
  required String description,
  required List<String> artIds,
  String? routePolyline,
  double? distanceKm,
  int? estimatedMinutes,
  String? coverImageUrl,
  bool isPublic = true,
  int viewCount = 0,
  int likeCount = 0,
  int shareCount = 0,
  required Timestamp createdAt,
  Timestamp? updatedAt,
});
```

## File Structure
- `models/`
  - `public_art_model.dart` - Model for public art with location data
  - `art_walk_model.dart` - Model for art walk collections
  
- `services/`
  - `art_walk_service.dart` - Service for CRUD operations on art walks
  
- `screens/art_walk/`
  - `art_walk_map_screen.dart` - Shows all public art on a map
  - `art_walk_list_screen.dart` - Lists user's and popular art walks
  - `art_walk_detail_screen.dart` - Shows details of a specific art walk
  - `create_art_walk_screen.dart` - Interface for creating/editing art walks

## Integration
- The Art Walk feature is integrated into the main app via:
  1. Dashboard cards for quick access
  2. Integration with the Capture feature for adding public art
  3. Banner in the Discover screen for visibility
  4. Routes registered in main.dart for navigation

## Walking Directions Features
The Art Walk feature includes walking directions between art pieces:

1. **Walking Route Generation**
   - Get optimized walking routes between selected art pieces
   - View estimated distance and time for completing the walk
   - See turn-by-turn routes displayed on the map
   - Automatic rerouting if art pieces are reordered

2. **Directions Implementation Details**
   - Uses Google Directions API for accurate walking directions
   - Optimizes waypoint order for the most efficient route
   - Includes fallback to straight-line routes if API is unavailable
   - Provides accurate distance and time estimates based on real walking paths

3. **Usage Notes**
   - Requires a valid Google Maps API key with Directions API enabled
   - Walking directions work best in areas with good map data
   - Routes are optimized for pedestrians, avoiding highways and car-only roads
   - Routes automatically update when art pieces are added or removed

## Future Enhancements
1. ✅ Real-time directions between art pieces using Google Directions API
2. ✅ AR (Augmented Reality) view of nearby art
3. Audio guide feature for art walks
4. Gamification with badges for completing walks
5. Social features like comments on art pieces
6. Art verification system to ensure quality
