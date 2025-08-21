import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ad_status.dart';
import '../models/ad_location.dart';

/// Service to fix common ad issues
class AdFixService {
  static final _firestore = FirebaseFirestore.instance;

  /// Fix ads in the ads collection for testing
  static Future<void> fixAdsForTesting() async {
    if (!kDebugMode) return;

    try {
      debugPrint('🔧 Starting ad fixes...');

      final adsSnapshot = await _firestore.collection('ads').get();

      for (final doc in adsSnapshot.docs) {
        final data = doc.data();
        final updates = <String, dynamic>{};

        // Fix status to running if it's 0 (pending)
        if (data['status'] == 0) {
          updates['status'] = AdStatus.running.index;
          debugPrint('📝 Setting status to running for ad: ${doc.id}');
        }

        // Fix dates if they're in the past
        final now = DateTime.now();
        if (data['startDate'] != null) {
          DateTime startDate;
          if (data['startDate'] is Timestamp) {
            startDate = (data['startDate'] as Timestamp).toDate();
          } else {
            startDate = DateTime.parse(data['startDate'].toString());
          }

          // If start date is in the past, set it to now
          if (startDate.isBefore(now)) {
            updates['startDate'] = Timestamp.fromDate(now);
            debugPrint('📅 Updated start date for ad: ${doc.id}');
          }
        }

        if (data['endDate'] != null) {
          DateTime endDate;
          if (data['endDate'] is Timestamp) {
            endDate = (data['endDate'] as Timestamp).toDate();
          } else {
            endDate = DateTime.parse(data['endDate'].toString());
          }

          // If end date is in the past, extend it by 30 days
          if (endDate.isBefore(now)) {
            updates['endDate'] = Timestamp.fromDate(
              now.add(const Duration(days: 30)),
            );
            debugPrint('📅 Extended end date for ad: ${doc.id}');
          }
        }

        // Set location to dashboard if not set or invalid
        final location = data['location'];
        if (location == null ||
            location is! int ||
            location < 0 ||
            location > 5) {
          updates['location'] = AdLocation.dashboard.index;
          debugPrint(
            '📍 Set location for ad: ${doc.id} from $location to ${AdLocation.dashboard.index}',
          );
        }

        // Apply updates if any
        if (updates.isNotEmpty) {
          updates['updatedAt'] = FieldValue.serverTimestamp();
          await _firestore.collection('ads').doc(doc.id).update(updates);
          debugPrint('✅ Updated ad: ${doc.id}');
        }
      }

      debugPrint('🎉 Ad fixes completed!');
    } catch (e) {
      debugPrint('❌ Error fixing ads: $e');
    }
  }

  /// Copy ads from ads collection to artist_approved_ads collection
  static Future<void> copyAdsToArtistApprovedCollection() async {
    if (!kDebugMode) return;

    try {
      debugPrint('📋 Copying ads to artist_approved_ads collection...');

      final adsSnapshot = await _firestore.collection('ads').get();
      final artistApprovedRef = _firestore.collection('artist_approved_ads');

      for (final doc in adsSnapshot.docs) {
        final data = doc.data();

        // Add required fields for artist approved ads
        final artistApprovedData = Map<String, dynamic>.from(data);

        // Ensure required fields exist
        artistApprovedData['artistId'] = data['ownerId'] ?? '';
        artistApprovedData['avatarImageUrl'] = data['imageUrl'] ?? '';
        artistApprovedData['artworkImageUrls'] = [
          data['imageUrl'] ?? '',
          data['imageUrl'] ?? '',
          data['imageUrl'] ?? '',
          data['imageUrl'] ?? '',
        ];
        artistApprovedData['tagline'] = data['description'] ?? '';
        artistApprovedData['animationSpeed'] = 1500;
        artistApprovedData['autoPlay'] = true;

        // Copy to artist_approved_ads collection
        await artistApprovedRef.doc(doc.id).set(artistApprovedData);
        debugPrint('📤 Copied ad: ${doc.id}');
      }

      debugPrint('🎉 Copy completed!');
    } catch (e) {
      debugPrint('❌ Error copying ads: $e');
    }
  }

