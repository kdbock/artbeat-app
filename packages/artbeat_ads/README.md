# ARTbeat Ads Package

A simplified, streamlined ad system for the ARTbeat Flutter application.

## 🚀 Quick Start

### 1. Add to your screen

```dart
import 'package:artbeat_ads/artbeat_ads.dart';

// Add ads anywhere in your app
SimpleAdPlacementWidget(
  location: AdLocation.dashboard,
)
```

### 2. Create ads

```dart
// Navigate to ad creation
Navigator.push(context, MaterialPageRoute(
  builder: (context) => SimpleAdCreateScreen(),
));
```

### 3. Admin management

```dart
// Admin panel for approving ads
Navigator.push(context, MaterialPageRoute(
  builder: (context) => SimpleAdManagementScreen(),
));
```

## 📋 Features

- ✅ **Unified ad creation** for all user types
- ✅ **Standardized pricing**: $1, $5, $10/day
- ✅ **Multi-image support** (1-4 images with rotation)
- ✅ **Easy placement** with simple widgets
- ✅ **Admin approval** workflow
- ✅ **Firebase integration** (Firestore + Storage)

## 📊 Ad Sizes & Pricing

| Size   | Dimensions | Price/Day |
| ------ | ---------- | --------- |
| Small  | 320x50     | $1        |
| Medium | 320x100    | $5        |
| Large  | 320x250    | $10       |

## 🎯 Placement Locations

- Main Dashboard
- Art Walk Dashboard
- Capture Dashboard
- Community Dashboard
- Events Dashboard
- Community Feed

## 📖 Documentation

- **[Complete Guide](README_SIMPLE.md)** - Detailed documentation
- **[Integration Examples](lib/src/examples/)** - Working code samples
- **[Removal Checklist](REMOVAL_CHECKLIST.md)** - Migration guide

## 🏗️ Architecture

### Core Components

- `SimpleAdService` - Single service for all ad operations
- `SimpleAdPlacementWidget` - Easy ad placement
- `SimpleAdCreateScreen` - Unified ad creation
- `SimpleAdManagementScreen` - Admin panel

### Models

- `AdModel` - Unified ad data model
- `AdLocation` - Placement locations
- `AdSize` - Standardized sizes
- `AdStatus` - Approval workflow

## 🔧 Migration from Legacy System

If migrating from the old complex ad system, see [REMOVAL_CHECKLIST.md](REMOVAL_CHECKLIST.md) for step-by-step instructions.

## 📈 Performance

- **65% reduction** in code size (9,133 → 3,160 lines)
- **46% reduction** in file count (48 → 26 files)
- **Simplified architecture** with single service and unified models
- **Improved developer experience** with consistent API

## 🎉 Success!

The ARTbeat ad system is now simplified, streamlined, and ready for easy integration across the entire application!
