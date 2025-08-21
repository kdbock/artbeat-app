import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ad_location.dart';
import '../models/ad_status.dart';
import '../services/ad_service.dart';

/// Comprehensive diagnostic service for ad issues
class AdDiagnosticService {
  static final _firestore = FirebaseFirestore.instance;
  static final _adService = AdService();

  /// Run complete diagnostic check
  static Future<void> runFullDiagnostic() async {
    if (!kDebugMode) return;

    debugPrint('🔍 === STARTING FULL AD DIAGNOSTIC ===');

    // Step 1: Check collections exist and have data
    await _checkCollections();

    // Step 2: Check ad queries for each location
    await _checkAdQueries();

    // Step 3: Test ad retrieval methods
    await _testAdRetrieval();

    // Step 4: Check for common issues
    await _checkCommonIssues();

    debugPrint('🔍 === DIAGNOSTIC COMPLETE ===');
  }

  static Future<void> _checkCollections() async {
    debugPrint('📁 Checking ad collections...');

    // Check ads collection
    final adsSnapshot = await _firestore.collection('ads').get();
    debugPrint(
      '📊 Regular ads collection: ${adsSnapshot.docs.length} documents',
    );

    // Check artist_approved_ads collection
    final artistAdsSnapshot = await _firestore
        .collection('artist_approved_ads')
        .get();
    debugPrint(
      '📊 Artist approved ads collection: ${artistAdsSnapshot.docs.length} documents',
    );

    if (adsSnapshot.docs.isEmpty && artistAdsSnapshot.docs.isEmpty) {
      debugPrint('❌ No ads found in either collection!');
    }
  }

  static Future<void> _checkAdQueries() async {
    debugPrint('🔍 Testing ad queries for each location...');

    for (final location in AdLocation.values) {
      debugPrint(
        '📍 Testing location: ${location.name} (index: ${location.index})',
      );

      try {
        // Test regular ads query
        final regularAdsQuery = await _firestore
            .collection('ads')
            .where('location', isEqualTo: location.index)
            .where('status', isEqualTo: AdStatus.running.index)
            .get();

        debugPrint('   Regular ads: ${regularAdsQuery.docs.length} found');

        // Test artist approved ads query
        final artistAdsQuery = await _firestore
            .collection('artist_approved_ads')
            .where('location', isEqualTo: location.index)
            .where('status', isEqualTo: AdStatus.running.index)
            .get();

        debugPrint('   Artist ads: ${artistAdsQuery.docs.length} found');

        // Test date-filtered query (this might fail due to missing indexes)
        try {
          final now = DateTime.now();
          final dateFilteredQuery = await _firestore
              .collection('ads')
              .where('location', isEqualTo: location.index)
              .where('status', isEqualTo: AdStatus.running.index)
              .where('startDate', isLessThanOrEqualTo: now)
              .where('endDate', isGreaterThanOrEqualTo: now)
              .get();

          debugPrint(
            '   Date-filtered ads: ${dateFilteredQuery.docs.length} found',
          );
        } catch (e) {
          debugPrint('   ❌ Date-filtered query failed: $e');
          debugPrint(
            '   💡 This might be due to missing Firestore composite indexes',
          );
        }
      } catch (e) {
        debugPrint('   ❌ Query failed for ${location.name}: $e');
      }
    }
  }

  static Future<void> _testAdRetrieval() async {
    debugPrint('🎯 Testing ad retrieval methods...');

    for (final location in [
      AdLocation.dashboard,
      AdLocation.artWalkDashboard,
      AdLocation.eventsDashboard,
    ]) {
      debugPrint('📍 Testing retrieval for ${location.name}...');

      try {
        // Test regular ad retrieval
        final regularAd = await _adService.getRandomAdForLocation(location);
        debugPrint(
          '   Regular ad retrieved: ${regularAd != null ? regularAd.title : 'null'}',
        );

        // Artist approved ads have been removed from the system
      } catch (e) {
        debugPrint('   ❌ Retrieval failed for ${location.name}: $e');
      }
    }
  }

  static Future<void> _checkCommonIssues() async {
    debugPrint('🔧 Checking for common issues...');

    // Check for ads with invalid dates
    await _checkInvalidDates();

    // Check for ads with invalid image URLs
    await _checkInvalidImages();

    // Check for ads with wrong status
    await _checkAdStatuses();
  }

