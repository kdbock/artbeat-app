import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/profile_customization_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Service for managing profile customization settings
class ProfileCustomizationService extends ChangeNotifier {
  static final ProfileCustomizationService _instance =
      ProfileCustomizationService._internal();
  factory ProfileCustomizationService() => _instance;
  ProfileCustomizationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _customizationCollection =>
      _firestore.collection('profile_customization');

  /// Get profile customization settings for a user
  Future<ProfileCustomizationModel?> getCustomizationSettings(
    String userId,
  ) async {
    try {
      final doc = await _customizationCollection.doc(userId).get();
      if (doc.exists) {
        return ProfileCustomizationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting customization settings: $e');
      return null;
    }
  }

  /// Create default customization settings for a new user
  Future<ProfileCustomizationModel> createDefaultSettings(String userId) async {
    try {
      final now = DateTime.now();
      final defaultSettings = ProfileCustomizationModel(
        userId: userId,
        selectedTheme: 'default',
        primaryColor: '#00fd8a',
        secondaryColor: '#8c52ff',
        showBio: true,
        showLocation: true,
        showAchievements: true,
        showActivity: true,
        layoutStyle: 'grid',
        visibilitySettings: {
          'showEmail': false,
          'showPhone': false,
          'showLocation': true,
          'showBirthdate': false,
        },
        createdAt: now,
        updatedAt: now,
      );

      await _customizationCollection
          .doc(userId)
          .set(defaultSettings.toFirestore());
      return defaultSettings;
    } catch (e) {
      AppLogger.error('Error creating default settings: $e');
      rethrow;
    }
  }

  /// Update profile customization settings
  Future<void> updateCustomizationSettings(
    ProfileCustomizationModel settings,
  ) async {
    try {
      final updatedSettings = settings.copyWith(updatedAt: DateTime.now());
      await _customizationCollection
          .doc(settings.userId)
          .set(updatedSettings.toFirestore(), SetOptions(merge: true));
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error updating customization settings: $e');
      rethrow;
    }
  }

  /// Update specific theme settings
  Future<void> updateTheme(
    String userId,
    String theme,
    String primaryColor,
    String secondaryColor,
  ) async {
    try {
      await _customizationCollection.doc(userId).update({
        'selectedTheme': theme,
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error updating theme: $e');
      rethrow;
    }
  }

  /// Update visibility settings
  Future<void> updateVisibilitySettings(
    String userId,
    Map<String, bool> visibilitySettings,
  ) async {
    try {
      await _customizationCollection.doc(userId).update({
        'visibilitySettings': visibilitySettings,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error updating visibility settings: $e');
      rethrow;
    }
  }

  /// Update cover photo
  Future<void> updateCoverPhoto(String userId, String? coverPhotoUrl) async {
    try {
      await _customizationCollection.doc(userId).update({
        'coverPhotoUrl': coverPhotoUrl,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error updating cover photo: $e');
      rethrow;
    }
  }

  /// Delete customization settings (reset to defaults)
  Future<void> resetToDefaults(String userId) async {
    try {
      await _customizationCollection.doc(userId).delete();
      await createDefaultSettings(userId);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error resetting to defaults: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    // Singleton pattern - don't dispose
    super.dispose();
  }
}
