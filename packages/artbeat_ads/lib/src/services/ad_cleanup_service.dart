import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ad_status.dart';
import '../models/ad_location.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Service to clean up and reset ad collections for testing
class AdCleanupService {
  static final _firestore = FirebaseFirestore.instance;

  /// Clean up all test ads and create fresh ones
  static Future<void> resetAdsForTesting() async {
    if (!kDebugMode) return;

    try {
      AppLogger.info('🧹 Starting ad cleanup and reset...');

      // Step 1: Clean up existing test ads
      await _cleanupTestAds();

      // Step 2: Create fresh test ads
      await _createFreshTestAds();

      AppLogger.info('✅ Ad cleanup and reset completed!');
    } catch (e) {
      AppLogger.error('❌ Error during ad cleanup and reset: $e');
    }
  }

  /// Clean up all test ads from both collections
  static Future<void> _cleanupTestAds() async {
    AppLogger.info('🗑️ Cleaning up existing test ads...');

    // Clean up ads collection
    await _cleanupCollection('ads');

    // Clean up artist_approved_ads collection
    await _cleanupCollection('artist_approved_ads');
  }

  static Future<void> _cleanupCollection(String collectionName) async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();

      if (snapshot.docs.isEmpty) {
        AppLogger.info('📭 No documents found in $collectionName');
        return;
      }

      final batch = _firestore.batch();
      int deleteCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final title = data['title']?.toString() ?? '';
        final ownerId = data['ownerId']?.toString() ?? '';

        // Delete test ads (those with test titles or test owner IDs)
        if (title.contains('Test') ||
            ownerId == 'test_owner' ||
            ownerId == 'test_artist' ||
            title.startsWith('Test Ad')) {
          batch.delete(doc.reference);
          deleteCount++;
        }
      }

      if (deleteCount > 0) {
        await batch.commit();
        AppLogger.info(
          '🗑️ Deleted $deleteCount test ads from $collectionName',
        );
      } else {
        AppLogger.info('📭 No test ads found to delete in $collectionName');
      }
    } catch (e) {
      AppLogger.error('❌ Error cleaning up $collectionName: $e');
    }
  }

  /// Create fresh test ads for all dashboard locations
  static Future<void> _createFreshTestAds() async {
    AppLogger.info('🎯 Creating fresh test ads...');

    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 30));

    // Create test ads for different locations
    final testAds = [
      {
        'location': AdLocation.fluidDashboard,
        'title': 'Fluid Dashboard Test Ad',
        'description': 'Test ad for fluid dashboard',
      },
      {
        'location': AdLocation.artWalkDashboard,
        'title': 'Art Walk Test Ad',
        'description': 'Test ad for art walk dashboard',
      },
      {
        'location': AdLocation.eventDashboard,
        'title': 'Event Dashboard Test Ad',
        'description': 'Test ad for event dashboard',
      },
      {
        'location': AdLocation.unifiedCommunityHub,
        'title': 'Community Hub Test Ad',
        'description': 'Test ad for unified community hub',
      },
    ];

    for (final adConfig in testAds) {
      try {
        // Create regular ad
        await _createRegularTestAd(
          location: adConfig['location'] as AdLocation,
          title: adConfig['title'] as String,
          description: adConfig['description'] as String,
          now: now,
          endDate: endDate,
        );

        // Create artist approved ad
        await _createArtistApprovedTestAd(
          location: adConfig['location'] as AdLocation,
          title: 'Artist ${adConfig['title']}',
          description: 'Artist ${adConfig['description']}',
          now: now,
          endDate: endDate,
        );

        debugPrint(
          '✅ Created test ads for ${(adConfig['location'] as AdLocation).name}',
        );
      } catch (e) {
        debugPrint(
          '❌ Failed to create test ads for ${(adConfig['location'] as AdLocation).name}: $e',
        );
      }
    }
  }

  static Future<void> _createRegularTestAd({
    required AdLocation location,
    required String title,
    required String description,
    required DateTime now,
    required DateTime endDate,
  }) async {
    final adData = {
      'ownerId': 'test_owner',
      'type': 0, // AdType.square
      'title': title,
      'description': description,
      'imageUrl': 'https://picsum.photos/300/300?random=1',
      'location': location.index,
      'status': AdStatus.running.index,
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(endDate),
      'duration': {'days': 30},
      'pricePerDay': 5.0,
      'ctaText': 'Learn More',
      'destinationUrl': 'https://artbeat.app',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('ads').add(adData);
  }

  static Future<void> _createArtistApprovedTestAd({
    required AdLocation location,
    required String title,
    required String description,
    required DateTime now,
    required DateTime endDate,
  }) async {
    final adData = {
      'ownerId': 'test_artist',
      'artistId': 'test_artist',
      'type': 2, // AdType.artistApproved
      'title': title,
      'description': description,
      'tagline': 'Discover Amazing Art',
      'avatarImageUrl': 'https://picsum.photos/100/100?random=10',
      'artworkImageUrls': [
        'https://picsum.photos/300/300?random=11',
        'https://picsum.photos/300/300?random=12',
        'https://picsum.photos/300/300?random=13',
        'https://picsum.photos/300/300?random=14',
      ],
      'location': location.index,
      'status': AdStatus.running.index,
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(endDate),
      'duration': {'days': 30},
      'pricePerDay': 10.0,
      'animationSpeed': 1500,
      'autoPlay': true,
      'ctaText': 'View Art',
      'destinationUrl': 'https://artbeat.app/artist/test',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('artist_approved_ads').add(adData);
  }

  /// Quick method to just create test ads without cleanup
  static Future<void> createTestAdsOnly() async {
    if (!kDebugMode) return;

    try {
      AppLogger.info('🎯 Creating test ads only...');
      await _createFreshTestAds();
      AppLogger.info('✅ Test ads created!');
    } catch (e) {
      AppLogger.error('❌ Error creating test ads: $e');
    }
  }
}
