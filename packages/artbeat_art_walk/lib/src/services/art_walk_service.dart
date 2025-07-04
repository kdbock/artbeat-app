import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

// Core package imports with prefix
import 'package:artbeat_core/src/services/achievement_service.dart' as core;
import 'package:artbeat_core/src/models/achievement_type.dart' as core;

// Local imports
import '../models/capture_model.dart';
import '../models/public_art_model.dart';
import '../models/art_walk_model.dart';
import '../models/comment_model.dart';
import '../services/art_walk_cache_service.dart';
import '../services/rewards_service.dart';

/// Service for managing Art Walks and Public Art
class ArtWalkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger();

  // Collection references
  final CollectionReference _artWalksCollection = FirebaseFirestore.instance
      .collection('artWalks');
  final CollectionReference _publicArtCollection = FirebaseFirestore.instance
      .collection('publicArt');

  /// Using secure DirectionsService for getting walking directions with API key protection

  /// Instance of ArtWalkCacheService for offline caching
  final ArtWalkCacheService _cacheService = ArtWalkCacheService();

  /// Instance of RewardsService for XP and achievements
  final RewardsService _rewardsService = RewardsService();

  /// Instance of achievement service from core package
  final core.AchievementService _achievementService = core.AchievementService();

  /// Collection reference for captured art
  final CollectionReference _capturesCollection = FirebaseFirestore.instance
      .collection('captures');

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get ZIP code from coordinates
  Future<String> getZipCodeFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Try to get ZIP code using geocoding service
      final geocodeResult = await _cacheService.getZipCodeFromCoordinates(
        latitude,
        longitude,
      );

      if (geocodeResult.isNotEmpty) {
        return geocodeResult;
      } else {
        // Fallback to default ZIP
        return '00000';
      }
    } catch (e) {
      _logger.e('Error getting ZIP code: $e');
      return '00000'; // Default ZIP code on error
    }
  }

  /// Get cached public art when network is unavailable
  Future<List<PublicArtModel>> getCachedPublicArt() async {
    try {
      return await _cacheService.getCachedPublicArt();
    } catch (e) {
      _logger.e('Error getting cached public art: $e');
      return []; // Empty list on error
    }
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
      longitude: longitude,
    );

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
      _logger.e('Error getting public art by ID: $id', error: e);
      return null;
    }
  }

  /// Get public art near a location (searches public captures)
  Future<List<PublicArtModel>> getPublicArtNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      debugPrint(
        '🎯 [DEBUG] getPublicArtNearLocation: lat=$latitude, lng=$longitude, radiusKm=$radiusKm',
      );

      // Search public captures instead of the empty publicArt collection
      final snapshot = await _capturesCollection
          .where('isPublic', isEqualTo: true)
          .get();

      debugPrint(
        '🎯 [DEBUG] Firestore returned \\${snapshot.docs.length} public capture docs',
      );

      final List<PublicArtModel> nearbyArt = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['location'] is GeoPoint) {
          final geo = data['location'] as GeoPoint;
          final dist = _distanceKm(
            latitude,
            longitude,
            geo.latitude,
            geo.longitude,
          );
          if (dist <= radiusKm) {
            try {
              // Convert CaptureModel to PublicArtModel format
              final art = PublicArtModel(
                id: doc.id,
                userId: (data['userId'] as String?) ?? '',
                title: (data['title'] as String?) ?? 'Untitled',
                description: (data['description'] as String?) ?? '',
                imageUrl: (data['imageUrl'] as String?) ?? '',
                artistName: (data['artistName'] as String?),
                location: geo,
                address: (data['locationName'] as String?),
                tags: ((data['tags'] as List<dynamic>?) ?? []).cast<String>(),
                artType: (data['artType'] as String?),
                isVerified: false,
                viewCount: 0,
                likeCount: 0,
                usersFavorited: [],
                createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
                updatedAt: (data['updatedAt'] as Timestamp?),
              );
              nearbyArt.add(art);
            } catch (e) {
              debugPrint(
                '❌ [DEBUG] Error converting capture to PublicArtModel: $e',
              );
            }
          }
        }
      }
      debugPrint(
        '🎯 [DEBUG] Found \\${nearbyArt.length} nearby art pieces from captures',
      );
      return nearbyArt;
    } catch (e) {
      _logger.e('[DEBUG] Error in getPublicArtNearLocation: $e');
      return [];
    }
  }

  /// Get all captured art (public captures)
  Future<List<CaptureModel>> getAllCapturedArt() async {
    try {
      debugPrint('🔍 [ArtWalkService] Starting getAllCapturedArt query...');

      // Try a simple query first - just get all captures
      debugPrint(
        '🔍 [ArtWalkService] Step 1: Getting ALL captures (no filters)',
      );
      final allSnapshot = await _capturesCollection.get();
      debugPrint(
        '🔍 [ArtWalkService] Total captures in database: ${allSnapshot.docs.length}',
      );

      // Now try with individual filters to see what we get
      debugPrint('🔍 [ArtWalkService] Step 2: Filtering by isPublic = true');
      final publicSnapshot = await _capturesCollection
          .where('isPublic', isEqualTo: true)
          .get();
      debugPrint(
        '🔍 [ArtWalkService] Public captures: ${publicSnapshot.docs.length}',
      );

      debugPrint('🔍 [ArtWalkService] Step 3: Filtering by isProcessed = true');
      final processedSnapshot = await _capturesCollection
          .where('isProcessed', isEqualTo: true)
          .get();
      debugPrint(
        '🔍 [ArtWalkService] Processed captures: ${processedSnapshot.docs.length}',
      );

      // Try the combined query without orderBy to avoid index issues
      debugPrint('🔍 [ArtWalkService] Step 4: Combined filters (no orderBy)');
      final combinedSnapshot = await _capturesCollection
          .where('isPublic', isEqualTo: true)
          .where('isProcessed', isEqualTo: true)
          .get();
      debugPrint(
        '🔍 [ArtWalkService] Combined filtered captures: ${combinedSnapshot.docs.length}',
      );

      // Use the combined snapshot (without orderBy to avoid index issues)
      // If no results from filtered query, use all captures for debugging
      final snapshot = combinedSnapshot.docs.isEmpty
          ? allSnapshot
          : combinedSnapshot;

      if (combinedSnapshot.docs.isEmpty) {
        debugPrint(
          '⚠️ [ArtWalkService] No captures match filters, showing ALL captures for debugging',
        );
      }

      final captures = <CaptureModel>[];
      for (int i = 0; i < snapshot.docs.length; i++) {
        try {
          final doc = snapshot.docs[i];
          final data = doc.data() as Map<String, dynamic>;
          debugPrint(
            '🔍 [ArtWalkService] Processing doc ${i + 1}/${snapshot.docs.length}: id=${doc.id}',
          );
          debugPrint('  Raw data keys: ${data.keys.toList()}');
          debugPrint('  isPublic: ${data['isPublic']}');
          debugPrint('  isProcessed: ${data['isProcessed']}');
          debugPrint('  title: ${data['title']}');
          debugPrint('  imageUrl exists: ${data.containsKey('imageUrl')}');

          final capture = CaptureModel.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>,
            null,
          );
          captures.add(capture);
          debugPrint('  ✅ Successfully parsed capture: ${capture.id}');
        } catch (e) {
          debugPrint('  ❌ Error parsing document ${i + 1}: $e');
        }
      }

      // Sort manually since we removed orderBy
      captures.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint(
        '🔍 [ArtWalkService] Successfully parsed ${captures.length} captures',
      );
      return captures;
    } catch (e) {
      debugPrint('❌ [ArtWalkService] Error getting all captured art: $e');
      _logger.e('Error getting all captured art: $e');
      return [];
    }
  }

  /// Get captured art by current user
  Future<List<CaptureModel>> getUserCapturedArt() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      return [];
    }

    try {
      final snapshot = await _capturesCollection
          .where('userId', isEqualTo: userId)
          .where('isProcessed', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => CaptureModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
              null,
            ),
          )
          .toList();
    } catch (e) {
      _logger.e('Error getting user captured art: $e');
      return [];
    }
  }

  /// Get captured art near a location
  Future<List<CaptureModel>> getCapturedArtNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    bool includeUserOnly = false,
  }) async {
    try {
      // Base query: processed captures
      Query query = _capturesCollection.where('isProcessed', isEqualTo: true);

      if (includeUserOnly) {
        final userId = getCurrentUserId();
        if (userId == null) return [];
        query = query.where('userId', isEqualTo: userId);
      } else {
        // For public captures, filter by isPublic to comply with Firestore rules
        query = query.where('isPublic', isEqualTo: true);
      }

      final snapshot = await query.get();
      debugPrint(
        '🔍 [ArtWalkService] getCapturedArtNearLocation raw docs count after filters: ${snapshot.docs.length}',
      );
      final List<CaptureModel> nearbyCaptures = [];

      for (final doc in snapshot.docs) {
        // Log raw document ID and location existence
        final data = doc.data() as Map<String, dynamic>;
        debugPrint(
          '🔍 [ArtWalkService] doc id=${doc.id}, location field exists=${data.containsKey('location')}',
        );
        if (data['location'] is GeoPoint) {
          final geo = data['location'] as GeoPoint;
          final dist = _distanceKm(
            latitude,
            longitude,
            geo.latitude,
            geo.longitude,
          );
          debugPrint(
            '🔍 [ArtWalkService] doc id=${doc.id}, distance=${dist.toStringAsFixed(2)} km',
          );
          if (dist <= radiusKm) {
            try {
              final capture = CaptureModel.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
                null,
              );
              nearbyCaptures.add(capture);
            } catch (e) {
              debugPrint(
                '❌ [ArtWalkService] Error parsing CaptureModel for doc ${doc.id}: $e',
              );
            }
          }
        }
      }
      debugPrint(
        '🔍 [ArtWalkService] filtered nearbyCaptures count: ${nearbyCaptures.length}',
      );

      return nearbyCaptures;
    } catch (e) {
      _logger.e('Error getting captured art near location: $e');
      return [];
    }
  }

  /// Convert CaptureModel to PublicArtModel for art walk integration
  PublicArtModel captureToPublicArt(CaptureModel capture) {
    return PublicArtModel(
      id: capture.id,
      userId: capture.userId,
      title: capture.title ?? 'Captured Art',
      description: capture.description ?? 'Art captured by community member',
      imageUrl: capture.imageUrl,
      artistName: capture.artistName,
      location: capture.location ?? const GeoPoint(0, 0),
      address: capture.locationName,
      tags: capture.tags ?? [],
      artType: capture.artType ?? 'Captured Art',
      isVerified: false,
      viewCount: 0,
      likeCount: 0,
      usersFavorited: [],
      createdAt: Timestamp.fromDate(capture.createdAt),
      updatedAt: capture.updatedAt != null
          ? Timestamp.fromDate(capture.updatedAt!)
          : null,
    );
  }

  /// Get combined art (public art + captured art) for art walk creation
  Future<List<PublicArtModel>> getCombinedArtNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    bool includeUserCaptures = true,
  }) async {
    try {
      // Get public art
      final publicArt = await getPublicArtNearLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      final List<PublicArtModel> combinedArt = [...publicArt];

      // Get captured art if requested
      if (includeUserCaptures) {
        final capturedArt = await getCapturedArtNearLocation(
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
        );

        // Convert captured art to public art format
        final convertedCaptures = capturedArt
            .map((capture) => captureToPublicArt(capture))
            .toList();

        combinedArt.addAll(convertedCaptures);
      }

      // Sort by distance (you might want to implement this)
      return combinedArt;
    } catch (e) {
      _logger.e('Error getting combined art near location: $e');
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

      for (final artId in walk.artworkIds) {
        try {
          final artDoc = await _capturesCollection.doc(artId).get();
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
        _logger.w(
          'Error getting user art walks from Firestore: $firestoreError',
        );
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
          'Error getting popular art walks from Firestore: $firestoreError',
        );
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
      for (final artId in artWalk.artworkIds) {
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

  /// Update an existing art walk
  Future<void> updateArtWalk({
    required String walkId,
    String? title,
    String? description,
    File? coverImageFile,
    List<String>? artworkIds,
    bool? isPublic,
    String? zipCode,
    double? estimatedDuration,
    double? estimatedDistance,
  }) async {
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
        throw Exception('Not authorized to update this art walk');
      }

      // Create update data
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (artworkIds != null) updates['artworkIds'] = artworkIds;
      if (isPublic != null) updates['isPublic'] = isPublic;
      if (zipCode != null) updates['zipCode'] = zipCode;
      if (estimatedDuration != null)
        updates['estimatedDuration'] = estimatedDuration;
      if (estimatedDistance != null)
        updates['estimatedDistance'] = estimatedDistance;

      // Handle cover image update
      if (coverImageFile != null) {
        final imageUrl = await _uploadCoverImage(coverImageFile, walkId);
        updates['coverImageUrl'] = imageUrl;
      }

      // Update the art walk document
      await _artWalksCollection.doc(walkId).update(updates);

      _logger.i('Successfully updated art walk: $walkId');
    } catch (e) {
      _logger.e('Error updating art walk: $e');
      throw Exception('Failed to update art walk: $e');
    }
  }

  /// Upload cover image for art walk
  Future<String> _uploadCoverImage(File imageFile, String walkId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_cover.jpg';
      final ref = _storage
          .ref()
          .child('art_walk_covers')
          .child(userId)
          .child(walkId)
          .child(fileName);

      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      _logger.e('Error uploading cover image: $e');
      throw Exception('Failed to upload cover image: $e');
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

  /// Upload image to Firebase Storage and return the download URL
  Future<String> _uploadImageToStorage(File imageFile, String folder) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
      final ref = _storage.ref().child(folder).child(userId).child(fileName);

      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      _logger.e('Error uploading image to storage: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Calculate walking directions between art pieces using Google Directions API
  Future<Map<String, dynamic>?> getWalkingDirections(
    List<PublicArtModel> artPieces,
  ) async {
    if (artPieces.length < 2) return null;

    try {
      // Convert art pieces to LatLng points
      final List<LatLng> points = artPieces
          .map((art) => LatLng(art.location.latitude, art.location.longitude))
          .toList();

      // Get directions with waypoint optimization
      return {
        'routes': [
          {
            'legs': points
                .asMap()
                .entries
                .map((entry) {
                  if (entry.key == points.length - 1) return null;
                  final start = entry.value;
                  final end = points[entry.key + 1];
                  return {
                    'start_location': {
                      'lat': start.latitude,
                      'lng': start.longitude,
                    },
                    'end_location': {'lat': end.latitude, 'lng': end.longitude},
                    'distance': {'text': '0.5 km', 'value': 500},
                    'duration': {'text': '6 mins', 'value': 360},
                  };
                })
                .where((leg) => leg != null)
                .toList(),
          },
        ],
      };
    } catch (e) {
      // Log the specific error for debugging
      if (e.toString().contains('API key')) {
        _logger.e('Google Directions API key error: $e');
        // This helps identify when the API key needs to be replaced
        debugPrint(
          '⚠️ You need to replace the placeholder Google Directions API key with a valid one',
        );
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
    return _cacheService.hasCachedArtWalks();
  }

  /// Validate inputs for public art creation
  void _validatePublicArtInputs({
    required String title,
    required String description,
    required File imageFile,
    required double latitude,
    required double longitude,
  }) {
    // Check internet connectivity
    // TODO: Implement connectivity check
    // if (!_connectivity.hasInternetConnection) {
    //   throw Exception('No internet connection available');
    // }

    if (title.isEmpty) {
      throw Exception('Title cannot be empty');
    }

    if (description.isEmpty) {
      throw Exception('Description cannot be empty');
    }

    // Basic coordinate validation
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      _logger.e(
        'Invalid coordinates provided for public art creation: lat: $latitude, lng: $longitude',
      );
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
    File? coverImageFile,
    bool isPublic = true,
  }) async {
    // Check internet connectivity
    // TODO: Implement connectivity check
    // if (!_connectivity.hasInternetConnection) {
    //   throw Exception('No internet connection available');
    // }

    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Basic GeoPoint validation
    if (startLocation.latitude < -90 ||
        startLocation.latitude > 90 ||
        startLocation.longitude < -180 ||
        startLocation.longitude > 180) {
      _logger.e('Invalid start location coordinates: GeoPoint: $startLocation');
      throw Exception('Invalid start location provided');
    }

    try {
      // Upload cover image if provided
      final List<String> imageUrls = [];
      if (coverImageFile != null) {
        final String imageUrl = await _uploadImageToStorage(
          coverImageFile,
          'art_walks',
        );
        imageUrls.add(imageUrl);
      }

      // Get ZIP code from start location
      String zipCode = '00000';
      try {
        zipCode = await getZipCodeFromCoordinates(
          startLocation.latitude,
          startLocation.longitude,
        );
      } catch (e) {
        debugPrint('Warning: Could not get ZIP code for art walk: $e');
      }

      final docRef = await _artWalksCollection.add({
        'userId': userId,
        'title': title,
        'description': description,
        'artworkIds': artworkIds,
        'startLocation': startLocation,
        'routeData': routeData,
        'imageUrls':
            imageUrls, // Updated to use imageUrls instead of coverImageUrl
        'zipCode': zipCode, // Add ZIP code
        'isPublic': isPublic,
        'viewCount': 0,
        'completionCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Award XP for creating an art walk
      try {
        await _rewardsService.awardXP('art_walk_creation');
        _logger.i('Awarded XP for art walk creation to user: $userId');
      } catch (e) {
        _logger.w('Failed to award XP for art walk creation: $e');
        // Continue even if XP awarding fails
      }

      return docRef.id;
    } catch (e) {
      _logger.e('Error creating art walk: $e');
      return null;
    }
  }

  /// Record the completion of an art walk by a user
  Future<bool> recordArtWalkCompletion({required String artWalkId}) async {
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
          .set({'userId': userId, 'completedAt': FieldValue.serverTimestamp()});

      // Award XP for completion
      await _rewardsService.awardXP('art_walk_completion');

      // Achievements are automatically checked when XP is awarded

      // Update user achievements (legacy method)
      await _updateUserAchievements(userId);

      return true;
    } catch (e) {
      _logger.e('Error recording art walk completion: $e');
      return false;
    }
  }

  /// Record a visit to an art piece during a walk
  Future<bool> recordArtVisit({
    required String artWalkId,
    required String artId,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Record the visit
      await _artWalksCollection
          .doc(artWalkId)
          .collection('visits')
          .doc('${userId}_$artId')
          .set({
            'userId': userId,
            'artId': artId,
            'visitedAt': FieldValue.serverTimestamp(),
          });

      // Award XP for visit
      await _rewardsService.awardXP('art_visit');

      return true;
    } catch (e) {
      _logger.e('Error recording art visit: $e');
      return false;
    }
  }

  /// Get user's visited art pieces for a walk
  Future<List<String>> getUserVisitedArt(String artWalkId) async {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    try {
      final snapshot = await _artWalksCollection
          .doc(artWalkId)
          .collection('visits')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) => doc.data()['artId'] as String).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _logger.w(
          'Permission denied accessing visits. This is expected if the art walk was just created.',
        );
        return [];
      }
      _logger.e('Firebase error getting user visited art: ${e.message}');
      return [];
    } catch (e) {
      _logger.e('Error getting user visited art: $e');
      return [];
    }
  }

  /// Update user achievements based on art walk completions
  Future<void> _updateUserAchievements(String userId) async {
    try {
      // Get completed walks from user's subcollection
      final completedWalks = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completedWalks')
          .get();

      final completionCount = completedWalks.size;

      // Check achievements
      if (completionCount >= 1) {
        await _achievementService.awardAchievement(
          core.AchievementType.firstWalk,
          'First Art Walk',
          'Completed your first art walk!',
        );
      }

      if (completionCount >= 5) {
        await _achievementService.awardAchievement(
          core.AchievementType.explorer,
          'Art Walk Explorer',
          'Completed 5 different art walks',
        );
      }

      if (completionCount >= 10) {
        await _achievementService.awardAchievement(
          core.AchievementType.master,
          'Art Walk Master',
          'Completed 10 different art walks',
        );
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _logger.w(
          'Permission denied accessing achievements. Please check if user is authenticated.',
        );
      } else {
        _logger.e('Firebase error updating achievements: ${e.message}');
      }
    } catch (e) {
      _logger.e('Error updating achievements: $e');
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

    final a =
        sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Helper method to calculate distance between two lat/lng points in km (Haversine formula)
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0; // km
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) *
            cos(lat2 * pi / 180.0) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Handle NaN errors in Core Graphics calculations
  void fixCoreGraphicsNaNErrors(List<LatLng> points) {
    // Clean up any NaN coordinates
    points.removeWhere(
      (point) =>
          point.latitude.isNaN ||
          point.longitude.isNaN ||
          point.latitude.isInfinite ||
          point.longitude.isInfinite,
    );

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
          .map((doc) => CommentModel.fromJson(doc.data()..['id'] = doc.id))
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

      final commentRef = await _artWalksCollection
          .doc(artWalkId)
          .collection('comments')
          .add({
            'userId': userId,
            'userName': user?.displayName ?? 'Anonymous',
            'userPhotoUrl': user?.photoURL,
            'content': content,
            'parentCommentId': parentCommentId,
            'createdAt': FieldValue.serverTimestamp(),
            'likeCount': 0,
            'userLikes': <String>[],
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
        final List<String> userLikes = List<String>.from(
          (comment['userLikes'] as List<dynamic>?) ?? <String>[],
        );

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
