# ARTbeat Ads Package

The **artbeat_ads** package provides a comprehensive local advertising system for the ARTbeat platform, enabling businesses and users to create, manage, and display targeted advertisements throughout the application.

## 🌟 Features

### Core Advertising Functions

- **Local Business Ads**: Simple ad creation for local businesses
- **Flexible Ad Sizes**: Small banner and large square ad formats
- **Zone-Based Targeting**: Strategic ad placement across app sections
- **Duration Options**: 1 week, 1 month, and 3-month campaigns
- **In-App Purchases**: Seamless payment processing for ad campaigns
- **Content Moderation**: Admin review system for ad approval
- **Real-Time Management**: Users can manage their active campaigns

### Advanced Features

- **Ad Analytics**: Performance tracking and reporting
- **Migration System**: Data migration tools for system updates
- **Smart Filtering**: Zone-based ad filtering and discovery
- **Automated Expiration**: Automatic ad lifecycle management
- **Reporting System**: User reporting for inappropriate content
- **Admin Dashboard Integration**: Full admin control and oversight

## 📱 User Interface

### Ad Display Components

- **Carousel Widget**: Rotating ad display with auto-navigation
- **Card Components**: Beautiful ad cards with rich media support
- **Banner Widgets**: Small format banner advertisements
- **Grid Layouts**: Multi-ad grid display for discovery
- **Native Cards**: Seamlessly integrated ad content

### Management Screens

- **Create Ad Screen**: Intuitive ad creation with image upload
- **My Ads Screen**: Personal ad management dashboard
- **Browse Ads Screen**: Ad discovery with filtering options
- **Migration Screen**: System migration interface for admins

## 🏗️ Architecture

### Data Models

#### Core Models

```dart
// Primary ad model with complete lifecycle management
LocalAd                 // Ad content, placement, and status
LocalAdZone            // Ad placement zones (Home, Events, Artists, etc.)
LocalAdSize            // Ad dimensions (Small banner, Large square)
LocalAdDuration        // Campaign duration (1 week, 1 month, 3 months)
LocalAdStatus          // Ad lifecycle status management
LocalAdPriority        // Ad display priority system

// Business models
LocalAdPurchase        // In-app purchase transaction records
AdPricingMatrix        // Pricing configuration and SKU management
AdReportModel          // User reporting and moderation system
```

#### Pricing Structure

```dart
class AdPricingMatrix {
  // Small ads (banner format)
  static const smallWeek = AdPricingConfig(
    size: LocalAdSize.small,
    duration: LocalAdDuration.oneWeek,
    sku: 'ad_small_1w',
    price: 0.99,
  );

  // Large ads (square format)
  static const bigMonth = AdPricingConfig(
    size: LocalAdSize.big,
    duration: LocalAdDuration.oneMonth,
    sku: 'ad_big_1m',
    price: 3.99,
  );

  // Complete pricing matrix with 6 total configurations
}
```

### Service Architecture

#### Core Services

```dart
// Primary ad management service
LocalAdService {
  Future<String> createAd(LocalAd ad);
  Future<List<LocalAd>> getAdsByZone(LocalAdZone zone);
  Future<List<LocalAd>> getMyAds(String userId);
  Future<void> updateAdStatus(String adId, LocalAdStatus status);
  Future<void> deleteAd(String adId);
  Future<List<LocalAd>> searchAds(String query);
}

// In-app purchase management
LocalAdIapService {
  Future<void> initIap();
  Future<List<ProductDetails>> fetchProducts();
  Future<void> purchaseAd(LocalAdSize size, LocalAdDuration duration);
  Future<void> recordPurchase(LocalAdPurchase purchase);
  Future<List<LocalAdPurchase>> getUserPurchases(String userId);
}

// Ad reporting and moderation
AdReportService {
  Future<void> reportAd(String adId, String reason);
  Future<List<AdReportModel>> getReportsForAd(String adId);
  Future<void> resolveReport(String reportId, String resolution);
}

// System migration utilities
AdMigrationService {
  Future<void> migrateAdData();
  Future<bool> checkMigrationStatus();
  Future<void> cleanupOldData();
}
```

