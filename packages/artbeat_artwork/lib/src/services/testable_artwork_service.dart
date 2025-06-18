import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/artbeat_core.dart' show SubscriptionTier;

/// Interface for subscription service to allow for dependency injection
abstract class ISubscriptionService {
  Future<SubscriptionData?> getUserSubscription();
  Future<ArtistProfileData?> getArtistProfileByUserId(String userId);
}

/// Data class for subscription to enable testing
class SubscriptionData {
  final SubscriptionTier tier;
  final DateTime? expiryDate;

  SubscriptionData({
    required this.tier,
    this.expiryDate,
  });
}

/// Data class for artist profile to enable testing
class ArtistProfileData {
  final String id;
  final String name;

  ArtistProfileData({
    required this.id,
    required this.name,
  });
}

/// A testable version of ArtworkService with dependency injection
class TestableArtworkService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final ISubscriptionService _subscriptionService;

  TestableArtworkService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required FirebaseStorage storage,
    required ISubscriptionService subscriptionService,
  })  : _firestore = firestore,
        _auth = auth,
        _storage = storage,
        _subscriptionService = subscriptionService;

  /// Get the current authenticated user's ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get current user's subscription tier
  Future<SubscriptionTier> _getCurrentUserTier() async {
    try {
      final subscription = await _subscriptionService.getUserSubscription();
      return subscription?.tier ?? SubscriptionTier.artistBasic;
    } catch (e) {
      debugPrint('Error getting user subscription: $e');
      return SubscriptionTier.artistBasic;
    }
  }

  /// Check if user can upload more artwork based on subscription
  Future<void> _checkUploadLimit() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get user's subscription tier
      final tier = await _getCurrentUserTier();

      // Users on free/basic tier can only upload 5 artworks
      if (tier == SubscriptionTier.artistBasic) {
        final snapshot = await _firestore
            .collection('artwork')
            .where('userId', isEqualTo: userId)
            .count()
            .get();

        final artworkCount = snapshot.count ?? 0;
        if (artworkCount >= 5) {
          throw Exception(
              'You have reached the maximum number of artworks for the basic tier. Please upgrade to upload more artwork.');
        }
      }
    } catch (e) {
      throw Exception('Error checking upload limit: $e');
    }
  }

  /// Upload new artwork
  Future<String> uploadArtwork({
    required File imageFile,
    required String title,
    required String description,
    required String medium,
    required List<String> styles,
    List<String>? tags,
    String? dimensions,
    String? materials,
    String? location,
    double? price,
    bool isForSale = false,
    int? yearCreated,
    bool isPublic = true,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Check user's subscription and artwork limit
      await _checkUploadLimit();

      // Get artist profile ID
      final artistProfile =
          await _subscriptionService.getArtistProfileByUserId(userId);
      if (artistProfile == null) {
        throw Exception('Artist profile not found. Please create one first.');
      }

      // Upload image to Firebase Storage with format: artwork/{userId}/{timestamp}_{filename}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = imageFile.path.split('/').last;
      final storageRef =
          _storage.ref().child('artwork/$userId/${timestamp}_$filename');

      // Upload image
      await storageRef.putFile(imageFile);

      // Get download URL
      final imageUrl = await storageRef.getDownloadURL();

      // Create artwork document
      final docRef = _firestore.collection('artwork').doc();
      final artworkData = {
        'id': docRef.id,
        'userId': userId,
        'artistId': artistProfile.id,
        'artistName': artistProfile.name,
        'title': title,
        'description': description,
        'medium': medium,
        'styles': styles,
        'tags': tags ?? [],
        'dimensions': dimensions,
        'materials': materials,
        'location': location,
        'price': price,
        'isForSale': isForSale,
        'yearCreated': yearCreated,
        'imageUrl': imageUrl,
        'isPublic': isPublic,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'views': 0,
        'verificationStatus': 'pending',
      };

      // Save artwork to Firestore
      await docRef.set(artworkData);

      return docRef.id;
    } catch (e) {
      debugPrint('Error uploading artwork: $e');
      rethrow;
    }
  }

  /// Get artwork by ID
  Future<Map<String, dynamic>?> getArtworkById(String artworkId) async {
    try {
      final doc = await _firestore.collection('artwork').doc(artworkId).get();

      if (!doc.exists) {
        return null;
      }

      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting artwork: $e');
      rethrow;
    }
  }

  /// Update artwork
  Future<void> updateArtwork({
    required String artworkId,
    String? title,
    String? description,
    String? medium,
    List<String>? styles,
    List<String>? tags,
    String? dimensions,
    String? materials,
    String? location,
    double? price,
    bool? isForSale,
    int? yearCreated,
    bool? isPublic,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the artwork document
      final doc = await _firestore.collection('artwork').doc(artworkId).get();

      if (!doc.exists) {
        throw Exception('Artwork not found');
      }

      final data = doc.data() as Map<String, dynamic>;

      // Check if user owns this artwork
      if (data['userId'] != userId) {
        throw Exception('You do not have permission to update this artwork');
      }

      // Update fields
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (medium != null) updateData['medium'] = medium;
      if (styles != null) updateData['styles'] = styles;
      if (tags != null) updateData['tags'] = tags;
      if (dimensions != null) updateData['dimensions'] = dimensions;
      if (materials != null) updateData['materials'] = materials;
      if (location != null) updateData['location'] = location;
      if (price != null) updateData['price'] = price;
      if (isForSale != null) updateData['isForSale'] = isForSale;
      if (yearCreated != null) updateData['yearCreated'] = yearCreated;
      if (isPublic != null) updateData['isPublic'] = isPublic;

      // Update document
      await _firestore.collection('artwork').doc(artworkId).update(updateData);
    } catch (e) {
      debugPrint('Error updating artwork: $e');
      rethrow;
    }
  }

  /// Delete artwork
  Future<void> deleteArtwork(String artworkId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the artwork document
      final doc = await _firestore.collection('artwork').doc(artworkId).get();

      if (!doc.exists) {
        throw Exception('Artwork not found');
      }

      final data = doc.data() as Map<String, dynamic>;

      // Check if user owns this artwork
      if (data['userId'] != userId) {
        throw Exception('You do not have permission to delete this artwork');
      }

      // Delete the image from storage if it exists
      if (data['imageUrl'] != null) {
        try {
          // Extract storage path from URL
          final url = data['imageUrl'] as String;
          final storagePath = Uri.decodeFull(url.split('?')[0].split('/o/')[1]);
          await _storage.ref(storagePath).delete();
        } catch (e) {
          debugPrint('Error deleting artwork image: $e');
          // Continue with document deletion even if image deletion fails
        }
      }

      // Delete document
      await _firestore.collection('artwork').doc(artworkId).delete();
    } catch (e) {
      debugPrint('Error deleting artwork: $e');
      rethrow;
    }
  }

  /// Get artwork list with optional filters
  Future<List<Map<String, dynamic>>> getArtworkList({
    String? userId,
    String? location,
    String? medium,
    bool onlyPublic = true,
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      // Start with collection reference
      Query query = _firestore.collection('artwork');

      // Apply filters
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (onlyPublic) {
        query = query.where('isPublic', isEqualTo: true);
      }

      if (location != null) {
        query = query.where('location', isEqualTo: location);
      }

      if (medium != null) {
        query = query.where('medium', isEqualTo: medium);
      }

      // Apply limit
      query = query.limit(limit);

      // Get results
      final snapshot = await query.get();

      // Convert to list of maps
      final artworkList = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data;
      }).toList();

      // If search query is provided, filter in-memory
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerCaseQuery = searchQuery.toLowerCase();
        return artworkList.where((artwork) {
          final title = artwork['title'] as String? ?? '';
          final description = artwork['description'] as String? ?? '';
          final artistName = artwork['artistName'] as String? ?? '';

          return title.toLowerCase().contains(lowerCaseQuery) ||
              description.toLowerCase().contains(lowerCaseQuery) ||
              artistName.toLowerCase().contains(lowerCaseQuery);
        }).toList();
      }

      return artworkList;
    } catch (e) {
      debugPrint('Error getting artwork list: $e');
      rethrow;
    }
  }
}
