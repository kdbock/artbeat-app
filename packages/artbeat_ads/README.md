# ArtBeat Local Ads Package

Simplified local ad system for ArtBeat - allows local businesses and users to post affordable ads across designated zones in the app.

## Overview

The `artbeat_ads` package provides a clean, straightforward advertising system where:
- **Local businesses and users** can post ads for 7, 30, 90, or 365 days
- **Pricing** is simple and affordable ($0.99 - $9.99 per ad)
- **Zones** are predefined app locations (Home, Events, Artists, Community, Featured)
- **IAP (In-App Purchase)** handles payments seamlessly on both iOS and Android
- **Firebase** manages all ad data and storage

## Architecture

### 1. Models (`lib/src/models/`)

**LocalAd** - Core ad model
- `id`: Unique identifier
- `userId`: Who posted the ad
- `title`, `description`: Ad content
- `imageUrl`: Optional image
- `contactInfo`: Phone/email
- `websiteUrl`: External link
- `zone`: Display location
- `createdAt`, `expiresAt`: Timeline
- `status`: Active, Expired, or Deleted

**LocalAdDuration** - Duration options
- 7 Days: $0.99
- 30 Days: $2.99
- 90 Days: $5.99
- 1 Year: $9.99

**LocalAdZone** - Ad placement zones
- `home`: Main dashboard
- `events`: Events & experiences
- `artists`: Artist profiles
- `community`: Community hub & feeds
- `featured`: Premium featured placement

**LocalAdStatus** - Ad lifecycle
- `active`: Currently running
- `expired`: Past expiration date
- `deleted`: User-deleted

**LocalAdPurchase** - Purchase records
- Tracks IAP transactions for ads

### 2. Services (`lib/src/services/`)

**LocalAdService** - Ad CRUD operations
```dart
// Create ad
Future<String> createAd(LocalAd ad)

// Retrieve ads
Future<LocalAd?> getAd(String id)
Future<List<LocalAd>> getAdsByZone(LocalAdZone zone)
Future<List<LocalAd>> getMyAds(String userId)
Future<List<LocalAd>> searchAds(String query)

// Delete ad
Future<void> deleteAd(String id)

// Maintenance
Future<void> expireOldAds()
```

**LocalAdIapService** - In-App Purchase management
```dart
// IAP operations
Future<void> initIap()
Future<List<ProductDetails>> fetchProducts()
Future<void> purchaseDuration(LocalAdDuration duration)
Future<void> restorePurchases()

// Recording
Future<void> recordPurchase(LocalAdPurchase purchase)
Future<List<LocalAdPurchase>> getUserPurchases(String userId)
```

### 3. Screens (`lib/src/screens/`)

**CreateLocalAdScreen**
- User fills in ad details: title, description, optional image, contact info, website
- Selects zone and duration
- Reviews pricing
- Completes IAP purchase
- Ad created automatically upon success

**LocalAdsListScreen**
- Browse ads by zone
- Search functionality
- Display ads in carousel/list
- Tap to view contact info or external links
- Latest/pinned ads shown first

**MyAdsScreen**
- View all user's ads
- Separate active and expired tabs
- Delete old ads
- Create new ads from this screen

### 4. Widgets (`lib/src/widgets/`)

**AdCard**
- Displays individual ad with image, title, description
- Shows days remaining
- Contact buttons (call, email, website)
- Delete button (for user's own ads)

**ZoneFilter**
- Horizontal chip filter
- Quick zone switching
- Integrated into browse screen

## Firebase Structure

```
/localAds/{adId}
├── userId
├── title
├── description
├── imageUrl
├── contactInfo
├── websiteUrl
├── zone (index)
├── createdAt (Timestamp)
├── expiresAt (Timestamp)
└── status (index)

/users/{userId}/adPurchases/{purchaseId}
├── iapTransactionId
├── duration (index)
├── purchasedAt (Timestamp)
└── price
```

## Usage

### Import

```dart
import 'package:artbeat_ads/artbeat_ads.dart';
```

### Browse Ads

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const LocalAdsListScreen(
      initialZone: LocalAdZone.home,
    ),
  ),
);
```

### Post New Ad

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CreateLocalAdScreen(),
  ),
);
```

### View My Ads

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MyAdsScreen(),
  ),
);
```

### Programmatic Ad Fetching

```dart
final adService = LocalAdService();