## 🛠️ Installation & Setup

### Dependencies

```yaml
dependencies:
  flutter: sdk
  artbeat_core: ^0.1.0
  cloud_firestore: ^6.0.0
  firebase_storage: ^13.0.0
  firebase_auth: ^6.0.1
  in_app_purchase: ^3.2.3
  provider: ^6.1.5
  image_picker: ^1.0.0
  cached_network_image: ^3.4.1
  intl: ^0.20.2
  url_launcher: ^6.2.5
```

### Firebase Configuration

#### Firestore Collections

```javascript
// Ad documents
/localAds/{adId} {
  userId: string,
  title: string,
  description: string,
  imageUrl?: string,
  contactInfo?: string,
  websiteUrl?: string,
  zone: number,        // LocalAdZone index
  size: number,        // LocalAdSize index
  createdAt: Timestamp,
  expiresAt: Timestamp,
  status: number,      // LocalAdStatus index
  reportCount: number,
  reviewedAt?: Timestamp,
  reviewedBy?: string,
  rejectionReason?: string
}

// Purchase records
/users/{userId}/adPurchases/{purchaseId} {
  iapTransactionId: string,
  size: number,
  duration: number,
  purchasedAt: Timestamp,
  price: number,
  sku: string
}

// Ad reports
/adReports/{reportId} {
  adId: string,
  reportedBy: string,
  reason: string,
  reportedAt: Timestamp,
  status: string,
  resolvedBy?: string,
  resolvedAt?: Timestamp
}
```

#### Required Firestore Indexes

```javascript
// Primary ad queries
Collection: localAds;
Fields: zone(Ascending), status(Ascending), expiresAt(Descending);

// User ads queries
Collection: localAds;
Fields: userId(Ascending), createdAt(Descending);

// Admin moderation queries
Collection: localAds;
Fields: status(Ascending), reportCount(Descending);
```

### In-App Purchase Setup

#### iOS App Store Connect

Create 6 consumable products:

**Small Ads (Banner Format)**

- `ad_small_1w`: $0.99 (1 Week)
- `ad_small_1m`: $1.99 (1 Month)
- `ad_small_3m`: $4.99 (3 Months)

**Large Ads (Square Format)**

- `ad_big_1w`: $1.99 (1 Week)
- `ad_big_1m`: $3.99 (1 Month)
- `ad_big_3m`: $9.99 (3 Months)

#### Android Google Play Console

Create matching managed products with identical SKUs and pricing.

## 🚀 Usage

### Basic Ad Operations

```dart
import 'package:artbeat_ads/artbeat_ads.dart';

// Initialize services
final adService = LocalAdService();
final iapService = LocalAdIapService();

// Create new ad
final newAd = LocalAd(
  id: '',
  userId: currentUserId,
  title: 'Local Art Gallery Opening',
  description: 'Join us for an amazing art exhibition...',
  zone: LocalAdZone.events,
  size: LocalAdSize.big,
  createdAt: DateTime.now(),
  expiresAt: DateTime.now().add(Duration(days: 30)),
);

final adId = await adService.createAd(newAd);
```

### Ad Navigation

```dart
// Browse ads by zone
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LocalAdsListScreen(
      initialZone: LocalAdZone.home,
    ),
  ),
);

// Create new ad
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CreateLocalAdScreen(),
  ),
);

// Manage user's ads
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MyAdsScreen(),
  ),
);
```

### Ad Widget Integration

```dart
// Display ads in app sections
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main content
        const MainContent(),

        // Ad carousel for home zone
        AdCarouselWidget(
          zone: LocalAdZone.home,
          height: 200,
          autoRotateDuration: Duration(seconds: 5),
        ),

        // More content
        const AdditionalContent(),
      ],
    );
  }
}

// Individual ad display
FutureBuilder<List<LocalAd>>(
  future: adService.getAdsByZone(LocalAdZone.community),
  builder: (context, snapshot) {
    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
      return Column(
        children: snapshot.data!.map((ad) => AdCard(
          ad: ad,
          onTap: () => _handleAdTap(ad),
          onReport: () => _reportAd(ad.id),
        )).toList(),
      );
    }
    return const SizedBox.shrink();
  },
)
```

