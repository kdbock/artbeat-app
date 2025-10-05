import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show CaptureModel, UserService, AppLogger;

// Import ArtWalkService for achievement checking
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;

// Import offline services
import 'offline_queue_service.dart';

/// Service for managing art captures in the ARTbeat app.
class CaptureService {
  static final CaptureService _instance = CaptureService._internal();

  final Connectivity _connectivity = Connectivity();
  final UserService _userService = UserService();
  final art_walk.RewardsService _rewardsService = art_walk.RewardsService();

  // Cache for getAllCaptures
  List<CaptureModel>? _cachedAllCaptures;
  DateTime? _allCapturesCacheTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);
  bool _isLoadingAllCaptures = false;

  factory CaptureService() {
    return _instance;
  }

  CaptureService._internal();

  /// Lazy Firebase Firestore instance
  FirebaseFirestore get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      AppLogger.firebase('Firebase not initialized yet: $e');
      rethrow;
    }
  }

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
      AppLogger.error('Error fetching captures: $e');
      return [];
    }
  }

  /// Save a new capture (with offline support)
  Future<String?> saveCaptureWithOfflineSupport({
    required CaptureModel capture,
    required String localImagePath,
  }) async {
    try {
      // Check internet connectivity
      final connectivityResults = await _connectivity.checkConnectivity();
      final isConnected = connectivityResults.any(
        (result) => result != ConnectivityResult.none,
      );

      if (isConnected) {
        // Online: save directly to Firestore
        return await saveCapture(capture);
      } else {
        // Offline: add to queue for later sync
        final offlineQueueService = OfflineQueueService();
        final localCaptureId = await offlineQueueService.addCaptureToQueue(
          captureData: capture,
          localImagePath: localImagePath,
        );

        AppLogger.info('Capture added to offline queue: $localCaptureId');
        return localCaptureId; // Return the local ID for immediate UI updates
      }
    } catch (e) {
      AppLogger.error('Error saving capture with offline support: $e');
      return null;
    }
  }

  /// Save a new capture
  Future<String?> saveCapture(CaptureModel capture) async {
    try {
      // Create geo field for GeoFlutterFire geospatial queries
      final Map<String, dynamic> geoData = {};
      if (capture.location != null) {
        final geoPoint = capture.location!;
        geoData['geo'] = {
          'geohash': _generateGeohash(geoPoint.latitude, geoPoint.longitude),
          'geopoint': geoPoint,
        };
      }

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
        'status': capture.status.name,
        ...geoData, // Add geo field for geospatial queries
      });

      // Update user's capture count
      await _userService.incrementUserCaptureCount(capture.userId);

      // If capture is public and processed, also save to publicArt collection
      if (capture.isPublic && capture.isProcessed) {
        await _saveToPublicArt(capture.copyWith(id: docRef.id));
      }

      return docRef.id;
    } catch (e) {
      AppLogger.error('Error saving capture: $e');
      return null;
    }
  }

  /// Save capture to publicArt collection for art walks
  Future<void> _saveToPublicArt(CaptureModel capture) async {
    try {
      // Create geo field for GeoFlutterFire geospatial queries
      final Map<String, dynamic> geoData = {};
      if (capture.location != null) {
        final geoPoint = capture.location!;
        geoData['geo'] = {
          'geohash': _generateGeohash(geoPoint.latitude, geoPoint.longitude),
          'geopoint': geoPoint,
        };
      }

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
        ...geoData, // Add geo field for geospatial queries
      });
      AppLogger.info('✅ Saved capture ${capture.id} to publicArt collection');
    } catch (e) {
      AppLogger.error('❌ Error saving to publicArt collection: $e');
    }
  }

  /// Generate geohash for a location (simple implementation)
  /// For production, consider using a proper geohash library
  String _generateGeohash(double latitude, double longitude) {
    // Simple geohash generation (9 characters precision ~4.8m x 4.8m)
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    final latRange = [-90.0, 90.0];
    final lonRange = [-180.0, 180.0];
    var hash = '';
    var isEven = true;
    var bit = 0;
    var ch = 0;

    while (hash.length < 9) {
      if (isEven) {
        final mid = (lonRange[0] + lonRange[1]) / 2;
        if (longitude > mid) {
          ch |= (1 << (4 - bit));
          lonRange[0] = mid;
        } else {
          lonRange[1] = mid;
        }
      } else {
        final mid = (latRange[0] + latRange[1]) / 2;
        if (latitude > mid) {
          ch |= (1 << (4 - bit));
          latRange[0] = mid;
        } else {
          latRange[1] = mid;
        }
      }

      isEven = !isEven;

      if (bit < 4) {
        bit++;
      } else {
        hash += base32[ch];
        bit = 0;
        ch = 0;
      }
    }

    return hash;
  }

  /// Create a new capture
  Future<CaptureModel> createCapture(CaptureModel capture) async {
    try {
      // Create geo field for GeoFlutterFire geospatial queries
      final Map<String, dynamic> captureData = capture.toFirestore();
      if (capture.location != null) {
        final geoPoint = capture.location!;
        captureData['geo'] = {
          'geohash': _generateGeohash(geoPoint.latitude, geoPoint.longitude),
          'geopoint': geoPoint,
        };
      }

      final docRef = await _capturesRef.add(captureData);
      final newCapture = capture.copyWith(id: docRef.id);

      // Update user's capture count
      await _userService.incrementUserCaptureCount(capture.userId);

      // Award XP for creating a capture
      await _rewardsService.awardXP('art_capture_created');

      // Record photo capture for daily challenges
      try {
        final challengeService = art_walk.ChallengeService();
        await challengeService.recordPhotoCapture();

        // Track time-based capture (golden hour)
        await challengeService.recordTimeBasedDiscovery();

        AppLogger.info('✅ Recorded photo capture for daily challenges');
      } catch (e) {
        AppLogger.error('Error recording photo capture for challenges: $e');
      }

      // Update weekly goals for photography
      try {
        final weeklyGoalsService = art_walk.WeeklyGoalsService();
        final currentGoals = await weeklyGoalsService.getCurrentWeekGoals();

        // Update photography-related weekly goals
        for (final goal in currentGoals) {
          if (goal.category == art_walk.WeeklyGoalCategory.photography &&
              !goal.isCompleted) {
            await weeklyGoalsService.updateWeeklyGoalProgress(goal.id, 1);
          }
        }
        AppLogger.info('✅ Updated weekly goals for photo capture');
      } catch (e) {
        AppLogger.error('Error updating weekly goals: $e');
      }

      // Post social activity for the capture
      try {
        debugPrint('🔍 CaptureService: Starting to post social activity...');
        debugPrint('🔍 CaptureService: Capture ID: ${newCapture.id}');
        debugPrint('🔍 CaptureService: Is Public: ${newCapture.isPublic}');

        final user = await _userService.getCurrentUserModel();
        debugPrint(
          '🔍 CaptureService: User retrieved: ${user?.username ?? "null"}',
        );

        if (user == null) {
          debugPrint('🔍 CaptureService: ❌ User is null, cannot post activity');
          AppLogger.warning('Cannot post social activity: user is null');
        } else if (!newCapture.isPublic) {
          debugPrint(
            '🔍 CaptureService: ❌ Capture is not public, skipping activity',
          );
        } else {
          debugPrint(
            '🔍 CaptureService: ✅ User and public check passed, posting activity...',
          );

          // Convert GeoPoint to Position for SocialService
          Position? position;
          if (capture.location != null) {
            position = Position(
              latitude: capture.location!.latitude,
              longitude: capture.location!.longitude,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            );
          }

          await art_walk.SocialService().postActivity(
            userId: capture.userId,
            userName: user.fullName.isNotEmpty ? user.fullName : user.username,
            userAvatar: user.profileImageUrl,
            type: art_walk.SocialActivityType.capture,
            message: 'captured new artwork',
            location: position,
            metadata: {
              'captureId': newCapture.id,
              'artTitle': capture.title ?? 'Untitled',
            },
          );
          debugPrint(
            '🔍 CaptureService: ✅ Posted social activity for capture ${newCapture.id}',
          );
          AppLogger.info('✅ Posted social activity for capture');
        }
      } catch (e, stackTrace) {
        debugPrint('🔍 CaptureService: ❌ Error posting social activity: $e');
        debugPrint('🔍 CaptureService: Stack trace: $stackTrace');
        AppLogger.error(
          'Error posting social activity: $e\nStack: $stackTrace',
        );
      }

      // If capture is public and processed, also save to publicArt collection
      if (newCapture.isPublic && newCapture.isProcessed) {
        await _saveToPublicArt(newCapture);
      }

      // Trigger achievement check for capture-related achievements
      _checkCaptureAchievements(capture.userId);

      return newCapture;
    } catch (e) {
      AppLogger.error('Error creating capture: $e');
      rethrow;
    }
  }

  /// Update an existing capture
  Future<bool> updateCapture(
    String captureId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // If location is being updated, also update the geo field
      final Map<String, dynamic> updateData = {...updates};
      if (updates.containsKey('location') && updates['location'] != null) {
        final geoPoint = updates['location'] as GeoPoint;
        updateData['geo'] = {
          'geohash': _generateGeohash(geoPoint.latitude, geoPoint.longitude),
          'geopoint': geoPoint,
        };
      }

      await _capturesRef.doc(captureId).update({
        ...updateData,
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

          // Trigger achievement check when capture becomes public
          _checkCaptureAchievements(capture.userId);
        }
      }
      // If the capture is being made private, remove from publicArt
      else if (updates['isPublic'] == false) {
        await _publicArtRef.doc(captureId).delete();
        AppLogger.info(
          '🗑️ Removed capture $captureId from publicArt collection',
        );
      }

      return true;
    } catch (e) {
      AppLogger.error('Error updating capture: $e');
      return false;
    }
  }

  /// Delete a capture
  Future<bool> deleteCapture(String captureId) async {
    try {
      // Get the capture document first to retrieve userId
      final captureDoc = await _capturesRef.doc(captureId).get();
      if (captureDoc.exists) {
        final data = captureDoc.data() as Map<String, dynamic>?;
        final userId = data?['userId'] as String?;

        // Delete from both collections
        await _capturesRef.doc(captureId).delete();
        await _publicArtRef.doc(captureId).delete();

        // Update user's capture count if we have userId
        if (userId != null) {
          await _userService.decrementUserCaptureCount(userId);
        }

        AppLogger.info('🗑️ Deleted capture $captureId from both collections');
        return true;
      } else {
        AppLogger.error('❌ Capture $captureId not found');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error deleting capture: $e');
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
      AppLogger.error('Error fetching capture: $e');
      return null;
    }
  }

  /// Get all captures (for dashboard display)
  Future<List<CaptureModel>> getAllCaptures({int limit = 50}) async {
    // Prevent multiple simultaneous calls
    if (_isLoadingAllCaptures) {
      debugPrint(
        '🔄 CaptureService.getAllCaptures() already loading, waiting...',
      );
      // Wait for the current load to complete
      while (_isLoadingAllCaptures) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return _cachedAllCaptures ?? [];
    }

    // Check cache first
    if (_cachedAllCaptures != null &&
        _allCapturesCacheTime != null &&
        DateTime.now().difference(_allCapturesCacheTime!) < _cacheTimeout) {
      AppLogger.info(
        '📦 CaptureService.getAllCaptures() returning cached data',
      );
      return _cachedAllCaptures!;
    }

    _isLoadingAllCaptures = true;

    try {
      debugPrint(
        '🚀 CaptureService.getAllCaptures() fetching from Firestore with limit: $limit',
      );

      // Try with orderBy first - get all captures for public display
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
          AppLogger.error('❌ Error parsing capture ${doc.id}: $e');
          // Skip this document and continue with others
        }
      }

      // Cache the results
      _cachedAllCaptures = captures;
      _allCapturesCacheTime = DateTime.now();

      debugPrint(
        '✅ CaptureService.getAllCaptures() found ${captures.length} captures',
      );
      return captures;
    } catch (e) {
      AppLogger.error('❌ Error fetching all captures with orderBy: $e');

      // Fallback: Try without orderBy to avoid index requirement
      try {
        AppLogger.info('🔄 Trying fallback query without orderBy...');
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
            AppLogger.error(
              '❌ Error parsing capture ${doc.id} in fallback: $e',
            );
            // Skip this document and continue with others
          }
        }

        // Sort manually by createdAt
        captures.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Cache the results
        _cachedAllCaptures = captures;
        _allCapturesCacheTime = DateTime.now();

        AppLogger.info(
          '✅ Fallback query found ${captures.length} all captures',
        );
        return captures;
      } catch (fallbackError) {
        AppLogger.error('❌ Fallback query also failed: $fallbackError');
        return [];
      }
    } finally {
      _isLoadingAllCaptures = false;
    }
  }

  /// Clear the cache for getAllCaptures
  void clearAllCapturesCache() {
    _cachedAllCaptures = null;
    _allCapturesCacheTime = null;
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
      AppLogger.error('Error fetching public captures with index: $e');

      // Fallback: Try without orderBy to avoid index requirement
      try {
        AppLogger.info('🔄 Trying fallback query without orderBy...');
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
        AppLogger.info(
          '✅ Fallback query found ${captures.length} public captures',
        );
        return captures;
      } catch (fallbackError) {
        AppLogger.error('❌ Fallback query also failed: $fallbackError');
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
      AppLogger.error('Error fetching user captures: $e');

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
      AppLogger.error('Error getting user capture count: $e');

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
      AppLogger.error('Error getting user capture views: $e');
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
      AppLogger.error('Error fetching pending captures: $e');

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
      // Get capture data to find userId for XP awarding
      final captureDoc = await _capturesRef.doc(captureId).get();
      if (!captureDoc.exists) {
        AppLogger.info('Capture $captureId not found');
        return false;
      }

      final captureData = captureDoc.data() as Map<String, dynamic>;
      final userId = captureData['userId'] as String?;

      // Update capture status
      await _capturesRef.doc(captureId).update({
        'status': 'approved',
        'moderationNotes': moderationNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Award XP for approved capture
      if (userId != null) {
        try {
          final rewardsService = art_walk.RewardsService();
          await rewardsService.awardXP('art_capture_approved');
          debugPrint(
            '✅ Awarded 50 XP for approved capture $captureId to user $userId',
          );
        } catch (xpError) {
          AppLogger.error(
            '⚠️ Error awarding XP for capture approval: $xpError',
          );
          // Don't fail the approval if XP fails
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('Error approving capture: $e');
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
      AppLogger.error('Error rejecting capture: $e');
      return false;
    }
  }

  /// Admin: Delete a capture completely
  Future<bool> adminDeleteCapture(String captureId) async {
    try {
      // Get the capture document first to retrieve userId
      final captureDoc = await _capturesRef.doc(captureId).get();
      if (captureDoc.exists) {
        final data = captureDoc.data() as Map<String, dynamic>?;
        final userId = data?['userId'] as String?;

        // Delete capture
        await _capturesRef.doc(captureId).delete();

        // Update user's capture count if we have userId
        if (userId != null) {
          await _userService.decrementUserCaptureCount(userId);
        }

        return true;
      } else {
        AppLogger.error('❌ Capture $captureId not found');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error admin deleting capture: $e');
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
      AppLogger.error('Error fetching captures by status: $e');

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

      AppLogger.analytics(
        '📊 Found ${snapshot.docs.length} public captures to migrate',
      );

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
            AppLogger.info('✅ Migrated capture ${doc.id}');
          } else {
            AppLogger.info('⏭️ Capture ${doc.id} already exists in publicArt');
          }
        } catch (e) {
          errors++;
          AppLogger.error('❌ Error migrating capture ${doc.id}: $e');
        }
      }

      AppLogger.error(
        '🎉 Migration completed: $migrated migrated, $errors errors',
      );
    } catch (e) {
      AppLogger.error('❌ Migration failed: $e');
    }
  }

  /// Check capture achievements for a user
  Future<void> _checkCaptureAchievements(String userId) async {
    try {
      // Use the ArtWalkService to check capture achievements
      final artWalkService = art_walk.ArtWalkService();
      await artWalkService.checkCaptureAchievements(userId);
    } catch (e) {
      AppLogger.error('❌ Error checking capture achievements: $e');
      // Don't rethrow - achievement checking shouldn't break capture creation
    }
  }

  /// Backfill geo field for existing captures (migration utility)
  /// This should be called once to add geo fields to existing captures
  Future<void> backfillGeoFieldForCaptures({int batchSize = 100}) async {
    try {
      AppLogger.info('🔄 Starting geo field backfill for captures...');

      // Query captures that have location but no geo field
      final querySnapshot = await _capturesRef
          .where('location', isNull: false)
          .limit(batchSize)
          .get();

      int updatedCount = 0;
      int skippedCount = 0;

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          // Skip if geo field already exists
          if (data.containsKey('geo')) {
            skippedCount++;
            continue;
          }

          final location = data['location'] as GeoPoint?;
          if (location != null) {
            // Add geo field
            await doc.reference.update({
              'geo': {
                'geohash': _generateGeohash(
                  location.latitude,
                  location.longitude,
                ),
                'geopoint': location,
              },
            });
            updatedCount++;
            AppLogger.info('✅ Added geo field to capture ${doc.id}');
          }
        } catch (e) {
          AppLogger.error('❌ Error updating capture ${doc.id}: $e');
        }
      }

      AppLogger.info(
        '✅ Geo field backfill complete: $updatedCount updated, $skippedCount skipped',
      );
    } catch (e) {
      AppLogger.error('❌ Error during geo field backfill: $e');
      rethrow;
    }
  }
}