  static Future<void> _checkInvalidDates() async {
    debugPrint('📅 Checking for ads with invalid dates...');

    final now = DateTime.now();

    // Check regular ads
    final adsSnapshot = await _firestore.collection('ads').get();
    int invalidDateCount = 0;

    for (final doc in adsSnapshot.docs) {
      final data = doc.data();
      try {
        final endDate = (data['endDate'] as Timestamp).toDate();

        if (endDate.isBefore(now)) {
          invalidDateCount++;
          debugPrint('   ⚠️ Expired ad: ${data['title']} (ended: $endDate)');
        }
      } catch (e) {
        debugPrint('   ❌ Date parsing error for ad ${doc.id}: $e');
      }
    }

    debugPrint('📊 Found $invalidDateCount expired ads in regular collection');

    // Check artist approved ads
    final artistAdsSnapshot = await _firestore
        .collection('artist_approved_ads')
        .get();
    int artistInvalidDateCount = 0;

    for (final doc in artistAdsSnapshot.docs) {
      final data = doc.data();
      try {
        final endDate = (data['endDate'] as Timestamp).toDate();

        if (endDate.isBefore(now)) {
          artistInvalidDateCount++;
          debugPrint(
            '   ⚠️ Expired artist ad: ${data['title']} (ended: $endDate)',
          );
        }
      } catch (e) {
        debugPrint('   ❌ Date parsing error for artist ad ${doc.id}: $e');
      }
    }

    debugPrint(
      '📊 Found $artistInvalidDateCount expired ads in artist collection',
    );
  }

  static Future<void> _checkInvalidImages() async {
    debugPrint('🖼️ Checking for ads with invalid image URLs...');

    // Check regular ads
    final adsSnapshot = await _firestore.collection('ads').get();
    int invalidImageCount = 0;

    for (final doc in adsSnapshot.docs) {
      final data = doc.data();
      final imageUrl = data['imageUrl']?.toString() ?? '';

      if (imageUrl.isEmpty ||
          (!imageUrl.startsWith('http') && !imageUrl.startsWith('https'))) {
        invalidImageCount++;
        debugPrint(
          '   ❌ Invalid image URL in ad: ${data['title']} - $imageUrl',
        );
      }
    }

    debugPrint(
      '📊 Found $invalidImageCount ads with invalid images in regular collection',
    );

    // Check artist approved ads
    final artistAdsSnapshot = await _firestore
        .collection('artist_approved_ads')
        .get();
    int artistInvalidImageCount = 0;

    for (final doc in artistAdsSnapshot.docs) {
      final data = doc.data();
      final avatarUrl = data['avatarImageUrl']?.toString() ?? '';
      final artworkUrls = data['artworkImageUrls'] as List? ?? [];

      if (avatarUrl.isEmpty ||
          (!avatarUrl.startsWith('http') && !avatarUrl.startsWith('https'))) {
        artistInvalidImageCount++;
        debugPrint(
          '   ❌ Invalid avatar URL in artist ad: ${data['title']} - $avatarUrl',
        );
      }

      for (final url in artworkUrls) {
        if (url.toString().isEmpty ||
            (!url.toString().startsWith('http') &&
                !url.toString().startsWith('https'))) {
          artistInvalidImageCount++;
          debugPrint(
            '   ❌ Invalid artwork URL in artist ad: ${data['title']} - $url',
          );
          break;
        }
      }
    }

    debugPrint(
      '📊 Found $artistInvalidImageCount artist ads with invalid images',
    );
  }

  static Future<void> _checkAdStatuses() async {
    debugPrint('📊 Checking ad statuses...');

    // Check regular ads
    final adsSnapshot = await _firestore.collection('ads').get();
    final statusCounts = <int, int>{};

    for (final doc in adsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] as int? ?? 0;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    debugPrint('📊 Regular ads by status:');
    for (final entry in statusCounts.entries) {
      final statusName = entry.key < AdStatus.values.length
          ? AdStatus.values[entry.key].name
          : 'unknown(${entry.key})';
      debugPrint('   $statusName: ${entry.value}');
    }

    // Check artist approved ads
    final artistAdsSnapshot = await _firestore
        .collection('artist_approved_ads')
        .get();
    final artistStatusCounts = <int, int>{};

    for (final doc in artistAdsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] as int? ?? 0;
      artistStatusCounts[status] = (artistStatusCounts[status] ?? 0) + 1;
    }