### In-App Purchase Flow

```dart
// Purchase ad campaign
Future<void> purchaseAdCampaign(
  LocalAdSize size,
  LocalAdDuration duration,
) async {
  try {
    // Initialize IAP
    await iapService.initIap();

    // Fetch available products
    final products = await iapService.fetchProducts();

    // Purchase specific configuration
    await iapService.purchaseAd(
      size: size,
      duration: duration,
    );

    // Record purchase for user
    final purchase = LocalAdPurchase(
      id: generateId(),
      userId: currentUserId,
      size: size,
      duration: duration,
      purchasedAt: DateTime.now(),
      price: AdPricingMatrix.getPrice(size, duration)!,
    );

    await iapService.recordPurchase(purchase);

  } catch (e) {
    // Handle purchase errors
    showErrorDialog('Purchase failed: $e');
  }
}
```

## 🎯 Ad Zone Management

### Zone Configuration

```dart
enum LocalAdZone {
  home,        // Main dashboard - highest visibility
  events,      // Events and exhibitions section
  artists,     // Artist profiles and portfolios
  community,   // Community hub and social feeds
  featured,    // Premium featured placement
}

// Zone-specific ad fetching
final homeAds = await adService.getAdsByZone(LocalAdZone.home);
final eventAds = await adService.getAdsByZone(LocalAdZone.events);
```

### Smart Ad Placement

```dart
// Automatic zone-appropriate ad display
class SmartAdWidget extends StatelessWidget {
  final LocalAdZone zone;
  final int maxAds;

  const SmartAdWidget({
    required this.zone,
    this.maxAds = 3,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LocalAd>>(
      future: LocalAdService().getAdsByZone(zone),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingWidget();

        final ads = snapshot.data!.take(maxAds).toList();

        return zone == LocalAdZone.featured
            ? FeaturedAdCarousel(ads: ads)
            : StandardAdGrid(ads: ads);
      },
    );
  }
}
```

## 🔐 Content Moderation

### Ad Review System

```dart
// Admin moderation workflow
class AdModerationService {
  Future<List<LocalAd>> getPendingAds() async {
    return await adService.getAdsForReview();
  }

  Future<void> approveAd(String adId, String adminId) async {
    await adService.updateAdStatus(
      adId: adId,
      status: LocalAdStatus.active,
      adminId: adminId,
    );
  }

  Future<void> rejectAd(
    String adId,
    String adminId,
    String reason,
  ) async {
    await adService.updateAdStatus(
      adId: adId,
      status: LocalAdStatus.rejected,
      adminId: adminId,
      rejectionReason: reason,
    );
  }
}
```

### User Reporting

```dart
// Report inappropriate ads
Future<void> reportAd(String adId, String reason) async {
  final reportService = AdReportService();

  await reportService.reportAd(adId, reason);

  // Show confirmation to user
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Ad reported. Thank you for helping keep our community safe.'),
    ),
  );
}

// Handle reports in admin panel
final reports = await reportService.getReportsForAd(adId);
final flaggedAds = reports.where((r) => r.status == 'pending').toList();
```

## 📊 Analytics & Reporting

### Ad Performance Tracking

