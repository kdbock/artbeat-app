import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/artist_profile_model.dart';
import '../models/subscription_tier.dart';

/// Service for managing subscriptions
class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the current user's subscription tier
  Future<SubscriptionTier> getCurrentSubscriptionTier() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return SubscriptionTier.basic;

      // Check if user has an artist profile
      final artistDoc = await _firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (artistDoc.docs.isEmpty) return SubscriptionTier.basic;

      // Get subscription tier from artist profile
      final artistProfile =
          ArtistProfileModel.fromFirestore(artistDoc.docs.first);
      SubscriptionTier tier = artistProfile.subscriptionTier;
      return Future<SubscriptionTier>.value(tier);
    } catch (e) {
      debugPrint('Error getting current subscription tier: $e');
      return SubscriptionTier.basic;
    }
  }

  /// Check if the current user is a subscriber (any paid tier)
  Future<bool> isSubscriber() async {
    try {
      final tier = await getCurrentSubscriptionTier();
      return tier == SubscriptionTier.standard ||
          tier == SubscriptionTier.premium;
    } catch (e) {
      debugPrint('Error checking if user is subscriber: $e');
      return false;
    }
  }

  /// Get featured artists based on subscription tier
  Future<List<ArtistProfileModel>> getFeaturedArtists() async {
    try {
      final snapshot = await _firestore
          .collection('artistProfiles')
          .where('isFeatured', isEqualTo: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting featured artists: $e');
      return [];
    }
  }

  /// Get local artists based on location
  Future<List<ArtistProfileModel>> getLocalArtists(String location) async {
    try {
      final snapshot = await _firestore
          .collection('artistProfiles')
          .where('location', isEqualTo: location)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting local artists: $e');
      return [];
    }
  }

  /// Get all galleries
  Future<List<ArtistProfileModel>> getGalleries() async {
    try {
      final snapshot = await _firestore
          .collection('artistProfiles')
          .where('userType', isEqualTo: UserType.gallery.name)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting galleries: $e');
      return [];
    }
  }

  /// Get subscription details by tier
  Map<String, dynamic> getSubscriptionDetails(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.standard:
        return {
          'name': 'Artist Pro',
          'price': 9.99,
          'priceId': 'price_artist_pro_monthly',
          'features': [
            'Unlimited artwork listings',
            'Featured in discover section',
            'Advanced analytics',
            'Priority support',
            'Event creation and promotion',
          ],
        };
      case SubscriptionTier.premium:
        return {
          'name': 'Gallery',
          'price': 49.99,
          'priceId': 'price_gallery_monthly',
          'features': [
            'Multiple artist management',
            'Business profile for galleries',
            'Advanced analytics dashboard',
            'Dedicated support',
            'All Pro features',
          ],
        };
      case SubscriptionTier.basic:
        return {
          'name': 'Artist Basic',
          'price': 0.00,
          'priceId': '',
          'features': [
            'Artist profile page',
            'Up to 5 artwork listings',
            'Basic analytics',
            'Community features',
          ],
        };
      case SubscriptionTier.none:
        return {
          'name': 'None',
          'price': 0.00,
          'priceId': '',
          'features': [],
        };
    }
  }
}
