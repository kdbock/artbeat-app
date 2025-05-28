import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat/models/subscription_model.dart';
import 'package:artbeat/models/artist_profile_model.dart';

/// Service for handling user subscriptions and artist profiles
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  final CollectionReference _subscriptionsCollection =
      FirebaseFirestore.instance.collection('subscriptions');
  final CollectionReference _artistProfilesCollection =
      FirebaseFirestore.instance.collection('artistProfiles');
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference _artworkCollection =
      FirebaseFirestore.instance.collection('artwork');
  final CollectionReference _artistFollowersCollection =
      FirebaseFirestore.instance.collection('artistFollowers');

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get user subscription
  Future<SubscriptionModel?> getUserSubscription() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final snapshot = await _subscriptionsCollection
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return SubscriptionModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting user subscription: $e');
      return null;
    }
  }

  /// Create or update artist profile
  Future<String> saveArtistProfile({
    required String displayName,
    required String bio,
    required List<String> mediums,
    required List<String> styles,
    String? location,
    String? websiteUrl,
    String? etsy,
    String? instagram,
    String? facebook,
    String? twitter,
    UserType userType = UserType.artist,
    String? profileId, // If updating existing profile
    Map<String, dynamic>? additionalInfo,
    List<String>? galleryArtists, // For gallery profiles
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get user's current subscription
    SubscriptionModel? subscription = await getUserSubscription();
    SubscriptionTier tier = subscription?.tier ?? SubscriptionTier.free;

    // Create artist profile data
    final artistData = {
      'userId': userId,
      'displayName': displayName,
      'bio': bio,
      'mediums': mediums,
      'styles': styles,
      'location': location,
      'websiteUrl': websiteUrl,
      'etsy': etsy,
      'instagram': instagram,
      'facebook': facebook,
      'twitter': twitter,
      'userType': userType == UserType.gallery ? 'gallery' : 'artist',
      'subscriptionTier': _tierToString(tier),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (additionalInfo != null) {
      artistData['additionalInfo'] = additionalInfo;
    }

    // Gallery-specific data
    if (userType == UserType.gallery && galleryArtists != null) {
      artistData['galleryArtists'] = galleryArtists;
    }

    try {
      // Create or update artist profile
      DocumentReference profileRef;
      if (profileId != null) {
        // Update existing profile
        profileRef = _artistProfilesCollection.doc(profileId);
        await profileRef.update(artistData);
      } else {
        // Create new profile
        profileRef = await _artistProfilesCollection.add(artistData);

        // Update user document with userType
        await _usersCollection.doc(userId).update({
          'userType': userType == UserType.gallery ? 'gallery' : 'artist',
        });
      }

      return profileRef.id;
    } catch (e) {
      print('Error saving artist profile: $e');
      throw Exception('Failed to save artist profile: $e');
    }
  }

  /// Get artist profile by user ID
  Future<ArtistProfileModel?> getArtistProfileByUserId(String userId) async {
    try {
      final snapshot = await _artistProfilesCollection
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ArtistProfileModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting artist profile: $e');
      return null;
    }
  }

  /// Get current user's artist profile
  Future<ArtistProfileModel?> getCurrentArtistProfile() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      return null;
    }

    return getArtistProfileByUserId(userId);
  }

  /// Subscribe to a plan
  Future<SubscriptionModel> subscribeToPlan({
    required SubscriptionTier tier,
    required String paymentMethodId,
    required bool autoRenew,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Calculate subscription dates
    final startDate = DateTime.now();
    final endDate =
        DateTime(startDate.year, startDate.month + 1, startDate.day);

    // TODO: Implement Stripe payment processing
    // This is a placeholder for the actual payment processing logic
    final String stripeCustomerId = 'cus_${userId.substring(0, 8)}';
    final String stripePriceId = _getStripePriceId(tier);
    final String stripeSubscriptionId =
        'sub_${DateTime.now().millisecondsSinceEpoch}';

    // Create subscription data
    final subscriptionData = {
      'userId': userId,
      'tier': _tierToString(tier),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': true,
      'autoRenew': autoRenew,
      'paymentMethod': paymentMethodId,
      'stripeCustomerId': stripeCustomerId,
      'stripePriceId': stripePriceId,
      'stripeSubscriptionId': stripeSubscriptionId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      // Cancel existing active subscriptions
      final existingSubscriptions = await _subscriptionsCollection
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      // Batch write to cancel existing subscriptions and add new one
      final batch = _firestore.batch();

      for (final doc in existingSubscriptions.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      // Add new subscription
      final newSubRef = _subscriptionsCollection.doc();
      batch.set(newSubRef, subscriptionData);

      // Commit batch
      await batch.commit();

      // Update user document with subscription info
      await _usersCollection.doc(userId).update({
        'subscriptionStatus': _tierToString(tier),
        'subscriptionExpiry': Timestamp.fromDate(endDate),
      });

      // Get the created subscription
      final newSub = await newSubRef.get();
      return SubscriptionModel.fromFirestore(newSub);
    } catch (e) {
      print('Error creating subscription: $e');
      throw Exception('Failed to create subscription: $e');
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the subscription document
      final subDoc = await _subscriptionsCollection.doc(subscriptionId).get();
      if (!subDoc.exists) {
        throw Exception('Subscription not found');
      }

      final subData = subDoc.data() as Map<String, dynamic>;

      // Verify ownership
      if (subData['userId'] != userId) {
        throw Exception('Not authorized to cancel this subscription');
      }

      // Note: Actual Stripe cancellation is now handled by PaymentService
      // Cancel the subscription in Firestore
      await _subscriptionsCollection.doc(subscriptionId).update({
        'isActive': false,
        'autoRenew': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user document
      await _usersCollection.doc(userId).update({
        'subscriptionStatus': 'free',
      });
    } catch (e) {
      print('Error cancelling subscription: $e');
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  /// Get featured artists
  Future<List<ArtistProfileModel>> getFeaturedArtists({int limit = 10}) async {
    try {
      final snapshot = await _artistProfilesCollection
          .where('isFeatured', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting featured artists: $e');
      return [];
    }
  }

  /// Get gallery profiles
  Future<List<ArtistProfileModel>> getGalleryProfiles({int limit = 10}) async {
    try {
      final snapshot = await _artistProfilesCollection
          .where('userType', isEqualTo: 'gallery')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting gallery profiles: $e');
      return [];
    }
  }

  /// Get artist profiles filtered by medium or style
  Future<List<ArtistProfileModel>> searchArtistProfiles({
    String? searchTerm,
    List<String>? mediums,
    List<String>? styles,
    int limit = 20,
  }) async {
    try {
      Query query = _artistProfilesCollection
          .where('userType', isEqualTo: 'artist')
          .limit(limit);

      // We can't use multiple array-contains queries, so we'll filter in code
      if (mediums != null && mediums.isNotEmpty) {
        query = query.where('mediums', arrayContainsAny: mediums);
      }

      final snapshot = await query.get();

      // Filter results
      List<ArtistProfileModel> results = snapshot.docs
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();

      // Additional filtering for styles if specified
      if (styles != null && styles.isNotEmpty) {
        results = results
            .where((profile) =>
                profile.styles.any((style) => styles.contains(style)))
            .toList();
      }

      // Filter by search term if specified
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final term = searchTerm.toLowerCase();
        results = results
            .where((profile) =>
                profile.displayName.toLowerCase().contains(term) ||
                profile.bio.toLowerCase().contains(term))
            .toList();
      }

      return results;
    } catch (e) {
      print('Error searching artist profiles: $e');
      return [];
    }
  }

  /// Check if user can access premium features
  Future<bool> canAccessPremiumFeatures() async {
    final subscription = await getUserSubscription();
    return subscription != null &&
        subscription.tier != SubscriptionTier.free &&
        subscription.isActive;
  }

  /// Helper method to convert tier enum to string
  String _tierToString(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'free';
      case SubscriptionTier.standard:
        return 'standard';
      case SubscriptionTier.premium:
        return 'premium';
    }
  }

  /// Helper to get Stripe price ID based on tier
  String _getStripePriceId(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'price_free';
      case SubscriptionTier.standard:
        return 'price_standard_monthly';
      case SubscriptionTier.premium:
        return 'price_premium_monthly';
    }
  }

  /// Get artist profile by ID
  Future<ArtistProfileModel?> getArtistProfileById(String profileId) async {
    try {
      final doc = await _artistProfilesCollection.doc(profileId).get();
      if (doc.exists) {
        return ArtistProfileModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting artist profile by ID: $e');
      return null;
    }
  }

  /// Get payment history for a user
  Future<List<Map<String, dynamic>>> getPaymentHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting payment history: $e');
      return [];
    }
  }

  /// Search for artists
  Future<List<ArtistProfileModel>> searchArtists({
    String? query,
    String? medium,
    String? style,
    int limit = 50,
  }) async {
    try {
      Query artistQuery = _artistProfilesCollection;

      // Filter by premium/featured artists first
      artistQuery = artistQuery.orderBy('subscriptionTier', descending: true);

      // Apply medium filter if provided
      if (medium != null) {
        artistQuery = artistQuery.where('mediums', arrayContains: medium);
      }

      // Get results and filter further in memory
      // (Firestore doesn't support multiple arrayContains queries)
      var snapshot = await artistQuery.limit(limit).get();

      List<ArtistProfileModel> artists = snapshot.docs
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();

      // Apply style filter if provided
      if (style != null) {
        artists =
            artists.where((artist) => artist.styles.contains(style)).toList();
      }

      // Apply search query if provided
      if (query != null && query.isNotEmpty) {
        final lowercaseQuery = query.toLowerCase();
        artists = artists
            .where((artist) =>
                artist.displayName.toLowerCase().contains(lowercaseQuery) ||
                artist.bio.toLowerCase().contains(lowercaseQuery) ||
                (artist.location != null &&
                    artist.location!.toLowerCase().contains(lowercaseQuery)))
            .toList();
      }

      return artists;
    } catch (e) {
      print('Error searching artists: $e');
      return [];
    }
  }

  /// Check if user follows an artist
  Future<bool> isFollowingArtist({required String artistProfileId}) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;

    try {
      final doc = await _artistFollowersCollection
          .doc(artistProfileId)
          .collection('followers')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking if following artist: $e');
      return false;
    }
  }

  /// Toggle follow status for an artist
  Future<bool> toggleFollowArtist({required String artistProfileId}) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final followRef = _artistFollowersCollection
        .doc(artistProfileId)
        .collection('followers')
        .doc(userId);

    try {
      final followDoc = await followRef.get();

      if (followDoc.exists) {
        // Unfollow
        await followRef.delete();
        return false;
      } else {
        // Follow
        await followRef.set({
          'userId': userId,
          'followedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
    } catch (e) {
      print('Error toggling artist follow: $e');
      throw Exception('Failed to update follow status: $e');
    }
  }

  /// Get artist followers count
  Future<int> getArtistFollowersCount(String artistProfileId) async {
    try {
      final snapshot = await _artistFollowersCollection
          .doc(artistProfileId)
          .collection('followers')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting artist followers count: $e');
      return 0;
    }
  }
}