```dart
// Track ad interactions
class AdAnalyticsService {
  Future<void> trackAdView(String adId) async {
    await FirebaseFirestore.instance
        .collection('adAnalytics')
        .doc(adId)
        .collection('events')
        .add({
      'type': 'view',
      'timestamp': FieldValue.serverTimestamp(),
      'userId': FirebaseAuth.instance.currentUser?.uid,
    });
  }

  Future<void> trackAdClick(String adId, String actionType) async {
    await FirebaseFirestore.instance
        .collection('adAnalytics')
        .doc(adId)
        .collection('events')
        .add({
      'type': 'click',
      'action': actionType, // 'contact', 'website', 'phone'
      'timestamp': FieldValue.serverTimestamp(),
      'userId': FirebaseAuth.instance.currentUser?.uid,
    });
  }

  Future<Map<String, dynamic>> getAdMetrics(String adId) async {
    final events = await FirebaseFirestore.instance
        .collection('adAnalytics')
        .doc(adId)
        .collection('events')
        .get();

    final views = events.docs.where((d) => d.data()['type'] == 'view').length;
    final clicks = events.docs.where((d) => d.data()['type'] == 'click').length;

    return {
      'views': views,
      'clicks': clicks,
      'ctr': clicks > 0 ? clicks / views : 0.0,
    };
  }
}
```

### Revenue Analytics

```dart
// Track ad revenue and performance
class AdRevenueService {
  Future<Map<String, dynamic>> getRevenueAnalytics() async {
    final purchases = await FirebaseFirestore.instance
        .collectionGroup('adPurchases')
        .get();

    double totalRevenue = 0;
    Map<String, int> purchasesBySize = {'small': 0, 'big': 0};
    Map<String, int> purchasesByDuration = {'1w': 0, '1m': 0, '3m': 0};

    for (final doc in purchases.docs) {
      final data = doc.data();
      totalRevenue += (data['price'] as num).toDouble();

      final size = LocalAdSize.values[data['size']];
      final duration = LocalAdDuration.values[data['duration']];

      purchasesBySize[size.name] =
          (purchasesBySize[size.name] ?? 0) + 1;
      purchasesByDuration[duration.name] =
          (purchasesByDuration[duration.name] ?? 0) + 1;
    }

    return {
      'totalRevenue': totalRevenue,
      'totalPurchases': purchases.docs.length,
      'purchasesBySize': purchasesBySize,
      'purchasesByDuration': purchasesByDuration,
      'averageRevenuePerPurchase': totalRevenue / purchases.docs.length,
    };
  }
}
```

## 🔧 Customization

### Custom Ad Widgets

```dart
// Create custom ad display components
class CustomAdBanner extends StatelessWidget {
  final LocalAd ad;
  final VoidCallback? onTap;

  const CustomAdBanner({
    required this.ad,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ad image
              if (ad.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: ad.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 12),

              // Ad content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ad.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Ad badge
              AdBadgeWidget(
                text: '${ad.daysRemaining}d',
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Theme Customization

```dart
// Custom ad theme configuration
class AdThemeConfig {
  static const primaryColor = Color(0xFF6B46C1);
  static const secondaryColor = Color(0xFF10B981);
  static const backgroundColor = Color(0xFFF9FAFB);

  static ThemeData get adTheme => ThemeData(
    primarySwatch: MaterialColor(0xFF6B46C1, {
      50: Color(0xFFF3F0FF),
      100: Color(0xFFE0D7FF),
      // ... other shades
    }),
    cardTheme: const CardTheme(
      elevation: 2,
      shadowColor: Colors.black12,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
  );
}
```

## 🚨 Error Handling

### Service Error Management

```dart
// Comprehensive error handling
class AdErrorHandler {
  static void handleAdError(dynamic error, StackTrace stackTrace) {
    // Log error details
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      fatal: false,
    );

    // Provide user-friendly error messages
    String userMessage;
    if (error is FirebaseException) {
      userMessage = _getFirebaseErrorMessage(error.code);
    } else if (error is PlatformException) {
      userMessage = _getIAPErrorMessage(error.code);
    } else {
      userMessage = 'An unexpected error occurred. Please try again.';
    }

    // Show error to user
    Get.snackbar(
      'Error',
      userMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  static String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action.';
      case 'not-found':
        return 'The requested ad was not found.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return 'A database error occurred. Please try again.';
    }
  }