    debugPrint('📊 Artist approved ads by status:');
    for (final entry in artistStatusCounts.entries) {
      final statusName = entry.key < AdStatus.values.length
          ? AdStatus.values[entry.key].name
          : 'unknown(${entry.key})';
      debugPrint('   $statusName: ${entry.value}');
    }
  }

  /// Quick fix for common issues
  static Future<void> quickFix() async {
    if (!kDebugMode) return;

    debugPrint('🔧 Running quick fixes...');

    // Fix approved ads that should be running
    await _fixApprovedAdsToRunning();

    // Fix expired ads by extending their end dates
    await _fixExpiredAds();

    // Fix ads with invalid statuses
    await _fixAdStatuses();

    debugPrint('✅ Quick fixes completed!');
  }

  /// Fix approved ads that should be running
  static Future<void> _fixApprovedAdsToRunning() async {
    debugPrint('🔄 Converting approved ads to running status...');

    final now = DateTime.now();
    int fixedCount = 0;

    // Fix regular ads collection
    final adsSnapshot = await _firestore.collection('ads').get();
    final batch = _firestore.batch();

    for (final doc in adsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] as int? ?? 0;

      // If ad is approved and within its date range, make it running
      if (status == AdStatus.approved.index) {
        try {
          final startDate = (data['startDate'] as Timestamp).toDate();
          final endDate = (data['endDate'] as Timestamp).toDate();

          if (now.isAfter(startDate) && now.isBefore(endDate)) {
            batch.update(doc.reference, {
              'status': AdStatus.running.index,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            fixedCount++;
            debugPrint(
              '   ✅ Converting approved ad to running: ${data['title']}',
            );
          }
        } catch (e) {
          debugPrint('   ❌ Error processing ad ${doc.id}: $e');
        }
      }
    }

    if (fixedCount > 0) {
      await batch.commit();
    }

    // Fix artist approved ads collection
    final artistAdsSnapshot = await _firestore
        .collection('artist_approved_ads')
        .get();
    final artistBatch = _firestore.batch();
    int artistFixedCount = 0;

    for (final doc in artistAdsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] as int? ?? 0;

      // If ad is approved and within its date range, make it running
      if (status == AdStatus.approved.index) {
        try {
          final startDate = (data['startDate'] as Timestamp).toDate();
          final endDate = (data['endDate'] as Timestamp).toDate();

          if (now.isAfter(startDate) && now.isBefore(endDate)) {
            artistBatch.update(doc.reference, {
              'status': AdStatus.running.index,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            artistFixedCount++;
            debugPrint(
              '   ✅ Converting approved artist ad to running: ${data['title']}',
            );
          }
        } catch (e) {
          debugPrint('   ❌ Error processing artist ad ${doc.id}: $e');
        }
      }
    }

    if (artistFixedCount > 0) {
      await artistBatch.commit();
    }

    debugPrint(
      '📊 Converted $fixedCount regular ads and $artistFixedCount artist ads from approved to running',
    );
  }

  static Future<void> _fixExpiredAds() async {
    debugPrint('📅 Fixing expired ads...');

    final now = DateTime.now();
    final newEndDate = now.add(const Duration(days: 30));

    // Fix regular ads
    final adsSnapshot = await _firestore.collection('ads').get();
    final batch = _firestore.batch();
    int fixedCount = 0;

    for (final doc in adsSnapshot.docs) {
      final data = doc.data();
      try {
        final endDate = (data['endDate'] as Timestamp).toDate();

        if (endDate.isBefore(now)) {
          batch.update(doc.reference, {
            'endDate': Timestamp.fromDate(newEndDate),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          fixedCount++;
        }
      } catch (e) {
        debugPrint('   ❌ Error fixing ad ${doc.id}: $e');
      }
    }

    if (fixedCount > 0) {
      await batch.commit();
      debugPrint('✅ Fixed $fixedCount expired regular ads');
    }

    // Fix artist approved ads
    final artistAdsSnapshot = await _firestore
        .collection('artist_approved_ads')
        .get();
    final artistBatch = _firestore.batch();
    int artistFixedCount = 0;

    for (final doc in artistAdsSnapshot.docs) {
      final data = doc.data();
      try {
        final endDate = (data['endDate'] as Timestamp).toDate();

        if (endDate.isBefore(now)) {
          artistBatch.update(doc.reference, {
            'endDate': Timestamp.fromDate(newEndDate),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          artistFixedCount++;
        }
      } catch (e) {
        debugPrint('   ❌ Error fixing artist ad ${doc.id}: $e');
      }
    }

    if (artistFixedCount > 0) {
      await artistBatch.commit();
      debugPrint('✅ Fixed $artistFixedCount expired artist ads');
    }
  }

  static Future<void> _fixAdStatuses() async {
    debugPrint('📊 Fixing ad statuses...');

    // Fix regular ads with pending status
    final adsSnapshot = await _firestore
        .collection('ads')
        .where('status', isEqualTo: AdStatus.pending.index)
        .get();

    if (adsSnapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in adsSnapshot.docs) {
        batch.update(doc.reference, {
          'status': AdStatus.running.index,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      debugPrint('✅ Fixed ${adsSnapshot.docs.length} pending regular ads');
    }

    // Fix artist approved ads with pending status
    final artistAdsSnapshot = await _firestore
        .collection('artist_approved_ads')
        .where('status', isEqualTo: AdStatus.pending.index)
        .get();

    if (artistAdsSnapshot.docs.isNotEmpty) {
      final artistBatch = _firestore.batch();
      for (final doc in artistAdsSnapshot.docs) {
        artistBatch.update(doc.reference, {
          'status': AdStatus.running.index,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await artistBatch.commit();
      debugPrint('✅ Fixed ${artistAdsSnapshot.docs.length} pending artist ads');
    }
  }
}
