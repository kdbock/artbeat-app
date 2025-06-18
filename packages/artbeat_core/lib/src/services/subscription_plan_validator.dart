import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_tier.dart';

/// Service for validating subscription plan transitions and capabilities
class SubscriptionPlanValidator {
  static final SubscriptionPlanValidator _instance =
      SubscriptionPlanValidator._internal();
  factory SubscriptionPlanValidator() => _instance;
  SubscriptionPlanValidator._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if transition between tiers is valid
  Future<bool> canTransitionTo(
      SubscriptionTier currentTier, SubscriptionTier targetTier) async {
    try {
      // Downgrade checks
      if (targetTier.index < currentTier.index) {
        // Check for active commissions for galleries downgrading from premium
        if (currentTier == SubscriptionTier.gallery) {
          final activeCommissions = await _hasActiveCommissions();
          if (activeCommissions) {
            return false;
          }
        }

        // Check artwork count for pro artists downgrading to basic
        if (currentTier == SubscriptionTier.artistPro &&
            (targetTier == SubscriptionTier.artistBasic ||
                targetTier == SubscriptionTier.free)) {
          final artworkCount = await _getArtworkCount();
          if (artworkCount > 5) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error validating tier transition: $e');
      return false;
    }
  }

  /// Check for active commission agreements
  Future<bool> _hasActiveCommissions() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final snapshot = await _firestore
          .collection('commissions')
          .where('galleryId', isEqualTo: userId)
          .where('status', whereIn: ['active', 'pending'])
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking active commissions: $e');
      return false;
    }
  }

  /// Get count of user's artwork
  Future<int> _getArtworkCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final snapshot = await _firestore
          .collection('artwork')
          .where('artistId', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting artwork count: $e');
      return 0;
    }
  }

  /// Get capabilities for a subscription tier
  Map<String, dynamic> getTierCapabilities(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.gallery:
        return {
          'maxArtists': -1, // Unlimited
          'maxArtworks': -1, // Unlimited
          'canManageArtists': true,
          'advancedAnalytics': true,
          'eventCreation': true,
          'customBranding': true,
          'prioritySupport': true,
          'bulkUpload': true,
          'commissionManagement': true,
        };
      case SubscriptionTier.artistPro:
        return {
          'maxArtists': 1,
          'maxArtworks': -1, // Unlimited
          'canManageArtists': false,
          'advancedAnalytics': true,
          'eventCreation': true,
          'customBranding': false,
          'prioritySupport': true,
          'bulkUpload': false,
          'commissionManagement': true,
        };
      case SubscriptionTier.artistBasic:
        return {
          'maxArtists': 1,
          'maxArtworks': 5,
          'canManageArtists': false,
          'advancedAnalytics': false,
          'eventCreation': false,
          'customBranding': false,
          'prioritySupport': false,
          'bulkUpload': false,
          'commissionManagement': false,
        };
      case SubscriptionTier.free:
        return {
          'maxArtists': 0,
          'maxArtworks': 0,
          'canManageArtists': false,
          'advancedAnalytics': false,
          'eventCreation': false,
          'customBranding': false,
          'prioritySupport': false,
          'bulkUpload': false,
          'commissionManagement': false,
        };
    }
  }
}