  static String _getIAPErrorMessage(String? code) {
    switch (code) {
      case 'user_cancelled':
        return 'Purchase was cancelled.';
      case 'product_not_available':
        return 'This ad package is not available.';
      case 'payment_failed':
        return 'Payment failed. Please check your payment method.';
      default:
        return 'Purchase failed. Please try again.';
    }
  }
}
```

### Network Error Recovery

```dart
// Retry logic for network operations
class NetworkRetryService {
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        if (attempts >= maxRetries) {
          rethrow;
        }

        // Exponential backoff
        await Future.delayed(delay * attempts);
      }
    }

    throw Exception('Max retry attempts exceeded');
  }
}

// Usage in services
Future<List<LocalAd>> getAdsWithRetry(LocalAdZone zone) async {
  return NetworkRetryService.retryOperation(
    () => adService.getAdsByZone(zone),
    maxRetries: 3,
    delay: const Duration(seconds: 2),
  );
}
```

## 🧪 Testing

### Unit Tests

```dart
// Test ad creation and management
void main() {
  group('LocalAdService Tests', () {
    late LocalAdService adService;

    setUp(() {
      adService = LocalAdService();
    });

    test('should create ad successfully', () async {
      final ad = LocalAd(
        id: '',
        userId: 'test-user',
        title: 'Test Ad',
        description: 'Test Description',
        zone: LocalAdZone.home,
        size: LocalAdSize.small,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 7)),
      );

      final adId = await adService.createAd(ad);
      expect(adId, isNotEmpty);
    });

    test('should fetch ads by zone', () async {
      final ads = await adService.getAdsByZone(LocalAdZone.home);
      expect(ads, isA<List<LocalAd>>());
    });

    test('should handle ad expiration', () {
      final expiredAd = LocalAd(
        id: 'test-id',
        userId: 'test-user',
        title: 'Test Ad',
        description: 'Test Description',
        zone: LocalAdZone.home,
        size: LocalAdSize.small,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        expiresAt: DateTime.now().subtract(Duration(days: 1)),
      );

      expect(expiredAd.isExpired, isTrue);
      expect(expiredAd.daysRemaining, equals(0));
    });
  });

  group('AdPricingMatrix Tests', () {
    test('should return correct pricing', () {
      final price = AdPricingMatrix.getPrice(
        LocalAdSize.small,
        LocalAdDuration.oneWeek,
      );
      expect(price, equals(0.99));
    });

    test('should return correct SKU', () {
      final sku = AdPricingMatrix.getSku(
        LocalAdSize.big,
        LocalAdDuration.oneMonth,
      );
      expect(sku, equals('ad_big_1m'));
    });
  });
}
```

### Widget Tests

```dart
// Test ad widget functionality
testWidgets('AdCard displays correctly', (tester) async {
  final testAd = LocalAd(
    id: 'test-id',
    userId: 'test-user',
    title: 'Test Ad Title',
    description: 'Test Ad Description',
    zone: LocalAdZone.home,
    size: LocalAdSize.small,
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(Duration(days: 7)),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AdCard(ad: testAd),
      ),
    ),
  );

  expect(find.text('Test Ad Title'), findsOneWidget);
  expect(find.text('Test Ad Description'), findsOneWidget);
  expect(find.text('7d'), findsOneWidget); // Days remaining
});

testWidgets('CreateLocalAdScreen validates input', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CreateLocalAdScreen(),
    ),
  );

  // Try to submit empty form
  await tester.tap(find.text('Create Ad'));
  await tester.pump();

  // Should show validation errors
  expect(find.text('Please enter ad title'), findsOneWidget);
  expect(find.text('Please enter ad description'), findsOneWidget);
});
```

### Integration Tests

```dart
// Test complete ad creation flow
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Ad Creation Flow', () {
    testWidgets('complete ad creation process', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to create ad screen
      await tester.tap(find.text('Create Ad'));
      await tester.pumpAndSettle();

      // Fill in ad details
      await tester.enterText(find.byKey(Key('title-field')), 'Test Ad');
      await tester.enterText(find.byKey(Key('description-field')), 'Test Description');

      // Select zone and size
      await tester.tap(find.text('Events'));
      await tester.tap(find.text('Large'));

      // Select duration
      await tester.tap(find.text('1 Month'));

      // Complete purchase (would need mock IAP)
      await tester.tap(find.text('Purchase Ad'));
      await tester.pumpAndSettle();

      // Verify ad creation success
      expect(find.text('Ad created successfully!'), findsOneWidget);
    });
  });
}
```

## 🔄 Migration & Updates

### Data Migration System

```dart
// Handle data migrations between versions
class AdMigrationService {
  static const String _migrationVersion = '1.0.0';

