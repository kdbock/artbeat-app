import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_model.dart';
import 'package:artbeat_core/artbeat_core.dart' show SubscriptionTier, UserType;

/// Injectable service for Stripe API access
abstract class IStripeApiService {
  /// Create a subscription in Stripe
  Future<Map<String, dynamic>> createSubscription(
      String customerId, String priceId);

  /// Cancel a subscription in Stripe
  Future<Map<String, dynamic>> cancelSubscription(String subscriptionId);

  /// Update a subscription in Stripe
  Future<Map<String, dynamic>> updateSubscription(
      String subscriptionId, String newPriceId);
}

/// A testable version of SubscriptionService with dependency injection
class TestableSubscriptionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final IStripeApiService _stripeApiService;

  TestableSubscriptionService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required IStripeApiService stripeApiService,
  })  : _firestore = firestore,
        _auth = auth,
        _stripeApiService = stripeApiService;

  /// Get the current authenticated user's ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get the current user's subscription
  Future<SubscriptionModel?> getUserSubscription() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
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

  /// Get current subscription tier
  Future<SubscriptionTier> getCurrentTier() async {
    try {
      final sub = await getUserSubscription();
      return sub?.tier ?? SubscriptionTier.free;
    } catch (e) {
      debugPrint('Error getting current tier: $e');
      return SubscriptionTier.free;
    }
  }

  /// Get subscription by ID
  Future<SubscriptionModel?> getSubscriptionById(String subscriptionId) async {
    try {
      final doc = await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();

      if (!doc.exists) return null;

      return SubscriptionModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting subscription by ID: $e');
      return null;
    }
  }

  /// Get artist profile by user ID
  Future<Map<String, dynamic>?> getArtistProfileByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return data;
    } catch (e) {
      debugPrint('Error getting artist profile: $e');
      return null;
    }
  }

  /// Create new subscription
  Future<String> createSubscription({
    required String userId,
    required SubscriptionTier tier,
    required String stripePriceId,
    required String stripeCustomerId,
    required bool autoRenew,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      // Create subscription in Stripe
      final stripeResponse = await _stripeApiService.createSubscription(
        stripeCustomerId,
        stripePriceId,
      );

      final stripeSubscriptionId = stripeResponse['id'] as String;

      // Create subscription document in Firestore
      final docRef = _firestore.collection('subscriptions').doc();

      await docRef.set({
        'id': docRef.id,
        'userId': userId,
        'tier': tier.apiName,
        'startDate': startDate,
        'endDate': endDate,
        'stripeSubscriptionId': stripeSubscriptionId,
        'stripePriceId': stripePriceId,
        'stripeCustomerId': stripeCustomerId,
        'autoRenew': autoRenew,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating subscription: $e');
      throw Exception('Failed to create subscription: $e');
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get subscription
      final doc = await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();

      if (!doc.exists) {
        throw Exception('Subscription not found');
      }

      final data = doc.data() as Map<String, dynamic>;

      // Check if user owns this subscription
      if (data['userId'] != userId) {
        throw Exception(
            'You do not have permission to cancel this subscription');
      }

      // Cancel in Stripe if connected
      if (data['stripeSubscriptionId'] != null) {
        await _stripeApiService.cancelSubscription(
          data['stripeSubscriptionId'],
        );
      }

      // Update Firestore document
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'canceledAt': FieldValue.serverTimestamp(),
        'autoRenew': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error canceling subscription: $e');
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  /// Upgrade subscription to a new tier
  Future<void> upgradeSubscription({
    required String subscriptionId,
    required SubscriptionTier newTier,
    required String newStripePriceId,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get subscription
      final doc = await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();

      if (!doc.exists) {
        throw Exception('Subscription not found');
      }

      final data = doc.data() as Map<String, dynamic>;

      // Check if user owns this subscription
      if (data['userId'] != userId) {
        throw Exception(
            'You do not have permission to upgrade this subscription');
      }

      // Update in Stripe if connected
      if (data['stripeSubscriptionId'] != null) {
        await _stripeApiService.updateSubscription(
          data['stripeSubscriptionId'],
          newStripePriceId,
        );
      }

      // Update Firestore document
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'tier': newTier.apiName,
        'stripePriceId': newStripePriceId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update artist profile with new tier
      final artistProfileSnapshot = await _firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: userId)
          .get();

      if (artistProfileSnapshot.docs.isNotEmpty) {
        await _firestore
            .collection('artistProfiles')
            .doc(artistProfileSnapshot.docs.first.id)
            .update({
          'subscriptionTier': newTier.apiName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error upgrading subscription: $e');
      throw Exception('Failed to upgrade subscription: $e');
    }
  }
}
