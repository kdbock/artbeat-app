import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

/// Interface for services needed by ArtWalkService
abstract class IArtWalkCacheService {
  Future<void> cachePublicArt(List<PublicArtModel> artworks);
  Future<List<PublicArtModel>> getCachedPublicArt();
  Future<void> cacheArtWalks(List<ArtWalkModel> artWalks);
  Future<List<ArtWalkModel>> getCachedArtWalks();
}

/// Testable version of ArtWalkService that allows dependency injection
class TestableArtWalkService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Logger _logger;
  final IArtWalkCacheService _cacheService;

  TestableArtWalkService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    Logger? logger,
    required IArtWalkCacheService cacheService,
  })  : _firestore = firestore,
        _auth = auth,
        _logger = logger ?? Logger(),
        _cacheService = cacheService;

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get a public art by ID
  Future<PublicArtModel?> getPublicArtById(String publicArtId) async {
    try {
      final doc =
          await _firestore.collection('publicArt').doc(publicArtId).get();
      if (!doc.exists) {
        return null;
      }
      return PublicArtModel.fromFirestore(doc);
    } catch (e) {
      _logger.e('Error getting public art: $e');
      return null;
    }
  }

  /// Get all public art pieces
  Future<List<PublicArtModel>> getAllPublicArt() async {
    try {
      final querySnapshot = await _firestore.collection('publicArt').get();
      return querySnapshot.docs
          .map((doc) => PublicArtModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error getting all public art: $e');

      // Try to get cached data if the network request failed
      try {
        return await _cacheService.getCachedPublicArt();
      } catch (cacheError) {
        _logger.e('Error getting cached public art: $cacheError');
        return [];
      }
    }
  }

  /// Get public art by user ID
  Future<List<PublicArtModel>> getPublicArtByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('publicArt')
          .where('userId', isEqualTo: userId)
          .get();
      return querySnapshot.docs
          .map((doc) => PublicArtModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error getting user public art: $e');
      return [];
    }
  }

  /// Get all art walks
  Future<List<ArtWalkModel>> getAllArtWalks({bool publicOnly = false}) async {
    try {
      Query query = _firestore.collection('artWalks');

      if (publicOnly) {
        query = query.where('isPublic', isEqualTo: true);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => ArtWalkModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error getting all art walks: $e');

      // Try to get cached data if the network request failed
      try {
        return await _cacheService.getCachedArtWalks();
      } catch (cacheError) {
        _logger.e('Error getting cached art walks: $cacheError');
        return [];
      }
    }
  }

  /// Get an art walk by ID
  Future<ArtWalkModel?> getArtWalkById(String artWalkId) async {
    try {
      final doc = await _firestore.collection('artWalks').doc(artWalkId).get();
      if (!doc.exists) {
        return null;
      }
      return ArtWalkModel.fromFirestore(doc);
    } catch (e) {
      _logger.e('Error getting art walk: $e');
      return null;
    }
  }

  /// Get art walks by user ID
  Future<List<ArtWalkModel>> getArtWalksByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('artWalks')
          .where('userId', isEqualTo: userId)
          .get();
      return querySnapshot.docs
          .map((doc) => ArtWalkModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error getting user art walks: $e');
      return [];
    }
  }

  /// Update art walk view count
  Future<void> incrementArtWalkViewCount(String artWalkId) async {
    try {
      await _firestore.collection('artWalks').doc(artWalkId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      _logger.e('Error incrementing art walk view count: $e');
    }
  }
}
