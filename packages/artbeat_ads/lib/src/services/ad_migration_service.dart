import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/local_ad.dart';
import '../models/local_ad_zone.dart';
import '../models/local_ad_status.dart';
import '../models/local_ad_size.dart';

/// Service for migrating ads from the old 'ads' collection to new 'localAds' collection
class AdMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _oldAdsCollection = 'ads';
  static const String _newAdsCollection = 'localAds';

  /// Migrate all ads from 'ads' collection to 'localAds' collection
  ///
  /// This will:
  /// - Copy ads with proper field mapping
  /// - Convert old AdLocation to new LocalAdZone
  /// - Convert old AdStatus to new LocalAdStatus
  /// - Add new reporting fields (reportCount = 0, no review data)
  /// - Skip ads that already exist in localAds
  Future<MigrationResult> migrateAllAds({
    bool dryRun = false,
    bool overwriteExisting = false,
  }) async {
    try {
      AppLogger.info(
        '🔄 Starting ad migration from $_oldAdsCollection to $_newAdsCollection...',
      );

      final result = MigrationResult();

      // Get all ads from old collection
      final oldAdsSnapshot = await _firestore
          .collection(_oldAdsCollection)
          .get();
      result.totalFound = oldAdsSnapshot.docs.length;

      if (result.totalFound == 0) {
        AppLogger.info('📭 No ads found in $_oldAdsCollection collection');
        return result;
      }

      // Get existing ads in new collection to avoid duplicates
      final existingAdsSnapshot = await _firestore
          .collection(_newAdsCollection)
          .get();
      final existingIds = existingAdsSnapshot.docs.map((doc) => doc.id).toSet();

      AppLogger.info(
        '📊 Found ${result.totalFound} ads to migrate, ${existingIds.length} already exist in $_newAdsCollection',
      );

      // Process each ad
      final batch = _firestore.batch();
      int batchCount = 0;

      for (final doc in oldAdsSnapshot.docs) {
        try {
          final oldData = doc.data();
          final adId = doc.id;

          // Skip if already exists and not overwriting
          if (existingIds.contains(adId) && !overwriteExisting) {
            result.skipped++;
            continue;
          }

          // Convert old ad data to new LocalAd structure
          final localAd = await _convertOldAdToLocalAd(adId, oldData);
          if (localAd == null) {
            result.failed++;
            result.errors.add(
              'Failed to convert ad $adId: Invalid data structure',
            );
            continue;
          }

          // Add to batch (if not dry run)
          if (!dryRun) {
            final newAdRef = _firestore.collection(_newAdsCollection).doc(adId);

            // Start from the LocalAd map, then preserve some legacy fields
            final Map<String, dynamic> newDoc = localAd.toMap();

            // Preserve artworkUrls array (if present) and ensure a primary imageUrl
            final artwork = oldData['artworkUrls'];
            if (artwork != null && artwork is List && artwork.isNotEmpty) {
              newDoc['artworkUrls'] = artwork;
              if ((newDoc['imageUrl'] == null ||
                      newDoc['imageUrl'].toString().isEmpty) &&
                  artwork.first != null) {
                newDoc['imageUrl'] = artwork.first.toString();
              }
            }

            // Preserve some additional legacy metadata that may be useful
            if (oldData['ctaText'] != null) {
              newDoc['ctaText'] = oldData['ctaText'];
            }
            if (oldData['imageFit'] != null) {
              newDoc['imageFit'] = oldData['imageFit'];
            }
            if (oldData['duration'] != null) {
              newDoc['duration'] = oldData['duration'];
            }

            batch.set(newAdRef, newDoc);
            batchCount++;

            // Commit batch every 450 operations (Firestore limit is 500)
            if (batchCount >= 450) {
              await batch.commit();
              batchCount = 0;
              AppLogger.info('📝 Committed batch of 450 ads...');
            }
          }

          result.migrated++;
        } catch (e) {
          result.failed++;
          result.errors.add('Error processing ad ${doc.id}: $e');
          AppLogger.error('❌ Error migrating ad ${doc.id}: $e');
        }
      }

      // Commit remaining batch
      if (!dryRun && batchCount > 0) {
        await batch.commit();
        AppLogger.info('📝 Committed final batch of $batchCount ads');
      }

      AppLogger.info(
        '✅ Migration completed! ${result.migrated} migrated, ${result.skipped} skipped, ${result.failed} failed',
      );
      return result;
    } catch (e) {
      AppLogger.error('❌ Migration failed: $e');
      throw Exception('Migration failed: $e');
    }
  }

  /// Convert old ad data structure to new LocalAd model
  Future<LocalAd?> _convertOldAdToLocalAd(
    String adId,
    Map<String, dynamic> oldData,
  ) async {
    try {
      // Map required fields
      final userId = oldData['ownerId']?.toString();
      final title = oldData['title']?.toString();
      final description = oldData['description']?.toString();

      if (userId == null || title == null || description == null) {
        return null; // Missing required fields
      }

      // Convert timestamps
      final createdAt = oldData['startDate'] is Timestamp
          ? (oldData['startDate'] as Timestamp).toDate()
          : oldData['createdAt'] is Timestamp
          ? (oldData['createdAt'] as Timestamp).toDate()
          : DateTime.now();

      final expiresAt = oldData['endDate'] is Timestamp
          ? (oldData['endDate'] as Timestamp).toDate()
          : createdAt.add(
              const Duration(days: 30),
            ); // Default 30 days if missing

      // Convert zone from old location/zone system
      final zone = _convertToLocalAdZone(oldData);

      // Convert status
      final status = _convertToLocalAdStatus(oldData);

      // Convert size
      final size = _convertToLocalAdSize(oldData);

      return LocalAd(
        id: adId,
        userId: userId,
        title: title,
        description: description,
        imageUrl: oldData['imageUrl']?.toString(),
        contactInfo:
            oldData['contactInfo']?.toString() ?? oldData['email']?.toString(),
        websiteUrl:
            oldData['destinationUrl']?.toString() ??
            oldData['websiteUrl']?.toString(),
        zone: zone,
        size: size,
        createdAt: createdAt,
        expiresAt: expiresAt,
        status: status,
        reportCount: 0, // New field - start with 0 reports
        // Review fields start as null (no review yet)
        reviewedAt: null,
        reviewedBy: null,
        rejectionReason: null,
      );
    } catch (e) {
      AppLogger.error('Error converting ad $adId: $e');
      return null;
    }
  }

  /// Convert old location/zone to new LocalAdZone
  LocalAdZone _convertToLocalAdZone(Map<String, dynamic> oldData) {
    // Try zone field first (newer ads)
    if (oldData['zone'] != null) {
      final zoneIndex = oldData['zone'] is int
          ? oldData['zone']
          : int.tryParse(oldData['zone'].toString());
      if (zoneIndex != null) {
        switch (zoneIndex) {
          case 0:
            return LocalAdZone.home; // homeDiscovery
          case 1:
            return LocalAdZone.events; // events
          case 2:
            return LocalAdZone.community; // communityMaps
          case 3:
            return LocalAdZone.artists; // artists
          case 4:
            return LocalAdZone.featured; // featured
          default:
            return LocalAdZone.home;
        }
      }
    }

    // Fall back to location field (older ads)
    if (oldData['location'] != null) {
      final locationIndex = oldData['location'] is int
          ? oldData['location']
          : int.tryParse(oldData['location'].toString());
      if (locationIndex != null) {
        switch (locationIndex) {
          case 0:
            return LocalAdZone.home; // dashboard
          case 1:
            return LocalAdZone.events; // events
          case 2:
            return LocalAdZone.community; // community
          case 3:
            return LocalAdZone.artists; // artists
          case 4:
            return LocalAdZone.featured; // featured
          default:
            return LocalAdZone.home;
        }
      }
    }

    return LocalAdZone.home; // Default fallback
  }

  /// Convert old AdStatus to new LocalAdStatus
  LocalAdStatus _convertToLocalAdStatus(Map<String, dynamic> oldData) {
    final statusValue = oldData['status'];

    if (statusValue is int) {
      switch (statusValue) {
        case 0:
          return LocalAdStatus.pendingReview; // pending -> pendingReview
        case 1:
          return LocalAdStatus.active; // approved -> active
        case 2:
          return LocalAdStatus.rejected; // rejected -> rejected
        case 3:
          return LocalAdStatus.expired; // expired -> expired
        case 4:
          return LocalAdStatus.deleted; // deleted -> deleted
        default:
          return LocalAdStatus.pendingReview;
      }
    }

    if (statusValue is String) {
      switch (statusValue.toLowerCase()) {
        case 'pending':
          return LocalAdStatus.pendingReview;
        case 'approved':
        case 'active':
          return LocalAdStatus.active;
        case 'rejected':
          return LocalAdStatus.rejected;
        case 'expired':
          return LocalAdStatus.expired;
        case 'deleted':
          return LocalAdStatus.deleted;
        default:
          return LocalAdStatus.pendingReview;
      }
    }

    return LocalAdStatus.pendingReview; // Default
  }

  /// Convert old AdSize to new LocalAdSize
  LocalAdSize _convertToLocalAdSize(Map<String, dynamic> oldData) {
    final sizeValue = oldData['size'];

    if (sizeValue is int) {
      switch (sizeValue) {
        case 0:
          return LocalAdSize.small; // small
        case 1:
          return LocalAdSize.big; // medium -> big
        case 2:
          return LocalAdSize.big; // large -> big
        default:
          return LocalAdSize.small;
      }
    }

    if (sizeValue is String) {
      switch (sizeValue.toLowerCase()) {
        case 'small':
          return LocalAdSize.small;
        case 'medium':
        case 'large':
        case 'big':
          return LocalAdSize.big;
        default:
          return LocalAdSize.small;
      }
    }

    return LocalAdSize.small; // Default fallback
  }

  /// Get migration statistics
  Future<MigrationStats> getMigrationStats() async {
    try {
      final oldAdsSnapshot = await _firestore
          .collection(_oldAdsCollection)
          .get();
      final newAdsSnapshot = await _firestore
          .collection(_newAdsCollection)
          .get();

      return MigrationStats(
        oldCollectionCount: oldAdsSnapshot.docs.length,
        newCollectionCount: newAdsSnapshot.docs.length,
        oldCollectionName: _oldAdsCollection,
        newCollectionName: _newAdsCollection,
      );
    } catch (e) {
      AppLogger.error('Error getting migration stats: $e');
      return MigrationStats(
        oldCollectionCount: 0,
        newCollectionCount: 0,
        oldCollectionName: _oldAdsCollection,
        newCollectionName: _newAdsCollection,
      );
    }
  }
}

/// Result of migration operation
class MigrationResult {
  int totalFound = 0;
  int migrated = 0;
  int skipped = 0;
  int failed = 0;
  List<String> errors = [];

  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() {
    return 'MigrationResult(total: $totalFound, migrated: $migrated, skipped: $skipped, failed: $failed, errors: ${errors.length})';
  }
}

/// Migration statistics for both collections
class MigrationStats {
  final int oldCollectionCount;
  final int newCollectionCount;
  final String oldCollectionName;
  final String newCollectionName;

  MigrationStats({
    required this.oldCollectionCount,
    required this.newCollectionCount,
    required this.oldCollectionName,
    required this.newCollectionName,
  });

  @override
  String toString() {
    return 'MigrationStats($oldCollectionName: $oldCollectionCount ads, $newCollectionName: $newCollectionCount ads)';
  }
}
