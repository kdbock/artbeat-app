# ARTbeat Ads - Simplified Ad System

This document describes the new simplified ad system for ARTbeat, designed to replace the complex legacy system with a streamlined, user-friendly approach.

## Overview

The simplified ad system provides:

- **Unified ad creation** for all user types (users, artists, galleries)
- **Standardized ad sizes** with fixed pricing
- **Simple image upload** (1-4 images with automatic rotation)
- **Easy placement** throughout the app
- **Admin approval workflow**

## Key Features

### 1. Simplified Ad Types

- **Banner Ads**: Horizontal banners for top/bottom placement
- **Feed Ads**: Integrated into content feeds and lists

### 2. Standardized Sizes & Pricing

- **Small (320x50)**: $1/day
- **Medium (320x100)**: $5/day
- **Large (320x250)**: $10/day

### 3. Multiple Images

- Upload 1-4 images per ad
- Automatic rotation every 5 seconds
- All images stored in Firebase Storage

### 4. Location Targeting

- Main Dashboard
- Art Walk Dashboard
- Capture Dashboard
- Community Dashboard
- Events Dashboard
- Community Feed

## Quick Start

### 1. Basic Integration

```dart
import 'package:artbeat_ads/artbeat_ads.dart';

// Add ads to any screen
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Banner ad at top
          BannerAdWidget(location: AdLocation.dashboard),

          // Your content here
          Expanded(child: YourContent()),

          // Banner ad at bottom
          BannerAdWidget(location: AdLocation.dashboard, showAtTop: false),
        ],
      ),
    );
  }
}
```

### 2. Feed Integration

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    // Show ad every 5 items
    if (index % 5 == 2) {
      return FeedAdWidget(
        location: AdLocation.communityFeed,
        index: index,
      );
    }
    return YourContentItem(items[index]);
  },
);
```

### 3. Creating Ads

```dart
// Navigate to ad creation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SimpleAdCreateScreen(),
  ),
);
```

### 4. Admin Management

```dart
// Navigate to admin panel
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SimpleAdManagementScreen(),
  ),
);
```

## Architecture

### Models

#### AdModel

```dart
class AdModel {
  final String id;
  final String ownerId;
  final AdType type;           // banner_ad, feed_ad
  final AdSize size;           // small, medium, large
  final String imageUrl;       // Primary image
  final List<String> artworkUrls; // All images (1-4)
  final String title;
  final String description;
  final AdLocation location;
  final AdDuration duration;
  final DateTime startDate;
  final DateTime endDate;
  final AdStatus status;       // pending, approved, rejected, paused
  final String? destinationUrl;
  final String? ctaText;

