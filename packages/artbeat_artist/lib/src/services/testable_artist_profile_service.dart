import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'dart:io';

/// Interface for subscription service dependency injection
abstract class ISubscriptionServiceDependency {
  Future<core.SubscriptionTier> getCurrentTier();
}

/// A testable version of the ArtistProfileService with dependency injection
class TestableArtistProfileService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final ISubscriptionServiceDependency _subscriptionService;

  TestableArtistProfileService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required FirebaseStorage storage,
    required ISubscriptionServiceDependency subscriptionService,
  })  : _firestore = firestore,
        _auth = auth,
        _storage = storage,
        _subscriptionService = subscriptionService;

  /// Get the current authenticated user's ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get artist profile by ID
  Future<Map<String, dynamic>?> getArtistProfileById(String profileId) async {
    try {
      final doc =
          await _firestore.collection('artistProfiles').doc(profileId).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      debugPrint('Error getting artist profile: $e');
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
      debugPrint('Error getting artist profile by user ID: $e');
      return null;
    }
  }

  /// Check if user has artist profile
  Future<bool> hasArtistProfile() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final profile = await getArtistProfileByUserId(userId);
      return profile != null;
    } catch (e) {
      debugPrint('Error checking for artist profile: $e');
      return false;
    }
  }

  /// Create new artist profile
  Future<String> createArtistProfile({
    required String displayName,
    required String bio,
    required core.UserType userType,
    required String location,
    required List<String> mediums,
    required List<String> styles,
    required Map<String, String> socialLinks,
    String? profileImageUrl,
    String? coverImageUrl,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if profile already exists
      final existingProfile = await getArtistProfileByUserId(userId);

      // Get subscription tier (default to basic)
      core.SubscriptionTier tier = await _subscriptionService.getCurrentTier();

      if (existingProfile != null) {
        // Update existing profile
        final docRef = _firestore
            .collection('artistProfiles')
            .doc(existingProfile['id'] as String);

        await docRef.update({
          'displayName': displayName,
          'bio': bio,
          'userType': userType.name,
          'location': location,
          'mediums': mediums,
          'styles': styles,
          'socialLinks': socialLinks,
          'subscriptionTier': tier.apiName,
          if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
          if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return docRef.id;
      } else {
        // Create new profile
        final docRef = _firestore.collection('artistProfiles').doc();

        await docRef.set({
          'id': docRef.id,
          'userId': userId,
          'displayName': displayName,
          'bio': bio,
          'userType': userType == core.UserType.gallery ? 'gallery' : 'artist',
          'location': location,
          'mediums': mediums,
          'styles': styles,
          'socialLinks': socialLinks,
          'profileImageUrl': profileImageUrl,
          'coverImageUrl': coverImageUrl,
          'isVerified': false,
          'isFeatured': false,
          'subscriptionTier': tier.apiName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return docRef.id;
      }
    } catch (e) {
      debugPrint('Error creating artist profile: $e');
      throw Exception('Failed to create artist profile: $e');
    }
  }

  /// Update artist profile
  Future<void> updateArtistProfile({
    required String profileId,
    String? displayName,
    String? bio,
    List<String>? mediums,
    List<String>? styles,
    String? location,
    Map<String, String>? socialLinks,
    String? profileImageUrl,
    String? coverImageUrl,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get profile to check ownership
      final profile = await getArtistProfileById(profileId);
      if (profile == null) {
        throw Exception('Artist profile not found');
      }

      if (profile['userId'] != userId) {
        throw Exception('You do not have permission to update this profile');
      }

      // Prepare data for update
      final Map<String, dynamic> data = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) data['displayName'] = displayName;
      if (bio != null) data['bio'] = bio;
      if (mediums != null) data['mediums'] = mediums;
      if (styles != null) data['styles'] = styles;
      if (location != null) data['location'] = location;
      if (socialLinks != null) data['socialLinks'] = socialLinks;
      if (profileImageUrl != null) data['profileImageUrl'] = profileImageUrl;
      if (coverImageUrl != null) data['coverImageUrl'] = coverImageUrl;

      // Update profile
      await _firestore.collection('artistProfiles').doc(profileId).update(data);
    } catch (e) {
      debugPrint('Error updating artist profile: $e');
      throw Exception('Failed to update artist profile: $e');
    }
  }

  /// Upload profile image
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      // Create storage reference
      final storageRef =
          _storage.ref().child('profile_images/$userId/profile_image.jpg');

      // Upload image
      await storageRef.putFile(imageFile);

      // Get download URL
      final imageUrl = await storageRef.getDownloadURL();
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Upload cover image
  Future<String> uploadCoverImage(File imageFile, String userId) async {
    try {
      // Create storage reference
      final storageRef =
          _storage.ref().child('profile_images/$userId/cover_image.jpg');

      // Upload image
      await storageRef.putFile(imageFile);

      // Get download URL
      final imageUrl = await storageRef.getDownloadURL();
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading cover image: $e');
      throw Exception('Failed to upload cover image: $e');
    }
  }

  /// Search for artists by location
  Future<List<Map<String, dynamic>>> searchArtistsByLocation(String location,
      {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('artistProfiles')
          .where('location', isEqualTo: location)
          .where('userType', isEqualTo: 'artist')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error searching artists by location: $e');
      return [];
    }
  }

  /// Search for galleries by location
  Future<List<Map<String, dynamic>>> searchGalleriesByLocation(String location,
      {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('artistProfiles')
          .where('location', isEqualTo: location)
          .where('userType', isEqualTo: 'gallery')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error searching galleries by location: $e');
      return [];
    }
  }
}
