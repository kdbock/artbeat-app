import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ad_location.dart';
import '../models/ad_status.dart';
import 'ad_service.dart';

/// Debug service to help troubleshoot ad display issues
class AdDebugService {
  static final _firestore = FirebaseFirestore.instance;

  /// Debug ads in both collections
  static Future<void> debugAdCollections() async {
    if (!kDebugMode) return;

    debugPrint('🔍 === AD DEBUG SERVICE ===');

    // Check ads collection
    await _debugCollection('ads');

    // Check artist_approved_ads collection
    await _debugCollection('artist_approved_ads');

    debugPrint('🔍 === END AD DEBUG ===');
  }

  static Future<void> _debugCollection(String collectionName) async {
    try {
      debugPrint('📁 Checking collection: $collectionName');

      final snapshot = await _firestore.collection(collectionName).get();

      debugPrint('📊 Total documents: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        debugPrint('❌ No documents found in $collectionName');
        return;
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        debugPrint('📄 Document ID: ${doc.id}');
        debugPrint(
          '   - type: ${data['type']} (should be ${_getArtistApprovedTypeIndex()})',
        );
        debugPrint(
          '   - status: ${data['status']} (running = ${AdStatus.running.index})',
        );
        debugPrint(
          '   - location: ${data['location']} (${_getLocationName(data['location'])})',
        );
        debugPrint('   - startDate: ${data['startDate']}');
        debugPrint('   - endDate: ${data['endDate']}');
        debugPrint('   - title: ${data['title']}');

        // Check if dates are valid
        _checkDateValidity(data);

        debugPrint('   ---');
      }
    } catch (e) {
      debugPrint('❌ Error checking $collectionName: $e');
    }
  }

  static void _checkDateValidity(Map<String, dynamic> data) {
    try {
      final now = DateTime.now();

      if (data['startDate'] != null && data['endDate'] != null) {
        DateTime startDate;
        DateTime endDate;

        if (data['startDate'] is Timestamp) {
          startDate = (data['startDate'] as Timestamp).toDate();
        } else {
          startDate = DateTime.parse(data['startDate'].toString());
        }

        if (data['endDate'] is Timestamp) {
          endDate = (data['endDate'] as Timestamp).toDate();
        } else {
          endDate = DateTime.parse(data['endDate'].toString());
        }

        final isActive = now.isAfter(startDate) && now.isBefore(endDate);
        debugPrint('   - Date range valid: $isActive');
        debugPrint('   - Start: $startDate');
        debugPrint('   - End: $endDate');
        debugPrint('   - Now: $now');
      } else {
        debugPrint('   - Missing date fields');
      }
    } catch (e) {
      debugPrint('   - Date parsing error: $e');
    }
  }

  static String _getLocationName(dynamic locationIndex) {
    if (locationIndex == null) return 'null';
    try {
      final index = locationIndex as int;
      if (index >= 0 && index < AdLocation.values.length) {
        return AdLocation.values[index].name;
      }
      return 'invalid($index)';
    } catch (e) {
      return 'error';
    }
  }

  static int _getArtistApprovedTypeIndex() {
    // This should match the AdType.artistApproved index
    // AdType enum: square(0), rectangle(1), artistApproved(2)
    return 2; // artistApproved is index 2
  }

  /// Fix ads in the ads collection by moving them to artist_approved_ads
  static Future<void> migrateAdsToArtistApprovedCollection() async {
    if (!kDebugMode) return;

    try {
      debugPrint('🔄 Starting migration from ads to artist_approved_ads...');

      final adsSnapshot = await _firestore.collection('ads').get();
      final artistApprovedAdsRef = _firestore.collection('artist_approved_ads');

      for (final doc in adsSnapshot.docs) {
        final data = doc.data();

        // Only migrate if it looks like an artist approved ad
        if (data['type'] == _getArtistApprovedTypeIndex()) {
          debugPrint('📤 Migrating ad: ${doc.id}');

          // Add to artist_approved_ads collection
          await artistApprovedAdsRef.doc(doc.id).set(data);

          debugPrint('✅ Migrated ad: ${doc.id}');
        }
      }

      debugPrint('🎉 Migration completed!');
    } catch (e) {
      debugPrint('❌ Migration error: $e');
    }
  }

