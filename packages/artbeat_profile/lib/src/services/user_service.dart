import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// User service for profile-related operations
class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('User profile updated for $userId');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Get capture user settings (specific to profile context)
  Future<Map<String, dynamic>?> getCaptureUserSettings(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();

      if (data != null && data.containsKey('captureSettings')) {
        return data['captureSettings'] as Map<String, dynamic>;
      }

      // Return default settings if none exist
      return {
        'autoSave': true,
        'quality': 'high',
        'maxFileSize': 10, // MB
        'enableOCR': true,
        'defaultTags': <String>[],
      };
    } catch (e) {
      debugPrint('Error getting capture user settings: $e');
      return null;
    }
  }

  /// Update capture user settings
  Future<void> updateCaptureUserSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'captureSettings': settings,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Capture settings updated for $userId');
    } catch (e) {
      debugPrint('Error updating capture settings: $e');
      rethrow;
    }
  }

  /// Get user preferences
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();

      if (data != null && data.containsKey('preferences')) {
        return data['preferences'] as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting user preferences: $e');
      return null;
    }
  }

  /// Update user preferences
  Future<void> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'preferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('User preferences updated for $userId');
    } catch (e) {
      debugPrint('Error updating user preferences: $e');
      rethrow;
    }
  }
}
