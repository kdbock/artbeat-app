import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Service for managing artist subscriptions
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? getCurrentUserId() => _auth.currentUser?.uid;

  /// Get the current user's subscription
  Future<SubscriptionModel?> getUserSubscription() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('❌ getUserSubscription: No authenticated user');
        return null;
      }

      debugPrint('🔍 getUserSubscription: Querying for userId: $userId');

      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      debugPrint(
          '📊 getUserSubscription: Found ${snapshot.docs.length} subscriptions');

      if (snapshot.docs.isEmpty) {
        debugPrint(
            'ℹ️ getUserSubscription: No active subscription found for user $userId');
        return null;
      }

      final subscription = SubscriptionModel.fromFirestore(snapshot.docs.first);
      debugPrint(
          '✅ getUserSubscription: Found subscription: ${subscription.tier}');
      return subscription;
    } catch (e) {
      debugPrint('Error getting user subscription: $e');
      return null;
    }
  }

  /// Get current subscription for a specific user
  Future<SubscriptionModel?> getCurrentSubscription(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return SubscriptionModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('Error getting subscription for user $userId: $e');
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

  /// Create new artist profile
  Future<String> createArtistProfile({
    required String userId,
    required String displayName,
    required String bio,
    required UserType userType,
    required String location,
    required List<String> mediums,
    required List<String> styles,
    required Map<String, String> socialLinks,
    String? profileImageUrl,
    String? coverImageUrl,
  }) async {
    try {
      DocumentReference docRef;

      // Check if profile already exists
      final existingProfile = await _firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existingProfile.docs.isNotEmpty) {
        // Update existing profile
        docRef = _firestore
            .collection('artistProfiles')
            .doc(existingProfile.docs.first.id);

        await docRef.update({
          'displayName': displayName,
          'bio': bio,
          'userType': userType.value,
          'location': location,
          'mediums': mediums,
          'styles': styles,
          'socialLinks': socialLinks,
          if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
          if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new profile
        docRef = _firestore.collection('artistProfiles').doc();

        await docRef.set({
          'userId': userId,
          'displayName': displayName,
          'bio': bio,
          'userType': userType.value,
          'location': location,
          'mediums': mediums,
          'styles': styles,
          'socialLinks': socialLinks,
          'profileImageUrl': profileImageUrl,
          'coverImageUrl': coverImageUrl,
          'isVerified': false,
          'isFeatured': false,
          'followerCount': 0,
          'subscriptionTier': SubscriptionTier.free.apiName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return docRef.id;
    } catch (e) {
      debugPrint('Error saving artist profile: $e');
      throw Exception('Failed to save artist profile: $e');
    }
  }

  /// Save or update artist profile
  Future<void> saveArtistProfile({
    String? profileId,
    required String displayName,
    required String bio,
    required List<String> mediums,
    required List<String> styles,
    String? location,
    String? websiteUrl,
    String? instagram,
    String? facebook,
    String? twitter,
    String? etsy,
    required UserType userType,
    String? profileImageUrl,
    String? coverImageUrl,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final Map<String, String> socialLinks = {
        if (websiteUrl != null) 'website': websiteUrl,
        if (instagram != null) 'instagram': instagram,
        if (facebook != null) 'facebook': facebook,
        if (twitter != null) 'twitter': twitter,
        if (etsy != null) 'etsy': etsy,
      };

      // Get current tier (default to basic)
      SubscriptionTier tier = SubscriptionTier.artistBasic;
      try {
        final subscription = await getUserSubscription();
        if (subscription != null) {
          tier = subscription.tier;
        }
      } catch (e) {
        debugPrint('Error getting subscription, defaulting to basic: $e');
      }

      // Prepare profile data
      final Map<String, dynamic> data = {
        'userId': userId,
        'displayName': displayName,
        'bio': bio,
        'userType': userType.value,
        'mediums': mediums,
        'styles': styles,
        'socialLinks': socialLinks,
        'subscriptionTier': tier.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (location != null) data['location'] = location;
      if (profileImageUrl != null) data['profileImageUrl'] = profileImageUrl;
      if (coverImageUrl != null) data['coverImageUrl'] = coverImageUrl;

      // Create or update profile
      if (profileId != null) {
        await _firestore
            .collection('artistProfiles')
            .doc(profileId)
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['isVerified'] = false;
        data['isFeatured'] = false;
        await _firestore.collection('artistProfiles').add(data);
      }
    } catch (e) {
      debugPrint('Error saving artist profile: $e');
      throw Exception('Failed to save artist profile: $e');
    }
  }

  /// Check if user has access to a specific tier's features
  Future<bool> hasTierAccess(SubscriptionTier minimumTier) async {
    try {
      final currentTier = await getCurrentTier();
      return currentTier.index >= minimumTier.index;
    } catch (e) {
      debugPrint('Error checking tier access: $e');
      return false;
    }
  }

  /// Helper method to get tier details
  Map<String, dynamic> getTierDetails(SubscriptionTier tier) {
    return {
      'name': tier.displayName,
      'price': tier.monthlyPrice,
      'features': tier.features,
    };
  }

  /// Get artist profile by user ID
  Future<ArtistProfileModel?> getArtistProfileByUserId(String userId) async {
    try {
      debugPrint('🔍 getArtistProfileByUserId: Querying for userId: $userId');

      final query = await _firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      debugPrint(
          '📊 getArtistProfileByUserId: Found ${query.docs.length} documents');

      if (query.docs.isEmpty) {
        debugPrint(
            '❌ getArtistProfileByUserId: No artist profile found for user $userId');
        return null;
      }

      final profile = ArtistProfileModel.fromFirestore(query.docs.first);
      debugPrint(
          '✅ getArtistProfileByUserId: Successfully loaded profile for ${profile.displayName}');
      return profile;
    } catch (e) {
      debugPrint('❌ Error getting artist profile: $e');
      return null;
    }
  }

  /// Get the current user's artist profile
  Future<ArtistProfileModel?> getCurrentArtistProfile() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return null;

      return await getArtistProfileByUserId(userId);
    } catch (e) {
      debugPrint('Error getting current artist profile: $e');
      return null;
    }
  }

  /// Get featured artists
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

  /// Get artist profile by ID
  Future<ArtistProfileModel?> getArtistProfileById(String id) async {
    try {
      final docSnapshot =
          await _firestore.collection('artistProfiles').doc(id).get();

      if (!docSnapshot.exists) return null;
      return ArtistProfileModel.fromFirestore(docSnapshot);
    } catch (e) {
      debugPrint('Error getting artist profile by id: $e');
      return null;
    }
  }

  /// Check if user is following an artist
  Future<bool> isFollowingArtist({required String artistProfileId}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore
          .collection('artistFollows')
          .doc('${userId}_$artistProfileId')
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if following artist: $e');
      return false;
    }
  }

  /// Follow an artist
  Future<void> followArtist({required String artistProfileId}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User must be logged in');

      await _firestore
          .collection('artistFollows')
          .doc('${userId}_$artistProfileId')
          .set({
        'userId': userId,
        'artistProfileId': artistProfileId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update follower count
      await _firestore
          .collection('artistProfiles')
          .doc(artistProfileId)
          .update({
        'followerCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error following artist: $e');
      rethrow;
    }
  }

  /// Unfollow an artist
  Future<void> unfollowArtist({required String artistProfileId}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User must be logged in');

      await _firestore
          .collection('artistFollows')
          .doc('${userId}_$artistProfileId')
          .delete();

      // Update follower count
      await _firestore
          .collection('artistProfiles')
          .doc(artistProfileId)
          .update({
        'followerCount': FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint('Error unfollowing artist: $e');
      rethrow;
    }
  }

  /// Toggle following status for an artist
  Future<bool> toggleFollowArtist({required String artistProfileId}) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) throw Exception('User must be logged in');

      final isCurrentlyFollowing =
          await isFollowingArtist(artistProfileId: artistProfileId);

      if (isCurrentlyFollowing) {
        await unfollowArtist(artistProfileId: artistProfileId);
        return false;
      } else {
        await followArtist(artistProfileId: artistProfileId);
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling artist follow status: $e');
      rethrow;
    }
  }

  /// Get all artists with optional filters
  Future<List<ArtistProfileModel>> getAllArtists({
    String? searchQuery,
    String? medium,
    String? style,
  }) async {
    try {
      Query query = _firestore.collection('artistProfiles');

      // Filter by medium if specified
      if (medium != null && medium != 'All') {
        query = query.where('mediums', arrayContains: medium);
      }

      // Get all artists
      final snapshot = await query.get();
      List<ArtistProfileModel> artists = snapshot.docs
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();

      // Apply style filter in memory (since Firestore doesn't support multiple array-contains queries)
      if (style != null && style != 'All') {
        artists =
            artists.where((artist) => artist.styles.contains(style)).toList();
      }

      // Apply search filter in memory
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        artists = artists.where((artist) {
          return artist.displayName.toLowerCase().contains(searchLower) ||
              (artist.bio?.toLowerCase().contains(searchLower) ?? false);
        }).toList();
      }

      // Sort by subscription tier, featured status, and name
      artists.sort((a, b) {
        // First sort by subscription tier (premium > standard > basic)
        final tierCompare =
            b.subscriptionTier.index.compareTo(a.subscriptionTier.index);
        if (tierCompare != 0) return tierCompare;

        // Then by featured status
        if (a.isFeatured != b.isFeatured) {
          return a.isFeatured ? -1 : 1;
        }

        // Finally by name
        return a.displayName.compareTo(b.displayName);
      });

      return artists;
    } catch (e) {
      debugPrint('Error getting all artists: $e');
      return [];
    }
  }
}
