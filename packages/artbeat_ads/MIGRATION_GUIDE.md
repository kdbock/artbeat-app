# Migration Guide: Legacy to Simplified Ad System

This guide helps you migrate from the legacy ad system to the new simplified ad system.

## Overview of Changes

### What's New

- ✅ Unified ad creation for all user types
- ✅ Standardized sizes and pricing
- ✅ Automatic image upload and management
- ✅ Simplified placement widgets
- ✅ Streamlined admin workflow

### What's Removed

- ❌ Complex ad type system (square, rectangle, etc.)
- ❌ Variable pricing models
- ❌ Separate models for different user types
- ❌ Manual image URL management
- ❌ Complex approval workflows

## Step-by-Step Migration

### 1. Update Imports

**Before:**

```dart
import 'package:artbeat_ads/artbeat_ads.dart';

// Using legacy widgets
DashboardAdPlacementWidget()
AdDisplayWidget()
BaseAdCreateScreen()
AdminAdManagementScreen()
```

**After:**

```dart
import 'package:artbeat_ads/artbeat_ads.dart';

// Using simplified widgets
SimpleAdPlacementWidget()
SimpleAdDisplayWidget()
SimpleAdCreateScreen()
SimpleAdManagementScreen()
```

### 2. Replace Ad Creation Screens

**Before:**

```dart
// Different screens for different user types
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ArtistAdCreateScreen(),
));

Navigator.push(context, MaterialPageRoute(
  builder: (context) => GalleryAdCreateScreen(),
));

Navigator.push(context, MaterialPageRoute(
  builder: (context) => UserAdCreateScreen(),
));
```

**After:**

```dart
// Single unified screen for all users
Navigator.push(context, MaterialPageRoute(
  builder: (context) => SimpleAdCreateScreen(),
));
```

### 3. Update Ad Placement

**Before:**

```dart
// Complex placement with manual configuration
DashboardAdPlacementWidget(
  adType: AdType.square,
  location: AdLocation.dashboard,
  priceRange: PriceRange(min: 1.0, max: 10.0),
  // ... many other parameters
)
```

**After:**

```dart
// Simple placement
BannerAdWidget(location: AdLocation.dashboard)

// Or for feeds
FeedAdWidget(location: AdLocation.communityFeed, index: index)

// Or custom placement
SimpleAdPlacementWidget(location: AdLocation.dashboard)
```

### 4. Update Admin Screens

**Before:**

```dart
Navigator.push(context, MaterialPageRoute(
  builder: (context) => AdminAdReviewScreen(),
));
```

**After:**

```dart
Navigator.push(context, MaterialPageRoute(
  builder: (context) => SimpleAdManagementScreen(),
));
```

### 5. Update Service Usage

**Before:**

```dart
final adService = AdService();
final adBusinessService = AdBusinessService();
final adUploadService = AdUploadService();

// Complex ad creation
final ad = await adBusinessService.createBusinessAd(/* many parameters */);
await adUploadService.uploadImages(images);
await adService.createAd(ad);
```

**After:**

```dart
final adService = SimpleAdService();

// Simple ad creation with images
await adService.createAdWithImages(ad, images);
```

## Data Migration

### Firestore Schema Changes

**Legacy Schema:**

```json
{
  "type": "square", // String values
  "pricePerDay": 5.5, // Variable pricing
  "targetId": "artist123", // Target references
  "imageUrl": "single_url" // Single image
  // ... many other fields
}
```

**New Schema:**

```json
{
  "type": 0, // Enum index (banner_ad)
  "size": 1, // Enum index (medium)
  "imageUrl": "primary_url", // Primary image
  "artworkUrls": "url1,url2,url3" // Multiple images
  // Removed: pricePerDay (calculated from size)
  // Removed: targetId (simplified model)
}
```

### Migration Script

Create a Firebase Cloud Function to migrate existing ads:

```typescript
// functions/src/migrateAds.ts
import * as admin from "firebase-admin";

export const migrateAdsToSimplified = functions.https.onRequest(
  async (req, res) => {
    const db = admin.firestore();
    const adsRef = db.collection("ads");

    const snapshot = await adsRef.get();
    let migratedCount = 0;

    for (const doc of snapshot.docs) {
      const oldData = doc.data();

      // Map old type to new type
      const newType = mapLegacyTypeToNew(oldData.type);
      const newSize = mapPriceToSize(oldData.pricePerDay);

      const newData = {
        type: newType,
        size: newSize,
        imageUrl: oldData.imageUrl || "",
        artworkUrls: oldData.imageUrl || "", // Single image becomes artworkUrls
        title: oldData.title || "",
        description: oldData.description || "",
        location: oldData.location || 0,
        duration: oldData.duration || { days: 7 },
        startDate: oldData.startDate,
        endDate: oldData.endDate,
        status: oldData.status || 0,
        ownerId: oldData.ownerId,
        approvalId: oldData.approvalId,
        destinationUrl: oldData.destinationUrl,
        ctaText: oldData.ctaText,
      };

      await doc.ref.update(newData);
      migratedCount++;
    }

    res.json({ success: true, migratedCount });
  }
);

function mapLegacyTypeToNew(legacyType: string): number {
  // Map legacy types to new simplified types
  switch (legacyType) {
    case "square":
    case "rectangle":
    default:
      return 0; // banner_ad
  }
}

function mapPriceToSize(price: number): number {
  // Map price to size
  if (price <= 1) return 0; // small
  if (price <= 5) return 1; // medium
  return 2; // large
}
```

