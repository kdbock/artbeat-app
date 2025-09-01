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
      return tier == SubscriptionTier.starter ||
          tier == SubscriptionTier.creator ||
          tier == SubscriptionTier.business ||
          tier == SubscriptionTier.enterprise;
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
      case SubscriptionTier.creator:
        return {
          'name': 'Creator',
          'price': 12.99,
          'priceId': 'price_creator_monthly_2025',
          'features': [
            'Unlimited artwork listings',
            'Featured in discover section',
            'Advanced analytics',
            'Priority support',
            'Event creation and promotion',
            'AI features: 50 credits/month',
          ],
        };
      case SubscriptionTier.business:
        return {
          'name': 'Business',
          'price': 29.99,
          'priceId': 'price_business_monthly_2025',
          'features': [
            'Multiple artist management',
            'Business profile for galleries',
            'Advanced analytics dashboard',
            'Dedicated support',
            'All Creator features',
            'AI features: 200 credits/month',
          ],
        };
      case SubscriptionTier.starter:
        return {
          'name': 'Starter',
          'price': 4.99,
          'priceId': 'price_starter_monthly_2025',
          'features': [
            'Artist profile page',
            'Up to 5 artwork listings',
            'Basic analytics',
            'Community features',
            'AI features: 10 credits/month',
          ],
        };
      case SubscriptionTier.free:
        return {
          'name': 'Free',
          'price': 0.00,
          'priceId': '',
          'features': [
            'Artist profile page',
            'Community features',
            'Basic support',
          ],
        };
      case SubscriptionTier.enterprise:
        return {
          'name': 'Enterprise',
          'price': 79.99,
          'priceId': 'price_enterprise_monthly_2025',
          'features': [
            'All Business features',
            'White-label branding',
            'Dedicated account manager',
            'SLA guarantee',
            'Custom integrations',
            'AI features: 1000 credits/month',
          ],
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

        DocumentReference artistRef;

        if (artistQuery.docs.isEmpty) {
          // Create a minimal artist profile for the user so subscription changes succeed.
          final displayName = _auth.currentUser?.displayName ?? '';
          artistRef = _firestore.collection('artistProfiles').doc();
          transaction.set(artistRef, {
            'userId': userId,
            'displayName': displayName,
            'userType': UserType.artist.name,
            'subscriptionTier': newTier.apiName,
            'isVerified': false,
            'isFeatured': false,
            'isPortfolioPublic': true,
            'mediums': <String>[],
            'styles': <String>[],
            'socialLinks': <String, String>{},
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'likesCount': 0,
            'viewsCount': 0,
            'artworksCount': 0,
          });
        } else {
          artistRef = artistQuery.docs.first.reference;

          // Update subscription tier in artist profile
          transaction.update(artistRef, {
            'subscriptionTier': newTier.apiName,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

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

        DocumentReference artistRef;

        if (artistQuery.docs.isEmpty) {
          final displayName = _auth.currentUser?.displayName ?? '';
          artistRef = _firestore.collection('artistProfiles').doc();
          transaction.set(artistRef, {
            'userId': userId,
            'displayName': displayName,
            'userType': UserType.artist.name,
            'subscriptionTier': newTier.apiName,
            'isVerified': false,
            'isFeatured': false,
            'isPortfolioPublic': true,
            'mediums': <String>[],
            'styles': <String>[],
            'socialLinks': <String, String>{},
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'likesCount': 0,
            'viewsCount': 0,
            'artworksCount': 0,
          });
        } else {
          artistRef = artistQuery.docs.first.reference;

          // Update subscription tier in artist profile
          transaction.update(artistRef, {
            'subscriptionTier': newTier.apiName,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

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
