import 'dart:io';
import 'dart:math' show pi, sin, cos, sqrt, atan2;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import '../models/comment_model.dart';

/// Service for managing Art Walks and Public Art
class ArtWalkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger();
  final FirebaseDiagnosticService _diagnostics = FirebaseDiagnosticService();
  final ConnectivityUtils _connectivity = ConnectivityUtils();

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
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      final data = doc.data() as Map<String, dynamic>;
      return PublicArtModel.fromJson(data);
    } catch (e) {
      _diagnostics.logError('Error getting public art by ID: $id', error: e);
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

  // Old createArtWalk implementation removed

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

  /// Validate inputs for public art creation
  void _validatePublicArtInputs({
    required String title,
    required String description,
    required File imageFile,
    required double latitude,
    required double longitude,
  }) {
    if (!_connectivity.hasInternetConnection) {
      throw Exception('No internet connection available');
    }

    if (title.isEmpty) {
      throw Exception('Title cannot be empty');
    }

    if (description.isEmpty) {
      throw Exception('Description cannot be empty');
    }

    if (!CoordinateValidator.isValidLatitude(latitude) ||
        !CoordinateValidator.isValidLongitude(longitude)) {
      _diagnostics.logError(
          'Invalid coordinates provided for public art creation',
          error: 'lat: $latitude, lng: $longitude');
      throw Exception('Invalid location coordinates provided');
    }

    if (!imageFile.existsSync()) {
      throw Exception('Image file does not exist');
    }
  }

  /// Create a new art walk with proper validation
  Future<String?> createArtWalk({
    required String title,
    required String description,
    required List<String> artworkIds,
    required GeoPoint startLocation,
    required String routeData,
    String? coverImageUrl,
    bool isPublic = true,
  }) async {
    if (!_connectivity.hasInternetConnection) {
      throw Exception('No internet connection available');
    }

    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    if (!CoordinateValidator.isValidGeoPoint(startLocation)) {
      _diagnostics.logError('Invalid start location coordinates',
          error: 'GeoPoint: $startLocation');
      throw Exception('Invalid start location provided');
    }

    try {
      final docRef = await _artWalksCollection.add({
        'userId': userId,
        'title': title,
        'description': description,
        'artworkIds': artworkIds,
        'startLocation': startLocation,
        'routeData': routeData,
        'coverImageUrl': coverImageUrl,
        'isPublic': isPublic,
        'viewCount': 0,
        'completionCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      _diagnostics.logError('Error creating art walk', error: e);
      return null;
    }
  }

  /// Record the completion of an art walk by a user
  Future<bool> recordArtWalkCompletion({
    required String artWalkId,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Add completion record
      await _artWalksCollection
          .doc(artWalkId)
          .collection('completions')
          .doc(userId)
          .set({
        'userId': userId,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Update user achievements
      await _updateUserAchievements(userId);

      return true;
    } catch (e) {
      _logger.e('Error recording art walk completion: $e');
      return false;
    }
  }

  /// Update user achievements based on art walk completions
  Future<void> _updateUserAchievements(String userId) async {
    try {
      // Get all completed art walks for user
      final completedWalks = await _firestore
          .collectionGroup('completions')
          .where('userId', isEqualTo: userId)
          .get();

      final completionCount = completedWalks.size;

      // Update user achievements based on completion count
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          return;
        }

        final achievements =
            List<String>.from(userDoc.data()?['achievements'] ?? []);

        // Add achievements based on completion count
        if (completionCount >= 1 && !achievements.contains('first_art_walk')) {
          achievements.add('first_art_walk');
        }
        if (completionCount >= 5 && !achievements.contains('art_explorer')) {
          achievements.add('art_explorer');
        }
        if (completionCount >= 10 && !achievements.contains('art_enthusiast')) {
          achievements.add('art_enthusiast');
        }
        if (completionCount >= 25 && !achievements.contains('art_aficionado')) {
          achievements.add('art_aficionado');
        }

        transaction.update(userRef, {'achievements': achievements});
      });
    } catch (e) {
      _logger.e('Error updating user achievements: $e');
    }
  }

  /// Calculate distance between points on art walk
  double calculateDistance(List<LatLng> points) {
    double totalDistance = 0.0;

    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += _calculateDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }

    return totalDistance;
  }

  /// Helper method to calculate distance between two points
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters

    // Convert to radians
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Handle NaN errors in Core Graphics calculations
  void fixCoreGraphicsNaNErrors(List<LatLng> points) {
    // Clean up any NaN coordinates
    points.removeWhere((point) =>
        point.latitude.isNaN ||
        point.longitude.isNaN ||
        point.latitude.isInfinite ||
        point.longitude.isInfinite);

    // Ensure minimum of 2 points for a valid route
    if (points.length < 2) {
      throw Exception('Invalid route: requires at least 2 valid points');
    }
  }

  /// Get comments for an art walk
  Future<List<CommentModel>> getArtWalkComments(String artWalkId) async {
    try {
      final snapshot = await _artWalksCollection
          .doc(artWalkId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CommentModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      _logger.e('Error getting art walk comments: $e');
      return [];
    }
  }

  /// Add a comment to an art walk
  Future<String?> addCommentToArtWalk({
    required String artWalkId,
    required String content,
    String? parentCommentId,
    double? rating,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get user info for the comment
      final user = _auth.currentUser;

      final commentRef =
          await _artWalksCollection.doc(artWalkId).collection('comments').add({
        'userId': userId,
        'userName': user?.displayName ?? 'Anonymous',
        'userPhotoUrl': user?.photoURL,
        'content': content,
        'parentCommentId': parentCommentId,
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
        'userLikes': [],
        'rating': rating,
      });

      return commentRef.id;
    } catch (e) {
      _logger.e('Error adding comment to art walk: $e');
      return null;
    }
  }

  /// Delete a comment from an art walk
  Future<bool> deleteArtWalkComment({
    required String artWalkId,
    required String commentId,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final commentDoc = await _artWalksCollection
          .doc(artWalkId)
          .collection('comments')
          .doc(commentId)
          .get();

      if (!commentDoc.exists) {
        return false;
      }

      final comment = commentDoc.data() as Map<String, dynamic>;
      if (comment['userId'] != userId) {
        throw Exception('Not authorized to delete this comment');
      }

      await _artWalksCollection
          .doc(artWalkId)
          .collection('comments')
          .doc(commentId)
          .delete();

      return true;
    } catch (e) {
      _logger.e('Error deleting art walk comment: $e');
      return false;
    }
  }

  /// Toggle like on a comment
  Future<bool> toggleCommentLike({
    required String artWalkId,
    required String commentId,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final commentRef = _artWalksCollection
          .doc(artWalkId)
          .collection('comments')
          .doc(commentId);

      return await _firestore.runTransaction<bool>((transaction) async {
        final commentDoc = await transaction.get(commentRef);

        if (!commentDoc.exists) {
          return false;
        }

        final comment = commentDoc.data() as Map<String, dynamic>;
        final List<String> userLikes =
            List<String>.from(comment['userLikes'] ?? []);

        if (userLikes.contains(userId)) {
          userLikes.remove(userId);
          transaction.update(commentRef, {
            'likeCount': FieldValue.increment(-1),
            'userLikes': userLikes,
          });
        } else {
          userLikes.add(userId);
          transaction.update(commentRef, {
            'likeCount': FieldValue.increment(1),
            'userLikes': userLikes,
          });
        }

        return true;
      });
    } catch (e) {
      _logger.e('Error toggling comment like: $e');
      return false;
    }
  }
}
