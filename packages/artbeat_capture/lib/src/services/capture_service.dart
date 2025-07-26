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

  /// Collection reference for public art
  CollectionReference get _publicArtRef => _firestore.collection('publicArt');

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
      // Save to captures collection (for user's personal collection)
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

      // If capture is public and processed, also save to publicArt collection
      if (capture.isPublic && capture.isProcessed) {
        await _saveToPublicArt(capture.copyWith(id: docRef.id));
      }

      return docRef.id;
    } catch (e) {
      debugPrint('Error saving capture: $e');
      return null;
    }
  }

  /// Save capture to publicArt collection for art walks
  Future<void> _saveToPublicArt(CaptureModel capture) async {
    try {
      await _publicArtRef.doc(capture.id).set({
        'userId': capture.userId,
        'title': capture.title ?? 'Untitled',
        'description': capture.description ?? '',
        'imageUrl': capture.imageUrl,
        'thumbnailUrl': capture.thumbnailUrl,
        'artistName': capture.artistName,
        'location': capture.location,
        'address': capture.locationName,
        'tags': capture.tags ?? [],
        'artType': capture.artType ?? 'Street Art',
        'artMedium': capture.artMedium,
        'isVerified': false,
        'viewCount': 0,
        'likeCount': 0,
        'usersFavorited': <String>[],
        'createdAt': capture.createdAt,
        'updatedAt': capture.updatedAt,
        'captureId': capture.id, // Reference to original capture
      });
      debugPrint('✅ Saved capture ${capture.id} to publicArt collection');
    } catch (e) {
      debugPrint('❌ Error saving to publicArt collection: $e');
    }
  }

  /// Create a new capture
  Future<CaptureModel> createCapture(CaptureModel capture) async {
    try {
      final docRef = await _capturesRef.add(capture.toFirestore());
      final newCapture = capture.copyWith(id: docRef.id);

      // If capture is public and processed, also save to publicArt collection
      if (newCapture.isPublic && newCapture.isProcessed) {
        await _saveToPublicArt(newCapture);
      }

      return newCapture;
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

      // If the capture is being made public and processed, add to publicArt
      if (updates['isPublic'] == true && updates['isProcessed'] == true) {
        final captureDoc = await _capturesRef.doc(captureId).get();
        if (captureDoc.exists) {
          final captureData = captureDoc.data() as Map<String, dynamic>;
          final capture = CaptureModel.fromJson({
            ...captureData,
            'id': captureId,
          });
          await _saveToPublicArt(capture);
        }
      }
      // If the capture is being made private, remove from publicArt
      else if (updates['isPublic'] == false) {
        await _publicArtRef.doc(captureId).delete();
        debugPrint('🗑️ Removed capture $captureId from publicArt collection');
      }

      return true;
    } catch (e) {
      debugPrint('Error updating capture: $e');
      return false;
    }
  }

  /// Delete a capture
  Future<bool> deleteCapture(String captureId) async {
    try {
      // Delete from both collections
      await _capturesRef.doc(captureId).delete();
      await _publicArtRef.doc(captureId).delete();
      debugPrint('🗑️ Deleted capture $captureId from both collections');
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

      final captures = <CaptureModel>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null && data.isNotEmpty) {
            final capture = CaptureModel.fromJson({...data, 'id': doc.id});
            captures.add(capture);
          }
        } catch (e) {
          debugPrint('❌ Error parsing capture ${doc.id}: $e');
          // Skip this document and continue with others
        }
      }

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

        final captures = <CaptureModel>[];
        for (final doc in fallbackQuery.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null && data.isNotEmpty) {
              final capture = CaptureModel.fromJson({...data, 'id': doc.id});
              captures.add(capture);
            }
          } catch (e) {
            debugPrint('❌ Error parsing capture ${doc.id} in fallback: $e');
            // Skip this document and continue with others
          }
        }

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

  /// Migration method: Move existing public captures to publicArt collection
  Future<void> migrateCapturesToPublicArt() async {
    try {
      debugPrint(
        '🔄 Starting migration of captures to publicArt collection...',
      );

      // Get all public and processed captures
      final snapshot = await _capturesRef
          .where('isPublic', isEqualTo: true)
          .where('isProcessed', isEqualTo: true)
          .get();

      debugPrint('📊 Found ${snapshot.docs.length} public captures to migrate');

      int migrated = 0;
      int errors = 0;

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final capture = CaptureModel.fromJson({...data, 'id': doc.id});

          // Check if already exists in publicArt
          final existingDoc = await _publicArtRef.doc(doc.id).get();
          if (!existingDoc.exists) {
            await _saveToPublicArt(capture);
            migrated++;
            debugPrint('✅ Migrated capture ${doc.id}');
          } else {
            debugPrint('⏭️ Capture ${doc.id} already exists in publicArt');
          }
        } catch (e) {
          errors++;
          debugPrint('❌ Error migrating capture ${doc.id}: $e');
        }
      }

      debugPrint('🎉 Migration completed: $migrated migrated, $errors errors');
    } catch (e) {
      debugPrint('❌ Migration failed: $e');
    }
  }
}