// Get ads by zone
final homeAds = await adService.getActiveAdsByZone(LocalAdZone.home);

// Get user's ads
final myAds = await adService.getMyAds(userId);

// Search ads
final results = await adService.searchAds('art supplies');
```

## Firebase Setup

### Firestore Composite Index

The ad queries require a composite index on the `localAds` collection:

**Index Fields (in order):**
1. `status` (Ascending)
2. `zone` (Ascending)
3. `createdAt` (Descending)
4. `expiresAt` (Descending)

**To Create:**
1. When you run the app and try to query ads, you'll get an error with a direct link
2. Click the link in the error message to create the index automatically in Firebase Console
3. Or manually create it:
   - Go to Firebase Console → Firestore Database → Indexes
   - Click "Create Index"
   - Collection: `localAds`
   - Add fields in order above
   - Click "Create Index"

**Note:** Indexes take 5-10 minutes to build. Ad queries will fail until the index is active.

### Firestore Collection Structure

Make sure your Firestore has these collections:
- `localAds` - Store ad documents
- `users/{userId}/adPurchases` - Store purchase records

## IAP Setup

### iOS (App Store Connect)

1. Create 6 consumable IAP products in App Store Connect:

   **Small Ads (Banner Format)**
   - **ID**: `ad_small_1w` → **Price**: $0.99
   - **ID**: `ad_small_1m` → **Price**: $1.99
   - **ID**: `ad_small_3m` → **Price**: $4.99

   **Big Ads (Square Format)**
   - **ID**: `ad_big_1w` → **Price**: $1.99
   - **ID**: `ad_big_1m` → **Price**: $3.99
   - **ID**: `ad_big_3m` → **Price**: $9.99

2. For each product:
   - Set Display Name (e.g., "Small Ad - 1 Week")
   - Ensure all metadata is complete
   - Set correct subscription group (if needed)

3. Set up StoreKit configuration in Xcode for testing

### Android (Google Play Console)

1. Create 6 managed products with exact same IDs and prices
2. Upload signed APK/AAB before testing IAP

### Testing on iOS

1. Create sandbox tester account in App Store Connect
2. Use that account to test purchases
3. Purchases won't charge real payment method
4. Products must be "Ready to Submit" status minimum

### Troubleshooting

If you see **"Product not available"** error:
- Verify all 6 products are created in App Store Connect
- Ensure product IDs match exactly (case-sensitive): `ad_small_1w`, `ad_small_1m`, `ad_small_3m`, `ad_big_1w`, `ad_big_1m`, `ad_big_3m`
- Check that bundle ID matches between Xcode and App Store Connect
- Wait 15-30 minutes after creating products for changes to sync
- Products must be in at least "Ready to Submit" status

## Key Features

✅ **Affordable Pricing** - Starting at $0.99  
✅ **Flexible Durations** - 7 days to 1 year  
✅ **Zone-Based Targeting** - Strategic placements  
✅ **IAP Integration** - Works on iOS & Android  
✅ **Image Support** - Upload and cache images  
✅ **Search & Filter** - Find relevant ads  
✅ **Contact Options** - Phone, email, web links  
✅ **Clean UI** - Simple, intuitive screens  
✅ **Auto-Expiration** - Ads automatically expire  
✅ **Firebase Backed** - Scalable and secure  

## State Management

Currently uses:
- **Provider** for state management (optional)
- **Firebase** for data persistence
- **Built-in setState** for screen-level state

For larger features, wrap services in `ChangeNotifier` or use Provider.

## Error Handling

All services throw descriptive exceptions:

```dart
try {
  await adService.createAd(ad);
} catch (e) {
  print('Error: $e'); // "Failed to create ad: ..."
}
```

## Performance Considerations

- **Firestore indexes** on `zone`, `status`, `expiresAt` for fast queries
- **Image caching** via `cached_network_image`
- **Lazy loading** - only fetch ads when viewing zone
- **Pagination** - limit 10 ads per load (can be increased)

## Future Enhancements

- Analytics dashboard (views, clicks per ad)
- Ad statistics (trending, popular)
- Admin moderation panel
- Recurring ad bundles (subscriptions)
- A/B testing support
- Multi-image gallery ads
- Social sharing