## Code Examples

### Before and After Comparisons

#### 1. Dashboard Integration

**Before:**

```dart
class FluidDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          DashboardAdPlacementWidget(
            adType: AdType.square,
            location: AdLocation.dashboard,
            priceRange: PriceRange(min: 1.0, max: 10.0),
            showDebugInfo: false,
            onAdTap: (ad) => handleAdTap(ad),
          ),
          // ... rest of dashboard
        ],
      ),
    );
  }
}
```

**After:**

```dart
class FluidDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BannerAdWidget(location: AdLocation.dashboard),
          // ... rest of dashboard
        ],
      ),
    );
  }
}
```

#### 2. Ad Creation

**Before:**

```dart
// Artist-specific ad creation
class ArtistAdCreateScreen extends StatefulWidget {
  @override
  _ArtistAdCreateScreenState createState() => _ArtistAdCreateScreenState();
}

class _ArtistAdCreateScreenState extends State<ArtistAdCreateScreen> {
  final _controller = AdFormController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UniversalAdForm(
        controller: _controller,
        userType: UserType.artist,
        onSubmit: (ad) async {
          // Complex submission logic
          await _controller.submitAd(ad);
        },
      ),
    );
  }
}
```

**After:**

```dart
// Single unified screen
class SimpleAdCreateScreen extends StatefulWidget {
  @override
  State<SimpleAdCreateScreen> createState() => _SimpleAdCreateScreenState();
}

class _SimpleAdCreateScreenState extends State<SimpleAdCreateScreen> {
  // Simple form with built-in logic
  // No need for separate controllers or user type handling
}
```

#### 3. Service Usage

**Before:**

```dart
class AdManager {
  final AdService _adService = AdService();
  final AdBusinessService _businessService = AdBusinessService();
  final AdUploadService _uploadService = AdUploadService();

  Future<void> createAd(AdModel ad, List<File> images) async {
    // Upload images first
    final imageUrls = await _uploadService.uploadImages(images);

    // Update ad with image URLs
    final updatedAd = ad.copyWith(imageUrl: imageUrls.first);

    // Create ad
    await _adService.createAd(updatedAd);

    // Handle business logic
    await _businessService.processAdCreation(updatedAd);
  }
}
```

**After:**

```dart
class AdManager {
  final SimpleAdService _adService = SimpleAdService();

  Future<void> createAd(AdModel ad, List<File> images) async {
    // Single method handles everything
    await _adService.createAdWithImages(ad, images);
  }
}
```

## Testing Migration

### 1. Create Test Environment

```dart
// test/migration_test.dart
void main() {
  group('Ad Migration Tests', () {
    testWidgets('Legacy ad placement still works', (tester) async {
      // Test that old widgets still function during transition
    });

    testWidgets('New simplified widgets work', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BannerAdWidget(location: AdLocation.dashboard),
          ),
        ),
      );

      // Verify widget renders correctly
    });
  });
}
```

### 2. Gradual Migration Strategy

1. **Phase 1**: Deploy new system alongside legacy (both work)
2. **Phase 2**: Update screens one by one to use new system
3. **Phase 3**: Migrate existing data using cloud function
4. **Phase 4**: Remove legacy code

### 3. Feature Flags

```dart
class FeatureFlags {
  static const bool useSimplifiedAds = true; // Toggle for gradual rollout
}

// In your widgets
Widget buildAdWidget() {
  if (FeatureFlags.useSimplifiedAds) {
    return BannerAdWidget(location: AdLocation.dashboard);
  } else {
    return DashboardAdPlacementWidget(/* legacy params */);
  }
}
```

## Rollback Plan

If issues arise, you can rollback:

1. **Code Rollback**: Set feature flag to `false`
2. **Data Rollback**: Keep legacy fields during migration period
3. **Service Rollback**: Keep both services running in parallel

## Validation Checklist

Before completing migration:

- [ ] All ad creation flows work with new system
- [ ] All ad placement locations display correctly
- [ ] Admin approval workflow functions properly
- [ ] Image upload and rotation work correctly
- [ ] Existing ads display properly after migration
- [ ] Performance is acceptable
- [ ] No data loss occurred during migration
- [ ] All user types can create ads successfully
- [ ] Analytics and tracking still work

## Support During Migration

1. **Monitor Error Logs**: Watch for migration-related errors
2. **User Feedback**: Collect feedback on new ad creation flow
3. **Performance Metrics**: Monitor ad load times and display rates
4. **Data Integrity**: Verify no ads are lost during migration

## Timeline Recommendation

- **Week 1**: Deploy new system (feature flagged off)
- **Week 2**: Enable for internal testing
- **Week 3**: Enable for 10% of users
- **Week 4**: Enable for 50% of users
- **Week 5**: Enable for all users
- **Week 6**: Run data migration
- **Week 7**: Remove legacy code

This gradual approach ensures stability and allows for quick rollback if needed.
