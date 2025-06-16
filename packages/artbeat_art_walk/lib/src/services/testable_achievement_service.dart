// filepath: /Users/kristybock/artbeat/packages/artbeat_art_walk/lib/src/services/testable_achievement_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

/// Interface for dependencies needed by the AchievementService
abstract class IAchievementNotificationService {
  Future<void> notifyUserOfNewAchievement(
      String userId, AchievementModel achievement);
}

/// Testable implementation of the AchievementService
class TestableAchievementService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Logger _logger;
  final IAchievementNotificationService? _notificationService;

  TestableAchievementService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    Logger? logger,
    IAchievementNotificationService? notificationService,
  })  : _firestore = firestore,
        _auth = auth,
        _logger = logger ?? Logger(),
        _notificationService = notificationService;

  /// Get the current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get all achievements for the current user
  Future<List<AchievementModel>> getUserAchievements({String? userId}) async {
    try {
      final uid = userId ?? getCurrentUserId();
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final achievementsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .get();

      return achievementsSnapshot.docs
          .map((doc) => AchievementModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error getting user achievements: $e');
      return [];
    }
  }

  /// Get achievements of a specific type for the current user
  Future<List<AchievementModel>> getUserAchievementsByType(AchievementType type,
      {String? userId}) async {
    try {
      final uid = userId ?? getCurrentUserId();
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final achievementsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .where('type', isEqualTo: type.name)
          .get();

      return achievementsSnapshot.docs
          .map((doc) => AchievementModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error getting user achievements by type: $e');
      return [];
    }
  }

  /// Award an achievement to a user
  Future<String> awardAchievement({
    required String userId,
    required AchievementType type,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      // Check if user already has this achievement based on type
      final existingAchievements = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .where('type', isEqualTo: type.name)
          .get();

      if (existingAchievements.docs.isNotEmpty) {
        _logger.i('User $userId already has achievement of type: ${type.name}');
        return existingAchievements.docs.first.id;
      }

      // Create new achievement
      final newAchievement = {
        'userId': userId,
        'type': type.name,
        'earnedAt': FieldValue.serverTimestamp(),
        'isNew': true,
        'metadata': metadata,
      };

      // Add to user's achievements
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .add(newAchievement);

      // Notify user if notification service is provided
      if (_notificationService != null) {
        final achievement = AchievementModel(
          id: docRef.id,
          userId: userId,
          type: type,
          earnedAt: DateTime.now(),
          isNew: true,
          metadata: metadata,
        );
        await _notificationService!
            .notifyUserOfNewAchievement(userId, achievement);
      }

      _logger.i('Awarded achievement of type ${type.name} to user $userId');
      return docRef.id;
    } catch (e) {
      _logger.e('Error awarding achievement: $e');
      throw Exception('Failed to award achievement: $e');
    }
  }

  /// Process ArtWalk completion to check for achievements
  Future<List<String>> processArtWalkCompletion({
    required String userId,
    required String artWalkId,
  }) async {
    try {
      final awardedAchievementIds = <String>[];

      // Get completed art walk details
      final artWalkDoc =
          await _firestore.collection('artWalks').doc(artWalkId).get();
      if (!artWalkDoc.exists) {
        _logger.w('Art Walk $artWalkId not found');
        return [];
      }

      // Count user's completed art walks
      final userCompletionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completedArtWalks')
          .count()
          .get();

      final completedCount = userCompletionsSnapshot.count;

      // First completion achievement
      if (completedCount == 0) {
        final firstAchievementId = await awardAchievement(
          userId: userId,
          type: AchievementType.firstWalk,
          metadata: {
            'artWalkId': artWalkId,
            'completionDate': DateTime.now().millisecondsSinceEpoch,
          },
        );
        awardedAchievementIds.add(firstAchievementId);
      }

      // Fifth completion achievement
      if (completedCount == 4) {
        final fifthAchievementId = await awardAchievement(
          userId: userId,
          type: AchievementType.walkExplorer,
          metadata: {
            'artWalkId': artWalkId,
            'completionDate': DateTime.now().millisecondsSinceEpoch,
            'totalCompleted': 5,
          },
        );
        awardedAchievementIds.add(fifthAchievementId);
      }

      // Record this completion
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('completedArtWalks')
          .doc(artWalkId)
          .set({
        'artWalkId': artWalkId,
        'completedAt': FieldValue.serverTimestamp(),
      });

      return awardedAchievementIds;
    } catch (e) {
      _logger.e('Error processing art walk completion: $e');
      return [];
    }
  }
}