  /// Update ad status to running for testing
  static Future<void> setAdStatusToRunning(
    String adId, {
    String collection = 'artist_approved_ads',
  }) async {
    if (!kDebugMode) return;

    try {
      await _firestore.collection(collection).doc(adId).update({
        'status': AdStatus.running.index,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint(
        '✅ Updated ad $adId status to running (${AdStatus.running.index})',
      );
    } catch (e) {
      debugPrint('❌ Error updating ad status: $e');
    }
  }

  /// Test ad query for specific location
  static Future<void> testAdQuery(AdLocation location) async {
    if (!kDebugMode) return;

    try {
      debugPrint(
        '🔍 Testing ad query for location: ${location.name} (index: ${location.index})',
      );

      final now = DateTime.now();
      final query = await _firestore
          .collection('artist_approved_ads')
          .where('location', isEqualTo: location.index)
          .where('status', isEqualTo: AdStatus.running.index)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThanOrEqualTo: now)
          .get();

      debugPrint('📊 Query results: ${query.docs.length} ads found');

      for (final doc in query.docs) {
        final data = doc.data();
        debugPrint('   - Ad: ${data['title']} (${doc.id})');
      }
    } catch (e) {
      debugPrint('❌ Query error: $e');
    }
  }

  /// Fix invalid location values in ad collections
  static Future<void> fixAdLocations() async {
    if (!kDebugMode) return;

    try {
      debugPrint('🔧 Starting ad location fixes...');

      // Fix ads collection
      await _fixCollectionLocations('ads');

      // Fix artist_approved_ads collection
      await _fixCollectionLocations('artist_approved_ads');

      debugPrint('✅ Ad location fixes completed!');
    } catch (e) {
      debugPrint('❌ Error fixing ad locations: $e');
    }
  }

  static Future<void> _fixCollectionLocations(String collectionName) async {
    try {
      debugPrint('📁 Fixing locations in collection: $collectionName');

      final snapshot = await _firestore.collection(collectionName).get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final currentLocation = data['location'];

        // If location is null, invalid, or outside valid range (0-5)
        if (currentLocation == null ||
            currentLocation is! int ||
            currentLocation < 0 ||
            currentLocation > 5) {
          // Set to dashboard (0) as default
          await doc.reference.update({
            'location': 0, // AdLocation.dashboard.index
            'updatedAt': FieldValue.serverTimestamp(),
          });

          debugPrint(
            '✅ Fixed ad ${doc.id}: location $currentLocation -> 0 (dashboard)',
          );
        }
      }

      debugPrint('📊 Finished fixing $collectionName');
    } catch (e) {
      debugPrint('❌ Error fixing locations in $collectionName: $e');
    }
  }

  /// Migrate existing ads to populate artworkUrls for proper image rotation
  static Future<void> migrateAdsArtworkUrls() async {
    if (!kDebugMode) return;

    debugPrint('🔧 === ARTWORK URLS MIGRATION ===');

    final adService = AdService();
    await adService.migrateExistingAdsArtworkUrls();

    debugPrint('🔧 === MIGRATION COMPLETE ===');
  }

  /// Fix ads that have broken artworkUrls by replacing them with working ones
  static Future<void> fixBrokenArtworkUrls() async {
    if (kDebugMode) {
      debugPrint('🔧 === FIXING BROKEN ARTWORK URLS ===');
    }

    try {
      // Use placeholder images that always work
      final workingUrls = [
        'https://via.placeholder.com/300x200/FF6B6B/FFFFFF?text=Image+1',
        'https://via.placeholder.com/300x200/4ECDC4/FFFFFF?text=Image+2',
        'https://via.placeholder.com/300x200/45B7D1/FFFFFF?text=Image+3',
        'https://via.placeholder.com/300x200/96CEB4/FFFFFF?text=Image+4',
      ];

      int totalFixedCount = 0;

      // Fix ads in 'ads' collection
      totalFixedCount += await _fixCollectionUrls('ads', workingUrls);

      // Fix ads in 'artist_approved_ads' collection
      totalFixedCount += await _fixCollectionUrls(
        'artist_approved_ads',
        workingUrls,
      );

      if (kDebugMode) {
        debugPrint('🎉 Fixed $totalFixedCount ads total with working URLs!');
        debugPrint('🔧 === FIX COMPLETE ===');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fixing broken URLs: $e');
      }
    }
  }

  /// Fix broken URLs in a specific collection
  static Future<int> _fixCollectionUrls(
    String collectionName,
    List<String> workingUrls,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('🔧 Fixing collection: $collectionName');
      }

      final collectionRef = FirebaseFirestore.instance.collection(
        collectionName,
      );
      final query = await collectionRef.get();

      int fixedCount = 0;

      for (final doc in query.docs) {
        final data = doc.data();
        final artworkUrlsString = data['artworkUrls'] as String? ?? '';
        final imageUrl = data['imageUrl'] as String? ?? '';

        // Check if we need to fix this ad
        bool needsFix = false;

        // If artworkUrls contains broken Firebase URLs or is empty
        if (artworkUrlsString.contains('firebasestorage') ||
            artworkUrlsString.isEmpty) {
          needsFix = true;
        }

        // If imageUrl contains broken Firebase URLs
        if (imageUrl.contains('firebasestorage')) {
          needsFix = true;
        }

        if (needsFix) {
          await collectionRef.doc(doc.id).update({
            'artworkUrls': workingUrls.join(','),
            'imageUrl': workingUrls.first,
          });
          fixedCount++;

          if (kDebugMode) {
            debugPrint('✅ Fixed URLs for ad ${doc.id} in $collectionName');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('📊 Fixed $fixedCount ads in $collectionName');
      }

      return fixedCount;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fixing URLs in $collectionName: $e');
      }
      return 0;
    }
  }
}
