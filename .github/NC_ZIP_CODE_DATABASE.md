# North Carolina ZIP Code Database

This document outlines the North Carolina ZIP code database implementation in the ARTbeat app, designed to enhance location-based features for artwork and artists across different regions of North Carolina.

## Overview

The NC ZIP code database organizes all North Carolina ZIP codes by region and county, allowing the app to offer location-specific content, recommendations, and filtering options.

## Structure

The database is organized into:

- 6 main geographical regions of North Carolina
- Counties within each region 
- ZIP codes within each county

### Regions

1. Mountain (Western NC)
2. Foothills
3. Piedmont
4. Sandhills
5. Coastal Plain (Eastern NC)
6. Coastal/Outer Banks

## Implementation Files

- `lib/models/nc_region_model.dart` - Data model classes for regions, counties, and ZIP codes
- `lib/data/nc_zip_code_db.dart` - Database implementation with comprehensive lookup methods
- `lib/utils/location_utils.dart` - Utility functions for location-based operations
- `lib/utils/nc_location_finder.dart` - Higher-level interface for app-specific location features
- `lib/services/nc_region_service.dart` - Service to fetch region-specific data
- `lib/widgets/nc_region_selector_widget.dart` - UI widget for region selection
- `lib/widgets/nc_regional_artwork_widget.dart` - UI widget to display region-filtered artwork
- `lib/screens/explore/nc_regions_explore_screen.dart` - Screen to explore art by NC region
- `test/nc_zip_code_test.dart` - Test cases to verify database functionality

## Usage Examples

### Checking if a location is in North Carolina

```dart
final zipCode = '28801'; // Asheville
final isInNC = LocationUtils.isLocationInNC(zipCode); // returns true
```

### Getting region information for a ZIP code

```dart
final zipCode = '28801'; // Asheville
final region = LocationUtils.getRegionForZipCode(zipCode); // returns "Mountain"
final county = LocationUtils.getCountyForZipCode(zipCode); // returns "Buncombe County"
```

### Finding nearby artists and artwork

```dart
final locationFinder = NCLocationFinder();
final locationContext = await locationFinder.getUserLocationContext();

if (locationContext['success'] && locationContext['isInNC']) {
  // Use the ZIP code to find nearby art walks
  final nearbyArtWalks = await locationFinder.getNearbyArtWalks(locationContext['zipCode']);
  
  // Filter artwork query by region
  final artworkQuery = FirebaseFirestore.instance.collection('artwork');
  final filteredQuery = locationFinder.filterArtworkByRegion(artworkQuery, locationContext['region']);
}
```

### Using the Region Service

```dart
final regionService = NCRegionService();

// Get artwork from a specific region
final mountainArtwork = await regionService.getArtworkByRegion('Mountain', limit: 20);

// Get artists from a specific region
final piedmontArtists = await regionService.getArtistsByRegion('Piedmont');

// Get events from a specific region
final coastalEvents = await regionService.getEventsByRegion('Coastal');

// Get statistics for a region
final stats = await regionService.getRegionStatistics('Mountain');
print('Artists in Mountain Region: ${stats['artistCount']}');
```

### Adding Region Selection to a Screen

```dart
NCRegionSelectorWidget(
  onRegionSelected: (region) {
    print('Selected region: $region');
    // Update UI based on selected region
  },
  initialRegion: 'Mountain', // Optional initial selection
  title: 'Choose a Region', // Optional custom title
),
```

### Adding Region-Filtered Artwork to a Screen

```dart
NCRegionalArtworkWidget(
  limit: 10,
  height: 280,
  showRegionSelector: true,
  initialRegion: 'Foothills',
  onArtworkTap: (artwork) {
    // Handle artwork selection
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ArtworkDetailScreen(artwork: artwork),
    ));
  },
),
```

## Benefits

This database enables:

1. **Localized Browsing** - Show artists and artwork from the user's region
2. **Regional Art Walks** - Discover public art organized by geographical regions
3. **Location Filtering** - Filter content by region, county, or ZIP code
4. **Local Event Discovery** - Find art events in specific regions of North Carolina
5. **Regional Analytics** - Track artwork popularity and user engagement by region

## Integration Points

The NC ZIP code database integrates with:

- Art Walk feature for regionalized public art discovery
- Artist discovery to find creators in specific regions
- Gallery location filtering
- Event discovery based on user's region
- Location-based recommendations in the dashboard

## Screen Navigation

The NC Region Explorer screen can be accessed through:

1. The dashboard "Explore" section
2. The Art Walk feature as a "Browse by Region" option
3. The artist discovery flow as a location filter

## Widget Integration

The region selector and regional artwork widgets can be integrated into:

1. Dashboard screens to show local art content
2. Artist profile screens to show other artists from the same region
3. Event screens to filter events by region
4. Gallery screens to showcase artists from specific regions

## Data Structure Requirements

For proper integration with the NC ZIP code database, the following fields must be included in your data models:

### Artwork Model
- `location` (String) - The ZIP code where the artwork is located

### Artist Profile Model
- `location` (String) - The ZIP code of the artist's studio/location

### Event Model
- `location` (String) - The ZIP code where the event is taking place

### Art Walk Model
- `zipCode` (String) - The primary ZIP code associated with the art walk

## Firestore Indexes

The following Firestore indexes should be added for optimal performance:

1. `artwork` collection:
   - `location` + `createdAt` (descending)
   
2. `artistProfiles` collection:
   - `location` + `displayName` (ascending)
   
3. `events` collection:
   - `location` + `startDate` (ascending)
   
4. `artWalks` collection:
   - `zipCode` + `isPublic` + `viewCount` (descending)

## Future Enhancements

Planned improvements include:

- Integration with Google Maps geocoding for more precise location matching
- Expansion to include points of interest within each ZIP code area
- Clustering algorithm improvements for nearby artwork recommendations
- Caching system for offline region browsing capabilities
- Advanced region-based analytics for artists and galleries
- ZIP code proximity algorithms for "nearby" recommendations
- Region-based promotional content for featured artists
