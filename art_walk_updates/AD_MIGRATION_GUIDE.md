## Ad Migration Tool - Quick Setup Guide

### 🎯 **What This Does**

Migrates your ads from the old `ads` collection to the new `localAds` collection with proper field mapping.

### 🚀 **How to Access the Migration Screen**

**Option 1: Add to App Router (Recommended)**

Add this route to your app's router:

```dart
case '/ads/migrate':
  return MaterialPageRoute(
    builder: (_) => const AdMigrationScreen(),
  );
```

Then navigate to it:

```dart
Navigator.pushNamed(context, '/ads/migrate');
```

**Option 2: Direct Navigation**

```dart
import 'package:artbeat_ads/artbeat_ads.dart';

// Navigate directly
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const AdMigrationScreen(),
  ),
);
```

**Option 3: Add to Admin Menu**

Add a button to your admin dashboard:

```dart
ElevatedButton.icon(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AdMigrationScreen()),
  ),
  icon: const Icon(Icons.upload),
  label: const Text('Migrate Ads'),
),
```

### 🔄 **Migration Steps**

1. **Check Stats** - See how many ads are in each collection
2. **Dry Run** - Preview what will be migrated (no changes made)
3. **Migrate** - Actually copy the ads over
4. **Verify** - Check that ads appear in your app

### ⚠️ **Important Notes**

- **Safe**: Original ads in `ads` collection are NOT deleted
- **Smart**: Skips ads that already exist in `localAds` (unless you choose overwrite)
- **Mapped**: Properly converts old field formats to new formats
- **Reporting Ready**: Adds reporting fields (reportCount = 0) to migrated ads

### 📊 **Field Mapping**

| Old Field         | New Field     | Notes                        |
| ----------------- | ------------- | ---------------------------- |
| `ownerId`         | `userId`      | User who owns the ad         |
| `location`/`zone` | `zone`        | Mapped to LocalAdZone enum   |
| `status`          | `status`      | Mapped to LocalAdStatus enum |
| `size`            | `size`        | Mapped to LocalAdSize enum   |
| `startDate`       | `createdAt`   | When ad was created          |
| `endDate`         | `expiresAt`   | When ad expires              |
| `destinationUrl`  | `websiteUrl`  | External link                |
| -                 | `reportCount` | New field, starts at 0       |
| -                 | `reviewedAt`  | New field, starts null       |
| -                 | `reviewedBy`  | New field, starts null       |

### ✅ **After Migration**

Your migrated ads will:

- ✅ Show up in the new ad system (`MyAdsScreen`, `LocalAdsListScreen`)
- ✅ Have reporting functionality enabled
- ✅ Work with the admin dashboard
- ✅ Be compatible with all new ad features

### 🆘 **If Something Goes Wrong**

The migration is safe - your original ads remain untouched in the `ads` collection. If needed, you can:

1. Delete ads from `localAds` collection in Firebase Console
2. Fix any issues with the migration script
3. Run migration again

---

**Ready to migrate?** Access the migration screen using one of the options above!
