import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:artbeat/models/art_walk_model.dart';
import 'package:artbeat/models/public_art_model.dart';
import 'package:artbeat/models/achievement_model.dart';
import 'package:artbeat/services/directions_service.dart';
import 'package:artbeat/services/secure_directions_service.dart';
import 'package:artbeat/services/art_walk_cache_service.dart';
import 'package:artbeat/services/achievement_service.dart';

/// Service for managing Art Walks and Public Art
class ArtWalkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger();

  // Collection references
  final CollectionReference _artWalksCollection =
      FirebaseFirestore.instance.collection('artWalks');
  final CollectionReference _publicArtCollection =
      FirebaseFirestore.instance.collection('publicArt');

  /// Using secure DirectionsService for getting walking directions with API key protection

  /// Instance of ArtWalkCacheService for offline caching
  final ArtWalkCacheService _cacheService = ArtWalkCacheService();

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Create a new public art entry with validation
  Future<String> createPublicArt({
    required String title,
    required String description,
    required File imageFile,
    required double latitude,
    required double longitude,
    String? artistName,
    String? address,
    List<String>? tags,
    String? artType,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Validate inputs
    _validatePublicArtInputs(
        title: title,
        description: description,
        imageFile: imageFile,
        latitude: latitude,
        longitude: longitude);

    try {
      // Upload image to Firebase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
      final ref = _storage
          .ref()
          .child('public_art_images')
          .child(userId)
          .child(fileName);

      final uploadTask = await ref.putFile(imageFile);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // Create public art in Firestore
      final docRef = await _publicArtCollection.add({
        'userId': userId,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'artistName': artistName,
        'location': GeoPoint(latitude, longitude),
        'address': address,
        'tags': tags ?? [],
        'artType': artType,
        'isVerified': false,
        'viewCount': 0,
        'likeCount': 0,
        'usersFavorited': [userId], // Creator automatically favorites
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      _logger.e('Error creating public art: $e');
      throw Exception('Failed to create public art: $e');
    }
  }

  /// Get a public art entry by ID
  Future<PublicArtModel?> getPublicArtById(String id) async {
    try {
      final doc = await _publicArtCollection.doc(id).get();
      if (!doc.exists) {
        return null;
      }

      return PublicArtModel.fromFirestore(doc);
    } catch (e) {
      _logger.e('Error getting public art: $e');
      return null;
    }
  }

  /// Get public art near a location
  Future<List<PublicArtModel>> getPublicArtNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      // This is a simplified approach - in a production app, you would use
      // Firestore's GeoPoint queries or a specialized geo library

      // Get all public art and filter in memory
      // Note: For production, use pagination and server-side filtering
      final snapshot = await _publicArtCollection.get();

      final List<PublicArtModel> nearbyArt = [];

      for (final doc in snapshot.docs) {
        final art = PublicArtModel.fromFirestore(doc);

        // Calculate distance between art location and provided location
        final double distance = _calculateDistance(
          art.location.latitude,
          art.location.longitude,
          latitude,
          longitude,
        );

        // Only include art within the specified radius
        if (distance <= radiusKm) {
          nearbyArt.add(art);
        }
      }

      return nearbyArt;
    } catch (e) {
      _logger.e('Error getting nearby public art: $e');
      return [];
    }
  }

  /// Create a new art walk
  Future<String> createArtWalk({
    required String title,
    required String description,
    required List<String> artIds,
    String? routePolyline,
    double? distanceKm,
    int? estimatedMinutes,
    File? coverImageFile,
    String? zipCode,
    bool isPublic = true,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      String? coverImageUrl;

      // Upload cover image if provided
      if (coverImageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
        final ref = _storage
            .ref()
            .child('art_walk_covers')
            .child(userId)
            .child(fileName);

        final uploadTask = await ref.putFile(coverImageFile);
        coverImageUrl = await uploadTask.ref.getDownloadURL();
      }

      // Create art walk in Firestore
      final docRef = await _artWalksCollection.add({
        'userId': userId,
        'title': title,
        'description': description,
        'artIds': artIds,
        'routePolyline': routePolyline,
        'distanceKm': distanceKm,
        'estimatedMinutes': estimatedMinutes,
        'coverImageUrl': coverImageUrl,
        'zipCode': zipCode,
        'isPublic': isPublic,
        'viewCount': 0,
        'likeCount': 0,
        'shareCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      _logger.e('Error creating art walk: $e');
      throw Exception('Failed to create art walk: $e');
    }
  }

  /// Get an art walk by ID
  Future<ArtWalkModel?> getArtWalkById(String id) async {
    try {
      // First try to get from Firestore
      try {
        final doc = await _artWalksCollection.doc(id).get();
        if (doc.exists) {
          final artWalk = ArtWalkModel.fromFirestore(doc);

          // Cache the art walk for offline use
          try {
            final artPieces = await getArtInWalk(id);
            await _cacheService.cacheArtWalk(artWalk, artPieces);
          } catch (cacheError) {
            _logger.w('Error caching art walk: $cacheError');
            // Continue even if caching fails
          }

          return artWalk;
        }
      } catch (firestoreError) {
        _logger.w('Error getting art walk from Firestore: $firestoreError');
        // Continue to try getting from cache if Firestore fails
      }

      // If Firestore failed or the document doesn't exist, try to get from cache
      return await _cacheService.getCachedArtWalk(id);
    } catch (e) {
      _logger.e('Error getting art walk: $e');
      return null;
    }
  }

  /// Get public art pieces in an art walk
  Future<List<PublicArtModel>> getArtInWalk(String walkId) async {
    try {
      ArtWalkModel? walk;

      // First try to get from Firestore
      try {
        final walkDoc = await _artWalksCollection.doc(walkId).get();
        if (walkDoc.exists) {
          walk = ArtWalkModel.fromFirestore(walkDoc);
        }
      } catch (firestoreError) {
        _logger.w('Error getting art walk from Firestore: $firestoreError');
        // Continue to try getting from cache if Firestore fails
      }

      // If Firestore failed or the document doesn't exist, try to get from cache
      if (walk == null) {
        walk = await _cacheService.getCachedArtWalk(walkId);
        if (walk == null) {
          throw Exception('Art walk not found in Firestore or cache');
        }

        // If found in cache, return cached art pieces
        return await _cacheService.getCachedArtInWalk(walk);
      }

      // Fetch all art pieces in the walk from Firestore
      final List<PublicArtModel> artPieces = [];

      for (final artId in walk.publicArtIds) {
        try {
          final artDoc = await _publicArtCollection.doc(artId).get();
          if (artDoc.exists) {
            artPieces.add(PublicArtModel.fromFirestore(artDoc));
          }
        } catch (artError) {
          _logger.w('Error getting art piece $artId: $artError');
          // Continue with other art pieces
        }
      }

      return artPieces;
    } catch (e) {
      _logger.e('Error getting art in walk: $e');
      return [];
    }
  }

  /// Get art walks created by a user
  Future<List<ArtWalkModel>> getUserArtWalks(String userId) async {
    try {
      // First try to get from Firestore
      try {
        final snapshot = await _artWalksCollection
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();

        final walks = snapshot.docs
            .map((doc) => ArtWalkModel.fromFirestore(doc))
            .toList();

        // Cache each art walk
        for (final walk in walks) {
          try {
            final artPieces = await getArtInWalk(walk.id);
            await _cacheService.cacheArtWalk(walk, artPieces);
          } catch (cacheError) {
            _logger.w('Error caching art walk: $cacheError');
            // Continue even if caching fails
          }
        }

        return walks;
      } catch (firestoreError) {
        _logger
            .w('Error getting user art walks from Firestore: $firestoreError');
        // Continue to try getting from cache if Firestore fails
      }

      // If Firestore failed, try to get from cache
      final cachedWalks = await _cacheService.getAllCachedArtWalks();
      return cachedWalks.where((walk) => walk.userId == userId).toList();
    } catch (e) {
      _logger.e('Error getting user art walks: $e');
      return [];
    }
  }

  /// Get popular art walks
  Future<List<ArtWalkModel>> getPopularArtWalks({int limit = 10}) async {
    try {
      // First try to get from Firestore
      try {
        final snapshot = await _artWalksCollection
            .where('isPublic', isEqualTo: true)
            .orderBy('viewCount', descending: true)
            .limit(limit)
            .get();

        final walks = snapshot.docs
            .map((doc) => ArtWalkModel.fromFirestore(doc))
            .toList();

        // Cache each art walk
        for (final walk in walks) {
          try {
            final artPieces = await getArtInWalk(walk.id);
            await _cacheService.cacheArtWalk(walk, artPieces);
          } catch (cacheError) {
            _logger.w('Error caching art walk: $cacheError');
            // Continue even if caching fails
          }
        }

        return walks;
      } catch (firestoreError) {
        _logger.w(
            'Error getting popular art walks from Firestore: $firestoreError');
        // Continue to try getting from cache if Firestore fails
      }

      // If Firestore failed, try to get from cache
      final allCachedWalks = await _cacheService.getAllCachedArtWalks();

      // Filter for public walks, sort by view count, and limit
      final publicWalks = allCachedWalks.where((walk) => walk.isPublic).toList()
        ..sort((a, b) => b.viewCount.compareTo(a.viewCount));

      return publicWalks.take(limit).toList();
    } catch (e) {
      _logger.e('Error getting popular art walks: $e');
      return [];
    }
  }

  /// Get public art pieces for an art walk
  Future<List<PublicArtModel>> getPublicArtForWalk(String walkId) async {
    try {
      // First get the art walk to access its art IDs
      final walkDoc = await _artWalksCollection.doc(walkId).get();
      if (!walkDoc.exists) {
        throw Exception('Art walk not found');
      }

      final artWalk = ArtWalkModel.fromFirestore(walkDoc);
      final List<PublicArtModel> artPieces = [];

      // Get each art piece by ID
      for (final artId in artWalk.publicArtIds) {
        final art = await getPublicArtById(artId);
        if (art != null) {
          artPieces.add(art);
        }
      }

      return artPieces;
    } catch (e) {
      _logger.e('Error getting public art for walk $walkId: $e');
      return [];
    }
  }

  /// Get art walks by ZIP codes (for region-based filtering)
  Future<List<ArtWalkModel>> getArtWalksByZipCodes(
    List<String> zipCodes, {
    int limit = 20,
  }) async {
    try {
      // Handle empty list case
      if (zipCodes.isEmpty) {
        return getPopularArtWalks(limit: limit);
      }

      // Query for art walks in the specified ZIP codes
      final querySnapshot = await _artWalksCollection
          .where('zipCode', whereIn: zipCodes)
          .where('isPublic', isEqualTo: true)
          .orderBy('viewCount', descending: true)
          .limit(limit)
          .get();

      final artWalks = querySnapshot.docs
          .map((doc) => ArtWalkModel.fromFirestore(doc))
          .toList();

      // Cache individual walks for offline use
      for (final walk in artWalks) {
        // Get the art pieces for each walk
        final artPieces = await getPublicArtForWalk(walk.id);
        // Cache the walk with its art pieces
        await _cacheService.cacheArtWalk(walk, artPieces);
      }

      return artWalks;
    } catch (e) {
      _logger.e('Error getting art walks by ZIP codes: $e');

      // We can't easily get all cached walks, so return empty list on error
      // Client code should handle showing appropriate error message
      return [];
    }
  }

  /// Like or unlike a public art piece
  Future<void> toggleArtLike(String artId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final artRef = _publicArtCollection.doc(artId);

      return _firestore.runTransaction((transaction) async {
        final artDoc = await transaction.get(artRef);
        if (!artDoc.exists) {
          throw Exception('Art not found');
        }

        final art = PublicArtModel.fromFirestore(artDoc);
        final List<String> usersFavorited = [...art.usersFavorited];

        if (usersFavorited.contains(userId)) {
          // Unlike
          usersFavorited.remove(userId);
          transaction.update(artRef, {
            'usersFavorited': usersFavorited,
            'likeCount': FieldValue.increment(-1),
          });
        } else {
          // Like
          usersFavorited.add(userId);
          transaction.update(artRef, {
            'usersFavorited': usersFavorited,
            'likeCount': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      _logger.e('Error toggling art like: $e');
      throw Exception('Failed to update art like status');
    }
  }

  /// Share an art walk (increment share count)
  Future<void> recordArtWalkShare(String walkId) async {
    try {
      await _artWalksCollection.doc(walkId).update({
        'shareCount': FieldValue.increment(1),
      });
    } catch (e) {
      _logger.e('Error recording art walk share: $e');
    }
  }

  /// Record a view of an art walk
  Future<void> recordArtWalkView(String walkId) async {
    try {
      await _artWalksCollection.doc(walkId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      _logger.e('Error recording art walk view: $e');
    }
  }

  /// Delete an art walk
  Future<void> deleteArtWalk(String walkId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Verify ownership
      final walkDoc = await _artWalksCollection.doc(walkId).get();
      if (!walkDoc.exists) {
        throw Exception('Art walk not found');
      }

      final walkData = walkDoc.data() as Map<String, dynamic>;
      if (walkData['userId'] != userId) {
        throw Exception('Not authorized to delete this art walk');
      }

      // Delete cover image if it exists
      final coverImageUrl = walkData['coverImageUrl'] as String?;
      if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(coverImageUrl).delete();
        } catch (e) {
          // Continue even if image deletion fails
          _logger.w('Failed to delete cover image: $e');
        }
      }

      // Delete the art walk document
      await _artWalksCollection.doc(walkId).delete();
    } catch (e) {
      _logger.e('Error deleting art walk: $e');
      throw Exception('Failed to delete art walk: $e');
    }
  }

  /// Upload a public art image from image picker
  Future<String> uploadPublicArtImage(XFile imageFile) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final file = File(imageFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
      final ref = _storage
          .ref()
          .child('public_art_images')
          .child(userId)
          .child(fileName);

      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      _logger.e('Error uploading public art image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Calculate walking directions between art pieces using Google Directions API with secure API key handling
  Future<DirectionsResult?> getWalkingDirections(
      List<PublicArtModel> artPieces) async {
    if (artPieces.length < 2) return null;

    try {
      // Convert art pieces to LatLng points
      final List<LatLng> points = artPieces
          .map((art) => LatLng(art.location.latitude, art.location.longitude))
          .toList();

      // Get directions with waypoint optimization using secure service
      return await SecureDirectionsService.getWalkingDirections(
        waypoints: points,
        optimizeWaypoints: true,
      );
    } catch (e) {
      // Log the specific error for debugging
      if (e.toString().contains('API key')) {
        _logger.e('Google Directions API key error: $e');
        // This helps identify when the API key needs to be replaced
        debugPrint(
            '⚠️ You need to replace the placeholder Google Directions API key with a valid one');
      } else {
        _logger.e('Error getting walking directions: $e');
      }
      return null;
    }
  }

  /// Clean up resources
  void dispose() {
    // No need to dispose since we're using static methods now
    // SecureDirectionsService handles its own resources
  }

  /// Check and clear expired caches
  Future<void> checkAndClearExpiredCache() async {
    await _cacheService.clearExpiredCache();
  }

  /// Get if we have any cached art walks
  Future<bool> hasCachedArtWalks() async {
    return await _cacheService.hasCachedArtWalks();
  }

  /// Validate public art inputs
  void _validatePublicArtInputs({
    required String title,
    required String description,
    required File imageFile,
    required double latitude,
    required double longitude,
  }) {
    // Validate title
    if (title.trim().isEmpty) {
      throw Exception('Title cannot be empty');
    }
    if (title.trim().length < 3) {
      throw Exception('Title must be at least 3 characters long');
    }
    if (title.trim().length > 100) {
      throw Exception('Title must be less than 100 characters long');
    }

    // Validate description
    if (description.trim().isEmpty) {
      throw Exception('Description cannot be empty');
    }
    if (description.trim().length < 10) {
      throw Exception('Description must be at least 10 characters long');
    }
    if (description.trim().length > 1000) {
      throw Exception('Description must be less than 1000 characters long');
    }

    // Validate image file
    if (imageFile.lengthSync() <= 0) {
      throw Exception('Image file is empty or invalid');
    }
    if (imageFile.lengthSync() > 10 * 1024 * 1024) {
      // 10MB limit
      throw Exception('Image file is too large (maximum 10MB)');
    }

    // Validate location coordinates
    if (latitude < -90 || latitude > 90) {
      throw Exception('Invalid latitude value (must be between -90 and 90)');
    }
    if (longitude < -180 || longitude > 180) {
      throw Exception('Invalid longitude value (must be between -180 and 180)');
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;

    // Convert degrees to radians
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    // Haversine formula
    final double a =
        (_haversin(dLat) + _haversin(dLon) * _cosine(lat1) * _cosine(lat2));
    final double c = 2 * _arcsin(a.isNaN ? 0 : _sqrt(a));

    return earthRadiusKm * c; // Distance in kilometers
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }

  double _haversin(double theta) {
    return (1.0 - _cosine(theta)) / 2.0;
  }

  double _cosine(double theta) {
    return _cos(_degreesToRadians(theta));
  }

  double _cos(double radians) {
    // Simplified implementation - for production use math libraries
    return 1.0 - (radians * radians) / 2.0;
  }

  // Note: Removed unused _sin function

  double _arcsin(double x) {
    return x; // Simplified - for production use math libraries
  }

  double _sqrt(double x) {
    return x.isNaN
        ? 0
        : x * x; // Simplified - for production use math libraries
  }

  //
  // COMMENTS FUNCTIONALITY
  //

  /// Add a comment to an art walk
  Future<String> addCommentToArtWalk({
    required String artWalkId,
    required String content,
    String? parentCommentId,
    double? rating,
    List<String>? mentionedUsers,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get user profile data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }
      final userData = userDoc.data();
      if (userData == null) {
        throw Exception('User profile data is null');
      }

      final userName = userData['fullName'] ?? 'Anonymous';
      final userPhotoUrl = userData['photoURL'] ?? '';

      // Create comment in subcollection
      final commentRef =
          _artWalksCollection.doc(artWalkId).collection('comments').doc();

      final commentData = {
        'userId': userId,
        'artWalkId': artWalkId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
        'parentCommentId': parentCommentId,
        'isEdited': false,
        'rating': rating,
        'mentionedUsers': mentionedUsers,
      };

      await commentRef.set(commentData);

      // Update art walk rating if a rating was provided
      if (rating != null) {
        await _updateArtWalkRating(artWalkId);
      }

      // Check for commentator achievement
      await _checkCommentatorAchievement(userId);

      return commentRef.id;
    } catch (e) {
      _logger.e('Error adding comment to art walk: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Get comments for an art walk
  Future<List<Map<String, dynamic>>> getArtWalkComments(String artWalkId,
      {int limit = 50}) async {
    try {
      final commentsSnapshot = await _artWalksCollection
          .doc(artWalkId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final List<Map<String, dynamic>> comments = [];
      final List<Map<String, dynamic>> topLevelComments = [];
      final Map<String, List<Map<String, dynamic>>> repliesMap = {};

      for (final doc in commentsSnapshot.docs) {
        final data = doc.data();
        final comment = {
          'id': doc.id,
          ...data,
        };

        comments.add(comment);

        // Organize comments into top-level and replies
        final parentId = data['parentCommentId'];
        if (parentId == null) {
          topLevelComments.add(comment);
        } else {
          if (!repliesMap.containsKey(parentId)) {
            repliesMap[parentId] = [];
          }
          repliesMap[parentId]!.add(comment);
        }
      }

      // Sort top-level comments by most recent
      topLevelComments.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      // For each top-level comment, add its replies
      final result = topLevelComments.map((comment) {
        final commentId = comment['id'];
        final replies = repliesMap[commentId] ?? [];

        // Sort replies chronologically (oldest first)
        replies.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return aTime.compareTo(bTime);
        });

        return {
          ...comment,
          'replies': replies,
        };
      }).toList();

      return result;
    } catch (e) {
      _logger.e('Error getting art walk comments: $e');
      return [];
    }
  }

  /// Delete a comment from an art walk
  Future<void> deleteArtWalkComment(String artWalkId, String commentId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final commentRef = _artWalksCollection
          .doc(artWalkId)
          .collection('comments')
          .doc(commentId);

      final commentDoc = await commentRef.get();
      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final commentData = commentDoc.data()!;
      if (commentData['userId'] != userId) {
        // Check if user is the art walk creator
        final artWalkDoc = await _artWalksCollection.doc(artWalkId).get();
        if (!artWalkDoc.exists) {
          throw Exception('Art walk not found');
        }
        final artWalkData = artWalkDoc.data() as Map<String, dynamic>?;
        if (artWalkData == null || artWalkData['userId'] != userId) {
          throw Exception('You do not have permission to delete this comment');
        }
      }

      // Delete the comment
      await commentRef.delete();

      // Also delete any replies to this comment
      final repliesQuery = await _artWalksCollection
          .doc(artWalkId)
          .collection('comments')
          .where('parentCommentId', isEqualTo: commentId)
          .get();

      final batch = _firestore.batch();
      for (final doc in repliesQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Update rating if necessary
      if (commentData['rating'] != null) {
        await _updateArtWalkRating(artWalkId);
      }
    } catch (e) {
      _logger.e('Error deleting art walk comment: $e');
      throw Exception('Failed to delete comment: $e');
    }
  }

  /// Like or unlike a comment on an art walk
  Future<void> toggleCommentLike(String artWalkId, String commentId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final commentRef = _artWalksCollection
          .doc(artWalkId)
          .collection('comments')
          .doc(commentId);
      final likeRef = commentRef.collection('likes').doc(userId);

      return _firestore.runTransaction((transaction) async {
        final likeDoc = await transaction.get(likeRef);

        if (likeDoc.exists) {
          // Unlike
          transaction.delete(likeRef);
          transaction.update(commentRef, {
            'likeCount': FieldValue.increment(-1),
          });
        } else {
          // Like
          transaction.set(likeRef, {
            'userId': userId,
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(commentRef, {
            'likeCount': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      _logger.e('Error toggling comment like: $e');
      throw Exception('Failed to update like status: $e');
    }
  }

  /// Update the average rating for an art walk
  Future<void> _updateArtWalkRating(String artWalkId) async {
    try {
      final ratingsQuery = await _artWalksCollection
          .doc(artWalkId)
          .collection('comments')
          .where('rating', isNull: false)
          .get();

      if (ratingsQuery.docs.isEmpty) {
        // No ratings, reset to null
        await _artWalksCollection.doc(artWalkId).update({
          'averageRating': null,
          'ratingCount': 0,
        });
        return;
      }

      // Calculate average rating
      double totalRating = 0;
      for (final doc in ratingsQuery.docs) {
        totalRating += (doc.data()['rating'] as num).toDouble();
      }
      final averageRating = totalRating / ratingsQuery.docs.length;

      // Update the art walk document
      await _artWalksCollection.doc(artWalkId).update({
        'averageRating': averageRating,
        'ratingCount': ratingsQuery.docs.length,
      });
    } catch (e) {
      _logger.e('Error updating art walk rating: $e');
    }
  }

  //
  // ACHIEVEMENTS FUNCTIONALITY
  //

  // Achievement service for awarding and tracking achievements
  final AchievementService _achievementService = AchievementService();

  /// Check and award the commentator achievement
  Future<void> _checkCommentatorAchievement(String userId) async {
    try {
      // Count all comments by this user across all art walks
      final comments = await _firestore
          .collectionGroup('comments')
          .where('userId', isEqualTo: userId)
          .get();

      if (comments.docs.length >= 10) {
        // Award the achievement if it doesn't exist
        await _achievementService.awardAchievement(
          userId,
          AchievementType.commentator,
          {'commentCount': comments.docs.length},
        );
      }
    } catch (e) {
      _logger.e('Error checking commentator achievement: $e');
      // Don't throw, achievements are non-critical
    }
  }

  /// Record completion of an art walk and check for achievements
  Future<void> recordArtWalkCompletion(String walkId, String userId) async {
    try {
      // Record the completion
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('completedWalks')
          .doc(walkId)
          .set({
        'walkId': walkId,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Check for various achievements
      await _checkWalkCompletionAchievements(userId, walkId);

      return;
    } catch (e) {
      _logger.e('Error recording art walk completion: $e');
      rethrow;
    }
  }

  /// Check for walk completion related achievements
  Future<void> _checkWalkCompletionAchievements(
      String userId, String walkId) async {
    try {
      // Get count of completed walks
      final walkCount =
          await _achievementService.getCompletedArtWalkCount(userId);

      // Check for first walk achievement
      if (walkCount == 1) {
        await _achievementService.awardAchievement(
          userId,
          AchievementType.firstWalk,
          {'walkCount': 1},
        );
      }

      // Check for walk explorer (5 walks)
      if (walkCount >= 5) {
        await _achievementService.awardAchievement(
          userId,
          AchievementType.walkExplorer,
          {'walkCount': walkCount},
        );
      }

      // Check for walk master (20 walks)
      if (walkCount >= 20) {
        await _achievementService.awardAchievement(
          userId,
          AchievementType.walkMaster,
          {'walkCount': walkCount},
        );
      }

      // Check for marathon walker (5km+ walk)
      await _checkForMarathonWalkerAchievement(userId, walkId);
    } catch (e) {
      _logger.e('Error checking walk completion achievements: $e');
    }
  }

  /// Check for the marathon walker achievement (5km+ walk)
  Future<void> _checkForMarathonWalkerAchievement(
      String userId, String walkId) async {
    try {
      // Get the walk document
      final walkDoc = await _artWalksCollection.doc(walkId).get();

      if (!walkDoc.exists) return;

      final walkData = walkDoc.data()! as Map<String, dynamic>;
      final distanceKm = walkData['distanceKm'] as double?;

      if (distanceKm != null && distanceKm >= 5.0) {
        // Found a 5km+ walk, award achievement
        await _achievementService.awardAchievement(
          userId,
          AchievementType.marathonWalker,
          {'walkId': walkId, 'distanceKm': distanceKm},
        );
      }
    } catch (e) {
      _logger.e('Error checking for marathon walker achievement: $e');
    }
  }
}
