// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ad_model.dart';
import '../models/ad_location.dart';
import '../models/ad_status.dart';
import '../models/ad_type.dart';
import '../models/ad_size.dart';
import '../models/ad_duration.dart';

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
          id: 'test_artwalk_map_ad',
          ownerId: ownerId,
          type: AdType.banner_ad,
          size: AdSize.small,
          imageUrl:
              'https://via.placeholder.com/400x200/4FB3BE/FFFFFF?text=Art+Walk+Map+Ad',
          title: 'Explore Local Art',
          description: 'Discover amazing artwork in your area',
          location: AdLocation.artWalkMap,
          duration: AdDuration.oneWeek,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
          status: AdStatus.approved,
          destinationUrl: 'https://artbeat.com',
          ctaText: 'Explore Now',
        ),
        AdModel(
          id: 'test_artwalk_captures_ad',
          ownerId: ownerId,
          type: AdType.banner_ad,
          size: AdSize.small,
          imageUrl:
              'https://via.placeholder.com/400x200/FF9E80/FFFFFF?text=Local+Captures+Ad',
          title: 'Share Your Art',
          description: 'Capture and share local artwork with the community',
          location: AdLocation.artWalkCaptures,
          duration: AdDuration.oneWeek,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
          status: AdStatus.approved,
          destinationUrl: 'https://artbeat.com/capture',
          ctaText: 'Start Capturing',
        ),
        AdModel(
          id: 'test_artwalk_achievements_ad',
          ownerId: ownerId,
          type: AdType.banner_ad,
          size: AdSize.small,
          imageUrl:
              'https://via.placeholder.com/400x200/00838F/FFFFFF?text=Achievements+Ad',
          title: 'Unlock Achievements',
          description: 'Earn badges and recognition for your art exploration',
          location: AdLocation.artWalkAchievements,
          duration: AdDuration.oneWeek,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
          status: AdStatus.approved,
          destinationUrl: 'https://artbeat.com/achievements',
          ctaText: 'View Achievements',
        ),
      ];

      for (final ad in testAds) {
        await _firestore.collection('ads').doc(ad.id).set(ad.toMap());
        print(
          'Created test ad: ${ad.title} for location: ${ad.location.displayName}',
        );
      }

      print('✅ Successfully created ${testAds.length} test ads');
    } catch (e) {
      print('❌ Error creating test ads: $e');
    }
  }

  Future<void> clearTestAds() async {
    try {
      final testAdIds = [
        'test_artwalk_map_ad',
        'test_artwalk_captures_ad',
        'test_artwalk_achievements_ad',
      ];

      for (final id in testAdIds) {
        await _firestore.collection('ads').doc(id).delete();
        print('Deleted test ad: $id');
      }

      print('✅ Successfully cleared test ads');
    } catch (e) {
      print('❌ Error clearing test ads: $e');
    }
  }
}
