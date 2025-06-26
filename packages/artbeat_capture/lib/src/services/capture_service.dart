import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/artbeat_core.dart' show CaptureModel;

/// Service for managing art captures in the ARTbeat app.
class CaptureService {
  static final CaptureService _instance = CaptureService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory CaptureService() {
    return _instance;
  }

  CaptureService._internal();

  /// Collection reference for captures
  CollectionReference get _capturesRef => _firestore.collection('captures');

  /// Get all captures for a specific user
  Future<List<CaptureModel>> getCapturesForUser(String? userId) async {
    if (userId == null) return [];

    try {
      final querySnapshot = await _capturesRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => CaptureModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      debugPrint('Error fetching captures: $e');
      return [];
    }
  }

  /// Save a new capture
  Future<String?> saveCapture(CaptureModel capture) async {
    try {
      final docRef = await _capturesRef.add({
        'userId': capture.userId,
        'title': capture.title,
        'textAnnotations': capture.textAnnotations,
        'imageUrl': capture.imageUrl,
        'thumbnailUrl': capture.thumbnailUrl,
        'createdAt': capture.createdAt,
        'updatedAt': capture.updatedAt,
        'location': capture.location,
        'locationName': capture.locationName,
        'description': capture.description,
        'isProcessed': capture.isProcessed,
        'tags': capture.tags,
        'artistId': capture.artistId,
        'artistName': capture.artistName,
        'isPublic': capture.isPublic,
        'artType': capture.artType,
        'artMedium': capture.artMedium,
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Error saving capture: $e');
      return null;
    }
  }

  /// Create a new capture
  Future<CaptureModel> createCapture(CaptureModel capture) async {
    try {
      final docRef = await _capturesRef.add(capture.toFirestore());
      return capture.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Error creating capture: $e');
      rethrow;
    }
  }

  /// Update an existing capture
  Future<bool> updateCapture(
    String captureId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _capturesRef.doc(captureId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating capture: $e');
      return false;
    }
  }

  /// Delete a capture
  Future<bool> deleteCapture(String captureId) async {
    try {
      await _capturesRef.doc(captureId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting capture: $e');
      return false;
    }
  }

  /// Get a single capture by ID
  Future<CaptureModel?> getCaptureById(String captureId) async {
    try {
      final docSnapshot = await _capturesRef.doc(captureId).get();
      if (!docSnapshot.exists) return null;

      return CaptureModel.fromJson({
        ...docSnapshot.data() as Map<String, dynamic>,
        'id': docSnapshot.id,
      });
    } catch (e) {
      debugPrint('Error fetching capture: $e');
      return null;
    }
  }

  /// Get public captures
  Future<List<CaptureModel>> getPublicCaptures({int limit = 20}) async {
    try {
      // Try the indexed query first
      final querySnapshot = await _capturesRef
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => CaptureModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      debugPrint('Error fetching public captures with index: $e');

      // Fallback: Try without orderBy to avoid index requirement
      try {
        debugPrint('🔄 Trying fallback query without orderBy...');
        final fallbackQuery = await _capturesRef
            .where('isPublic', isEqualTo: true)
            .limit(limit)
            .get();

        final captures = fallbackQuery.docs
            .map(
              (doc) => CaptureModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .toList();

        // Sort manually by createdAt
        captures.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        debugPrint('✅ Fallback query found ${captures.length} public captures');
        return captures;
      } catch (fallbackError) {
        debugPrint('❌ Fallback query also failed: $fallbackError');
        return [];
      }
    }
  }
}