  /// Create a test ad for debugging
  static Future<void> createTestAd() async {
    if (!kDebugMode) return;

    try {
      final now = DateTime.now();
      final testAd = {
        'ownerId': 'test_owner',
        'artistId': 'test_artist',
        'type': 2, // artistApproved is index 2
        'title': 'Test Artist Ad',
        'description': 'This is a test ad for debugging',
        'tagline': 'Test Artist Tagline',
        'avatarImageUrl': '',
        'artworkImageUrls': ['', '', '', ''],
        'location': AdLocation.dashboard.index,
        'status': AdStatus.running.index,
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(now.add(const Duration(days: 30))),
        'duration': {'days': 30},
        'pricePerDay': 10.0,
        'animationSpeed': 1500,
        'autoPlay': true,
        'destinationUrl': 'https://example.com',
        'ctaText': 'Learn More',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final doc = await _firestore
          .collection('artist_approved_ads')
          .add(testAd);
      debugPrint('🎯 Created test ad: ${doc.id}');
    } catch (e) {
      debugPrint('❌ Error creating test ad: $e');
    }
  }

  /// Create test ads for all dashboard locations
  static Future<void> createTestAdsForAllLocations() async {
    if (!kDebugMode) return;

    try {
      debugPrint('🎯 Creating test ads for all dashboard locations...');
      final now = DateTime.now();

      // Locations used in FluidDashboardScreen
      final locationsToCreate = [
        {'location': AdLocation.artWalkDashboard, 'title': 'Art Walk Promo'},
        {'location': AdLocation.eventsDashboard, 'title': 'Events Showcase'},
        {'location': AdLocation.communityDashboard, 'title': 'Community Hub'},
        {'location': AdLocation.communityFeed, 'title': 'Feed Promotion'},
      ];

      for (final locationData in locationsToCreate) {
        final location = locationData['location'] as AdLocation;
        final title = locationData['title'] as String;

        final testAd = {
          'ownerId': 'test_owner',
          'artistId': 'test_artist',
          'type': 1, // artistApproved type
          'title': title,
          'description': 'Test ad for ${location.name} location',
          'tagline': 'Discover amazing art',
          'avatarImageUrl': '',
          'artworkImageUrls': ['', '', '', ''],
          'location': location.index,
          'status': AdStatus.running.index,
          'startDate': Timestamp.fromDate(now),
          'endDate': Timestamp.fromDate(now.add(const Duration(days: 30))),
          'duration': {'days': 30},
          'pricePerDay': 10.0,
          'animationSpeed': 1500,
          'autoPlay': true,
          'destinationUrl': 'https://example.com',
          'ctaText': 'Learn More',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final doc = await _firestore
            .collection('artist_approved_ads')
            .add(testAd);
        debugPrint('🎯 Created ${location.name} ad: ${doc.id}');
      }

      debugPrint('🎉 Created test ads for all dashboard locations!');
    } catch (e) {
      debugPrint('❌ Error creating test ads for all locations: $e');
    }
  }

  /// Clean up ads with problematic placeholder URLs
  static Future<void> cleanupPlaceholderUrls() async {
    if (!kDebugMode) return;

    try {
      debugPrint('🧹 Cleaning up placeholder URLs in ads...');

      // Clean up artist_approved_ads collection
      final artistAdsSnapshot = await _firestore
          .collection('artist_approved_ads')
          .get();

      for (final doc in artistAdsSnapshot.docs) {
        final data = doc.data();
        final updates = <String, dynamic>{};
        bool needsUpdate = false;

        // Check avatarImageUrl
        if (data['avatarImageUrl'] != null &&
            (data['avatarImageUrl'] as String).contains(
              'via.placeholder.com',
            )) {
          updates['avatarImageUrl'] = '';
          needsUpdate = true;
          debugPrint('🔧 Cleaning avatar URL for ad: ${doc.id}');
        }

        // Check artworkImageUrls
        if (data['artworkImageUrls'] is List) {
          final artworkUrls = List<String>.from(
            data['artworkImageUrls'] as List,
          );
          bool urlsChanged = false;

          for (int i = 0; i < artworkUrls.length; i++) {
            if (artworkUrls[i].contains('via.placeholder.com')) {
              artworkUrls[i] = '';
              urlsChanged = true;
            }
          }

          if (urlsChanged) {
            updates['artworkImageUrls'] = artworkUrls;
            needsUpdate = true;
            debugPrint('🔧 Cleaning artwork URLs for ad: ${doc.id}');
          }
        }

        // Apply updates if needed
        if (needsUpdate) {
          updates['updatedAt'] = FieldValue.serverTimestamp();
          await _firestore
              .collection('artist_approved_ads')
              .doc(doc.id)
              .update(updates);
          debugPrint('✅ Cleaned up ad: ${doc.id}');
        }
      }

      // Clean up regular ads collection
      final adsSnapshot = await _firestore.collection('ads').get();

      for (final doc in adsSnapshot.docs) {
        final data = doc.data();
        final updates = <String, dynamic>{};
        bool needsUpdate = false;

        // Check imageUrl
        if (data['imageUrl'] != null &&
            (data['imageUrl'] as String).contains('via.placeholder.com')) {
          updates['imageUrl'] = '';
          needsUpdate = true;
          debugPrint('🔧 Cleaning image URL for ad: ${doc.id}');
        }

        // Apply updates if needed
        if (needsUpdate) {
          updates['updatedAt'] = FieldValue.serverTimestamp();
          await _firestore.collection('ads').doc(doc.id).update(updates);
          debugPrint('✅ Cleaned up ad: ${doc.id}');
        }
      }

      debugPrint('🎉 Placeholder URL cleanup completed!');
    } catch (e) {
      debugPrint('❌ Error cleaning up placeholder URLs: $e');
    }
  }
}
