# ArtBeat Artwork Enhancements - Quick Start Guide

Fast reference for developers using the new enhancement features.

---

## 🎯 Quick Links

- **Payment Processing**: [Stripe Integration](#stripe-payment)
- **Social Sharing**: [URL-Based Sharing](#social-sharing)
- **Pagination**: [Infinite Scroll](#infinite-scroll)
- **Caching**: [Offline Cache](#offline-caching)

---

## 💳 Stripe Payment

### Import

```dart
import 'package:artbeat_core/artbeat_core.dart' show StripePaymentService;
```

### Basic Usage

```dart
final paymentService = StripePaymentService();

// Initialize at app startup
await paymentService.initializeStripe('pk_test_...');

// Create payment for purchase
final intent = await paymentService.createPaymentIntent(
  artworkId: 'artwork_123',
  artistId: 'artist_456',
  amount: 99.99,
  currency: 'USD',
);

// Process purchase
final transactionId = await paymentService.purchaseArtwork(
  artworkId: 'artwork_123',
  artistId: 'artist_456',
  amount: 99.99,
  paymentMethod: 'card',
);

// Get purchase history
final purchases = await paymentService.getPurchaseHistory();

// Refund
await paymentService.refundPurchase(transactionId);

// Artist earnings
final earnings = await paymentService.getArtistEarnings('artist_456');
print('Artist earned: \$${earnings.toStringAsFixed(2)}');
```

### Payout Calculation

```dart
// Default: Platform takes 15%, artist gets 85%
final purchase = 100.00;
final artistPayment = paymentService.calculateArtistPayout(purchase);
// Result: $85.00
```

### Custom Platform Fee

```dart
// 20% fee example
final payout = paymentService.calculateArtistPayout(
  100.00,
  platformFeePercentage: 0.20,
); // Result: $80.00
```

---

## 🤝 Social Sharing

### Import

```dart
import 'package:artbeat_core/artbeat_core.dart' show EnhancedShareService;
```

### Basic Usage

```dart
final shareService = EnhancedShareService();

// Share to Facebook
await shareService.shareOnFacebook(
  artworkId: 'artwork_123',
  artworkTitle: 'Sunset Painting',
  artistName: 'Jane Doe',
  imageUrl: 'https://...',
);

// Share to Instagram
await shareService.shareOnInstagram(
  artworkId: 'artwork_123',
  artworkTitle: 'Sunset Painting',
  artistName: 'Jane Doe',
);

// Share to Stories (Instagram or Facebook)
await shareService.shareToStories(
  artworkId: 'artwork_123',
  artworkTitle: 'Sunset Painting',
  artistName: 'Jane Doe',
  backgroundImage: 'https://...',
);

// Share to Twitter
await shareService.shareOnTwitter(
  artworkId: 'artwork_123',
  artworkTitle: 'Sunset Painting',
  artistName: 'Jane Doe',
);

// Share to WhatsApp
await shareService.shareOnWhatsApp(
  artworkId: 'artwork_123',
  artworkTitle: 'Sunset Painting',
  artistName: 'Jane Doe',
);

// Share via Email
await shareService.shareViaEmail(
  artworkId: 'artwork_123',
  artworkTitle: 'Sunset Painting',
  artistName: 'Jane Doe',
  userEmail: 'user@example.com',
);
```

### Helper Methods

```dart
// Generate deep link
final link = shareService.generateDeepLink('artwork_123');
// Output: https://artbeat.app/artwork/artwork_123

// Generate share message
final msg = shareService.generateShareMessage(
  artworkTitle: 'Sunset Painting',
  artistName: 'Jane Doe',
);
// Output: "✨ Check out "Sunset Painting" by Jane Doe on ArtBeat! 🎨"

// Get all platforms
final platforms = shareService.getAvailablePlatforms();
platforms.forEach((platform) {
  print('${platform['label']}: ${platform['platform']}');
});
```

### UI Integration Example

```dart
ElevatedButton(
  onPressed: () async {
    final success = await shareService.shareOnTwitter(
      artworkId: artwork.id,
      artworkTitle: artwork.title,
      artistName: artwork.artistName,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shared on Twitter!')),
      );
    }
  },
  child: const Text('Share on Twitter'),
)
```

---

## 📜 Infinite Scroll Pagination

### Import

```dart
import 'package:artbeat_artwork/artbeat_artwork.dart'
  show ArtworkPaginationService;
```

### Basic Usage

```dart
final paginationService = ArtworkPaginationService();

// Load first page
var state = await paginationService.loadFeaturedArtworks();
print('Loaded ${state.items.length} items');
print('Has more: ${state.hasMore}');

// Load next page
if (state.hasMore) {
  state = await paginationService.loadFeaturedArtworks(
    lastDocument: state.lastDocument,
  );
}

// Alternative methods
final recentState = await paginationService.loadRecentArtworks();
final trendingState = await paginationService.loadTrendingArtworks();
final allState = await paginationService.loadAllArtworks();

// By artist
final artistState = await paginationService.loadArtistArtworks(
  artistId: 'artist_123',
);
```

### Return Value Details

```dart
state.items        // List<ArtworkModel> - the 50 items loaded
state.lastDocument // DocumentSnapshot - cursor for next batch
state.hasMore      // bool - true if more items exist
state.isLoading    // bool - current loading state
state.error        // String? - error message if any
```

### Page Size Configuration

```dart
// Current page size: 50 items
// Change in ArtworkPaginationService:
static const int _pageSize = 100; // Edit this constant
```

### Scroll Detection Threshold

```dart
// Current threshold: 500 pixels from bottom
// Edit in screen's _onScroll():
if (_scrollController.position.pixels >=
    _scrollController.position.maxScrollExtent - 500) {
  _loadMoreArtworks();
}
```

### Full Screen Implementation

```dart
class MyArtworkScreen extends StatefulWidget {
  @override
  State<MyArtworkScreen> createState() => _MyArtworkScreenState();
}

class _MyArtworkScreenState extends State<MyArtworkScreen> {
  final ArtworkPaginationService _pagService = ArtworkPaginationService();
  final ScrollController _scrollController = ScrollController();

  List<ArtworkModel> _artworks = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadInitial() async {
    final state = await _pagService.loadRecentArtworks();
    setState(() {
      _artworks = state.items;
      _lastDocument = state.lastDocument;
      _hasMore = state.hasMore;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final state = await _pagService.loadRecentArtworks(
      lastDocument: _lastDocument,
    );

    setState(() {
      _artworks.addAll(state.items);
      _lastDocument = state.lastDocument;
      _hasMore = state.hasMore;
      _isLoadingMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _artworks.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _artworks.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return ArtworkTile(artwork: _artworks[index]);
      },
    );
  }
}
```

---

## 💾 Offline Caching

### Import

```dart
import 'package:artbeat_core/artbeat_core.dart'
  show OfflineCachingService;
```

### Initialize (In main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize
  await OfflineCachingService().initialize();

  // Start auto-cleanup (optional but recommended)
  OfflineCachingService().startPeriodicCleanup(
    interval: Duration(minutes: 15),
  );

  runApp(const MyApp());
}
```

### Cache Single Item

```dart
final cache = OfflineCachingService();

// Cache a single item
await cache.cacheData(
  'current_user',
  userData,
  ttl: Duration(hours: 1),
);

// Retrieve later
final cached = await cache.getCachedData<UserModel>(
  'current_user',
  fromJson: (json) => UserModel.fromJson(json),
);

if (cached != null) {
  print('Using cached user data');
} else {
  print('Cache expired or not found');
}
```

### Cache Lists (Pagination)

```dart
// Cache list of artworks
await cache.cacheList(
  'featured_artworks',
  artworks,
  ttl: Duration(hours: 1),
);

// Retrieve cached list
final cached = await cache.getCachedList<ArtworkModel>(
  'featured_artworks',
  fromJson: (json) => ArtworkModel.fromJson(json),
);
```

### Append to Cache (For Pagination)

```dart
// When user loads more
final newBatch = await _loadMoreArtworks();

// Append to existing cache
await cache.appendToCache(
  'featured_artworks',
  newBatch,
  ttl: Duration(hours: 1),
);
```

### Cache Management

```dart
// Check cache statistics
final stats = await cache.getCacheStats();
print('Total entries: ${stats['totalCacheEntries']}');
print('Size: ${stats['approximateSizeKB']} KB');

// Clear specific cache
await cache.clearCache('featured_artworks');

// Clear all caches
await cache.clearAllCaches();

// Manual cleanup
await cache.autoCleanup();
```

### TTL Options

```dart
// Default: 1 hour
await cache.cacheData('key', data);

// Custom durations
await cache.cacheData('key', data, ttl: Duration(minutes: 30));
await cache.cacheData('key', data, ttl: Duration(days: 1));
await cache.cacheData('key', data, ttl: Duration(hours: 6));
```

### Usage Pattern for Network-First Strategy

```dart
Future<List<ArtworkModel>> getArtworks() async {
  final cache = OfflineCachingService();

  try {
    // Try to fetch from network
    final artworks = await fetchFromFirebase();

    // Cache for offline use
    await cache.cacheList('artworks', artworks);

    return artworks;
  } catch (e) {
    // Fall back to cache if network fails
    final cached = await cache.getCachedList<ArtworkModel>(
      'artworks',
      fromJson: (json) => ArtworkModel.fromJson(json),
    );

    if (cached != null) {
      print('Using cached artworks (offline mode)');
      return cached;
    } else {
      rethrow; // No cache available
    }
  }
}
```

### Key Naming Convention

```dart
// Use consistent keys for easier management
'artworks_featured'      // Featured artworks
'artworks_recent'        // Recent uploads
'artworks_trending'      // Trending artworks
'artworks_user_{id}'     // User's artworks
'artist_{id}_profile'    // Artist profile
'user_settings'          // User settings
```

---

## 🔄 Combined Usage Example

### Purchase + Share Flow

```dart
// User buys artwork
final transactionId = await paymentService.purchaseArtwork(
  artworkId: artwork.id,
  artistId: artwork.artistId,
  amount: artwork.price,
  paymentMethod: 'card',
);

// Show success
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Purchase successful!')),
);

// Offer to share
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Share Your Purchase?'),
    actions: [
      TextButton(
        onPressed: () async {
          await shareService.shareOnTwitter(
            artworkId: artwork.id,
            artworkTitle: artwork.title,
            artistName: artwork.artistName,
          );
        },
        child: const Text('Twitter'),
      ),
      TextButton(
        onPressed: () async {
          await shareService.shareOnFacebook(
            artworkId: artwork.id,
            artworkTitle: artwork.title,
            artistName: artwork.artistName,
          );
        },
        child: const Text('Facebook'),
      ),
    ],
  ),
);
```

### Paginate + Cache Flow

```dart
Future<void> loadArtworks() async {
  // Check cache first
  final cached = await cache.getCachedList<ArtworkModel>(
    'featured_artworks',
    fromJson: (json) => ArtworkModel.fromJson(json),
  );

  if (cached != null) {
    setState(() => _artworks = cached);
  }

  // Load fresh data in background
  final state = await paginationService.loadFeaturedArtworks();

  // Update UI
  setState(() {
    _artworks = state.items;
    _hasMore = state.hasMore;
  });

  // Cache for next time
  await cache.cacheList('featured_artworks', state.items);
}
```

---

## 🐛 Troubleshooting

### Payment Issues

```dart
// Check if authenticated
if (FirebaseAuth.instance.currentUser == null) {
  // Show login screen
}

