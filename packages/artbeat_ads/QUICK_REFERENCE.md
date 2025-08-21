# ARTbeat Ads - Quick Reference Guide

## 🚀 Quick Start

### 1. Add Banner Ad

```dart
BannerAdWidget(location: AdLocation.dashboard)
```

### 2. Add Feed Ad

```dart
FeedAdWidget(location: AdLocation.communityFeed, index: index)
```

### 3. Create Ad Screen

```dart
Navigator.push(context, MaterialPageRoute(
  builder: (context) => SimpleAdCreateScreen(),
));
```

### 4. Admin Management

```dart
Navigator.push(context, MaterialPageRoute(
  builder: (context) => SimpleAdManagementScreen(),
));
```

## 📊 Ad Sizes & Pricing

| Size   | Dimensions | Price/Day | Use Case         |
| ------ | ---------- | --------- | ---------------- |
| Small  | 320x50     | $1        | Small banners    |
| Medium | 320x100    | $5        | Standard banners |
| Large  | 320x250    | $10       | Featured ads     |

## 📍 Ad Locations

- `AdLocation.dashboard` - Main dashboard
- `AdLocation.artWalkDashboard` - Art walk section
- `AdLocation.captureDashboard` - Capture section
- `AdLocation.communityDashboard` - Community section
- `AdLocation.eventsDashboard` - Events section
- `AdLocation.communityFeed` - Community feed

## 🧩 Key Widgets

### BannerAdWidget

```dart
BannerAdWidget(
  location: AdLocation.dashboard,
  showAtTop: true, // or false for bottom
)
```

### FeedAdWidget

```dart
FeedAdWidget(
  location: AdLocation.communityFeed,
  index: index, // for feed positioning
)
```

### SimpleAdPlacementWidget

```dart
SimpleAdPlacementWidget(
  location: AdLocation.dashboard,
  padding: EdgeInsets.all(16),
  showIfEmpty: false,
)
```

## ⚙️ Service Usage

### Create Ad with Images

```dart
final adService = SimpleAdService();
await adService.createAdWithImages(ad, imageFiles);
```

### Get Ads by Location

```dart
final ads = await adService.getAdsByLocation(AdLocation.dashboard);
```

### Admin Operations

```dart
await adService.approveAd(adId, adminId);
await adService.rejectAd(adId, adminId, reason);
await adService.deleteAd(adId); // Also deletes images
```

## 📱 Integration Examples

### Dashboard with Ads

```dart
Column(
  children: [
    BannerAdWidget(location: AdLocation.dashboard),
    Expanded(child: YourContent()),
    BannerAdWidget(location: AdLocation.dashboard, showAtTop: false),
  ],
)
```

### Feed with Ads

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    if (index % 5 == 2) {
      return FeedAdWidget(location: AdLocation.communityFeed, index: index);
    }
    return YourContentItem(items[index]);
  },
)
```

## 🔧 Common Patterns

### Provider Setup

```dart
ChangeNotifierProvider(
  create: (_) => SimpleAdService(),
  child: YourApp(),
)
```

### Stream Ads

```dart
StreamBuilder<List<AdModel>>(
  stream: adService.getAdsStream(AdLocation.dashboard),
  builder: (context, snapshot) {
    // Handle ad display
  },
)
```

### Error Handling

```dart
try {
  await adService.createAdWithImages(ad, images);
} catch (e) {
  // Handle error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to create ad: $e')),
  );
}
```

## 🎨 Customization

### Custom Ad Space

```dart
SimpleAdPlacementWidget(
  location: AdLocation.dashboard,
  builder: (context, ad) {
    return CustomAdWidget(ad: ad);
  },
)
```

### Custom Empty State

```dart
SimpleAdPlacementWidget(
  location: AdLocation.dashboard,
  emptyBuilder: (context) {
    return Text('No ads available');
  },
)
```

## 🧪 Testing

### Widget Tests

```dart
testWidgets('Banner ad displays correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BannerAdWidget(location: AdLocation.dashboard),
    ),
  );

  expect(find.byType(BannerAdWidget), findsOneWidget);
});
```

### Service Tests

```dart
test('Creates ad with images', () async {
  final service = SimpleAdService();
  final ad = AdModel(/* ... */);
  final images = [File('test.jpg')];

  await service.createAdWithImages(ad, images);

  // Verify ad was created
});
```

## 🚨 Troubleshooting

### Ads Not Showing

1. Check ad status is `approved`
2. Verify ad dates (not expired)
3. Ensure correct location targeting
4. Check Firebase permissions

### Images Not Loading

1. Verify Firebase Storage setup
2. Check image URLs are valid
3. Ensure network connectivity
4. Check file permissions

### Upload Failures

1. Check file size limits
2. Verify Firebase Storage rules
3. Ensure user authentication
4. Check network connection

## 📚 Documentation

- **README_SIMPLE.md** - Complete documentation
- **MIGRATION_GUIDE.md** - Migration from legacy system
- **SimpleAdExample** - Working code examples

## 🔗 Related Files

- **Models**: `lib/src/models/`
- **Services**: `lib/src/services/simple_ad_service.dart`
- **Widgets**: `lib/src/widgets/`
- **Screens**: `lib/src/screens/`
- **Examples**: `lib/src/examples/`
