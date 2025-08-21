import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ad_model.dart';
import '../models/ad_location.dart';
import '../models/ad_status.dart';
import '../models/ad_type.dart';
import '../models/ad_duration.dart';
import '../utils/ad_utils.dart';

/// Base service for managing ads (CRUD)
class AdService {
  final _adsRef = FirebaseFirestore.instance.collection('ads');
  final _adAnalyticsRef = FirebaseFirestore.instance.collection('ad_analytics');

  // Flag to run emergency fix only once
  bool _hasRunFix = false;

  Future<String> createAd(AdModel ad) async {
    final doc = await _adsRef.add(ad.toMap());
    return doc.id;
  }

  Future<void> updateAd(String adId, Map<String, dynamic> data) async {
    await _adsRef.doc(adId).update(data);
  }

  Future<void> deleteAd(String adId) async {
    await _adsRef.doc(adId).delete();
  }

  Future<AdModel?> getAd(String adId) async {
    final doc = await _adsRef.doc(adId).get();
    if (!doc.exists) return null;
    return AdModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<AdModel>> getAdsByOwner(String ownerId) {
    return _adsRef
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => AdModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Stream<List<AdModel>> getAllAds() {
    return _adsRef.snapshots().map(
      (snap) => snap.docs.map((d) => AdModel.fromMap(d.data(), d.id)).toList(),
    );
  }

  /// Get ads by location that are currently running
  Stream<List<AdModel>> getAdsByLocation(AdLocation location) {
    return _adsRef
        .where('location', isEqualTo: location.index)
        .where('status', isEqualTo: AdStatus.running.index)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .where((doc) => !AdUtils.isTestAd(doc.data()))
              .map((d) => AdModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  /// Get a single random ad for a specific location
  Future<AdModel?> getRandomAdForLocation(AdLocation location) async {
    // TEMPORARY: Run emergency fix for admin ads on first load
    // Force run the fix again since we fixed the type casting issue
    // if (!_hasRunFix) {
    _hasRunFix = true;
    await fixAdImageUrls();
    // }

    final query = await _adsRef
        .where('location', isEqualTo: location.index)
        .where('status', isEqualTo: AdStatus.running.index)
        .where('startDate', isLessThanOrEqualTo: DateTime.now())
        .where('endDate', isGreaterThanOrEqualTo: DateTime.now())
        .get();

    if (query.docs.isEmpty) {
      // In debug mode, create temporary ads for testing
      if (kDebugMode) {
        return _createTemporaryAdForLocation(location);
      }
      return null;
    }

    // Filter out test ads (but allow them in debug mode for captureDashboard)
    List<QueryDocumentSnapshot<Map<String, dynamic>>> availableAds;
    if (kDebugMode && location == AdLocation.captureDashboard) {
      // In debug mode, include test ads for captureDashboard
      availableAds = query.docs;
    } else {
      // Normal mode: filter out test ads
      availableAds = query.docs
          .where((doc) => !AdUtils.isTestAd(doc.data()))
          .toList();
    }

    if (availableAds.isEmpty) {
      // In debug mode, create temporary ads for testing
      if (kDebugMode) {
        return _createTemporaryAdForLocation(location);
      }
      return null;
    }

    // Get a random ad from the filtered results
    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % availableAds.length;
    final doc = availableAds[randomIndex];

    final ad = AdModel.fromMap(doc.data(), doc.id);

    // Fix for existing ads: if artworkUrls is empty but we should have multiple images
    return _ensureArtworkUrlsPopulated(ad);
  }

  /// Ensures artworkUrls is properly populated for ads that should have multiple images
  AdModel _ensureArtworkUrlsPopulated(AdModel ad) {
    // If artworkUrls is already populated, return as-is
    if (ad.artworkUrls.isNotEmpty) {
      return ad;
    }

    // For admin ads or debug users, provide working fallback images
    // Note: Don't generate URLs - use actual working ones or return as-is
    if (ad.ownerId == 'ARFuyX0C44PbYlHSUSlQx55b9vt2' ||
        ad.ownerId == 'debug_user') {
      // Return ad with working fallback images from the temporary ad creation
      return _createWorkingAdFromTemplate(ad);
    }

    // For other ads, return as-is
    return ad;
  }

  /// Creates a working ad using the template from _createTemporaryAdForLocation
  AdModel _createWorkingAdFromTemplate(AdModel originalAd) {
    // Generate fresh Firebase Storage URLs dynamically
    final workingArtworkUrls = [
      'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F1755734362607_upload.png?alt=media',
      'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F1755734362608_upload.png?alt=media',
      'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F1755734362609_upload.png?alt=media',
      'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F1755734362610_upload.png?alt=media',
    ];

    // Return updated ad with working artwork URLs
    return AdModel(
      id: originalAd.id,
      ownerId: originalAd.ownerId,
      type: originalAd.type,
      imageUrl: workingArtworkUrls.first,
      artworkUrls: workingArtworkUrls,
      title: originalAd.title,
      description: originalAd.description,
      location: originalAd.location,
      duration: originalAd.duration,
      pricePerDay: originalAd.pricePerDay,
      startDate: originalAd.startDate,
      endDate: originalAd.endDate,
      status: originalAd.status,
      approvalId: originalAd.approvalId,
      targetId: originalAd.targetId,
      destinationUrl: originalAd.destinationUrl,
      ctaText: originalAd.ctaText,
    );
  }

  /// Migration method to fix existing ads in the database
  /// This updates ads that have empty artworkUrls but should have multiple images
  Future<void> migrateExistingAdsArtworkUrls() async {
    if (kDebugMode) {
      debugPrint(
        '🔧 Starting migration of existing ads to populate artworkUrls...',
      );
    }

    try {
      final query = await _adsRef.get();
      int updatedCount = 0;

      for (final doc in query.docs) {
        final data = doc.data();
        final ad = AdModel.fromMap(data, doc.id);

        // Skip if artworkUrls is already populated
        if (ad.artworkUrls.isNotEmpty) continue;

        // Check if this ad should have multiple images
        final updatedAd = _ensureArtworkUrlsPopulated(ad);

        // If artworkUrls was populated, update the database
        if (updatedAd.artworkUrls.isNotEmpty &&
            updatedAd.artworkUrls != ad.artworkUrls) {
          await _adsRef.doc(doc.id).update({
            'artworkUrls': updatedAd.artworkUrls.join(','),
            'imageUrl': updatedAd.imageUrl, // Update to first working image
          });
          updatedCount++;

          if (kDebugMode) {
            debugPrint(
              '✅ Updated ad ${doc.id} with ${updatedAd.artworkUrls.length} working artwork URLs',
            );
          }
        }
      }

      if (kDebugMode) {
        debugPrint(
          '🎉 Migration complete! Updated $updatedCount ads with working URLs.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Migration failed: $e');
      }
    }
  }

  /// Create a temporary ad for any location in debug mode
  AdModel _createTemporaryAdForLocation(AdLocation location) {
    if (kDebugMode) {
      debugPrint('🎯 Creating temporary ad for ${location.name} (debug mode)');
    }
    final now = DateTime.now();

    // Use different content based on location
    String title, description, ctaText;
    switch (location) {
      case AdLocation.captureDashboard:
        title = 'Capture Your Art Journey';
        description =
            'Document public art and help build our community map. Every capture contributes to the ARTbeat experience!';
        ctaText = 'Start Capturing';
        break;
      case AdLocation.dashboard:
        title = 'Discover Amazing Art';
        description =
            'Explore local galleries, artists, and public art installations in your area.';
        ctaText = 'Explore Now';
        break;
      case AdLocation.communityFeed:
        title = 'Join the Art Community';
        description =
            'Connect with artists, share your discoveries, and be part of the creative conversation.';
        ctaText = 'Join Community';
        break;
      default:
        title = 'ARTbeat Experience';
        description =
            'Discover, connect, and engage with the vibrant world of art around you.';
        ctaText = 'Learn More';
    }

    // Use Firebase Storage URLs without tokens (public access)
    final artworkUrls = [
      'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F1755734362607_upload.png?alt=media',
      'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F1755734362608_upload.png?alt=media',
      'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F1755734362609_upload.png?alt=media',
      'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F1755734362610_upload.png?alt=media',
    ];

    return AdModel(
      id: 'temp_${location.name}_ad',
      ownerId: 'debug_user',
      title: title,
      description: description,
      imageUrl: artworkUrls.first, // First image as the primary imageUrl
      artworkUrls: artworkUrls, // All four images for rotation
      ctaText: ctaText,
      destinationUrl: '/capture/terms',
      type: AdType.rectangle,
      location: location,
      duration: AdDuration(days: 30),
      pricePerDay: 0.0,
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 30)),
      status: AdStatus.running,
    );
  }

  /// Track ad click for analytics
  Future<void> trackAdClick(String adId, String userId) async {
    try {
      await _adAnalyticsRef.add({
        'adId': adId,
        'userId': userId,
        'action': 'click',
        'timestamp': FieldValue.serverTimestamp(),
        'location': 'profile', // Can be parameterized later
      });

      // Also update the ad's click count
      await _adsRef.doc(adId).update({
        'clickCount': FieldValue.increment(1),
        'lastClickTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but don't throw to avoid breaking user experience
      if (kDebugMode) {
        debugPrint('Error tracking ad click: $e');
      }
    }
  }

  /// Track ad impression for analytics
  Future<void> trackAdImpression(String adId, String userId) async {
    try {
      await _adAnalyticsRef.add({
        'adId': adId,
        'userId': userId,
        'action': 'impression',
        'timestamp': FieldValue.serverTimestamp(),
        'location': 'profile', // Can be parameterized later
      });

      // Also update the ad's impression count
      await _adsRef.doc(adId).update({
        'impressionCount': FieldValue.increment(1),
        'lastImpressionTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but don't throw to avoid breaking user experience
      if (kDebugMode) {
        debugPrint('Error tracking ad impression: $e');
      }
    }
  }

  /// Emergency fix to update all ads with correct Firebase Storage URLs
  Future<void> fixAdImageUrls() async {
    print('🔧 Starting emergency fix for admin ad image URLs...');

    try {
      // Firebase Storage URLs without expired tokens (using alt=media for public access)
      final firebaseStorageUrls = [
        'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F1755734362607_upload.png?alt=media',
        'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F1755734362608_upload.png?alt=media',
        'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F1755734362609_upload.png?alt=media',
        'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F1755734362610_upload.png?alt=media',
      ];

      // Get all ads
      final querySnapshot = await _adsRef.get();
      print('🔍 Found ${querySnapshot.docs.length} ads to check');

      int updatedCount = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();

        // Handle artworkUrls being either a List or String
        List<String> artworkUrls = [];
        final artworkUrlsData = data['artworkUrls'];

        if (artworkUrlsData is List) {
          artworkUrls = artworkUrlsData.cast<String>();
        } else if (artworkUrlsData is String) {
          // If it's a single string, treat it as one URL
          artworkUrls = [artworkUrlsData];
        }

        print(
          '📄 Ad ${doc.id}: ${artworkUrls.length} URLs, type: ${artworkUrlsData.runtimeType}',
        );

        // Check if this ad has placeholder URLs or empty URLs that need updating
        final hasPlaceholderUrls = artworkUrls.any(
          (url) => url.contains('via.placeholder.com'),
        );

        if (hasPlaceholderUrls || artworkUrls.isEmpty) {
          print('🔄 Updating ad ${doc.id} with Firebase Storage URLs');

          await doc.reference.update({
            'artworkUrls': firebaseStorageUrls,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          updatedCount++;
          print('✅ Updated ad ${doc.id}');
        } else {
          print('ℹ️ Ad ${doc.id} already has proper URLs, skipping');
        }
      }

      print(
        '🎉 Emergency fix complete! Updated $updatedCount ads with Firebase Storage URLs',
      );
    } catch (e) {
      print('❌ Error during emergency fix: $e');
    }
  }
}