  Future<void> runMigrations() async {
    final currentVersion = await _getCurrentVersion();

    if (currentVersion != _migrationVersion) {
      await _performMigration(currentVersion, _migrationVersion);
      await _setCurrentVersion(_migrationVersion);
    }
  }

  Future<void> _performMigration(String from, String to) async {
    // Migration logic for different version transitions
    if (from == '0.9.0' && to == '1.0.0') {
      await _migrateV090ToV100();
    }
  }

  Future<void> _migrateV090ToV100() async {
    // Example: Add new fields to existing ads
    final batch = FirebaseFirestore.instance.batch();
    final ads = await FirebaseFirestore.instance
        .collection('localAds')
        .get();

    for (final doc in ads.docs) {
      if (!doc.data().containsKey('reportCount')) {
        batch.update(doc.reference, {'reportCount': 0});
      }
    }

    await batch.commit();
  }
}
```

## 📚 API Reference

### Core Classes

#### LocalAd

Primary ad model containing all ad information and metadata.

**Key Properties:**

- `id`: Unique identifier
- `userId`: Ad owner's user ID
- `title`: Ad headline
- `description`: Ad content description
- `zone`: Placement zone
- `size`: Ad dimensions
- `createdAt`: Creation timestamp
- `expiresAt`: Expiration timestamp
- `status`: Current ad status

**Key Methods:**

- `isExpired`: Check if ad has expired
- `daysRemaining`: Get remaining days in campaign
- `isVisibleToUsers`: Check if ad should be displayed
- `needsReview`: Check if ad requires moderation

#### LocalAdService

Core service for ad management operations.

**Key Methods:**

- `createAd(LocalAd ad)`: Create new advertisement
- `getAd(String id)`: Retrieve specific ad
- `getAdsByZone(LocalAdZone zone)`: Get ads for specific zone
- `getMyAds(String userId)`: Get user's ads
- `updateAdStatus()`: Update ad moderation status
- `deleteAd(String id)`: Remove advertisement
- `searchAds(String query)`: Search ads by keyword

#### LocalAdIapService

In-app purchase management for ad campaigns.

**Key Methods:**

- `initIap()`: Initialize purchase system
- `fetchProducts()`: Get available IAP products
- `purchaseAd()`: Process ad campaign purchase
- `recordPurchase()`: Save purchase record
- `getUserPurchases()`: Retrieve purchase history

### Enums and Constants

```dart
// Ad placement zones
enum LocalAdZone { home, events, artists, community, featured }

// Ad sizes
enum LocalAdSize { small, big }

// Campaign durations
enum LocalAdDuration { oneWeek, oneMonth, threeMonths }

// Ad lifecycle status
enum LocalAdStatus {
  active, expired, deleted, pendingReview, rejected, flagged
}

// Ad display priority
enum LocalAdPriority { low, normal, high, urgent }
```

## 📄 License

This package is part of the ARTbeat platform and follows the project's licensing terms.

## 🆘 Support

For ad system related issues:

- **Documentation**: Check this README and integration guide
- **IAP Issues**: Review App Store Connect/Google Play Console setup
- **Firebase**: Verify Firestore indexes and security rules
- **Performance**: Check ad loading and caching behavior

---

**Version**: 1.0.0  
**Last Updated**: November 2025  
**Maintainer**: ARTbeat Development Team
