import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/artist_profile_model.dart';
import '../models/subscription_tier.dart';
import '../models/subscription_model.dart';
import '../models/user_type.dart';
import 'subscription_plan_validator.dart';
import 'subscription_validation_service.dart';

/// Service for managing subscriptions
class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SubscriptionPlanValidator _planValidator = SubscriptionPlanValidator();
  final SubscriptionValidationService _validationService =
      SubscriptionValidationService();

  /// Get the current user's subscription
  Future<SubscriptionModel?> getUserSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return SubscriptionModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('Error getting user subscription: $e');
      return null;
    }
  }

  /// Get the current user's subscription tier
  Future<SubscriptionTier> getCurrentSubscriptionTier() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return SubscriptionTier.free;

      // Check if user has an artist profile
      final artistDoc = await _firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (artistDoc.docs.isEmpty) return SubscriptionTier.free;

      // Get subscription tier from artist profile
      final artistProfile = ArtistProfileModel.fromFirestore(
        artistDoc.docs.first,
      );
      final tier = artistProfile.subscriptionTier;
      return tier;
    } catch (e) {
      debugPrint('Error getting current subscription tier: $e');
      return SubscriptionTier.free;
    }
  }

  /// Check if the current user is a subscriber (any paid tier)
  Future<bool> isSubscriber() async {
    try {
      final tier = await getCurrentSubscriptionTier();
      return tier == SubscriptionTier.artistPro ||
          tier == SubscriptionTier.gallery;
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
      case SubscriptionTier.artistPro:
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
      case SubscriptionTier.gallery:
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
      case SubscriptionTier.artistBasic:
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
      case SubscriptionTier.free:
        return {
          'name': 'None',
          'price': 0.00,
          'priceId': '',
          'features': <String>[],
        };
    }
  }

  /// Validate and process subscription tier change
  Future<bool> changeTier(SubscriptionTier newTier) async {
    try {
      final currentTier = await getCurrentSubscriptionTier();

      // Check if transition is valid
      if (!await _planValidator.canTransitionTo(currentTier, newTier)) {
        debugPrint('Invalid tier transition from $currentTier to $newTier');
        return false;
      }

      // Start a transaction to update subscription data
      await _firestore.runTransaction((transaction) async {
        final userId = _auth.currentUser?.uid;
        if (userId == null) throw Exception('User not authenticated');

        // Get artist profile reference
        final artistQuery = await _firestore
            .collection('artistProfiles')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (artistQuery.docs.isEmpty) {
          throw Exception('Artist profile not found');
        }

        final artistRef = artistQuery.docs.first.reference;

        // Update subscription tier in artist profile
        transaction.update(artistRef, {
          'subscriptionTier': newTier.apiName,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update subscriptions collection
        final subscriptionQuery = await _firestore
            .collection('subscriptions')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (subscriptionQuery.docs.isNotEmpty) {
          transaction.update(subscriptionQuery.docs.first.reference, {
            'tier': newTier.apiName,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final newSubscriptionRef = _firestore
              .collection('subscriptions')
              .doc();
          transaction.set(newSubscriptionRef, {
            'userId': userId,
            'tier': newTier.apiName,
            'startDate': FieldValue.serverTimestamp(),
            'isActive': true,
            'autoRenew': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return true;
    } catch (e) {
      debugPrint('Error changing subscription tier: $e');
      return false;
    }
  }

  /// Change subscription tier with validation
  Future<Map<String, dynamic>> changeTierWithValidation(
    SubscriptionTier newTier, {
    bool validateOnly = false,
  }) async {
    try {
      final validation = await _validationService.prepareTierChange(newTier);
      if ((validation['isValid'] as bool? ?? false) == false) {
        return validation;
      }

      if (validateOnly) {
        return validation;
      }

      // Start a transaction to update subscription data
      await _firestore.runTransaction((transaction) async {
        final userId = _auth.currentUser?.uid;
        if (userId == null) throw Exception('User not authenticated');

        // Get artist profile reference
        final artistQuery = await _firestore
            .collection('artistProfiles')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (artistQuery.docs.isEmpty) {
          throw Exception('Artist profile not found');
        }

        final artistRef = artistQuery.docs.first.reference;

        // Update subscription tier in artist profile
        transaction.update(artistRef, {
          'subscriptionTier': newTier.apiName,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update subscriptions collection
        final subscriptionQuery = await _firestore
            .collection('subscriptions')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (subscriptionQuery.docs.isNotEmpty) {
          transaction.update(subscriptionQuery.docs.first.reference, {
            'tier': newTier.apiName,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final newSubscriptionRef = _firestore
              .collection('subscriptions')
              .doc();
          transaction.set(newSubscriptionRef, {
            'userId': userId,
            'tier': newTier.apiName,
            'startDate': FieldValue.serverTimestamp(),
            'isActive': true,
            'autoRenew': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return {
        'isValid': true,
        'message': 'Successfully changed subscription tier',
        'newTier': newTier,
      };
    } catch (e) {
      return {
        'isValid': false,
        'message': 'Error changing subscription tier: $e',
      };
    }
  }

  /// Get capabilities for current subscription tier
  Future<Map<String, dynamic>> getCurrentTierCapabilities() async {
    final tier = await getCurrentSubscriptionTier();
    return _planValidator.getTierCapabilities(tier);
  }

  /// Check if current tier allows a specific capability
  Future<bool> hasCapability(String capability) async {
    try {
      final capabilities = await getCurrentTierCapabilities();
      final dynamic value = capabilities[capability];
      return (value as bool?) ?? false;
    } catch (e) {
      debugPrint('Error checking capability $capability: $e');
      return false;
    }
  }
}
