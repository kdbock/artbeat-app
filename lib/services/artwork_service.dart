import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:artbeat/models/artwork_model.dart';
import 'package:artbeat/models/subscription_model.dart';
import 'package:artbeat/services/subscription_service.dart';

/// Service for managing artwork
class ArtworkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final SubscriptionService _subscriptionService = SubscriptionService();

  // Collection references
  final CollectionReference _artworkCollection =
      FirebaseFirestore.instance.collection('artwork');

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get all artwork for current user
  Future<List<ArtworkModel>> getUserArtwork() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final snapshot = await _artworkCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user artwork: $e');
      return [];
    }
  }

  /// Get artwork by ID
  Future<ArtworkModel?> getArtworkById(String artworkId) async {
    try {
      final doc = await _artworkCollection.doc(artworkId).get();
      if (doc.exists) {
        return ArtworkModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting artwork: $e');
      return null;
    }
  }

  /// Get artwork for a specific artist profile
  Future<List<ArtworkModel>> getArtworkByArtistProfileId(
      String artistProfileId) async {
    try {
      final snapshot = await _artworkCollection
          .where('artistProfileId', isEqualTo: artistProfileId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting artist artwork: $e');
      return [];
    }
  }

  /// Get featured artwork
  Future<List<ArtworkModel>> getFeaturedArtwork({int limit = 10}) async {
    try {
      final snapshot = await _artworkCollection
          .where('isFeatured', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting featured artwork: $e');
      return [];
    }
  }

  /// Upload new artwork
  Future<String> uploadArtwork({
    required File imageFile,
    required String title,
    required String description,
    required String medium,
    required String style,
    required List<String> tags,
    String? dimensions,
    double? price,
    bool isForSale = false,
    int? year,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Check user's subscription and artwork limit
    await _checkUploadLimit();

    // Get artist profile ID
    final artistProfile = await _subscriptionService.getCurrentArtistProfile();
    if (artistProfile == null) {
      throw Exception('Artist profile not found. Please create one first.');
    }

    // Upload image to Firebase Storage
    final storageRef = _storage
        .ref()
        .child('artwork/$userId/${DateTime.now().millisecondsSinceEpoch}');
    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask.whenComplete(() => null);
    final imageUrl = await snapshot.ref.getDownloadURL();

    // Create artwork data
    final artworkData = {
      'userId': userId,
      'artistProfileId': artistProfile.id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'medium': medium,
      'style': style,
      'tags': tags,
      'dimensions': dimensions,
      'price': price,
      'isForSale': isForSale,
      'year': year,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isFeatured': false,
      'viewCount': 0,
      'likeCount': 0,
      'commentCount': 0,
    };

    try {
      // Save to Firestore
      final docRef = await _artworkCollection.add(artworkData);
      return docRef.id;
    } catch (e) {
      // Clean up storage if Firestore fails
      await storageRef
          .delete()
          .catchError((e) => print('Error deleting image: $e'));
      throw Exception('Failed to upload artwork: $e');
    }
  }

  /// Update existing artwork
  Future<void> updateArtwork({
    required String artworkId,
    String? title,
    String? description,
    String? medium,
    String? style,
    List<String>? tags,
    String? dimensions,
    double? price,
    bool? isForSale,
    int? year,
    File? newImageFile,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Check if artwork exists and belongs to user
    final existingArtwork = await getArtworkById(artworkId);
    if (existingArtwork == null) {
      throw Exception('Artwork not found');
    }

    if (existingArtwork.userId != userId) {
      throw Exception('You do not have permission to update this artwork');
    }

    // Prepare update data
    final Map<String, dynamic> updateData = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (title != null) updateData['title'] = title;
    if (description != null) updateData['description'] = description;
    if (medium != null) updateData['medium'] = medium;
    if (style != null) updateData['style'] = style;
    if (tags != null) updateData['tags'] = tags;
    if (dimensions != null) updateData['dimensions'] = dimensions;
    if (price != null) updateData['price'] = price;
    if (isForSale != null) updateData['isForSale'] = isForSale;
    if (year != null) updateData['year'] = year;

    // Upload new image if provided
    if (newImageFile != null) {
      final storageRef = _storage
          .ref()
          .child('artwork/$userId/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = storageRef.putFile(newImageFile);
      final snapshot = await uploadTask.whenComplete(() => null);
      final imageUrl = await snapshot.ref.getDownloadURL();

      updateData['imageUrl'] = imageUrl;

      // Delete old image if it exists
      try {
        if (existingArtwork.imageUrl.isNotEmpty) {
          await _storage.refFromURL(existingArtwork.imageUrl).delete();
        }
      } catch (e) {
        print('Error deleting old image: $e');
        // Continue with update even if old image deletion fails
      }
    }

    // Update Firestore document
    await _artworkCollection.doc(artworkId).update(updateData);
  }

  /// Delete artwork
  Future<void> deleteArtwork(String artworkId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Check if artwork exists and belongs to user
    final existingArtwork = await getArtworkById(artworkId);
    if (existingArtwork == null) {
      throw Exception('Artwork not found');
    }

    if (existingArtwork.userId != userId) {
      throw Exception('You do not have permission to delete this artwork');
    }

    // Delete image from storage
    try {
      if (existingArtwork.imageUrl.isNotEmpty) {
        await _storage.refFromURL(existingArtwork.imageUrl).delete();
      }
    } catch (e) {
      print('Error deleting artwork image: $e');
      // Continue with deletion even if image deletion fails
    }

    // Delete from Firestore
    await _artworkCollection.doc(artworkId).delete();
  }

  /// Check if user can upload more artwork based on subscription
  Future<void> _checkUploadLimit() async {
    // Get user's current subscription
    final subscription = await _subscriptionService.getUserSubscription();
    final tier = subscription?.tier ?? SubscriptionTier.free;

    // Free tier can only upload 5 artworks
    if (tier == SubscriptionTier.free) {
      final userId = getCurrentUserId();
      if (userId != null) {
        final snapshot =
            await _artworkCollection.where('userId', isEqualTo: userId).get();

        if (snapshot.docs.length >= 5) {
          throw Exception(
              'Free tier is limited to 5 artworks. Please upgrade to Pro to upload more.');
        }
      }
    }
    // No limit for other tiers
  }

  /// Increment view count for an artwork
  Future<void> incrementViewCount(String artworkId) async {
    await _artworkCollection.doc(artworkId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  /// Toggle like on artwork
  Future<bool> toggleLike(String artworkId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final likeRef = _firestore
        .collection('artwork')
        .doc(artworkId)
        .collection('likes')
        .doc(userId);

    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      // Unlike
      await likeRef.delete();
      await _artworkCollection.doc(artworkId).update({
        'likeCount': FieldValue.increment(-1),
      });
      return false;
    } else {
      // Like
      await likeRef.set({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _artworkCollection.doc(artworkId).update({
        'likeCount': FieldValue.increment(1),
      });
      return true;
    }
  }

  /// Check if user has liked an artwork
  Future<bool> hasLiked(String artworkId) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;

    final likeDoc = await _firestore
        .collection('artwork')
        .doc(artworkId)
        .collection('likes')
        .doc(userId)
        .get();

    return likeDoc.exists;
  }

  /// Search artwork by title, description, medium, style or tags
  Future<List<ArtworkModel>> searchArtwork(String query) async {
    try {
      // This is a simplified search - in a real app you might use algolia or similar
      final snapshot = await _artworkCollection.get();

      final lowercaseQuery = query.toLowerCase();

      return snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .where((artwork) {
        return artwork.title.toLowerCase().contains(lowercaseQuery) ||
            artwork.description.toLowerCase().contains(lowercaseQuery) ||
            artwork.medium.toLowerCase().contains(lowercaseQuery) ||
            artwork.style.toLowerCase().contains(lowercaseQuery) ||
            artwork.tags
                .any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();
    } catch (e) {
      print('Error searching artwork: $e');
      return [];
    }
  }
}
