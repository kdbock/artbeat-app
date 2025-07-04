import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/achievement_type.dart';

/// Service for managing user achievements
class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  /// Award an achievement to the current user
  Future<void> awardAchievement(
    AchievementType type,
    String title,
    String description,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(type.value);

      await docRef.set({
        'type': type.value,
        'title': title,
        'description': description,
        'earnedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _logger.i('Awarded achievement ${type.value} to user $userId');
    } catch (e) {
      _logger.e('Error awarding achievement: $e');
      rethrow;
    }
  }

  /// Check if user has a specific achievement
  Future<bool> hasAchievement(AchievementType type) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(type.value);

      final doc = await docRef.get();
      return doc.exists;
    } catch (e) {
      _logger.e('Error checking achievement: $e');
      return false;
    }
  }

  /// Get all achievements for the current user
  Future<List<Map<String, dynamic>>> getUserAchievements() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      return snapshot.docs
          .map((doc) => doc.data()..['id'] = doc.id)
          .toList();
    } catch (e) {
      _logger.e('Error getting user achievements: $e');
      return [];
    }
  }
}
