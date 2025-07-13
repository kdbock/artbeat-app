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

  /// Get all captures (for dashboard display)
  Future<List<CaptureModel>> getAllCaptures({int limit = 50}) async {
    try {
      debugPrint(
        '🚀 CaptureService.getAllCaptures() called with limit: $limit',
      );

      // Try with orderBy first
      final querySnapshot = await _capturesRef
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final captures = querySnapshot.docs
          .map(
            (doc) => CaptureModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();

      debugPrint(
        '✅ CaptureService.getAllCaptures() found ${captures.length} captures',
      );
      return captures;
    } catch (e) {
      debugPrint('❌ Error fetching all captures with orderBy: $e');

      // Fallback: Try without orderBy to avoid index requirement
      try {
        debugPrint('🔄 Trying fallback query without orderBy...');
        final fallbackQuery = await _capturesRef.limit(limit).get();

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
        debugPrint('✅ Fallback query found ${captures.length} all captures');
        return captures;
      } catch (fallbackError) {
        debugPrint('❌ Fallback query also failed: $fallbackError');
        return [];
      }
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

  /// Get user captures with limit
  Future<List<CaptureModel>> getUserCaptures({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _capturesRef
          .where('userId', isEqualTo: userId)
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
      debugPrint('Error fetching user captures: $e');

      // Fallback without orderBy
      try {
        final fallbackQuery = await _capturesRef
            .where('userId', isEqualTo: userId)
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
        return captures;
      } catch (fallbackError) {
        debugPrint(
          '❌ Fallback user captures query also failed: $fallbackError',
        );
        return [];
      }
    }
  }

  /// Get user capture count
  Future<int> getUserCaptureCount(String userId) async {
    try {
      final querySnapshot = await _capturesRef
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting user capture count: $e');

      // Fallback: get all documents and count manually
      try {
        final querySnapshot = await _capturesRef
            .where('userId', isEqualTo: userId)
            .get();

        return querySnapshot.docs.length;
      } catch (fallbackError) {
        debugPrint(
          '❌ Fallback capture count query also failed: $fallbackError',
        );
        return 0;
      }
    }
  }

  /// Get user capture views (total views across all user's captures)
  Future<int> getUserCaptureViews(String userId) async {
    try {
      final querySnapshot = await _capturesRef
          .where('userId', isEqualTo: userId)
          .get();

      int totalViews = 0;
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final views = data['views'] as int? ?? 0;
        totalViews += views;
      }

      return totalViews;
    } catch (e) {
      debugPrint('Error getting user capture views: $e');
      return 0;
    }
  }

  /// Admin: Get captures pending moderation
  Future<List<CaptureModel>> getPendingCaptures({int limit = 50}) async {
    try {
      final querySnapshot = await _capturesRef
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: false) // Oldest first for review
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
      debugPrint('Error fetching pending captures: $e');

      // Fallback without orderBy
      try {
        final fallbackQuery = await _capturesRef
            .where('status', isEqualTo: 'pending')
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
        captures.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return captures;
      } catch (fallbackError) {
        debugPrint(
          '❌ Fallback pending captures query also failed: $fallbackError',
        );
        return [];
      }
    }
  }

  /// Admin: Approve a capture
  Future<bool> approveCapture(
    String captureId, {
    String? moderationNotes,
  }) async {
    try {
      await _capturesRef.doc(captureId).update({
        'status': 'approved',
        'moderationNotes': moderationNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error approving capture: $e');
      return false;
    }
  }

  /// Admin: Reject a capture
  Future<bool> rejectCapture(
    String captureId, {
    String? moderationNotes,
  }) async {
    try {
      await _capturesRef.doc(captureId).update({
        'status': 'rejected',
        'moderationNotes': moderationNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error rejecting capture: $e');
      return false;
    }
  }

  /// Admin: Delete a capture completely
  Future<bool> adminDeleteCapture(String captureId) async {
    try {
      await _capturesRef.doc(captureId).delete();
      return true;
    } catch (e) {
      debugPrint('Error admin deleting capture: $e');
      return false;
    }
  }

  /// Get captures by status
  Future<List<CaptureModel>> getCapturesByStatus(
    String status, {
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _capturesRef
          .where('status', isEqualTo: status)
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
      debugPrint('Error fetching captures by status: $e');

      // Fallback without orderBy
      try {
        final fallbackQuery = await _capturesRef
            .where('status', isEqualTo: status)
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
        return captures;
      } catch (fallbackError) {
        debugPrint(
          '❌ Fallback status captures query also failed: $fallbackError',
        );
        return [];
      }
    }
  }
}
