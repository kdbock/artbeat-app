// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ad_model.dart';
import '../models/ad_location.dart';
import '../models/ad_status.dart';
import '../models/ad_type.dart';
import '../models/ad_size.dart';
import '../models/ad_duration.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Utility to create test ads for dashboard locations
class TestAdCreator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createTestAds() async {
    try {
      // Get current user or use a test user ID
      final user = FirebaseAuth.instance.currentUser;
      final ownerId = user?.uid ?? 'test_user_id';

      final testAds = [
        AdModel(
          id: 'test_fluid_dashboard_ad',
          ownerId: ownerId,
          type: AdType.banner_ad,
          size: AdSize.medium,
          imageUrl:
              'https://via.placeholder.com/400x200/4FB3BE/FFFFFF?text=Fluid+Dashboard+Ad',
          title: 'Discover ARTbeat',
          description: 'Your gateway to the local art community',
          location: AdLocation.fluidDashboard,
          duration: AdDuration.oneWeek,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
          status: AdStatus.approved,
          destinationUrl: 'https://artbeat.com',
          ctaText: 'Explore Now',
        ),
        AdModel(
          id: 'test_art_walk_dashboard_ad',
          ownerId: ownerId,
          type: AdType.banner_ad,
          size: AdSize.small,
          imageUrl:
              'https://via.placeholder.com/400x200/FF9E80/FFFFFF?text=Art+Walk+Ad',
          title: 'Explore Art Walks',
          description: 'Discover curated art experiences in your area',
          location: AdLocation.artWalkDashboard,
          duration: AdDuration.oneWeek,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
          status: AdStatus.approved,
          destinationUrl: 'https://artbeat.com/art-walks',
          ctaText: 'Start Walking',
        ),
        AdModel(
          id: 'test_capture_dashboard_ad',
          ownerId: ownerId,
          type: AdType.banner_ad,
          size: AdSize.small,
          imageUrl:
              'https://via.placeholder.com/400x200/00838F/FFFFFF?text=Capture+Ad',
          title: 'Capture & Share',
          description: 'Document and share amazing artwork you discover',
          location: AdLocation.captureDashboard,
          duration: AdDuration.oneWeek,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
          status: AdStatus.approved,
          destinationUrl: 'https://artbeat.com/capture',
          ctaText: 'Start Capturing',
        ),
        AdModel(
          id: 'test_community_hub_ad',
          ownerId: ownerId,
          type: AdType.banner_ad,
          size: AdSize.medium,
          imageUrl:
              'https://via.placeholder.com/400x200/9C27B0/FFFFFF?text=Community+Hub+Ad',
          title: 'Join the Community',
          description: 'Connect with artists and art lovers worldwide',
          location: AdLocation.unifiedCommunityHub,
          duration: AdDuration.oneWeek,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
          status: AdStatus.approved,
          destinationUrl: 'https://artbeat.com/community',
          ctaText: 'Join Now',
        ),
        AdModel(
          id: 'test_event_dashboard_ad',
          ownerId: ownerId,
          type: AdType.banner_ad,
          size: AdSize.small,
          imageUrl:
              'https://via.placeholder.com/400x200/E91E63/FFFFFF?text=Events+Ad',
          title: 'Upcoming Events',
          description: 'Don\'t miss the latest art exhibitions and shows',
          location: AdLocation.eventDashboard,
          duration: AdDuration.oneWeek,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
          status: AdStatus.approved,
          destinationUrl: 'https://artbeat.com/events',
          ctaText: 'View Events',
        ),
      ];

      for (final ad in testAds) {
        await _firestore.collection('ads').doc(ad.id).set(ad.toMap());
        print(
          'Created test ad: ${ad.title} for location: ${ad.location.displayName}',
        );
      }

      AppLogger.info('✅ Successfully created ${testAds.length} test ads');
    } catch (e) {
      AppLogger.error('❌ Error creating test ads: $e');
    }
  }

  Future<void> clearTestAds() async {
    try {
      final testAdIds = [
        'test_fluid_dashboard_ad',
        'test_art_walk_dashboard_ad',
        'test_capture_dashboard_ad',
        'test_community_hub_ad',
        'test_event_dashboard_ad',
      ];

      for (final id in testAdIds) {
        await _firestore.collection('ads').doc(id).delete();
        AppLogger.info('Deleted test ad: $id');
      }

      AppLogger.info('✅ Successfully cleared test ads');
    } catch (e) {
      AppLogger.error('❌ Error clearing test ads: $e');
    }
  }
}