  // Price calculated from size
  double get pricePerDay => size.pricePerDay;
}
```

#### AdSize

```dart
enum AdSize {
  small,  // 320x50 - $1/day
  medium, // 320x100 - $5/day
  large,  // 320x250 - $10/day
}
```

#### AdType

```dart
enum AdType {
  banner_ad, // Banner advertisements
  feed_ad,   // Feed advertisements
}
```

### Services

#### SimpleAdService

Main service for ad operations:

- `createAdWithImages()` - Create ad with image upload
- `getAdsByLocation()` - Get ads for specific location
- `getAdsByOwner()` - Get user's ads
- `approveAd()` - Admin approval
- `rejectAd()` - Admin rejection
- `deleteAd()` - Delete ad and images

### Widgets

#### SimpleAdDisplayWidget

Displays individual ads with:

- Image rotation (if multiple images)
- Click handling
- CTA buttons
- Responsive sizing

#### SimpleAdPlacementWidget

Handles ad placement:

- Streams ads by location
- Shows placeholder when no ads
- Automatic refresh

#### BannerAdWidget & FeedAdWidget

Specialized placement widgets for specific use cases.

## Usage Examples

### Dashboard Integration

```dart
class FluidDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top banner
          BannerAdWidget(location: AdLocation.dashboard),

          // Dashboard content
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: [
                DashboardTile('Art Walks'),
                DashboardTile('Community'),
                DashboardTile('Events'),
                DashboardTile('Capture'),
              ],
            ),
          ),

          // Bottom banner
          BannerAdWidget(
            location: AdLocation.dashboard,
            showAtTop: false,
          ),
        ],
      ),
    );
  }
}
```

### Community Feed Integration

```dart
class CommunityFeedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: postsStream,
      builder: (context, snapshot) {
        final posts = snapshot.data ?? [];

        return ListView.builder(
          itemCount: posts.length + (posts.length ~/ 5), // Add space for ads
          itemBuilder: (context, index) {
            // Insert ad every 5 posts
            if (index % 6 == 5) {
              return FeedAdWidget(
                location: AdLocation.communityFeed,
                index: index,
              );
            }

            final postIndex = index - (index ~/ 6);
            return PostWidget(posts[postIndex]);
          },
        );
      },
    );
  }
}
```

### Custom Ad Placement

```dart
class CustomScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom ad space
          SimpleAdPlacementWidget(
            location: AdLocation.artWalkDashboard,
            padding: EdgeInsets.all(16),
          ),

          // Your content
          Expanded(child: YourContent()),
        ],
      ),
    );
  }
}
```

## Admin Workflow

### 1. Ad Review Process

1. User creates ad → Status: `pending`
2. Admin reviews in `SimpleAdManagementScreen`
3. Admin approves → Status: `approved` (ad goes live)
4. Admin rejects → Status: `rejected` (ad hidden)

### 2. Ad Management

- View all ads with status indicators
- Approve/reject pending ads
- Pause/resume active ads
- Delete ads (removes images from storage)
- View statistics

### 3. Statistics Dashboard

- Total ads count
- Pending review count
- Approved ads count
- Rejected ads count
- Expired ads count

## Firebase Structure

### Firestore Collection: `ads`

```json
{
  "ownerId": "user123",
  "type": 0, // AdType.banner_ad
  "size": 1, // AdSize.medium
  "imageUrl": "https://...", // Primary image
  "artworkUrls": "url1,url2,url3", // Comma-separated
  "title": "My Ad Title",
  "description": "Ad description",
  "location": 0, // AdLocation.dashboard
  "duration": {
    "days": 7,
    "startDate": "2024-01-01T00:00:00Z",
    "endDate": "2024-01-08T00:00:00Z"
  },
  "startDate": "2024-01-01T00:00:00Z",
  "endDate": "2024-01-08T00:00:00Z",
  "status": 1, // AdStatus.approved
  "approvalId": "admin123",
  "destinationUrl": "https://example.com",
  "ctaText": "Shop Now"
}
```

### Firebase Storage: `ads/{ownerId}/{timestamp}_{index}_upload.png`

## Migration from Legacy System

The simplified system replaces the complex legacy system:

### Before (Legacy)

- Multiple ad types (square, rectangle, etc.)
- Complex pricing models
- Separate models for different user types
- Complicated approval workflows
- Manual image management

### After (Simplified)

- Two ad types (banner, feed)
- Fixed pricing by size
- Single unified model
- Simple approval workflow
- Automatic image upload/management

## Best Practices

### 1. Ad Placement

- Use `BannerAdWidget` for top/bottom placement
- Use `FeedAdWidget` for content integration
- Don't overload screens with too many ads
- Consider user experience when placing ads

### 2. Image Guidelines

- Use high-quality images (recommended: 1920x1080 max)
- Keep file sizes reasonable (< 2MB per image)
- Ensure images are appropriate for all audiences
- Test with different aspect ratios

### 3. Performance

- Ads are cached automatically
- Images are optimized during upload
- Use `showIfEmpty: false` to hide empty ad spaces
- Monitor ad load times in production

### 4. Testing

- Use `SimpleAdExample` for testing integration
- Test with different screen sizes
- Verify ad rotation works correctly
- Test admin approval workflow

## Troubleshooting

### Common Issues

1. **Ads not showing**

   - Check if ads are approved (`status: approved`)
   - Verify ad dates (not expired)
   - Ensure correct location targeting

2. **Images not loading**

   - Check Firebase Storage permissions
   - Verify image URLs are valid
   - Check network connectivity

3. **Upload failures**
   - Verify Firebase Storage is configured
   - Check file size limits
   - Ensure proper authentication

### Debug Tools

```dart
// Check active ads count
final adService = SimpleAdService();
final count = await adService.getActiveAdsCount(AdLocation.dashboard);
print('Active ads: $count');

// Get ad statistics
final stats = await adService.getAdsStatistics();
print('Stats: $stats');
```

## Future Enhancements

Potential improvements for future versions:

- A/B testing for ad performance
- Click tracking and analytics
- Geo-targeting capabilities
- Advanced scheduling options
- Revenue sharing models
- Integration with external ad networks

## Support

For questions or issues with the ad system:

1. Check this documentation
2. Review the example implementations
3. Test with `SimpleAdExample`
4. Check Firebase console for data/storage issues
