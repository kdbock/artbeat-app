import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

/// Service for managing user achievements
class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

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

  /// Get unviewed achievements for the current user
  Future<List<AchievementModel>> getUnviewedAchievements(
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
          .where('isNew', isEqualTo: true)
          .get();

      return achievementsSnapshot.docs
          .map((doc) => AchievementModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error getting unviewed achievements: $e');
      return [];
    }
  }

  /// Mark an achievement as viewed
  Future<bool> markAchievementAsViewed(String achievementId,
      {String? userId}) async {
    try {
      final uid = userId ?? getCurrentUserId();
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .doc(achievementId)
          .update({'isNew': false});

      return true;
    } catch (e) {
      _logger.e('Error marking achievement as viewed: $e');
      return false;
    }
  }

  /// Award an achievement to a user
  Future<bool> awardAchievement(
    String userId,
    AchievementType type,
    Map<String, dynamic> metadata,
  ) async {
    try {
      // Check if user already has this achievement
      final existingQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .where('type', isEqualTo: type.name)
          .limit(1)
          .get();

      if (existingQuery.docs.isEmpty) {
        // Award the achievement
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .add({
          'userId': userId,
          'type': type.name,
          'earnedAt': FieldValue.serverTimestamp(),
          'isNew': true,
          'metadata': metadata,
        });

        // TODO: Send notification to user about the new achievement
        return true;
      }

      // Achievement already exists
      return false;
    } catch (e) {
      _logger.e('Error awarding achievement: $e');
      return false;
    }
  }

  /// Check if user has completed a specific art walk
  Future<bool> hasCompletedArtWalk(String userId, String walkId) async {
    try {
      final completedWalkDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completedWalks')
          .doc(walkId)
          .get();

      return completedWalkDoc.exists;
    } catch (e) {
      _logger.e('Error checking if user completed art walk: $e');
      return false;
    }
  }

  /// Get count of completed art walks for a user
  Future<int> getCompletedArtWalkCount(String userId) async {
    try {
      final completedWalks = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completedWalks')
          .count()
          .get();

      return completedWalks.count ??
          0; // Make sure we handle null case by returning 0
    } catch (e) {
      _logger.e('Error getting completed art walk count: $e');
      return 0;
    }
  }
}