// Verify card details
if (cardNumber.length != 16) {
  print('Invalid card number');
}

// Check Stripe keys
if (stripePublishableKey.isEmpty) {
  print('Stripe key not configured');
}
```

### Pagination Issues

```dart
// Check for duplicates
final uniqueIds = Set.from(_artworks.map((a) => a.id));
if (uniqueIds.length != _artworks.length) {
  print('WARNING: Duplicate items found!');
}

// Verify hasMore flag
if (!_hasMore && _artworks.isNotEmpty) {
  print('Reached end of list');
}

// Check scroll position
print('Scroll: ${_scrollController.position.pixels}/'
      '${_scrollController.position.maxScrollExtent}');
```

### Cache Issues

```dart
// Check cache stats
final stats = await cache.getCacheStats();
if (stats['totalCacheEntries'] == 0) {
  print('Cache is empty');
}

// Verify TTL
final data = await cache.getCachedData('key');
if (data == null) {
  print('Cache expired or not found');
}

// Clear corrupted cache
await cache.clearAllCaches();
await OfflineCachingService().initialize();
```

---

## 📚 Related Files

- **Payment Service**: `packages/artbeat_core/lib/src/services/stripe_payment_service.dart`
- **Share Service**: `packages/artbeat_core/lib/src/services/enhanced_share_service.dart`
- **Pagination Service**: `packages/artbeat_artwork/lib/src/services/artwork_pagination_service.dart`
- **Caching Service**: `packages/artbeat_core/lib/src/services/offline_caching_service.dart`
- **Purchase Screen**: `packages/artbeat_artwork/lib/src/screens/artwork_purchase_screen.dart`

---

## 📞 Support

For issues or questions:

1. Check inline documentation in source files
2. Review test files for usage examples
3. Check implementation summary for architecture details
4. Debug with `AppLogger.info()` and `AppLogger.error()`

---

**Last Updated**: January 2025  
**Version**: 1.0  
**Status**: Ready to Use ✅
